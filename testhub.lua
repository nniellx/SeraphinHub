local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Seraphin",
    Icon = "rbxassetid://120248611602330",
    Author = "Restaurant Tycoon",
    Folder = "Seraphin",
    Size = UDim2.fromOffset(300, 420),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    Background = "",
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
})

local Tabs = {
    Home = Window:Tab({ Title = "Main", Icon = "rbxassetid://10723407389"})
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CustomerSystem = require(LocalPlayer.PlayerScripts.Source.Systems.Restaurant.Customers)

local TaskCompletedRemote = ReplicatedStorage.Events.Restaurant.TaskCompleted
local InteractedRemote = ReplicatedStorage.Events.Restaurant.Interactions.Interacted
local CookInputRequested = ReplicatedStorage.Events.Cook.CookInputRequested

local function getMyTycoon()
    local allTycoons = Workspace.Tycoons:GetChildren()
    for _, tycoon in ipairs(allTycoons) do
        local playerValue = tycoon:FindFirstChild("Player")
        if playerValue and playerValue.Value == LocalPlayer then
            return tycoon
        end
    end
    return Workspace.Tycoons:FindFirstChild("Tycoon") or nil
end

local myTycoon = getMyTycoon()
if not myTycoon then return end

local function getAllT1Tables()
    local itemsFolder = myTycoon:FindFirstChild("Items")
    if not itemsFolder then return {} end
    local surface = itemsFolder:FindFirstChild("Surface")
    if not surface then return {} end
    local tables = {}
    for _, item in ipairs(surface:GetChildren()) do
        if item.Name == "T1" then
            table.insert(tables, item)
        end
    end
    return tables
end

local function getCookingEquipment()
    local equipmentList = {}
    local itemsFolder = myTycoon:FindFirstChild("Items")
    if not itemsFolder then return equipmentList end
    local surface = itemsFolder:FindFirstChild("Surface")
    if not surface then return equipmentList end
    for _, item in ipairs(surface:GetChildren()) do
        if item.Name:sub(1,1) == "K" then
            table.insert(equipmentList, item)
        end
    end
    return equipmentList
end

local usedTables = {}
local usedFoodModels = {}
local allTables = getAllT1Tables()
local cookingEquipment = getCookingEquipment()

local function findAvailableTable()
    for _, tableObj in ipairs(allTables) do
        if not usedTables[tableObj] then
            return tableObj
        end
    end
    usedTables = {}
    return allTables[1] or nil
end

local function findAvailableFoodModel()
    local objectsFolder = myTycoon:FindFirstChild("Objects")
    if objectsFolder then
        local foodFolder = objectsFolder:FindFirstChild("Food")
        if foodFolder then
            for _, foodModel in ipairs(foodFolder:GetChildren()) do
                if foodModel:IsA("Model") and not usedFoodModels[foodModel] then
                    usedFoodModels[foodModel] = true
                    return foodModel
                end
            end
        end
    end
    local itemsFolder = myTycoon:FindFirstChild("Items")
    if itemsFolder then
        local surface = itemsFolder:FindFirstChild("Surface")
        if surface then
            for _, tableObj in ipairs(surface:GetChildren()) do
                if tableObj.Name:sub(1,1) == "T" then
                    for _, item in ipairs(tableObj:GetChildren()) do
                        if item:IsA("Model") and not usedFoodModels[item] and item.Name ~= "Trash" then
                            usedFoodModels[item] = true
                            return item
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function autoSitCustomer(groupId, customerId)
    local customerData = CustomerSystem:GetCustomerData(myTycoon, groupId, customerId)
    if not customerData or customerData.State ~= "None" then return end
    local availableTable = findAvailableTable()
    if not availableTable then return end
    usedTables[availableTable] = true
    local args = {{
        Name = "SendToTable",
        GroupId = groupId,
        Tycoon = myTycoon,
        FurnitureModel = availableTable
    }}
    TaskCompletedRemote:FireServer(unpack(args))
end

local function autoTakeOrder(groupId, customerId)
    local args = {{
        Name = "TakeOrder",
        GroupId = groupId,
        Tycoon = myTycoon,
        CustomerId = customerId
    }}
    TaskCompletedRemote:FireServer(unpack(args))
end

local function cookWithInteracted(equipment)
    if not equipment then return end
    local equipmentPos = equipment:GetPivot().Position
    local args1 = {
        myTycoon,
        {
            WorldPosition = equipmentPos + Vector3.new(-4, 0, 0),
            HoldDuration = 0.375,
            Id = "1",
            TemporaryPart = Instance.new("Part"),
            Model = equipment,
            ActionText = "Cook",
            Prompt = Instance.new("ProximityPrompt"),
            Part = Instance.new("Part"),
            InteractionType = "OrderCounter"
        }
    }
    InteractedRemote:FireServer(unpack(args1))
    local args2 = {
        myTycoon,
        {
            WorldPosition = equipmentPos + Vector3.new(0, 0, 0),
            HoldDuration = 0.375,
            Id = "0",
            TemporaryPart = Instance.new("Part"),
            Model = equipment,
            ActionText = "Cook",
            Prompt = Instance.new("ProximityPrompt"),
            Part = Instance.new("Part"),
            InteractionType = "OrderCounter"
        }
    }
    InteractedRemote:FireServer(unpack(args2))
end

local function cookWithCompleteTask(equipment)
    if not equipment then return end
    local equipmentType = "Kitchen"
    if equipment.Name == "K28" then
        equipmentType = "Oven"
    end
    CookInputRequested:FireServer("CompleteTask", equipment, equipmentType)
    CookInputRequested:FireServer("CompleteTask", equipment, equipmentType)
end

local function autoCook()
    if #cookingEquipment == 0 then return end
    for _, equipment in ipairs(cookingEquipment) do
        cookWithInteracted(equipment)
        cookWithCompleteTask(equipment)
    end
end

local function autoDeliverFood(groupId, customerId)
    local foodModel = findAvailableFoodModel()
    if not foodModel then return end
    local args = {
        {
            Name = "Serve",
            GroupId = groupId,
            Tycoon = myTycoon,
            FoodModel = foodModel,
            CustomerId = customerId
        }
    }
    TaskCompletedRemote:FireServer(unpack(args))
    task.delay(10, function()
        usedFoodModels[foodModel] = nil
    end)
end

local function autoCollectCleanup()
    local itemsFolder = myTycoon:FindFirstChild("Items")
    if not itemsFolder then return end
    
    local surface = itemsFolder:FindFirstChild("Surface")
    if not surface then return end

    for _, tableModel in ipairs(surface:GetChildren()) do
        if tableModel:IsA("Model") then
            local argsDishes = {
                {
                    Tycoon = myTycoon,
                    Name = "CollectDishes",
                    FurnitureModel = tableModel
                }
            }
            TaskCompletedRemote:FireServer(unpack(argsDishes))            
            task.wait(0.3)
            local argsBill = {
                {
                    Tycoon = myTycoon,
                    Name = "CollectBill", 
                    FurnitureModel = tableModel
                }
            }
            TaskCompletedRemote:FireServer(unpack(argsBill))           
        end
    end
end

_G.AutoSit = false
_G.AutoCook = false
_G.AutoDeliver = false
_G.AutoCleanup = false

Tabs.Home:Toggle({
    Title = "Auto Sit Customer",
    Default = false,
    Callback = function(v) _G.AutoSit = v end
})

Tabs.Home:Toggle({
    Title = "Auto Cook",
    Default = false,
    Callback = function(v) _G.AutoCook = v end
})

Tabs.Home:Toggle({
    Title = "Auto Deliver",
    Default = false,
    Callback = function(v) _G.AutoDeliver = v end
})

Tabs.Home:Toggle({
    Title = "Auto Cleanup",
    Default = false,
    Callback = function(v) _G.AutoCleanup = v end
})

CustomerSystem.CustomerStateChanged:Connect(function(TycoonModel, GroupId, CustomerId, OldState, NewState)
    if TycoonModel ~= myTycoon then return end
    if NewState == "None" and _G.AutoSit then
        autoSitCustomer(GroupId, CustomerId)
    elseif NewState == "Ordering" and _G.AutoSit then
        autoTakeOrder(GroupId, CustomerId)
    elseif (NewState == "WaitingForDish" or NewState == "WaitingForFood") and (_G.AutoCook or _G.AutoDeliver) then
        task.delay(1, function()
            if _G.AutoCook then
                autoCook()
            end
            task.delay(2, function()
                if _G.AutoDeliver then
                    autoDeliverFood(GroupId, CustomerId)
                end
            end)
        end)
    elseif (NewState == "Finished" or NewState == "Leaving" or NewState == "Completed") and _G.AutoCleanup then
        task.delay(2, function()
            autoCollectCleanup()
        end)
    end
end)

local function scanExistingCustomers()
    local storage = CustomerSystem:GetStorage(myTycoon)
    if not storage or not storage.Groups then return end
    for groupId, groupData in pairs(storage.Groups) do
        for customerId, customerData in pairs(groupData.Customers) do
            if customerData.State == "None" and _G.AutoSit then
                autoSitCustomer(groupId, customerId)
            elseif customerData.State == "Ordering" and _G.AutoSit then
                autoTakeOrder(groupId, customerId)
            elseif (customerData.State == "WaitingForDish" or customerData.State == "WaitingForFood") and (_G.AutoCook or _G.AutoDeliver) then
                if _G.AutoCook then autoCook() end
                task.delay(2, function()
                    if _G.AutoDeliver then
                        autoDeliverFood(groupId, customerId)
                    end
                end)
            elseif (customerData.State == "Finished" or customerData.State == "Leaving" or customerData.State == "Completed") and _G.AutoCleanup then
                autoCollectCleanup()
            end
        end
    end
end

spawn(function()
    while task.wait(1) do
        pcall(scanExistingCustomers)
        if _G.AutoCleanup then
            autoCollectCleanup()
        end
    end
end)
