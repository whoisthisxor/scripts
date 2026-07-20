-- fluent code converted to wind ui
-- [[ KEY SYSTEM LOADER ]] --
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/wendigo5414-cmyk/scripts/refs/heads/main/keysystem.lua"))()
KeySystem.Init()

-- [[ GAME SCRIPT START ]] --
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local WindUI
local ok, result = pcall(function()
    return require("./src/Init")
end)

if ok then
    WindUI = result
else 
    if cloneref(game:GetService("RunService")):IsStudio() then
        WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
    else
        local windUI_Source = game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
        windUI_Source = windUI_Source:gsub("([%w_]+)\\.UserInputType%s*==%s*Enum\\.UserInputType\\.MouseButton1", "(%1.UserInputType == Enum.UserInputType.MouseButton1 or %1.UserInputType == Enum.UserInputType.Touch)")
        windUI_Source = windUI_Source:gsub("([%w_]+)\\.UserInputType%s*==%s*Enum\\.UserInputType\\.MouseMovement", "(%1.UserInputType == Enum.UserInputType.MouseMovement or %1.UserInputType == Enum.UserInputType.Touch)")
        WindUI = loadstring(windUI_Source)()
    end
end

local gameName = "Unknown Game"
pcall(function()
    gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)

local Window = WindUI:CreateWindow({
    Title = "Prime X Hub | " .. gameName,
    Folder = "PXH_Hub",
    Icon = "solar:gamepad-bold",
    HideSearchBar = false,
    OpenButton = {
        Title = "Open PXH Hub",
        CornerRadius = UDim.new(1,0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.8,
        Color = ColorSequence.new(
            Color3.fromHex("#30FF6A"), 
            Color3.fromHex("#e7ff2f")
        )
    },
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

Window:Tag({
    Title = "by PXH",
    Icon = "github",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "solar:home-bold" }),
    Movement = Window:Tab({ Title = "Movement", Icon = "solar:running-bold" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "solar:map-point-bold" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "solar:settings-bold" }),
    AboutUs  = Window:Tab({ Title = "About Us", Icon = "solar:info-circle-bold" })
}

-- ══════════════════════════════════════════
--              LOAD OTHERS.LUA
-- ══════════════════════════════════════════
local ok, OthersFunc = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/wendigo5414-cmyk/FireballxArena/main/Others.lua", true))()
end)

local NumberConverter = nil
if ok and type(OthersFunc) == "function" then
    NumberConverter = OthersFunc(Window, Tabs, WindUI)
else
    WindUI:Notify({
        Title = "Error",
        Content = "Failed to load basic categories from Others.lua",
        Duration = 5
    })
end

local executorName = identifyexecutor and ({identifyexecutor()})[1] or "Unknown"
if type(executorName) == "string" and string.find(string.lower(executorName), "xeno") then
    print("Detected: Xeno")
else
    print("Detected: Non-Xeno (" .. tostring(executorName) .. ")")
end

local function fireTouch(part, toPart)
    if not part or not toPart then return end
    
    if type(executorName) == "string" and string.find(string.lower(executorName), "xeno") then
        firetouchinterest(part, toPart, 0)
    else
        firetouchinterest(part, toPart, 0)
        task.wait(0.01)
        firetouchinterest(part, toPart, 1)
    end
end


local MainSection = Tabs.Main:Section({
    Title = "Farming",
    Box = true,
    BoxBorder = true,
    Expandable = true,
    Opened = true
})

_G.PauseForTreadmill = false
_G.PauseForPlusSign = false
_G.AutoFarmWins = false

MainSection:Toggle({
    Title = "Auto Farm Wins",
    Value = false,
    Callback = function(Value)
        _G.AutoFarmWins = Value
        if Value then
            task.spawn(function()
                while _G.AutoFarmWins do
                    if not _G.PauseForTreadmill and not _G.PauseForPlusSign then
                        pcall(function()
                            local giveWins = workspace:FindFirstChild("GiveWins")
                            if giveWins then
                                local highestNum = -1
                                local highestButton = nil
                                for _, btn in ipairs(giveWins:GetChildren()) do
                                    if string.match(btn.Name, "^Button(%d+)$") then
                                        local num = tonumber(string.match(btn.Name, "^Button(%d+)$"))
                                        if num > highestNum then
                                            local touchPart = btn:FindFirstChild("Touch")
                                            if touchPart and touchPart:IsA("BasePart") then
                                                highestNum = num
                                                highestButton = touchPart
                                            end
                                        end
                                    end
                                end
                                
                                if highestButton then
                                    local lp = game:GetService("Players").LocalPlayer
                                    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                                        local hrp = lp.Character.HumanoidRootPart
                                        hrp.CFrame = highestButton.CFrame * CFrame.new(math.random(-1, 1), math.random(1, 2), math.random(-1, 1))
                                        fireTouch(highestButton, hrp)
                                    end
                                end
                            end
                        end)
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

_G.AutoEquipBest = false
MainSection:Toggle({
    Title = "Auto Equip Best",
    Value = false,
    Callback = function(Value)
        _G.AutoEquipBest = Value
        if Value then
            task.spawn(function()
                while _G.AutoEquipBest do
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("InventoryAction"):InvokeServer("EquipBest")
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})

local EggsSection = Tabs.Main:Section({
    Title = "Eggs",
    Box = true,
    BoxBorder = true,
    Expandable = true,
    Opened = true
})

local EggOptions = {
    "Basic Egg (100)",
    "Rare Egg (3K)",
    "Epic Egg (15K)",
    "Legendary Egg (30K)",
    "Earth Egg (500K)",
    "Moon Egg (1.25M)",
    "Sun Egg (2.5M)",
    "Alien Egg (10M)"
}

local EggPrices = {
    ["Basic Egg (100)"] = {id = "basic_egg", price = 100},
    ["Rare Egg (3K)"] = {id = "rare_egg", price = 3000},
    ["Epic Egg (15K)"] = {id = "epic_egg", price = 15000},
    ["Legendary Egg (30K)"] = {id = "legendary_egg", price = 30000},
    ["Earth Egg (500K)"] = {id = "earth_egg", price = 500000},
    ["Moon Egg (1.25M)"] = {id = "moon_egg", price = 1250000},
    ["Sun Egg (2.5M)"] = {id = "sun_egg", price = 2500000},
    ["Alien Egg (10M)"] = {id = "alien_egg", price = 10000000}
}

local SelectedEgg = "Basic Egg (100)"

_G.AutoOpenEgg = false
EggsSection:Toggle({
    Title = "Auto Open Egg",
    Value = false,
    Callback = function(Value)
        _G.AutoOpenEgg = Value
        if Value then
            task.spawn(function()
                while _G.AutoOpenEgg do
                    pcall(function()
                        local lp = game:GetService("Players").LocalPlayer
                        local winsObj = lp:FindFirstChild("leaderstats") and lp.leaderstats:FindFirstChild("Wins")
                        if winsObj then
                            local currentWins = winsObj.Value
                            local eggData = EggPrices[SelectedEgg]
                            if eggData and currentWins >= eggData.price then
                                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("OpenEgg"):InvokeServer(eggData.id)
                            end
                        end
                    end)
                    task.wait(0.2)
                end
            end)
        end
    end
})

EggsSection:Dropdown({
    Title = "Select Egg",
    Value = "Basic Egg (100)",
    Multi = false,
    Values = EggOptions,
    Callback = function(Value)
        SelectedEgg = Value
    end
})

_G.AutoRebirth = false
MainSection:Toggle({
    Title = "Auto Rebirth",
    Value = false,
    Callback = function(Value)
        _G.AutoRebirth = Value
        if Value then
            task.spawn(function()
                while _G.AutoRebirth do
                    pcall(function()
                        local lp = game:GetService("Players").LocalPlayer
                        local progress = lp.PlayerGui.GUI.Frames.Rebirth.Bar.Progress
                        if progress and progress.Size.X.Scale >= 1 then
                            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("RequestRebirth"):InvokeServer()
                        end
                    end)
                    task.wait(1)
                end
            end)
        end
    end
})



_G.AutoTreadmill = false
MainSection:Toggle({
    Title = "Auto Treadmill",
    Value = false,
    Callback = function(Value)
        _G.AutoTreadmill = Value
        if Value then
            task.spawn(function()
                while _G.AutoTreadmill do
                    if not _G.PauseForPlusSign then
                        pcall(function()
                            local eventPart = workspace:FindFirstChild("Treadmills") and workspace.Treadmills:FindFirstChild("EventTreadmill") and workspace.Treadmills.EventTreadmill:FindFirstChild("Part")
                        if eventPart then
                            if eventPart.Position.Y > 10 then
                                _G.PauseForTreadmill = true
                                local lp = game:GetService("Players").LocalPlayer
                                if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                                    lp.Character.HumanoidRootPart.CFrame = eventPart.CFrame + Vector3.new(0, 3, 0)
                                end
                            else
                                _G.PauseForTreadmill = false
                            end
                        else
                            _G.PauseForTreadmill = false
                        end
                        end)
                    end
                    task.wait(0.2)
                end
                _G.PauseForTreadmill = false
            end)
        else
            _G.PauseForTreadmill = false
        end
    end
})

_G.AutoPlusSign = false
MainSection:Toggle({
    Title = "Auto PlusSign",
    Value = false,
    Callback = function(Value)
        _G.AutoPlusSign = Value
        print("[Auto PlusSign] Toggled:", Value)
        if Value then
            task.spawn(function()
                print("[Auto PlusSign] Loop started...")
                while _G.AutoPlusSign do
                    if _G.AutoPlusSign then
                        print("[Auto PlusSign] Starting check...")
                        local success, err = pcall(function()
                            local lp = game:GetService("Players").LocalPlayer
                            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            if not hrp then
                                print("[Auto PlusSign] WARNING: HumanoidRootPart not found. Skipping.")
                                return 
                            end
                            
                            print("[Auto PlusSign] Looking for workspace.GameBoosts...")
                            local gameBoosts = workspace:FindFirstChild("GameBoosts")
                            if not gameBoosts then
                                print("[Auto PlusSign] ERROR: workspace.GameBoosts NOT FOUND! Cannot proceed.")
                                return
                            end
                            
                            print("[Auto PlusSign] Condition met! Pausing other farms...")
                            _G.PauseForPlusSign = true
                            print("[Auto PlusSign] Waiting 0.5s for other farms to pause...")
                            task.wait(0.5)
                            
                            print("[Auto PlusSign] Saving current position before collecting...")
                            local savedPos = hrp.CFrame
                            
                            local collected = 0
                            local allBoosts = gameBoosts:GetChildren()
                            print("[Auto PlusSign] Total children in GameBoosts: " .. tostring(#allBoosts))
                            
                            for i, boost in ipairs(allBoosts) do
                                print("[Auto PlusSign] Checking child " .. tostring(i) .. ": " .. tostring(boost.Name))
                                if string.match(boost.Name, "PlusSign") then
                                    local textPart = boost:FindFirstChild("TextBasePart")
                                    if textPart then
                                        print("[Auto PlusSign] -> Found TextBasePart. IsA BasePart? " .. tostring(textPart:IsA("BasePart")) .. ", Y Position: " .. tostring(textPart.Position.Y))
                                        if textPart:IsA("BasePart") then
                                            if textPart.Position.Y > 10 then
                                                print("[Auto PlusSign] Found active PlusSign: " .. boost.Name .. " at Y: " .. tostring(textPart.Position.Y))
                                                print("[Auto PlusSign] Teleporting to " .. boost.Name .. "...")
                                                hrp.CFrame = textPart.CFrame
                                                task.wait(0.4)
                                                collected = collected + 1
                                                print("[Auto PlusSign] Collected " .. boost.Name .. "!")
                                            else
                                                print("[Auto PlusSign] Skipping inactive PlusSign: " .. boost.Name .. " (Y: " .. tostring(textPart.Position.Y) .. " is not > 10)")
                                            end
                                        end
                                    else
                                        print("[Auto PlusSign] -> TextBasePart NOT FOUND in " .. boost.Name)
                                    end
                                end
                            end
                            
                            print("[Auto PlusSign] Total collected this run: " .. tostring(collected))
                            print("[Auto PlusSign] Teleporting back to original position...")
                            hrp.CFrame = savedPos
                            task.wait(0.1)
                            
                            print("[Auto PlusSign] Finished. Resuming other farms... Waiting for next 30s cycle.")
                            _G.PauseForPlusSign = false
                        end)
                        if not success then
                            print("[Auto PlusSign] ERROR in pcall:", tostring(err))
                            _G.PauseForPlusSign = false
                        end
                    end
                    if _G.AutoPlusSign then
                        print("[Auto PlusSign] Waiting 30 seconds before next cycle...")
                        task.wait(30)
                    end
                end
                print("[Auto PlusSign] Loop stopped.")
                _G.PauseForPlusSign = false
            end)
        else
            print("[Auto PlusSign] Force stopped, resuming farms.")
            _G.PauseForPlusSign = false
        end
    end
})

WindUI:Notify({
    Title = "Prime X Hub",
    Content = "Script loaded successfully!",
    Duration = 5
})
