-- Renamed With Gemini 3.6 Flash
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

if _G.AbyssPrisonLifeCleanup then
    pcall(_G.AbyssPrisonLifeCleanup)
end

local function cleanupContainer(container)
    if container then
        for _, child in pairs(container:GetChildren()) do
            if child.Name == "AbyssKeySystem" or child.Name == "bankroll.wtf" then
                pcall(function()
                    child:Destroy()
                end)
            end
        end
    end
end

pcall(function()
    cleanupContainer(game:GetService("CoreGui"))
end)

pcall(function()
    cleanupContainer(Players.LocalPlayer:WaitForChild("PlayerGui"))
end)

local aimbotEnabled = false
local aimbotFovVisible = false
local teamCheckEnabled = false
local aimPart = "Head"
local aimbotFovRadius = 120
local aimbotStrength = 50

local chamsEnabled = false
local nameEspEnabled = false
local espTeamCheck = false
local espHighlightColor = Color3.fromRGB(255, 0, 0)
local espOutlineColor = Color3.fromRGB(255, 255, 255)

local flyEnabled = false
local noclipEnabled = false
local walkSpeedValue = 16
local flySpeed = 50

local isRightMouseDown = false
local espCache = {}
local fovCircle = nil

local aimbotConnection = nil
local flyConnection = nil
local noclipConnection = nil
local fovConnection = nil
local inputBeganConnection = nil
local inputEndedConnection = nil
local playerRemovingConnection = nil
local characterAddedConnection = nil

local bodyVelocity = nil
local bodyGyro = nil
local flyToggleUI = nil

