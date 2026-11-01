
-- GET TRADE LICENSE | ADOPT ME
-- Standalone: No ZekeHub, No Farming

repeat task.wait(0.2) until game:IsLoaded()

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

while not player do
    task.wait(0.2)
    player = Players.LocalPlayer
end

local env = (type(getgenv) == "function"
    and getgenv()) or _G

if env.__GetTradeLicenseRunning then
    warn("[GET-LICENSE] Already running")
    return
end

env.__GetTradeLicenseRunning = true

local LOG_FILE = "GetTradeLicense.log"

local function log(level, message)
    local line = ("[GET-LICENSE][%s] %s")
        :format(level, tostring(message))

    if level == "ERROR" or level == "FAIL" then
        warn(line)
    else
        print(line)
    end

    if type(appendfile) == "function" then
        pcall(function()
            if type(isfile) == "function"
                and not isfile(LOG_FILE)
                and type(writefile) == "function" then
                writefile(LOG_FILE, "")
            end

            appendfile(
                LOG_FILE,
                os.date("%Y-%m-%d %H:%M:%S ")
                    .. line .. "\n"
            )
        end)
    end
end

local function main()
    log("START", "User=" .. player.Name)

    local fsysObject = RS:WaitForChild("Fsys", 30)
    assert(fsysObject, "Fsys not found")

    local fsys = require(fsysObject).load
    assert(type(fsys) == "function",
        "Fsys.load unavailable")

    local ClientData = fsys("ClientData")
    local RouterClient = fsys("RouterClient")

    assert(ClientData and RouterClient,
        "ClientData / RouterClient unavailable")

    local function hasLicense()
        if type(ClientData.get_data) ~= "function" then
            return nil
        end

        local ok, raw = pcall(function()
            return ClientData.get_data()
        end)

        if not ok or type(raw) ~= "table" then
            return nil
        end

        local own = raw[player.Name]
            or raw[tostring(player.UserId)]
            or raw[player.UserId]

        if type(own) ~= "table" then
            return nil
        end

        local inventory = own.inventory
        local toys = type(inventory) == "table"
            and inventory.toys

        if type(toys) ~= "table" then
            return nil
        end

        for _, toy in pairs(toys) do
            if type(toy) == "table"
                and toy.id == "trade_license" then
                return true
            end
        end

        return false
    end

    local function fire(route, ...)
        local remote = RouterClient.get(route)
        assert(remote, "Remote unavailable: " .. route)
        remote:FireServer(...)
    end

    -- Wait for inventory
    for _ = 1, 30 do
        if hasLicense() ~= nil then
            break
        end
        task.wait(0.5)
    end

    -- Skip accounts with license
    if hasLicense() == true then
        log("SUCCESS", "License already owned")
        return
    end

    for attempt = 1, 2 do
        log("INFO", "Quiz attempt " .. attempt .. "/2")

        local ok, err = pcall(function()
            fire(
                "SettingsAPI/SetBooleanFlag",
                "has_talked_to_trade_quest_npc",
                true
            )

            task.wait(1)

            -- Start license quiz
            fire("TradeAPI/BeginQuiz")

            local questions

            for _ = 1, 20 do
                local found, state = pcall(function()
                    return ClientData.get(
                        "trade_license_quiz_manager"
                    )
                end)

                if found
                    and type(state) == "table"
                    and type(state.quiz) == "table"
                    and #state.quiz > 0 then

                    questions = state.quiz
                    break
                end

                task.wait(0.5)
            end

            assert(questions, "Quiz data unavailable")

            log("INFO", "Questions: " .. #questions)

            -- Submit answers from game data
            for index, question in ipairs(questions) do
                assert(
                    type(question) == "table"
                    and question.answer ~= nil,
                    "Missing answer: " .. index
                )

                fire(
                    "TradeAPI/AnswerQuizQuestion",
                    question.answer
                )

                log("INFO", "Answer sent: " .. index)
                task.wait(1)
            end
        end)

        if not ok then
            log("ERROR", err)
        end

        -- Verify license in inventory
        for _ = 1, 12 do
            if hasLicense() == true then
                log(
                    "SUCCESS",
                    "Trade License verified in Toys"
                )
                return
            end
            task.wait(1)
        end

        if attempt < 2 then
            task.wait(2)
        end
    end

    log(
        "FAIL",
        "License not verified. Check inventory."
    )
end

local ok, err = pcall(main)

if not ok then
    log("ERROR", err)
end

env.__GetTradeLicenseRunning = false
