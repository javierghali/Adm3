#!/usr/bin/env python3
"""Adopt Me trade screen OCR assistant.
Install: pip install pillow pytesseract
Also install Tesseract OCR (English) and Android platform-tools.
Run: python trade_ocr.py --serial DEVICE
Use --live to enable tapping normal incoming request Accept.
This does not bypass warnings, finalize trades, or modify the game.
"""
import argparse
import io
import re
import subprocess
import time
from dataclasses import dataclass
from PIL import Image, ImageOps
import pytesseract
from pytesseract import Output

@dataclass
class Word:
    text: str
    x: int
    y: int
    w: int
    h: int
    confidence: float

def adb(args, *cmd):
    return subprocess.run([args.adb, "-s", args.serial, *cmd],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          check=True, timeout=15).stdout

def screenshot(args):
    raw = adb(args, "exec-out", "screencap", "-p")
    with Image.open(io.BytesIO(raw)) as im:
        return im.convert("RGB")

def read_screen(im):
    # Central screen, including the full trade dialog and its buttons.
    w, h = im.size
    left, top = int(w * .15), int(h * .12)
    right, bottom = int(w * .85), int(h * .90)
    crop = im.crop((left, top, right, bottom))
    scale = max(1.0, 1500 / crop.width)
    gray = ImageOps.autocontrast(ImageOps.grayscale(crop))
    gray = gray.resize((round(gray.width * scale), round(gray.height * scale)))
    d = pytesseract.image_to_data(gray, lang="eng",
                                  config="--psm 11", output_type=Output.DICT)
    words = []
    for i, raw in enumerate(d["text"]):
        t = raw.strip()
        try:
            confidence = float(d["conf"][i])
        except (ValueError, TypeError):
            continue
        if not t or confidence < 45:
            continue
        words.append(Word(t, left + round(d["left"][i] / scale),
                          top + round(d["top"][i] / scale),
                          round(d["width"][i] / scale),
                          round(d["height"][i] / scale), confidence))
    return words

def normalize(t):
    return re.sub(r"[^a-z0-9]+", " ", t.lower()).strip()

def center(word):
    return word.x + word.w // 2, word.y + word.h // 2

def exact(words, name):
    return [w for w in words if normalize(w.text) == name]

def button_pair(words, w, h):
    # An Accept candidate must be beside Decline, below the screen midpoint.
    matches = []
    for a in exact(words, "accept"):
        if a.confidence < 70:
            continue
        ax, ay = center(a)
        if not (.45*w < ax < .82*w and .50*h < ay < .88*h):
            continue
        for d in exact(words, "decline"):
            dx, dy = center(d)
            if 0 < ax - dx < .35*w and abs(ay - dy) < .04*h:
                matches.append(a)
                break
    return matches[0] if len(matches) == 1 else None

def classify(words, width, height):
    # OCR order can vary; also check individual keywords conservatively.
    text = normalize(" ".join(w.text for w in words))
    terms = set(text.split())
    if (terms & {"unbalanced", "bannable", "scamming", "captcha", "suspicious"}
        or "real world trading" in text or "not your friend" in text):
        return "SAFETY_WARNING_MANUAL", None
    if ("is this trade fair" in text
        or ("confirm" in terms and "trade" in terms)):
        return "FINAL_CONFIRM_MANUAL", None
    if "next" in terms:
        return "NEXT_MANUAL", None
    if "confirm" in terms:
        return "CONFIRM_MANUAL", None
    request = ("sent you a trade request" in text
               or {"sent", "you", "trade", "request"}.issubset(terms))
    candidate = button_pair(words, width, height)
    if request and candidate:
        return "INCOMING_REQUEST", candidate
    if request:
        return "REQUEST_BUTTON_UNCERTAIN", None
    if "trade" in terms and "accept" in terms and "decline" in terms:
        if re.search(r"\baccept\s+\d+\b", text):
            return "NEGOTIATION_COUNTDOWN", None
        return "NEGOTIATION_MANUAL", None
    if "play" in terms:
        return "START_MENU", None
    return "UNKNOWN", None

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--serial", required=True, help="ADB device serial")
    p.add_argument("--adb", default="adb", help="ADB executable")
    p.add_argument("--tesseract", help="Tesseract executable path")
    p.add_argument("--interval", type=float, default=2.0)
    p.add_argument("--live", action="store_true",
                   help="Tap ordinary incoming request Accept only")
    p.add_argument("--image", help="Inspect a local screenshot once; never taps")
    args = p.parse_args()
    if args.tesseract:
        pytesseract.pytesseract.tesseract_cmd = args.tesseract
    if args.interval < 1:
        p.error("--interval must be at least 1 second")
    if args.image:
        with Image.open(args.image) as src:
            im = src.convert("RGB")
        words = read_screen(im)
        state, button = classify(words, *im.size)
        print("[OCR]", state, "candidate:", center(button) if button else None)
        print("Detected text:", " ".join(w.text for w in words))
        return
    print("[OCR] Mode:", "LIVE request-only" if args.live else "DRY RUN", flush=True)
    print("[OCR] Open the game normally; Ctrl+C to stop.", flush=True)
    last_state = None
    prior_candidate = None
    stable = 0
    tapped = False
    absent = 0
    try:
        while True:
            try:
                im = screenshot(args)
                words = read_screen(im)
                state, button = classify(words, *im.size)
                if state != last_state:
                    print("[OCR]", state, flush=True)
                    last_state = state
                if state == "INCOMING_REQUEST" and button:
                    point = center(button)
                    near = prior_candidate and abs(point[0]-prior_candidate[0]) <= 12 and abs(point[1]-prior_candidate[1]) <= 12
                    stable = stable + 1 if near else 1
                    prior_candidate = point
                    absent = 0
                    if stable >= 2 and not tapped:
                        print("[OCR] Incoming Accept candidate", point, flush=True)
                        if args.live:
                            adb(args, "shell", "input", "tap", str(point[0]), str(point[1]))
                            print("[OCR] Tapped incoming Accept; verify the game response", flush=True)
                        tapped = True
                else:
                    stable, prior_candidate = 0, None
                    absent += 1
                    if absent >= 3:
                        tapped = False
            except Exception as exc:
                stable, prior_candidate = 0, None
                print("[OCR] Read error; no action:", exc, flush=True)
                time.sleep(5)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print("\n[OCR] Stopped")

if __name__ == "__main__":
    main()