local function initializeCheat()
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local CurrentCamera = workspace.CurrentCamera

    local function getPlayerCharacter(targetPlayer)
        if targetPlayer and targetPlayer.Character then
            return targetPlayer.Character
        end
        return nil
    end

    local function isTeammate(targetPlayer)
        if not targetPlayer or not Players.LocalPlayer then
            return false
        end
        if targetPlayer.TeamColor and (Players.LocalPlayer.TeamColor and targetPlayer.TeamColor == Players.LocalPlayer.TeamColor) then
            return true
        end
        if targetPlayer.Team and (Players.LocalPlayer.Team and targetPlayer.Team == Players.LocalPlayer.Team) then
            return true
        end
        return false
    end

    local function getClosestPlayerToCursor()
        local closestTarget = nil
        local maxDistance = aimbotFovVisible and aimbotFovRadius or math.huge

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                if not (teamCheckEnabled and isTeammate(player)) then
                    local char = player.Character
                    if char and char:FindFirstChild(aimPart) then
                        local viewportPoint, isOnScreen = CurrentCamera:WorldToViewportPoint(char[aimPart].Position)
                        if isOnScreen then
                            local mouseLocation = UserInputService:GetMouseLocation()
                            local screenDistance = (Vector2.new(viewportPoint.X, viewportPoint.Y) - mouseLocation).Magnitude
                            if screenDistance < maxDistance then
                                maxDistance = screenDistance
                                closestTarget = player
                            end
                        end
                    end
                end
            end
        end
        return closestTarget
    end

    local function smoothAimAt(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        local targetPart = targetPlayer.Character:FindFirstChild(aimPart)
        if targetPart then
            CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(
                CFrame.new(CurrentCamera.CFrame.Position, targetPart.Position),
                math.clamp(aimbotStrength / 100, 0.01, 1)
            )
        end
    end

    local function createFovCircle()
        if fovCircle then
            pcall(function()
                fovCircle:Remove()
            end)
        end
        if Drawing then
            fovCircle = Drawing.new("Circle")
            fovCircle.Visible = aimbotFovVisible
            fovCircle.Radius = aimbotFovRadius
            fovCircle.Thickness = 1.5
            fovCircle.Color = Color3.fromRGB(255, 255, 255)
            fovCircle.Filled = false
            fovCircle.NumSides = 64
            fovCircle.Position = UserInputService:GetMouseLocation()
        end
    end

    local function updateFovCircle()
        if fovCircle then
            fovCircle.Visible = aimbotFovVisible
            fovCircle.Radius = aimbotFovRadius
            fovCircle.Position = UserInputService:GetMouseLocation()
        end
    end

    local function startAimbotLoop()
        if aimbotConnection then
            aimbotConnection:Disconnect()
        end
        aimbotConnection = RunService.RenderStepped:Connect(function()
            if aimbotEnabled and isRightMouseDown then
                local closest = getClosestPlayerToCursor()
                if closest then
                    smoothAimAt(closest)
                end
            end
        end)
    end

    local function stopAimbotLoop()
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end

    local function removeEspForPlayer(targetPlayer)
        if espCache[targetPlayer] then
            pcall(function()
                if espCache[targetPlayer].highlight then
                    espCache[targetPlayer].highlight:Destroy()
                end
                if espCache[targetPlayer].billboard then
                    espCache[targetPlayer].billboard:Destroy()
                end
            end)
            espCache[targetPlayer] = nil
        end
    end

    local function clearAllEsp()
        for player, _ in pairs(espCache) do
            removeEspForPlayer(player)
        end
        espCache = {}
    end

    local function updateEsp()
        if not chamsEnabled and not nameEspEnabled then
            clearAllEsp()
            return
        end

        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                if espTeamCheck and isTeammate(player) then
                    removeEspForPlayer(player)
                else
                    local char = player.Character
                    local isAlive = char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0
                    
                    if isAlive then
                        local playerEspData = espCache[player] or {}

                        if chamsEnabled then
                            if not playerEspData.highlight or playerEspData.highlight.Parent ~= char then
                                if playerEspData.highlight then
                                    pcall(function() playerEspData.highlight:Destroy() end)
                                end
                                local highlight = Instance.new("Highlight")
                                highlight.Name = "AbyssHighlight"
                                highlight.FillColor = espHighlightColor
                                highlight.OutlineColor = espOutlineColor
                                highlight.FillTransparency = 0.5
                                highlight.OutlineTransparency = 0.2
                                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                highlight.Adornee = char
                                highlight.Parent = char
                                playerEspData.highlight = highlight
                            else
                                playerEspData.highlight.FillColor = espHighlightColor
                                playerEspData.highlight.OutlineColor = espOutlineColor
                            end
                        else
                            if playerEspData.highlight then
                                pcall(function() playerEspData.highlight:Destroy() end)
                                playerEspData.highlight = nil
                            end
                        end

                        if nameEspEnabled then
                            local head = char:FindFirstChild("Head")
                            if head then
                                if not playerEspData.billboard or playerEspData.billboard.Parent ~= head then
                                    if playerEspData.billboard then
                                        pcall(function() playerEspData.billboard:Destroy() end)
                                    end
                                    local billboard = Instance.new("BillboardGui")
                                    billboard.Name = "AbyssNameESP"
                                    billboard.Adornee = head
                                    billboard.Size = UDim2.new(0, 200, 0, 50)
                                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                                    billboard.AlwaysOnTop = true

                                    local textLabel = Instance.new("TextLabel", billboard)
                                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                                    textLabel.BackgroundTransparency = 1
                                    textLabel.Text = player.Name
                                    textLabel.TextColor3 = espHighlightColor
                                    textLabel.TextStrokeTransparency = 0
                                    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                    textLabel.Font = Enum.Font.GothamBold
                                    textLabel.TextSize = 13

                                    billboard.Parent = head
                                    playerEspData.billboard = billboard
                                else
                                    local label = playerEspData.billboard:FindFirstChildOfClass("TextLabel")
                                    if label then
                                        label.TextColor3 = espHighlightColor
                                        label.Text = player.Name
                                    end
                                end
                            end
                        else
                            if playerEspData.billboard then
                                pcall(function() playerEspData.billboard:Destroy() end)
                                playerEspData.billboard = nil
                            end
                        end

                        espCache[player] = playerEspData
                    else
                        removeEspForPlayer(player)
                    end
                end
            end
        end
    end

    local function fetchWeapon(giverGetter)
        local localChar = Players.LocalPlayer.Character
        if not localChar then return end
        local hrp = localChar:FindFirstChild("HumanoidRootPart")
        local giver = giverGetter()
        if hrp and giver then
            local oldCFrame = hrp.CFrame
            hrp.CFrame = giver.CFrame
            task.wait(0.2)
            if hrp then
                hrp.CFrame = oldCFrame
            end
        end
    end

    local function applyWalkSpeed()
        local localChar = Players.LocalPlayer.Character
        local humanoid = localChar and localChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = walkSpeedValue
        end
    end

    local function enableFly()
        if not flyEnabled then return end
        local localChar = Players.LocalPlayer.Character
        if not localChar then return end
        local hrp = localChar:FindFirstChild("HumanoidRootPart")
        local humanoid = localChar:FindFirstChildOfClass("Humanoid")
        if not hrp then return end

        if humanoid then
            humanoid.PlatformStand = true
        end

        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end

        bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = hrp

        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp

        if flyConnection then flyConnection:Disconnect() end

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not bodyVelocity or not bodyGyro then return end
            local currentHrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not currentHrp then return end

            local cameraCFrame = CurrentCamera.CFrame
            bodyGyro.CFrame = CFrame.new(currentHrp.Position, currentHrp.Position + Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z))
            bodyVelocity.Velocity = cameraCFrame.LookVector * flySpeed
        end)
    end

    local function disableFly()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        if bodyGyro then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
        local localChar = Players.LocalPlayer.Character
        local humanoid = localChar and localChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end

    local function setFlyState(state)
        flyEnabled = state
        if flyEnabled then
            enableFly()
        else
            disableFly()
        end
        if flyToggleUI then
            flyToggleUI:Set(state)
        end
    end

    local function enableNoclip()
        if noclipConnection then
            noclipConnection:Disconnect()
        end
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled then
                local localChar = Players.LocalPlayer.Character
                if localChar then
                    for _, part in pairs(localChar:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end

    local function disableNoclip()
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        local localChar = Players.LocalPlayer.Character
        if localChar then
            for _, part in pairs(localChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightMouseDown = true
        end
        if input.KeyCode == Enum.KeyCode.F then
            setFlyState(not flyEnabled)
        end
    end)

    inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightMouseDown = false
        end
    end)

    fovConnection = RunService.RenderStepped:Connect(function()
        if fovCircle and fovCircle.Visible then
            fovCircle.Position = UserInputService:GetMouseLocation()
        end
    end)

    playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
        removeEspForPlayer(player)
    end)

    characterAddedConnection = Players.LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        local humanoid = newCharacter:WaitForChild("Humanoid", 5)
        if humanoid then
            task.wait(0.5)
            humanoid.WalkSpeed = walkSpeedValue
        end
    end)

    _G.AbyssPrisonLifeCleanup = function()
        stopAimbotLoop()
        disableFly()
        disableNoclip()
        clearAllEsp()

        if fovCircle then
            pcall(function()
                fovCircle:Remove()
            end)
        end

        if inputBeganConnection then inputBeganConnection:Disconnect() end
        if inputEndedConnection then inputEndedConnection:Disconnect() end
        if fovConnection then fovConnection:Disconnect() end
        if playerRemovingConnection then playerRemovingConnection:Disconnect() end
        if characterAddedConnection then characterAddedConnection:Disconnect() end
    end

    task.spawn(function()
        while true do
            pcall(updateEsp)
            task.wait(0.2)
        end
    end)

    local library = loadstring(game:HttpGet("https://bankroll.wtf/scripts/uilib.lua"))()
    library:Window({
        ["Name"] = "bankroll.wtf",
        ["Logo"] = "rbxassetid://105944724315073",
        ["Center"] = true,
        ["Size"] = Vector2.new(450, 600)
    })

    local aimbotTab = library:Tab({
        ["Title"] = "Aimbot",
        ["Icon"] = "rbxassetid://3926305904"
    })
    local aimbotSection = aimbotTab:Section({
        ["Name"] = "Aimbot Settings"
    })
    aimbotSection:Toggle({
        ["Name"] = "Enable Aimbot",
        ["Default"] = false,
        ["Callback"] = function(state)
            aimbotEnabled = state
            if state then
                startAimbotLoop()
            else
                stopAimbotLoop()
            end
        end
    })
    aimbotSection:Toggle({
        ["Name"] = "Show FOV Circle",
        ["Default"] = false,
        ["Callback"] = function(state)
            aimbotFovVisible = state
            if not fovCircle then
                createFovCircle()
            end
            if fovCircle then
                fovCircle.Visible = state
            end
        end
    })
    aimbotSection:Toggle({
        ["Name"] = "Team Check",
        ["Default"] = false,
        ["Callback"] = function(state)
            teamCheckEnabled = state
        end
    })
    aimbotSection:Dropdown({
        ["Name"] = "Aim Part",
        ["Options"] = {
            "Head",
            "HumanoidRootPart",
            "UpperTorso",
            "LowerTorso"
        },
        ["Default"] = "Head",
        ["Callback"] = function(selectedPart)
            aimPart = selectedPart
        end
    })
    aimbotSection:Slider({
        ["Name"] = "Aimbot FOV",
        ["Min"] = 30,
        ["Max"] = 360,
        ["Default"] = 120,
        ["Callback"] = function(value)
            aimbotFovRadius = value
            if fovCircle then
                updateFovCircle()
            end
        end
    })
    aimbotSection:Slider({
        ["Name"] = "Strength",
        ["Min"] = 1,
        ["Max"] = 100,
        ["Default"] = 50,
        ["Callback"] = function(value)
            aimbotStrength = value
        end
    })

    local espTab = library:Tab({
        ["Title"] = "ESP",
        ["Icon"] = "rbxassetid://3926305904"
    })
    local espSection = espTab:Section({
        ["Name"] = "ESP Settings"
    })
    espSection:Toggle({
        ["Name"] = "Enable Chams",
        ["Default"] = false,
        ["Callback"] = function(state)
            chamsEnabled = state
            updateEsp()
        end
    })
    espSection:Toggle({
        ["Name"] = "Enable Names",
        ["Default"] = false,
        ["Callback"] = function(state)
            nameEspEnabled = state
            updateEsp()
        end
    })
    espSection:Toggle({
        ["Name"] = "Team Check",
        ["Default"] = false,
        ["Callback"] = function(state)
            espTeamCheck = state
            updateEsp()
        end
    })
    espSection:ColorPicker({
        ["Name"] = "Highlight Color",
        ["Default"] = Color3.fromRGB(255, 0, 0),
        ["Callback"] = function(color)
            espHighlightColor = color
            updateEsp()
        end
    })

    local movementTab = library:Tab({
        ["Title"] = "Movement",
        ["Icon"] = "rbxassetid://3926305904"
    })
    local movementSection = movementTab:Section({
        ["Name"] = "Movement Settings"
    })
    flyToggleUI = movementSection:Toggle({
        ["Name"] = "Fly (Press F)",
        ["Default"] = false,
        ["Callback"] = function(state)
            if flyEnabled ~= state then
                setFlyState(state)
            end
        end
    })
    movementSection:Toggle({
        ["Name"] = "Noclip",
        ["Default"] = false,
        ["Callback"] = function(state)
            noclipEnabled = state
            if state then
                enableNoclip()
            else
                disableNoclip()
            end
        end
    })
    movementSection:Slider({
        ["Name"] = "Walk Speed",
        ["Min"] = 16,
        ["Max"] = 250,
        ["Default"] = 16,
        ["Callback"] = function(value)
            walkSpeedValue = value
            applyWalkSpeed()
        end
    })
    movementSection:Slider({
        ["Name"] = "Fly Speed",
        ["Min"] = 10,
        ["Max"] = 200,
        ["Default"] = 50,
        ["Callback"] = function(value)
            flySpeed = value
        end
    })

    local gunsTab = library:Tab({
        ["Title"] = "Guns",
        ["Icon"] = "rbxassetid://3926305904"
    })
    local gunsSection = gunsTab:Section({
        ["Name"] = "Get Weapons"
    })
    gunsSection:Button({
        ["Name"] = "Get MP5",
        ["Callback"] = function()
            fetchWeapon(function()
                return workspace:GetChildren()[186].TouchGiver
            end)
        end
    })
    gunsSection:Button({
        ["Name"] = "Get Shotgun",
        ["Callback"] = function()
            fetchWeapon(function()
                return workspace:GetChildren()[182].TouchGiver
            end)
        end
    })
    gunsSection:Button({
        ["Name"] = "Get Criminal Shotgun",
        ["Callback"] = function()
            fetchWeapon(function()
                return workspace:GetChildren()[205]:GetChildren()[2].TouchGiver
            end)
        end
    })
    gunsSection:Button({
        ["Name"] = "Get AK-47",
        ["Callback"] = function()
            fetchWeapon(function()
                return workspace:GetChildren()[205].TouchGiver.TouchGiver
            end)
        end
    })

    createFovCircle()
end
