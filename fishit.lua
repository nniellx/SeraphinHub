local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    warn("âš ï¸ UI failed to load!")
    return
else
    print("âœ“ UI loaded successfully!")
end

--//services
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local camera = workspace.CurrentCamera
local VIM = game:GetService("VirtualInputManager")

--// Local
local Net               = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local FishingController = require(ReplicatedStorage.Controllers.FishingController)
local Replion           = require(ReplicatedStorage.Packages.Replion)
local ItemUtility       = require(ReplicatedStorage.Shared.ItemUtility)
local VendorUtility     = require(ReplicatedStorage.Shared.VendorUtility)
local Data              = Replion.Client:WaitReplion("Data")
local Items             = ReplicatedStorage:WaitForChild("Items")

--// Modules
local replicateCutscene    = Net["RE/ReplicateCutscene"]
local stopCutscene         = Net["RE/StopCutscene"]
local REFavoriteItem       = Net["RE/FavoriteItem"]
local FavoriteStateChanged = Net["RE/FavoriteStateChanged"]
local REFishingCompleted   = Net["RE/FishingCompleted"]
local REFishCaught         = Net["RE/FishCaught"]
local RETextNotification   = Net["RE/TextNotification"]
local PurchaseRod          = Net["RF/PurchaseFishingRod"]
local PurchaseBait         = Net["RF/PurchaseBait"]
local PurchaseWeather      = Net["RF/PurchaseWeatherEvent"]
local RFChargeRod          = Net["RF/ChargeFishingRod"]
local RFMinigame           = Net["RF/RequestFishingMinigameStarted"]


--//State
local autoInstant = false
local canFish = true
local autoBuyWeather   = false
local sellMode          = "Delay"
local sellDelay         = 60
local inputSellCount    = 50
local autoSellEnabled   = false
local autoFavEnabled = false
local selectedName, selectedRarity = {}, {}
local rodDataList = {}
local rodDisplayNames = {}
local selectedRodId = nil
local baitDataList = {}
local baitDisplayNames = {}
local selectedBaitId = nil
local selectedEvents = {}
local autoEventActive = false
local farmMoneyActive = false
local baseValue = 0
local runningTotal = 0
local targetExtra = 0
local startCFrame


--//Functions & Caller
REFishCaught.OnClientEvent:Connect(function() canFish = true end)
REFishingCompleted.OnClientEvent:Connect(function() canFish = true end)

if replicateCutscene then
    replicateCutscene.OnClientEvent:Connect(function(...)
        warn("[Seraphin] Success Blocked!", ...)
    end)
end

if stopCutscene then
    stopCutscene.OnClientEvent:Connect(function()
        warn("[Seraphin] Success Blocked!")
    end)
end

local success, cutsceneController = pcall(function()
    return require(ReplicatedStorage.Controllers.CutsceneController)
end)

if success and cutsceneController then
    cutsceneController.Play = function(...)
        warn("[Seraphin] Skipped Cutscene!")
    end
    cutsceneController.Stop = function(...)
        warn("[Seraphin] Stop Skipped Cutscene!")
    end
end

warn("[Seraphin] Skipped!")

local tierToRarity = {
    [1] = "Uncommon",
    [2] = "Common",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "Secret"
}

local fishNames = {}
for _, module in ipairs(ReplicatedStorage.Items:GetChildren()) do
    if module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and data.Data and data.Data.Type == "Fishes" then
            table.insert(fishNames, data.Data.Name)
        end
    end
end
table.sort(fishNames)

local favState = {}

FavoriteStateChanged.OnClientEvent:Connect(function(uuid, state)
    rawset(favState, uuid, state)
end)

local function containsOrAll(list, value)
    if not list or #list == 0 then
        return true
    end
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

local function checkAndFavorite(item)
    if not autoFavEnabled then return end

    local info = ItemUtility.GetItemDataFromItemType("Items", item.Id)
    if not info or info.Data.Type ~= "Fishes" then return end

    local rarity = tierToRarity[info.Data.Tier]
    local nameMatches   = containsOrAll(selectedName, info.Data.Name)
    local rarityMatches = containsOrAll(selectedRarity, rarity)

    local isFav = rawget(favState, item.UUID)
    if isFav == nil then
        isFav = item.Favorited
    end

    if (nameMatches or rarityMatches) and not isFav then
        REFavoriteItem:FireServer(item.UUID)
        rawset(favState, item.UUID, true)
    end
end

local function scanInventory()
    if not autoFavEnabled then return end
    for _, item in ipairs(Data:GetExpect({"Inventory", "Items"})) do
        checkAndFavorite(item)
    end
end

Data:OnChange({"Inventory", "Items"}, function()
    if autoFavEnabled then
        scanInventory()
    end
end)

for _, item in ipairs(Items:GetChildren()) do
    if item:IsA("ModuleScript") and item.Name:match("^!!! .+ Rod$") then
        local success, moduleData = pcall(require, item)
        if success and typeof(moduleData) == "table" and moduleData.Data then
            local name = moduleData.Data.Name or "Unknown"
            local id = moduleData.Data.Id or "Unknown"
            local price = moduleData.Price or "???"
            local display = name .. " ($" .. price .. ")"

            table.insert(rodDataList, { Name = name, Id = id, Display = display })
            table.insert(rodDisplayNames, display)
        end
    end
end

local BaitsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Baits")
for _, module in ipairs(BaitsFolder:GetChildren()) do
    if module:IsA("ModuleScript") then
        local success, data = pcall(require, module)
        if success and typeof(data) == "table" and data.Data then
            local name = data.Data.Name or "Unknown"
            local id = data.Data.Id or "Unknown"
            local price = data.Price or "???"
            local display = name .. " ($" .. price .. ")"

            table.insert(baitDataList, { Name = name, Id = id, Display = display })
            table.insert(baitDisplayNames, display)
        end
    end
end

local weatherData = {
    { Name = "Cloudy",     Price = 10000 },
    { Name = "Wind",       Price = 10000 },
    { Name = "Snow",       Price = 15000 },
    { Name = "Storm",      Price = 35000 },
    { Name = "Radiant",    Price = 50000 },
    { Name = "Shark Hunt", Price = 300000 }
}

local dropdownValues = {}
for _, w in ipairs(weatherData) do
    table.insert(dropdownValues, string.format("%s $%d", w.Name, w.Price))
end

local selectedWeathers = {}

local function getPlayerNames()
    local names = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

local playerList = getPlayerNames()
local selectedPlayer = playerList[1] or nil

local abaikanEvent = {
    Cloudy = true, Day = true, ["Increased Luck"] = true,
    Mutated = true, Night = true, Snow = true,
    ["Sparkling Cove"] = true, Storm = true, Wind = true,
    UIListLayout = true, ["Admin - Shocked"] = true,
    ["Admin - Super Mutated"] = true, Radiant = true,
}

local eventOffsets = { ["Worm Hunt"] = 25 }

