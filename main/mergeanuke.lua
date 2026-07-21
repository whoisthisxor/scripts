-- Roblox "Merge a Nuke!" Auto Merge & Lock Script for bankroll.wtf
-- Written by Antigravity

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Clean up previous execution
if _G.BankrollMergeNukeCleanup then
    pcall(_G.BankrollMergeNukeCleanup)
end

local runId = math.random()
_G.BankrollMergeNukeRunId = runId

local autoMerge = false
local autoLock = false

_G.BankrollMergeNukeCleanup = function()
    _G.BankrollMergeNukeRunId = nil
    autoMerge = false
    autoLock = false
end

-- Resolve Client Modules
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local NukeModules = PlayerScripts:WaitForChild("NukeClientModules", 5)

local HeldNuke, HoldingUI, Config
if NukeModules then
    pcall(function() HeldNuke = require(NukeModules:WaitForChild("HeldNuke")) end)
    pcall(function() HoldingUI = require(NukeModules:WaitForChild("HoldingUI")) end)
    pcall(function() Config = require(NukeModules:WaitForChild("Config")) end)
end

-- Resolves base owner's UserId through multiple fallback strategies
local function getBaseOwnerUserId(base)
    -- 1. Direct attribute check
    local ownerId = base:GetAttribute("OwnerUserId") or base:GetAttribute("ownerUserId") or base:GetAttribute("OwnerId") or base:GetAttribute("Owner")
    if ownerId then
        return tonumber(ownerId)
    end

    -- 2. Check children of Nukes folder (used in NukeClient)
    local Nukes = base:FindFirstChild("Nukes")
    if Nukes then
        for _, nuke in ipairs(Nukes:GetChildren()) do
            local nukeOwner = nuke:GetAttribute("OwnerUserId") or nuke:GetAttribute("ownerUserId")
            if nukeOwner then
                return tonumber(nukeOwner)
            end
        end
    end

    -- 3. Check for child ValueObjects
    local ownerVal = base:FindFirstChild("Owner") or base:FindFirstChild("OwnerUserId")
    if ownerVal and (ownerVal:IsA("ValueObject") or ownerVal:IsA("StringValue") or ownerVal:IsA("IntValue")) then
        return tonumber(ownerVal.Value)
    end

    return nil
end

-- Resolves the local player's base model
local cachedBase = nil
local function findMyBase()
    if cachedBase and cachedBase.Parent then
        return cachedBase
    end
    cachedBase = nil
    local Bases = Workspace:FindFirstChild("Bases")
    if not Bases then return nil end

    for _, base in ipairs(Bases:GetChildren()) do
        local ownerId = getBaseOwnerUserId(base)
        if ownerId == LocalPlayer.UserId then
            cachedBase = base
            return base
        end
    end
    return nil
end

-- Resolves the local player's Nukes folder inside their base
local cachedNukesFolder = nil
local function findMyNukesFolder()
    if cachedNukesFolder and cachedNukesFolder.Parent then
        return cachedNukesFolder
    end
    cachedNukesFolder = nil
    local base = findMyBase()
    local Nukes = base and base:FindFirstChild("Nukes")
    if Nukes then
        cachedNukesFolder = Nukes
        return Nukes
    end
    return nil
end

-- Checks if there is a nuke on the base of the same tier that is not held and not locked
local function getMergeableNuke(tier)
    local nukesFolder = findMyNukesFolder()
    if not nukesFolder then return nil end

    for _, child in ipairs(nukesFolder:GetChildren()) do
        if (child:IsA("BasePart") or child:IsA("Model")) and child:GetAttribute("Tier") == tier then
            local state = child:GetAttribute("State")
            local isLocked = child:GetAttribute("Locked") or child:GetAttribute("Lock")
            if (state == "floor" or state == "based") and not isLocked then
                return child
            end
        end
    end
    return nil
end

-- Finds a pair of identical tier, unlocked floor/based nukes to merge
local function findPairToMerge()
    local nukesFolder = findMyNukesFolder()
    if not nukesFolder then return nil, nil end

    local tierGroups = {}
    for _, child in ipairs(nukesFolder:GetChildren()) do
        if (child:IsA("BasePart") or child:IsA("Model")) then
            local state = child:GetAttribute("State")
            local isLocked = child:GetAttribute("Locked") or child:GetAttribute("Lock")
            if (state == "floor" or state == "based") and not isLocked then
                local tier = child:GetAttribute("Tier")
                if tier then
                    if not tierGroups[tier] then
                        tierGroups[tier] = {}
                    end
                    table.insert(tierGroups[tier], child)
                end
            end
        end
    end

    for tier, list in pairs(tierGroups) do
        if #list >= 2 then
            return list[1], list[2]
        end
    end
    return nil, nil