local currentEventCFrame, originalCFrame = nil, nil
local Floating, FloatFunc = false, nil
local FloatPartName = "FloatPart"
local atFarm, atEvent = false, false
local selectedEvents, autoEventActive = {}, false

local function notify(title, content, duration, icon)
    WindUI:Notify({
        Title = title or "Seraphin",
        Content = content or "",
        Duration = duration or 3,
        Icon = icon or "rbxassetid://120248611602330"
    })
end

local function getEventList()
    local list = {}
    local playerGui = player:WaitForChild("PlayerGui")
    local eventsGui = playerGui:FindFirstChild("Events")
        and playerGui.Events:FindFirstChild("Frame")
        and playerGui.Events.Frame:FindFirstChild("Events")

    if eventsGui then
        for _, e in ipairs(eventsGui:GetChildren()) do
            local displayName
            if e:IsA("Frame") and e:FindFirstChild("DisplayName") then
                displayName = e.DisplayName.Text
            else
                displayName = e.Name
            end
            if displayName and not abaikanEvent[displayName] then
                if displayName:match("^Admin %- (.+)$") then
                    displayName = displayName:gsub("^Admin %- ", "")
                end
                table.insert(list, displayName)
            end
        end
    end
    return list
end

local function getRoot(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart"))
end

local function disableFloat(char)
    Floating = false
    if FloatFunc then FloatFunc:Disconnect() end
    if char then
        local part = char:FindFirstChild(FloatPartName)
        if part then part:Destroy() end
    end
end

local function enableFloat(char, root)
    disableFloat(char)
    Floating = true
    local Float = Instance.new("Part")
    Float.Name, Float.Size = FloatPartName, Vector3.new(3, 0.2, 3)
    Float.Transparency, Float.Anchored, Float.CanCollide = 1, true, true
    Float.Parent = char
    FloatFunc = RunService.Heartbeat:Connect(function()
        if char and char.Parent and Float and root then
            Float.CFrame = root.CFrame * CFrame.new(0, -3.1, 0)
        end
    end)
end

local function findEventTarget(eventName)
    if not eventName or type(eventName) ~= "string" then return nil end
    if eventName:match("^Admin %-") then
        eventName = eventName:gsub("^Admin %- ", "")
    end

    if eventName == "Megalodon Hunt" then
        local props = workspace:FindFirstChild("Props")
        if props then
            local model = props:FindFirstChild("Megalodon Hunt")
            if model and model:IsA("Model") then
                local part = model:FindFirstChild("Megalodon Hunt")
                if part and part:IsA("BasePart") then
                    return part
                end
            end
        end
        return nil
    end

    for _, props in ipairs(workspace:GetChildren()) do
        if props.Name == "Props" then
            for _, model in ipairs(props:GetChildren()) do
                for _, obj in ipairs(model:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Name == "DisplayName" then
                        local txt = obj.ContentText ~= "" and obj.ContentText or obj.Text
                        if txt and string.lower(txt) == string.lower(eventName) then
                            local part = model:FindFirstChild("Part") or obj:FindFirstAncestorOfClass("Model"):FindFirstChild("Part")
                            if part and part:IsA("BasePart") then
                                return part
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function teleportToTarget(eventTarget, offsetY)
    local char, root = player.Character, getRoot(player.Character)
    if not char or not root or not eventTarget then return end
    local targetCFrame = eventTarget.CFrame + Vector3.new(0, offsetY or 7, 0)
    currentEventCFrame = targetCFrame
    char:PivotTo(targetCFrame)
    enableFloat(char, root)
end

local function saveFarmCFrame()
    local char, root = player.Character, getRoot(player.Character)
    if char and root then
        originalCFrame = root.CFrame
    end
end

local function isNearEvent(eventTarget, maxDist)
    local char, root = player.Character, getRoot(player.Character)
    if not char or not root or not eventTarget then return false end
    return (root.Position - eventTarget.Position).Magnitude <= (maxDist or 50)
end

player.CharacterAdded:Connect(function(newChar)
    if autoEventActive then
        task.spawn(function()
            local root = newChar:WaitForChild("HumanoidRootPart", 5)
            if root then
                task.wait(0.3)
                if currentEventCFrame then
                    newChar:PivotTo(currentEventCFrame)
                    enableFloat(newChar, root)
                    notify("Respawned", "Ohnoo got respawned! Back to position..", 3, "refresh-cw")
                elseif originalCFrame then
                    newChar:PivotTo(originalCFrame)
                    enableFloat(newChar, root)
                    notify("Back to Spot", "Success back to position :3", 3, "map-pin")
                end
            end
        end)
    end
end)

local function autoEventLoop()
    saveFarmCFrame()
    while autoEventActive do
        local char, root = player.Character, getRoot(player.Character)
        if char and root then
            local foundEvent = nil
            for _, eventName in ipairs(selectedEvents) do
                local eventTarget = findEventTarget(eventName)
                if eventTarget then
                    foundEvent = {target = eventTarget, name = eventName}
                    break
                end
            end
            if foundEvent then
                if not isNearEvent(foundEvent.target, 40) then
                    local offsetY = eventOffsets[foundEvent.name] or 7
                    teleportToTarget(foundEvent.target, offsetY)
                    notify("Event Spawned", "Teleporting to " .. foundEvent.name, 3, "map-pin")
                end
                atEvent, atFarm = true, false
            else
                if not atFarm and originalCFrame and player.Character then
                    local newRoot = getRoot(player.Character)
                    if newRoot then
                        player.Character:PivotTo(originalCFrame)
                        enableFloat(player.Character, newRoot)
                        currentEventCFrame = nil
                        atFarm, atEvent = true, false
                        notify("Event Ended", "Event ended â†’ Back to spot :3", 3, "flag")
                    end
                end
            end
        end
        task.wait(0.1)
    end
    disableFloat(player.Character)
    if originalCFrame and player.Character then
        local root = getRoot(player.Character)
        if root then
            player.Character:PivotTo(originalCFrame)
            atFarm, atEvent = true, false
            notify("Auto Event Off", "Back to original spot :3", 3, "power")
        end
    end
end

local Window = WindUI:CreateWindow({
    Title = "Seraphin",
    Icon = "rbxassetid://120248611602330",
    Author = "nniellx | Fish It",
    Folder = "SERAPHIN_HUB",
    Size = UDim2.fromOffset(270, 300),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = true,
})

task.spawn(function()
    local timeout = 3
    local start = tick()
    while tick() - start < timeout do
        local WindGui = gethui and gethui():FindFirstChild("WindUI")
        if WindGui then
            for _, obj in ipairs(WindGui:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Text:match("Seraphin") then
                    local gradient = Instance.new("UIGradient")
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(80, 0, 120)),
                        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 0, 180)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(160, 0, 220)),
                        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(120, 0, 180)),
                        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(80, 0, 120))
                    })
                    gradient.Rotation = 45
                    gradient.Parent = obj
                    break
                end
            end
            break
        end
        task.wait()
    end