end

-- Handles dropping the held nuke
local function dropHeldNuke()
    if HeldNuke and HeldNuke.Stop then
        pcall(function() HeldNuke.Stop() end)
    end
    if HoldingUI and HoldingUI.Hide then
        pcall(function() HoldingUI.Hide() end)
    end

    local NukeRemotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
    if NukeRemotes then
        local dropRemote = NukeRemotes:FindFirstChild("Drop") or NukeRemotes:FindFirstChild("DropRequest") or NukeRemotes:FindFirstChild("DropNuke")
        if dropRemote then
            pcall(function() dropRemote:FireServer() end)
        else
            local PickUp = NukeRemotes:FindFirstChild("PickUp")
            if PickUp then
                pcall(function() PickUp:FireServer() end)
            end
        end
    end
end

-- Main Auto Merge Loop
task.spawn(function()
    while _G.BankrollMergeNukeRunId == runId do
        if autoMerge then
            pcall(function()
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not root then return end

                local heldTier = nil
                if HeldNuke and HeldNuke.GetTier then
                    heldTier = HeldNuke.GetTier()
                end

                if heldTier then
                    -- We are currently holding a nuke
                    local target = getMergeableNuke(heldTier)
                    if target then
                        -- Teleport player to target nuke
                        root.CFrame = target:GetPivot()
                        task.wait(0.1)

                        -- Fire Merge Request
                        local Remotes = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Remotes")
                        if Remotes then
                            pcall(function()
                                require(Remotes).MergeRequest:FireServer(target)
                            end)
                        end
                        task.wait(0.2)
                    else
                        -- No matching nuke on base, drop it
                        dropHeldNuke()
                        task.wait(0.3)
                    end
                else
                    -- We are NOT holding a nuke, look for a pair to merge
                    local nuke1, nuke2 = findPairToMerge()
                    if nuke1 and nuke2 then
                        -- Teleport to first nuke
                        root.CFrame = nuke1:GetPivot()
                        task.wait(0.1)

                        -- Pick up first nuke
                        local NukeRemotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
                        local PickUp = NukeRemotes and NukeRemotes:FindFirstChild("PickUp")
                        if PickUp then
                            pcall(function() PickUp:FireServer(nuke1) end)
                        end

                        -- Wait for hold state to be registered
                        local startTime = os.clock()
                        while os.clock() - startTime < 0.5 do
                            if HeldNuke and HeldNuke.GetTier and HeldNuke.GetTier() then
                                break
                            end
                            task.wait(0.05)
                        end

                        -- Teleport to second nuke
                        root.CFrame = nuke2:GetPivot()
                        task.wait(0.1)

                        -- Merge second nuke
                        local Remotes = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Remotes")
                        if Remotes then
                            pcall(function()
                                require(Remotes).MergeRequest:FireServer(nuke2)
                            end)
                        end
                        task.wait(0.2)
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- Auto Lock Base Loop
task.spawn(function()
    while _G.BankrollMergeNukeRunId == runId do
        if autoLock then
            pcall(function()
                local myBase = findMyBase()
                if myBase and myBase:GetAttribute("BaseLocked") ~= true then
                    local NukeRemotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
                    local RequestLockBase = NukeRemotes and NukeRemotes:FindFirstChild("RequestLockBase")
                    if RequestLockBase then
                        RequestLockBase:FireServer()
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- Load UI Library
local Library
if isfile and isfile("mains/uilib.lua") then
    Library = loadstring(readfile("mains/uilib.lua"))()
elseif isfile and isfile("scripts/mains/uilib.lua") then
    Library = loadstring(readfile("scripts/mains/uilib.lua"))()
else
    Library = loadstring(game:HttpGet("https://bankroll.wtf/scripts/uilib.lua"))()
end

table.insert(Library.UnloadCallbacks, function()
    if _G.BankrollMergeNukeCleanup then
        pcall(_G.BankrollMergeNukeCleanup)
    end
end)

-- Main UI Setup
local Window = Library:Window({
    Name = "bankroll.wtf",
    Logo = "rbxassetid://105944724315073",
    Center = true,
    Size = Vector2.new(450, 310)
})

local mainTab = Library:Tab({
    Title = "Main",
    Icon = "rbxassetid://6031075939"
})

local farmSection = mainTab:Section({
    Name = "Nuke Farming",
    ShowTitle = true,
    Side = "Left"
})

farmSection:Toggle({
    Name = "Auto Merge Nukes",
    Default = false,
    Callback = function(value)
        autoMerge = value
    end
})

farmSection:Toggle({
    Name = "Auto Lock Base",
    Default = false,
    Callback = function(value)
        autoLock = value
    end
})