end)


Window:EditOpenButton({ Enabled = false })
Window:SetToggleKey(nil)

local Chloe = Instance.new('ScreenGui')
local Button = Instance.new('ImageButton')
local Corner = Instance.new('UICorner')
local Scale = Instance.new('UIScale')
local Stroke = Instance.new("UIStroke")
local Gradient = Instance.new("UIGradient")

Chloe.Name = 'ChloeImup'
Chloe.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Chloe.ResetOnSpawn = false
Chloe.Parent = game:GetService('CoreGui')

Button.Name = 'ChloeGemoy'
Button.Parent = Chloe
Button.BackgroundTransparency = 0
Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Button.Size = UDim2.new(0, 40, 0, 40)
Button.Position = UDim2.new(0, 10, 0, 50)
Button.Image = 'rbxassetid://120248611602330'
Button.Draggable = true

Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Button
Scale.Scale = 1
Scale.Parent = Button

local TweenService = game:GetService("TweenService")
Button.MouseEnter:Connect(function()
    TweenService:Create(Scale, TweenInfo.new(0.1), { Scale = 1.2 }):Play()
end)
Button.MouseLeave:Connect(function()
    TweenService:Create(Scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
end)

Stroke.Thickness = 4
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
Stroke.LineJoinMode = Enum.LineJoinMode.Round
Stroke.Color = Color3.fromRGB(145, 110, 255)
Stroke.Parent = Button

Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(90, 0, 130)),
    ColorSequenceKeypoint.new(0.15, Color3.fromRGB(70, 0, 110)),
    ColorSequenceKeypoint.new(0.30, Color3.fromRGB(50, 0, 80)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(30, 0, 50)),
    ColorSequenceKeypoint.new(0.70, Color3.fromRGB(10, 0, 20)),
    ColorSequenceKeypoint.new(0.85, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(90, 0, 130))
})

Gradient.Rotation = 0
Gradient.Parent = Stroke

local isWindowOpen = true
Button.MouseButton1Click:Connect(function()
    if isWindowOpen then
        Window:Close()
    else
        Window:Open()
    end
    isWindowOpen = not isWindowOpen
end)

Window:OnDestroy(function()
    if Chloe then
        Chloe:Destroy()
    end
end)

--//window
local I = Window:Tab({Title = 'Info', Icon = 'rbxassetid://76311199408449', Locked = false,})
local M = Window:Tab({Title = 'Main', Icon = 'rbxassetid://16338529233', Locked = false,})
local S = Window:Tab({Title = 'Shop', Icon = 'rbxassetid://5239139676', Locked = false,})
local T = Window:Tab({Title = 'Map', Icon = 'rbxassetid://5950114098', Locked = false,})
local NU = Window:Tab({Title = 'Menu', Icon = 'rbxassetid://84786186709332', Locked = false,})
local MSC= Window:Tab({Title = 'Misc', Icon = 'rbxassetid://139927660022098', Locked = false,})
local WEB= Window:Tab({Title = 'Webhook', Icon = 'rbxassetid://11395780588', Locked = false,})

Window:SelectTab(1)

I:Section({
    Title = 'Info Script',
    TextXAlignment = 'Left',
    TextSize = 17,
})

I:Divider()

I:Paragraph({
    Title = "Seraphin Hub",
    Desc = "This script is still under development. Check for updates on our Discord! Please report to us if you find any bugs, errors, or patched features."
})

I:Button({
    Title = "Discord",
    Desc = "click to copy link",
    Callback = function()
        if setclipboard then
            setclipboard("discord.gg/getseraphin")
        end
    end
})

M:Section({
    Title = 'Minigame Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

M:Divider()

M:Toggle({
    Title = "Auto Equip Rod",
    Default = false,
    Callback = function(state)
        autoRod = state
        if autoRod then
            task.spawn(function()
                while autoRod do
                    pcall(function()
                        Net["RE/EquipToolFromHotbar"]:FireServer(1)
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

M:Paragraph({
    Title = "Support Fishing",
    Desc = "<font color='rgb(0,191,255)'>For Your Information :3</font>\nSupport fishing is useful to help you know when you get stuck in your minigame! So if your character gets stuck, this feature will reset your character and restore it back to normal."
})

local ST = 15
local SE = false
local FT, ET = 0, 0
local LFC, SCF

local function getFishCount()
    local plr = game.Players.LocalPlayer
    local bagLabel = plr.PlayerGui:WaitForChild("Inventory")
        :WaitForChild("Main")
        :WaitForChild("Top")
        :WaitForChild("Options")
        :WaitForChild("Fish")
        :WaitForChild("Label")
        :WaitForChild("BagSize")
    local bagText = bagLabel.Text or "0/???"
    return tonumber(bagText:match("(%d+)/")) or 0
end

M:Input({
    Title = "Counter Stuck",
    Placeholder = "Input Here",
    Default = "10",
    Callback = function(val)
        ST = tonumber(val) or 15
    end
})

M:Toggle({
    Title = "Enable Support",
    Default = false,
    Callback = function(state)
        SE = state
        if SE then
            local CH = player.Character or player.CharacterAdded:Wait()
            SCF = CH:WaitForChild("HumanoidRootPart").CFrame
            LFC, FT, ET = getFishCount(), 0, 0

            task.spawn(function()
                while SE do
                    task.wait(0.1)

                    ET += 0.1
                    if ET >= 0.5 then
                        ET = 0
                        pcall(function()
                            Net["RE/EquipToolFromHotbar"]:FireServer(1)
                        end)
                    end

                    FT += 0.1
                    local CF = getFishCount()

                    if CF > LFC then
                        LFC, FT = CF, 0
                    elseif CF < LFC then
                        LFC = CF
                    elseif FT >= ST then
                        notify("Stuck Detected! Resetting...")

                        local RC = CH:FindFirstChild("HumanoidRootPart")
                        if RC then SCF = RC.CFrame end
                        CH:BreakJoints()

                        local NCR = player.CharacterAdded:Wait()
                        local NR = NCR:WaitForChild("HumanoidRootPart")
                        NR.CFrame = SCF
                        CH = NCR

                        task.wait(0.5)
                        pcall(function()
                            Net["RE/EquipToolFromHotbar"]:FireServer(1)
                        end)

                        FT = 0
                    end
                end
            end)
        else
            notify("Support Disabled")
        end
    end,
})

M:Toggle({
    Title = "Legit Fishing",
    Default = false,
    Callback = function(state)
        local function clickCenter()
            local vs = camera.ViewportSize
            VIM:SendMouseButtonEvent(vs.X/2, vs.Y/2, 0, true, nil, 0)
            VIM:SendMouseButtonEvent(vs.X/2, vs.Y/2, 0, false, nil, 0)
        end

        if not FishingController._oldGetPower then
            FishingController._oldGetPower = FishingController._getPower
        end

        if state then
            FishingController._getPower = function(...) return 1 end
            task.delay(0.3, clickCenter)

            FishingController._autoLoop = true
            task.spawn(function()
                while FishingController._autoLoop do
                    task.wait(0.1)
                    if not FishingController:GetCurrentGUID() then
                        task.wait(0.1)
                        clickCenter()
                        task.wait(0.1)
                    end
                end
            end)
        else
            if FishingController._oldGetPower then
                FishingController._getPower = FishingController._oldGetPower
            end
            FishingController._autoLoop = false
        end
    end
})

M:Toggle({
    Title = "Instant Fishing",
    Default = false,
    Callback = function(state)
        autoInstant = state
        if autoInstant then
            task.spawn(function()
                while autoInstant do
                    if canFish then
                        canFish = false
                        local t = workspace:GetServerTimeNow()
                        local ok = pcall(function()
                            return RFChargeRod:InvokeServer(t)
                        end)

                        if ok then
                            RFMinigame:InvokeServer(-1, 1)
                            local start = tick()
                            local timeout = 3
                            while not canFish and tick() - start < timeout do
                                task.wait(0.1)
                            end
                            if not canFish then
                                REFishingCompleted:FireServer()
                                canFish = true
                            end
                        else
                            canFish = true
                        end
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
})

M:Toggle({
    Title = "Auto Shake",
    Default = false,
    Callback = function(state)
        Shke = state
        if state then
            task.spawn(function()
                while Shke do
                    if FishingController:GetCurrentGUID() then
                        FishingController:RequestFishingMinigameClick()
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

M:Toggle({
    Title = "Auto Finish Fishing",
    Default = false,
    Callback = function(state)
        Fs = state
        if state then
            task.spawn(function()
                while Fs do
                    local Fe = game:GetService("ReplicatedStorage")
                        :WaitForChild("Packages")
                        :WaitForChild("_Index")
                        :WaitForChild("sleitnick_net@0.2.0")
                        :WaitForChild("net")
                        :WaitForChild("RE/FishingCompleted")

                    Fe:FireServer()
                    task.wait(0.1)
                end
            end)
        end
    end
})

M:Section({
    Title = 'Selling Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

M:Divider()

M:Dropdown({
    Title = "Sell Mode",
    Values = { "Delay", "Input" },
    Value = "Delay",
    Callback = function(option)
        sellMode = option
    end
})

M:Input({
    Title = "Set Value",
    Placeholder = "Input Here",
    Numeric = true,
    Callback = function(val)
        local number = tonumber(val) or 1
        if sellMode == "Delay" then
            sellDelay = number
        else
            inputSellCount = number
        end
    end
})

M:Toggle({
    Title = "Start Selling",
    Default = false,
    Callback = function(state)
        autoSellEnabled = state
        if state then
            task.spawn(function()
                local RFSellAllItems = ReplicatedStorage
                    .Packages
                    ._Index["sleitnick_net@0.2.0"]
                    .net["RF/SellAllItems"]

                while autoSellEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local bagSizeLabel = player.PlayerGui:WaitForChild("Inventory")
                        :WaitForChild("Main")
                        :WaitForChild("Top")
                        :WaitForChild("Options")
                        :WaitForChild("Fish")
                        :WaitForChild("Label")
                        :WaitForChild("BagSize")
                    local bagText = bagSizeLabel.Text or "0/5000"
                    local currentFish = tonumber(bagText:match("(%d+)/")) or 0

                    if sellMode == "Delay" then
                        RFSellAllItems:InvokeServer()
                        task.wait(sellDelay)
                    else
                        if currentFish >= inputSellCount then
                            RFSellAllItems:InvokeServer(inputSellCount)
                        end
                        task.wait()
                    end
                end
            end)
        end
    end
})

M:Section({
    Title = 'Favorited Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

M:Divider()

M:Dropdown({
    Title = "Favorite by Name",
    Values = fishNames,
    Multi = true,
    Search = true,
    AllowNull = true,
    Default = {},
    Callback = function(opts)
        selectedName = opts or {}
    end
})

M:Dropdown({
    Title = "Favorite by Rarity",
    Values = { "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret" },
    Multi = true,
    Search = true,
    AllowNull = true,
    Default = {},
    Callback = function(opts)
        selectedRarity = opts or {}
    end
})

M:Toggle({
    Title = "Start",
    Default = false,
    Callback = function(state)
        autoFavEnabled = state
        if autoFavEnabled then
            scanInventory()
        end
    end
})

S:Section({
    Title = 'Buy Rod',
    TextXAlignment = 'Left',
    TextSize = 17,
})

S:Divider()

S:Dropdown({
    Title = "Select Rod",
    Values = rodDisplayNames,
    Value = rodDisplayNames[1] or "None",
    Callback = function(selected)
        for _, rod in ipairs(rodDataList) do
            if rod.Display == selected then
                selectedRodId = rod.Id
                break
            end
        end
    end
})

S:Button({
    Title = "Buy Selected Rod",
    Callback = function()
        if not selectedRodId then
            return
        end

        local Net = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
        local PurchaseRod = Net:WaitForChild("RF/PurchaseFishingRod")

        PurchaseRod:InvokeServer(selectedRodId)
    end
})

S:Section({
    Title = 'Buy Baits',
    TextXAlignment = 'Left',
    TextSize = 17,
})

S:Divider()

S:Dropdown({
    Title = "Select Bait",
    Values = baitDisplayNames,
    Value = baitDisplayNames[1] or "None",
    Callback = function(selected)
        for _, bait in ipairs(baitDataList) do
            if bait.Display == selected then
                selectedBaitId = bait.Id
                break
            end
        end
    end
})

S:Button({
    Title = "Buy Selected Bait",
    Callback = function()
        if not selectedBaitId then
            return
        end

        local Net = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")
        local PurchaseBait = Net:WaitForChild("RF/PurchaseBait")

        PurchaseBait:InvokeServer(selectedBaitId)
    end
})

S:Section({
    Title = 'Buy Weather',
    TextXAlignment = 'Left',
    TextSize = 17,
})

S:Divider()

S:Dropdown({
    Title = "Select Weather",
    Values = dropdownValues,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        selectedWeathers = {}
        for _, fullName in ipairs(selected) do
            local name = fullName:match("^(.-) %$") or fullName
            table.insert(selectedWeathers, name)
        end
    end
})

S:Toggle({
    Title = "Auto Buy Weather",
    Default = false,
    Callback = function(state)
        local Net = ReplicatedStorage:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("sleitnick_net@0.2.0")
            :WaitForChild("net")

        local PurchaseWeather = Net:WaitForChild("RF/PurchaseWeatherEvent")

        if state then
            task.spawn(function()
                while state do
                    for _, weatherName in ipairs(selectedWeathers) do
                        pcall(function()
                            PurchaseWeather:InvokeServer(weatherName)
                        end)
                        task.wait(0.1)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

T:Section({
    Title = 'Teleport Island',
    TextXAlignment = 'Left',
    TextSize = 17,
})

T:Divider()

local function getKeys(tbl)
    local keyset = {}
    for k in pairs(tbl) do
        table.insert(keyset, k)
    end
    return keyset
end

local locations = {
    ["Treasure Room"] = Vector3.new(-3602.01, -266.57, -1577.18),
    ["Sisyphus Statue"] = Vector3.new(-3703.69, -135.57, -1017.17),
    ["Crater Island Top"] = Vector3.new(1011.29, 22.68, 5076.27),
    ["Crater Island Ground"] = Vector3.new(1079.57, 3.64, 5080.35),
    ["Coral Reefs 1"] = Vector3.new(-3031.88, 2.52, 2276.36),
    ["Coral Reefs 2"] = Vector3.new(-3270.86, 2.50, 2228.10),
    ["Coral Reefs 3"] = Vector3.new(-3136.10, 2.61, 2126.11),
    ["Lost Shore"] = Vector3.new(-3737.97, 5.43, -854.68),
    ["Weather Machine"] = Vector3.new(-1524.88, 2.87, 1915.56),
    ["Kohana Volcano"] = Vector3.new(-561.81, 21.24, 156.72),
    ["Kohana 1"] = Vector3.new(-367.77, 6.75, 521.91),
    ["Kohana 2"] = Vector3.new(-623.96, 19.25, 419.36),
    ["Stingray Shores"] = Vector3.new(44.41, 28.83, 3048.93),
    ["Tropical Grove"] = Vector3.new(-2018.91, 9.04, 3750.59),
    ["Ice Sea"] = Vector3.new(2164, 7, 3269),
    ["Tropical Grove Cave 1"] = Vector3.new(-2151, 3, 3671),
    ["Tropical Grove Cave 2"] = Vector3.new(-2018, 5, 3756),
    ["Tropical Grove Highground"] = Vector3.new(-2139, 53, 3624),
    ["Fisherman Island Underground"] = Vector3.new(-62, 3, 2846),
    ["Fisherman Island Mid"] = Vector3.new(33, 3, 2764),
    ["Fisherman Island Left"] = Vector3.new(-26, 10, 2686),
    ["Fisherman Island Right"] = Vector3.new(95, 10, 2684),
}

local locationNames = getKeys(locations)
local selectedLocation = locationNames[1]

T:Dropdown({
    Title = "Teleport Location",
    Values = locationNames,
    Default = selectedLocation,
    Multi = false,
    Callback = function(value)
        selectedLocation = value
    end,
})

T:Button({
    Title = "Teleport",
    Callback = function()
        local pos = locations[selectedLocation]
        if pos then
            local hrp = game.Players.LocalPlayer.Character and
                game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(pos)
            end
        end
    end,
})

T:Section({
    Title = 'Teleport Player',
    TextXAlignment = 'Left',
    TextSize = 17,
})

T:Divider()

T:Dropdown({
    Title = "Select Player",
    Values = playerList,
    Default = selectedPlayer,
    Multi = false,
    Callback = function(value)
        selectedPlayer = value
    end
})

T:Button({
    Title = "Refresh Player",
    Callback = function()
        playerList = getPlayerNames()
        selectedPlayer = playerList[1] or nil
    end
})

T:Button({
    Title = "Teleport",
    Callback = function()
        if not selectedPlayer then return end
        local target = Players:FindFirstChild(selectedPlayer)
        if not target then return end
        local char = target.Character or target.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
        local myChar = player.Character or player.CharacterAdded:Wait()
        local myHrp = myChar:FindFirstChild("HumanoidRootPart") or myChar:WaitForChild("HumanoidRootPart")
        if hrp and myHrp then
            myHrp.CFrame = hrp.CFrame + Vector3.new(0, 5, 0)
        end
    end
})

T:Section({
    Title = 'Teleport Event',
    TextXAlignment = 'Left',
    TextSize = 17,
})

T:Divider()

T:Dropdown({
    Title = "Select Event",
    Values = getEventList(),
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(options)
        selectedEvents = options
    end
})

T:Toggle({
    Title = "Auto Event",
    Default = false,
    Callback = function(state)
        autoEventActive = state
        if state and #selectedEvents > 0 then
            task.spawn(autoEventLoop)
        end
    end
})

NU:Section({
    Title = 'Trading Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

NU:Divider()

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net                = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local tradeFunc          = Net["RF/InitiateTrade"]
local RETextNotification = Net["RE/TextNotification"]

local Data               = require(ReplicatedStorage.Packages.Replion).Client:WaitReplion("Data")
local ItemUtility        = require(ReplicatedStorage.Shared.ItemUtility)
local TradingController  = require(ReplicatedStorage.Controllers.ItemTradingController)

local TradeState = {
    selectedPlayer = nil,
    selectedItem   = nil,
    tradeAmount    = 1,
    trading        = false,
    successCount   = 0,
    failCount      = 0,
    totalToTrade   = 0,
    awaiting       = false,
    currentGrouped = {},
    lastResult     = nil
}

local function safeGetHui()
    local funcs = { gethui, get_hidden_ui, syn and syn.protect_gui }
    for _, f in ipairs(funcs) do
        if typeof(f) == "function" then
            local ok, ui = pcall(f)
            if ok and ui then return ui end
        end
    end
end
local WindGui = CoreGui:FindFirstChild("WindUI")
    or (safeGetHui() and safeGetHui():FindFirstChild("WindUI"))
    or Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("WindUI")

local tradeParagraph = NU:Paragraph({
    Title = "Monitoring Trade Status",
    Desc  = "ChloePrettyGirl"
})

local function setStatus(info)
    local desc = string.format(
        "Trade to : %s\nAmount : %d\n%s\nStatus : %d/%d (%d failed)",
        TradeState.selectedPlayer or "???",
        TradeState.tradeAmount or 0,
        info or "<font color='#999999'>Progress : Idle</font>",
        TradeState.successCount,
        TradeState.totalToTrade,
        TradeState.failCount
    )

    if tradeParagraph.SetDesc then
        tradeParagraph:SetDesc(desc)
    else
        tradeParagraph.Desc = desc
    end
end

local function getGroupedByType(typeName)
    local items = Data:GetExpect({ "Inventory", "Items" })
    local grouped, values = {}, {}
    for _, item in ipairs(items) do
        local info = ItemUtility.GetItemDataFromItemType("Items", item.Id)
        if info and info.Data.Type == typeName then
            local name = info.Data.Name
            grouped[name] = grouped[name] or { count = 0, uuids = {} }
            grouped[name].count += (item.Quantity or 1)
            table.insert(grouped[name].uuids, item.UUID)
        end
    end
    for name, data in pairs(grouped) do
        table.insert(values, ("%s | Total %dx"):format(name, data.count))
    end
    return grouped, values
end

local itemDropdown = NU:Dropdown({
    Title = "Select Item",
    Values = {},
    Multi = false,
    Callback = function(value)
        TradeState.selectedItem = value and value:match("^(.-) %|")
        setStatus(nil)
    end
})

NU:Button({
    Title = "Refresh Fish",
    Callback = function()
        TradeState.currentGrouped, values = getGroupedByType("Fishes")
        itemDropdown:Refresh(values)
    end
})

NU:Button({
    Title = "Refresh Stone",
    Callback = function()
        TradeState.currentGrouped, values = getGroupedByType("EnchantStones")
        itemDropdown:Refresh(values)
    end
})

NU:Input({
    Title = "Amount to Trade",
    Placeholder = "Enter Number",
    Default = "1",
    Callback = function(value)
        TradeState.tradeAmount = tonumber(value) or 1
        setStatus(nil)
    end
})

local playerList = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= Players.LocalPlayer then
        table.insert(playerList, plr.Name)
    end
end

local playerDropdown = NU:Dropdown({
    Title = "Select Player",
    Values = playerList,
    Value = playerList[1],
    Multi = false,
    Callback = function(value)
        TradeState.selectedPlayer = value
        setStatus(nil)
    end
})

NU:Button({
    Title = "Refresh Player",
    Callback = function()
        local names = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Players.LocalPlayer then
                table.insert(names, plr.Name)
            end
        end
        playerDropdown:Refresh(names)
    end
})

RETextNotification.OnClientEvent:Connect(function(data)
    if not TradeState.trading then return end
    if not data or not data.Text then return end
    local msg = data.Text

    if msg:find("Trade was declined") then
        TradeState.awaiting = false
        TradeState.lastResult = "declined"
        setStatus("<font color='#ff3333'>Progress : Trade declined</font>")
    elseif msg:find("Trade completed") then
        TradeState.awaiting = false
        TradeState.lastResult = "completed"
        setStatus("<font color='#00cc66'>Progress : Trade success</font>")
    elseif msg:find("Sent trade request") then
        setStatus("<font color='#daa520'>Progress : Waiting player...</font>")
    end
end)

TradingController.CompletedTrade = function()
    if TradeState.trading then
        TradeState.awaiting = false
        TradeState.lastResult = "completed"
    end
end
TradingController.OnTradeCancelled = function()
    if TradeState.trading then
        TradeState.awaiting = false
        TradeState.lastResult = "declined"
    end
end

local function sendTrade(target, uuid, itemName)
    while TradeState.trading do
        TradeState.awaiting = true
        TradeState.lastResult = nil
        setStatus("<font color='#3399ff'>Sending " .. (itemName or "Item") .. "...</font>")

        pcall(function()
            tradeFunc:InvokeServer(target.UserId, uuid)
        end)

        local startTime = tick()
        while TradeState.trading and TradeState.awaiting do
            task.wait()
            if tick() - startTime > 6 then
                TradeState.awaiting = false
                TradeState.lastResult = "timeout"
                break
            end
        end

        if TradeState.lastResult == "completed" then
            TradeState.successCount += 1
            setStatus("<font color='#00cc66'>Success : " .. (itemName or "Item") .. "</font>")
            return true
        elseif TradeState.lastResult == "declined" then
            TradeState.failCount += 1
            setStatus("<font color='#ff3333'>Declined : " .. (itemName or "Item") .. "</font>")
            return true
        else
            setStatus("<font color='#ffaa00'>Retrying " .. (itemName or "Item") .. "...</font>")
            task.wait()
        end
    end
    return false
end

local function startTrade()
    if TradeState.trading then return end
    if not TradeState.selectedPlayer or not TradeState.selectedItem then
        return warn("Not Completed")
    end

    TradeState.trading = true
    TradeState.successCount, TradeState.failCount = 0, 0

    local itemData = TradeState.currentGrouped[TradeState.selectedItem]
    if not itemData then
        setStatus("<font color='#ff3333'>Item not found</font>")
        TradeState.trading = false
        return
    end

    local target = Players:FindFirstChild(TradeState.selectedPlayer)
    if not target then
        setStatus("<font color='#ff3333'>Player not found</font>")
        TradeState.trading = false
        return
    end

    local uuids = itemData.uuids
    TradeState.totalToTrade = math.min(TradeState.tradeAmount, #uuids)

    for i = 1, TradeState.totalToTrade do
        if not TradeState.trading then break end
        local uuid = uuids[i]
        sendTrade(target, uuid, TradeState.selectedItem)
    end

    TradeState.trading = false
    setStatus(string.format(
        "<font color='#66ccff'>Progress : All trades finished! (%d/%d, %d failed)</font>",
        TradeState.successCount,
        TradeState.totalToTrade,
        TradeState.failCount
    ))

    tradeParagraph.Desc = [[
<font color="rgb(255,105,180)">ðŸŒŒ </font>
<font color="rgb(135,206,250)">SERAPHIN TRADING COMPLETE!</font>
<font color="rgb(255,105,180)"> ðŸŒŒ</font>
]]
end

NU:Toggle({
    Title = "Auto Trade",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(startTrade)
        else
            TradeState.trading = false
            TradeState.awaiting = false
            setStatus("<font color='#999999'>Progress : Idle</font>")
        end
    end
})

NU:Section({
    Title = 'Money Threshold Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

NU:Divider()

local function tpTo(cf, rotate180)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local finalCF = cf
    if rotate180 then
        finalCF = cf * CFrame.Angles(0, math.rad(180), 0)
    end
    char:PivotTo(finalCF + Vector3.new(0, 5, 0))
end

local function saveStartPosition()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        startCFrame = char.HumanoidRootPart.CFrame
    end
end

local function getBackpackValue()
    local items = Data:GetExpect({ "Inventory", "Items" })
    local total = 0
    for _, item in ipairs(items) do
        local price = VendorUtility:GetSellPrice(item)
        if price then
            total += price
        end
    end
    return total
end

local function notifyProgress()
    notify(string.format("Money Progress: %s / %s", runningTotal, baseValue + targetExtra))
end

local function checkGoal()
    notifyProgress()
    if targetExtra > 0 and runningTotal >= baseValue + targetExtra then
        farmMoneyActive = false
        task.spawn(function()
            if startCFrame then
                tpTo(startCFrame, false)
            end
            notify("Target money achieved!")
        end)
    end
end

REFishCaught.OnClientEvent:Connect(function()
    if farmMoneyActive then
        runningTotal = getBackpackValue()
        checkGoal()
    end
end)

NU:Input({
    Title = "Target Money",
    Placeholder = "Input here",
    Default = "0",
    Callback = function(val)
        targetExtra = tonumber(val) or 0
    end
})

NU:Toggle({
    Title = "Start",
    Default = false,
    Callback = function(state)
        farmMoneyActive = state
        if state then
            saveStartPosition()
            baseValue = getBackpackValue()
            runningTotal = baseValue
            tpTo(CFrame.new(-565, 22, 153), true)
            checkGoal()
        end
    end
})

NU:Section({
    Title = 'Stones Threshold Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

NU:Divider()

local function tpTo(cf, rotate180)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local finalCF = cf
    if rotate180 then
        finalCF = cf * CFrame.Angles(0, math.rad(180), 0)
    end
    char:PivotTo(finalCF + Vector3.new(0, 5, 0))
end

local function saveStartPosition()
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        startCFrame = char.HumanoidRootPart.CFrame
    end
end

local function getStoneCount()
    local items = Data:GetExpect({"Inventory", "Items"})
    local total = 0
    for _, item in ipairs(items) do
        local info = ItemUtility.GetItemDataFromItemType("Items", item.Id)
        if info and info.Data.Type == "EnchantStones" then
            total += item.Quantity or 1
        end
    end
    return total
end

local function checkStoneGoal()
    if targetStones > 0 and runningStones >= baseStones + targetStones then
        farmStonesActive = false
        task.spawn(function()
            if startCFrame then
                tpTo(startCFrame, false)
            end
            notify("Target stones achieved!")
        end)
    end
end

task.spawn(function()
    local last = 0
    while true do
        task.wait(1)
        if farmStonesActive then
            local current = getStoneCount()
            if current ~= runningStones then
                runningStones = current
                notify(string.format("Stone Progress: %s / %s", runningStones, baseStones + targetStones))
                checkStoneGoal()
            end
        end
    end
end)

NU:Input({
    Title = "Target Stones",
    Placeholder = "Input Here",
    Default = "0",
    Callback = function(val)
        targetStones = tonumber(val) or 0
    end
})

NU:Toggle({
    Title = "Start",
    Default = false,
    Callback = function(state)
        farmStonesActive = state
        if state then
            saveStartPosition()
            baseStones = getStoneCount()
            runningStones = baseStones
            tpTo(CFrame.new(-2083, 6, 3660), true)
            notify(string.format("ðŸ”® Stone Progress: %s / %s", runningStones, baseStones + targetStones))
            checkStoneGoal()
        end
    end
})

NU:Section({
    Title = 'Quest Features',
    TextXAlignment = 'Left',
    TextSize = 17,
})

NU:Divider()

local questColors = {
    [1] = "rgb(0,191,255)",
    [2] = "rgb(255,50,50)",
    [3] = "rgb(50,255,100)",
    [4] = "rgb(255,165,0)"
}

local QuestParagraph = NU:Paragraph({
    Title = "Deep Sea Tracker",
    Desc = "No quest detected"
})

local function getQuestLabels()
    local labels = {}
    local content = workspace["!!! MENU RINGS"]["Deep Sea Tracker"].Board.Gui.Content
    for i = 1, 4 do
        local lbl = content:FindFirstChild("Label"..i)
        if lbl and lbl:IsA("TextLabel") then
            table.insert(labels, lbl)
        end
    end
    return labels
end

local function updateQuestPanel()
    local labels = getQuestLabels()
    if #labels == 0 then
        QuestParagraph:SetDesc("No quest detected")
        return nil
    end

    local lines = {"Your Progress now :"}
    for i, lbl in ipairs(labels) do
        local txt = lbl.Text:gsub(" %- ", " | ")
        local color = questColors[i] or "rgb(255,255,255)"
        table.insert(lines, string.format("<font color='%s'>%d. %s</font>", color, i, txt))
    end

    for i, lbl in ipairs(labels) do
        local perc = lbl.Text:match("(%d+)%%")
        if perc and tonumber(perc) < 100 then
            QuestParagraph:SetDesc(table.concat(lines, "\n")..
                string.format("\n\nProgress Now : Waiting quest %d until reached 100%%", i))
            return i
        end
    end

    QuestParagraph:SetDesc("You already completed this quest")
    return nil
end

RunService.Heartbeat:Connect(updateQuestPanel)

local questActive = false
local teleported1, teleported2 = false, false

local function questLoop()
    teleported1, teleported2 = false, false
    while questActive do
        local index = updateQuestPanel()
        if index == 1 and not teleported1 then
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            hrp.CFrame = CFrame.new(-3597, -276, -1641)
            teleported1 = true
        elseif index and index > 1 and not teleported2 then
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")
            hrp.CFrame = CFrame.new(-3704, -135, -1011)
            teleported2 = true
        elseif not index then
            questActive = false
        end
        task.wait(1)
    end
end

NU:Toggle({
    Title = "Start",
    Default = false,
    Callback = function(state)
        questActive = state
        if state then
            task.spawn(questLoop)
        end
    end
})

MSC:Section({
    Title = 'Simple Feature',
    TextXAlignment = 'Left',
    TextSize = 17,
})

MSC:Divider()

local normalWS = 16
local customWS = 16
local wsEnabled = false

MSC:Input({
    Title = "WalkSpeed",
    Placeholder = "Enter WalkSpeed",
    Default = tostring(normalWS),
    Callback = function(val)
        customWS = tonumber(val) or normalWS
        if wsEnabled then
            local char = player.Character or player.CharacterAdded:Wait()
            local hum = char:WaitForChild("Humanoid")
            hum.WalkSpeed = customWS
        end
    end
})

MSC:Toggle({
    Title = "Enable WalkSpeed",
    Default = false,
    Callback = function(state)
        wsEnabled = state
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        if state then
            hum.WalkSpeed = customWS
        else
            hum.WalkSpeed = normalWS
        end
    end
})

player.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = wsEnabled and customWS or normalWS
end)

MSC:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(state)
        noclip = state
        task.spawn(function()
            while noclip do
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
                task.wait()
            end
        end)
    end
})

local ToggleInfOxygen = false

MSC:Toggle({
    Title = "Infinite Health",
    Default = false,
    Callback = function(state)
        ToggleInfOxygen = state
        if state then
            task.spawn(function()
                while ToggleInfOxygen do
                    local args = { -999999 }
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Packages")
                        :WaitForChild("_Index")
                        :WaitForChild("sleitnick_net@0.2.0")
                        :WaitForChild("net")
                        :WaitForChild("URE/UpdateOxygen")
                        :FireServer(unpack(args))
                    task.wait(1)
                end
            end)
        end
    end
})

MSC:Toggle({
    Title = "Bypass Radar",
    Default = false,
    Callback = function(state)
        local Net = require(ReplicatedStorage.Packages.Net)
        local UpdateRadar = Net:RemoteFunction("UpdateFishingRadar")

        pcall(function()
            UpdateRadar:InvokeServer(state)
        end)
    end
})

WEB:Section({
    Title = "Webhook Fish Caught",
    TextXAlignment = "Left",
    TextSize = 17,
})

local httpRequest = (syn and syn.request)
    or (http and http.request)
    or http_request
    or request
if not httpRequest then return end

local defaultWebhook = "https://discord.com/api/webhooks/1416396676435939459/cnba_Gcqdf05ZFRV1PSGKXMEIoBj8IcGCLo4w3QabUmFOG7-wA74sghNlc1qgg1j1lId"
local customWebhook  = nil
local function getWebhook() return customWebhook or defaultWebhook end

local TierNames = {
    [1] = "Common", [2] = "Uncommon", [3] = "Rare",
    [4] = "Epic", [5] = "Legendary", [6] = "Mythic", [7] = "Secret",
}
local TierColors = {
    [1] = 0xA9A9A9, [2] = 0x1ABC9C, [3] = 0x3498DB,
    [4] = 0x9B59B6, [5] = 0xE67E22, [6] = 0xE74C3C, [7] = 0x2ECC71,
}

local selectedTiers = {}
local selectedNames = {}
local autoSend = false

local fishNames = {}
local Items = ReplicatedStorage:WaitForChild("Items")
for _, item in ipairs(Items:GetChildren()) do
    if item:IsA("ModuleScript") then
        local ok, data = pcall(require, item)
        if ok and typeof(data) == "table" and data.Data and data.Data.Type == "Fishes" then
            table.insert(fishNames, data.Data.Name)
        end
    end
end
table.sort(fishNames)

WEB:Input({
    Title = "Set Webhook",
    Placeholder = "Input webhook link",
    Callback = function(value)
        if value and value:match("^https://discord.com/api/webhooks/") then
            customWebhook = value
            notify("Custom webhook set!")
        else
            customWebhook = nil
            notify("Invalid link, reset to default")
        end
    end,
})

WEB:Dropdown({
    Title = "Select Tier",
    Values = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    Multi = true,
    Default = {},
    Callback = function(values)
        selectedTiers = {}

        if type(values) == "table" then
            for _, v in ipairs(values) do
                for id, name in pairs(TierNames) do
                    if name == v then
                        table.insert(selectedTiers, id)
                        break
                    end
                end
            end
        elseif type(values) == "string" then
            for id, name in pairs(TierNames) do
                if name == values then
                    selectedTiers = { id }
                    break
                end
            end
        end
    end,
})

WEB:Dropdown({
    Title = "Select Fish (Optional)",
    Values = fishNames,
    Multi = true,
    Default = {},
    Callback = function(values)
        selectedNames = {}

        if type(values) == "table" then
            for _, v in ipairs(values) do
                table.insert(selectedNames, v)
            end
        elseif type(values) == "string" then
            selectedNames = { values }
        end
    end,
})

WEB:Button({
    Title = "Test Webhook",
    Callback = function()
        if not customWebhook then
            notify("Please set a custom webhook first!", 3)
            return
        end

        local embed = {
            title = "Seraphin Webhook Connected",
            description = "Webhook is working correctly!",
            color = 0x2ECC71,
            image = { url = "https://i.imgur.com/IvNLsLU.png" }
        }
        httpRequest({
            Url = customWebhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ --- error disini 
                username   = "Seraphin Webhook",
                avatar_url = "https://i.imgur.com/IvNLsLU.png",
                embeds     = { embed }
            })
        })
        notify("Test webhook sent to custom link!", 3)
    end,
})

WEB:Toggle({
    Title = "Auto Send Webhook",
    Default = false,
    Callback = function(state)
        autoSend = state
    end,
})

local function getThumbnailUrl(assetId)
    if not assetId or assetId == 0 then
        return "https://i.imgur.com/Ka5Fsur.jpeg"
    end
    local url = ("https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png&isCircular=false"):format(assetId)
    local ok, res = pcall(function() return httpRequest({ Url = url, Method = "GET" }) end)
    if ok and res and res.StatusCode == 200 and res.Body then
        local success, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if success and decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl then
            return decoded.data[1].imageUrl
        end
    end
    return "https://i.imgur.com/IvNLsLU.png"
end

local function detectFishById(fishId)
    local Items = ReplicatedStorage:FindFirstChild("Items")
    if not Items then return nil end
    for _, inst in ipairs(Items:GetChildren()) do
        if inst:IsA("ModuleScript") then
            local ok, module = pcall(require, inst)
            if ok and module and module.Data and module.Data.Id == fishId and module.Data.Type == "Fishes" then
                local iconRaw = tostring(module.Data.Icon or "")
                local iconId  = tonumber(iconRaw:match("%d+")) or 0
                return {
                    Id      = fishId,
                    Name    = module.Data.Name,
                    Tier    = module.Data.Tier,
                    IconUrl = getThumbnailUrl(iconId)
                }
            end
        end
    end
    return nil
end

local function shouldSend(fishName, tier)
    if #selectedNames > 0 then
        for _, n in ipairs(selectedNames) do
            if n == fishName then return true end
        end
        return false
    end
    if #selectedTiers > 0 then
        for _, t in ipairs(selectedTiers) do
            if t == tier then return true end
        end
        return false
    end
    return false
end

local function sendWebhook(playerName, fishData, weight, mutation)
    local tierName     = TierNames[fishData.Tier] or "Unknown"
    local color        = TierColors[fishData.Tier] or 0x3329A3
    local mutationName = mutation or "-"
    local timestamp    = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
    local embed = {
        title = "Seraphin Webhook",
        description = string.format(
            "Congrats! **%s**\nYou got a new **%s** fish! heres for information :",
            playerName, tierName
        ),
        url = "https://discord.com/invite/getseraphin",
        color = color,
        fields = {
            { name = "Name Fish :", value = string.format("```%s```", fishData.Name) },
            { name = "Tier Fish :", value = string.format("```%s```", tierName) },
            { name = "Weight :", value = string.format("```%.2f Kg```", tonumber(weight) or 0) },
            { name = "Mutation :", value = string.format("```%s```", mutationName) }
        },
        timestamp = timestamp,
        image = { url = fishData.IconUrl }
    }
    httpRequest({
        Url = getWebhook(),
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({
            username   = "Celestia",
            avatar_url = "https://i.imgur.com/IvNLsLU.png",
            embeds     = { embed }
        })
    })
end

local REObtainedNewFishNotification =
    ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]

if REObtainedNewFishNotification then
    REObtainedNewFishNotification.OnClientEvent:Connect(function(fishId, extraData, inventoryItem, isNew)
        if not autoSend then return end

        local playerName = Players.LocalPlayer.Name
        local fishData   = detectFishById(fishId)
        if not fishData then return end

        if fishData.Tier and shouldSend(fishData.Name, fishData.Tier) then
            sendWebhook(playerName, fishData, extraData.Weight or 0, extraData.VariantId)
        end
    end)
end

--------------///Anti Idle///----------------
local GC = getconnections or get_signal_cons
if GC then
    for i, v in pairs(GC(Players.LocalPlayer.Idled)) do
        if v["Disable"] then
            v["Disable"](v)
        elseif v["Disconnect"] then
            v["Disconnect"](v)
        end
    end
else
    local VirtualUser = cloneref(game:GetService("VirtualUser"))
    Players.LocalPlayer.Idled:Connect(
        function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    )
end