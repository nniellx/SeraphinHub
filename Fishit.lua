loadstring([[
    function LPH_NO_VIRTUALIZE(f) return f end;
]])();

local Chloex   = loadstring(game:HttpGet("https://raw.githubusercontent.com/ChloeXTest/UI/refs/heads/main/Library"))()

local svc      = {
    Players     = game:GetService("Players"),
    RunService  = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    RS          = game:GetService("ReplicatedStorage"),
    VIM         = game:GetService("VirtualInputManager"),
    PG          = game:GetService("Players").LocalPlayer.PlayerGui,
    Camera      = workspace.CurrentCamera,
    GuiService  = game:GetService("GuiService"),
    CoreGui     = game:GetService("CoreGui")
}

_G.httpRequest =
    (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request
if not _G.httpRequest then
    return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RaycastUtility = require(ReplicatedStorage.Shared.RaycastUtility)

local player               = svc.Players.LocalPlayer
local hrp                  = player.Character and player.Character:WaitForChild("HumanoidRootPart") or
    player.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")

local BaseFolder           = "Seraphin/FishIt"
local PositionFile         = BaseFolder .. "/Position.json"

local gui                  = {
    MerchantRoot    = svc.PG.Merchant.Main.Background,
    ItemsFrame      = svc.PG.Merchant.Main.Background.Items.ScrollingFrame,
    RefreshMerchant = svc.PG.Merchant.Main.Background.RefreshLabel,
}

local mods                 = {
    Net                = svc.RS.Packages._Index["sleitnick_net@0.2.0"].net,
    Replion            = require(svc.RS.Packages.Replion),
    FishingController  = require(svc.RS.Controllers.FishingController),
    TradingController  = require(svc.RS.Controllers.ItemTradingController),
    ItemUtility        = require(svc.RS.Shared.ItemUtility),
    VendorUtility      = require(svc.RS.Shared.VendorUtility),
    PlayerStatsUtility = require(svc.RS.Shared.PlayerStatsUtility),
    Effects            = require(svc.RS.Shared.Effects),
}

local api                  = {
    Events = {
        RECutscene                    = mods.Net["RE/ReplicateCutscene"],
        REStop                        = mods.Net["RE/StopCutscene"],
        REFav                         = mods.Net["RE/FavoriteItem"],
        REFavChg                      = mods.Net["RE/FavoriteStateChanged"],
        REFishDone                    = mods.Net["RE/FishingCompleted"],
        REFishGot                     = mods.Net["RE/FishCaught"],
        RENotify                      = mods.Net["RE/TextNotification"],
        REEquip                       = mods.Net["RE/EquipToolFromHotbar"],
        REEquipItem                   = mods.Net["RE/EquipItem"],
        REAltar                       = mods.Net["RE/ActivateEnchantingAltar"],
        REAltar2                      = mods.Net["RE/ActivateSecondEnchantingAltar"],
        UpdateOxygen                  = mods.Net["URE/UpdateOxygen"],
        REPlayFishEffect              = mods.Net["RE/PlayFishingEffect"],
        RETextEffect                  = mods.Net["RE/ReplicateTextEffect"],
        REEvReward                    = mods.Net["RE/ClaimEventReward"],
        Totem                         = mods.Net["RE/SpawnTotem"],
        REObtainedNewFishNotification = mods.Net["RE/ObtainedNewFishNotification"],
        FishingMinigameChanged        = mods.Net["RE/FishingMinigameChanged"],
        FishingStopped                = mods.Net["RE/FishingStopped"],
    },

Functions = {
        Trade       = mods.Net["RF/InitiateTrade"],
        BuyRod      = mods.Net["RF/PurchaseFishingRod"],
        BuyBait     = mods.Net["RF/PurchaseBait"],
        BuyWeather  = mods.Net["RF/PurchaseWeatherEvent"],
        ChargeRod   = mods.Net["RF/ChargeFishingRod"],
        StartMini   = mods.Net["RF/RequestFishingMinigameStarted"],
        UpdateRadar = mods.Net["RF/UpdateFishingRadar"],
        Cancel      = mods.Net["RF/CancelFishingInputs"],
        Dialogue    = mods.Net["RF/SpecialDialogueEvent"],
        Done        = mods.Net["RF/RequestFishingMinigameStarted"],
        AutoEnabled = mods.Net["RF/UpdateAutoFishingState"],
        SellItem    = mods.Net["RF/SellItem"],
    }
}

local repl                 = {
    Data = mods.Replion.Client:WaitReplion("Data"),
    Items = svc.RS:WaitForChild("Items"),
    PlayerStat = require(svc.RS.Packages._Index:FindFirstChild("ytrev_replion@2.0.0-rc.3").replion)
}

local st                   = {
    autoInstant      = false,
    selectedEvents   = {},
    autoWeather      = false,
    autoSellEnabled  = false,
    autoFavEnabled   = false,
    autoEventActive  = false,
    canFish          = true,
    savedCFrame      = nil,
    sellMode         = "Delay",
    sellDelay        = 60,
    inputSellCount   = 50,
    selectedName     = {},
    selectedRarity   = {},
    selectedVariant  = {},
    rodDataList      = {},
    rodDisplayNames  = {},
    baitDataList     = {},
    baitDisplayNames = {},
    selectedRodId    = nil,
    selectedBaitId   = nil,
    rods             = {},
    baits            = {},
    weathers         = {},
    lcc              = 0,
    player           = player,
    stats            = player:WaitForChild("leaderstats"),
    caught           = player:WaitForChild("leaderstats"):WaitForChild("Caught"),
    char             = player.Character or player.CharacterAdded:Wait(),
    vim              = svc.VIM,
    cam              = svc.Camera,
    offs             = { ["Worm Hunt"] = 25 },
    curCF            = nil,
    origCF           = nil,
    flt              = false,
    con              = nil,
    Instant          = false,
    CancelWaitTime   = 3.0,
    ResetTimer       = 0.5,
    hasTriggeredBug  = false,
    lastFishTime     = 0,
    fishConnected    = false,
    lastCancelTime   = 0,
    hasFishingEffect = false,
    trade            = {
        selectedPlayer = nil,
        selectedItem   = nil,
        tradeAmount    = 1,
        targetCoins    = 0,
        trading        = false,
        awaiting       = false,
        lastResult     = nil,
        successCount   = 0,
        failCount      = 0,
        totalToTrade   = 0,
        sentCoins      = 0,
        successCoins   = 0,
        failCoins      = 0,
        totalReceived  = 0,
        currentGrouped = {},
        TotemActive    = false,
    },
    ignore           = {
        Cloudy = true,
        Day = true,
        ["Increased Luck"] = true,
        Mutated = true,
        Night = true,
        Snow = true,
        ["Sparkling Cove"] = true,
        Storm = true,
        Wind = true,
        UIListLayout = true,
        ["Admin - Shocked"] = true,
        ["Admin - Super Mutated"] = true,
        Radiant = true,
    },
    notifConnections = {},
    defaultHandlers  = {},
    disabledCons     = {},
    CEvent           = true
}

-- Helpers
_G.Celestial               = _G.Celestial or {}
_G.Celestial.DetectorCount = _G.Celestial.DetectorCount or 0
_G.Celestial.InstantCount  = _G.Celestial.InstantCount or 0

function getFishCount()
    local bag = st.player.PlayerGui:WaitForChild("Inventory")
        :WaitForChild("Main"):WaitForChild("Top")
        :WaitForChild("Options"):WaitForChild("Fish")
        :WaitForChild("Label"):WaitForChild("BagSize")
    return tonumber((bag.Text or "0/???"):match("(%d+)/")) or 0
end

local fishNames = {}

for _, module in ipairs(repl.Items:GetChildren()) do
    if module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and data.Data and data.Data.Type == "Fish" then
            table.insert(fishNames, data.Data.Name)
        end
    end
end

table.sort(fishNames)

_G.TierFish = {
    [1] = " ",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "Secret"
}

_G.WebhookRarities = _G.WebhookRarities or {}
_G.WebhookNames = _G.WebhookNames or {}

_G.Variant = {
    "Galaxy",
    "Corrupt",
    "Gemstone",
    "Ghost",
    "Lightning",
    "Fairy Dust",
    "Gold",
    "Midnight",
    "Radioactive",
    "Stone",
    "Holographic",
    "Albino"
}

function toSet(sel)
    local set = {}
    if type(sel) == "table" then
        for _, v in ipairs(sel) do set[v] = true end
        for k, v in pairs(sel) do if v then set[k] = true end end
    end
    return set
end

local favState = {}
api.Events.REFavChg.OnClientEvent:Connect(function(uuid, state)
    rawset(favState, uuid, state)
end)

function checkAndFavorite(item)
    if not st.autoFavEnabled then return end
    local info = mods.ItemUtility.GetItemDataFromItemType("Items", item.Id)
    if not info or info.Data.Type ~= "Fish" then return end

    local rarity       = _G.TierFish[info.Data.Tier]
    local name         = info.Data.Name
    local variant      = (item.Metadata and item.Metadata.VariantId) or "None"

    local nameMatch    = st.selectedName[name]
    local rarityMatch  = st.selectedRarity[rarity]
    local variantMatch = st.selectedVariant[variant]

    local isFav        = rawget(favState, item.UUID)
    if isFav == nil then isFav = item.Favorited end

    local shouldFav = false
    if next(st.selectedVariant) ~= nil and next(st.selectedName) ~= nil then
        shouldFav = nameMatch and variantMatch
    else
        shouldFav = nameMatch or rarityMatch
    end

    if shouldFav and not isFav then
        api.Events.REFav:FireServer(item.UUID)
        rawset(favState, item.UUID, true)
    end
end

function scanInventory()
    if not st.autoFavEnabled then return end
    for _, item in ipairs(repl.Data:GetExpect({ "Inventory", "Items" })) do
        checkAndFavorite(item)
    end
end

for _, item in ipairs(svc.RS.Items:GetChildren()) do
    if item:IsA("ModuleScript") and item.Name:match("Rod") then
        local ok, moduleData = pcall(require, item)
        if ok and typeof(moduleData) == "table" and moduleData.Data then
            local name = moduleData.Data.Name or "Unknown"
            local id = moduleData.Data.Id or "Unknown"
            local price = moduleData.Price or 0
            local cleanName = name:gsub("^!!!%s*", "")
            local display = cleanName .. " ($" .. price .. ")"
            local entry = { Name = cleanName, Id = id, Price = price, Display = display }
            st.rods[id] = entry
            st.rods[cleanName] = entry
            table.insert(st.rodDisplayNames, display)
        end
    end
end

BaitsFolder = svc.RS:WaitForChild("Baits")
for _, module in ipairs(BaitsFolder:GetChildren()) do
    if module:IsA("ModuleScript") then
        local ok, data = pcall(require, module)
        if ok and typeof(data) == "table" and data.Data then
            local name = data.Data.Name or "Unknown"
            local id = data.Data.Id or "Unknown"
            local price = data.Price or 0
            local display = name .. " ($" .. price .. ")"
            local entry = { Name = name, Id = id, Price = price, Display = display }
            st.baits[id] = entry
            st.baits[name] = entry
            table.insert(st.baitDisplayNames, display)
        end
    end
end

function _cleanName(display)
    if type(display) ~= "string" then
        return tostring(display)
    end
    return display:match("^(.-) %(") or display
end

function SavePosition(cf)
    local data = { cf:GetComponents() }
    writefile(PositionFile, svc.HttpService:JSONEncode(data))
end

function LoadPosition()
    if isfile(PositionFile) then
        local success, data = pcall(function()
            return svc.HttpService:JSONDecode(readfile(PositionFile))
        end)
        if success and typeof(data) == "table" then
            return CFrame.new(unpack(data))
        end
    end
    return nil
end

function TeleportLastPos(char)
    spawn(LPH_NO_VIRTUALIZE(function()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local last = LoadPosition()

        if last then
            task.wait(2)
            hrp.CFrame = last
            notify("Teleported to your last position...")
        end
    end))
end

player.CharacterAdded:Connect(TeleportLastPos)
if player.Character then
    TeleportLastPos(player.Character)
end

ignore = {
    Cloudy = true,
    Day = true,
    ["Increased Luck"] = true,
    Mutated = true,
    Night = true,
    Snow = true,
    ["Sparkling Cove"] = true,
    Storm = true,
    Wind = true,
    UIListLayout = true,
    ["Admin - Shocked"] = true,
    ["Admin - Super Mutated"] = true,
    Radiant = true
}

local function root(c)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChildWhichIsA("BasePart"))
end

local function setFreeze(c, freeze)
    if not c then return end
    for _, x in ipairs(c:GetDescendants()) do
        if x:IsA("BasePart") then
            x.Anchored = freeze
        end
    end
end

local function float(c, r, off)
    if st.flt and st.con then st.con:Disconnect() end
    st.flt = off or false
    if off then
        local F = c:FindFirstChild("FloatPart") or Instance.new("Part")
        F.Name, F.Size, F.Transparency, F.Anchored, F.CanCollide =
            "FloatPart", Vector3.new(3, .2, 3), 1, true, true
        F.Parent = c
        st.con = svc.RunService.Heartbeat:Connect(function()
            if c and r and F then
                F.CFrame = r.CFrame * CFrame.new(0, -3.1, 0)
            end
        end)
    else
        local p = c and c:FindFirstChild("FloatPart")
        if p then p:Destroy() end
    end
end

local function getEvents()
    local l, eg = {}, st.player:WaitForChild("PlayerGui"):FindFirstChild("Events")
    eg = eg and eg:FindFirstChild("Frame") and eg.Frame:FindFirstChild("Events")
    if eg then
        for _, e in ipairs(eg:GetChildren()) do
            local dn = (e:IsA("Frame") and e:FindFirstChild("DisplayName") and e.DisplayName.Text) or e.Name
            if typeof(dn) == "string" and dn ~= "" and not st.ignore[dn] then
                table.insert(l, (dn:gsub("^Admin %- ", "")))
            end
        end
    end
    return l
end

local function findTarget(n)
    if not n then return end
    if n == "Megalodon Hunt" then
        local menu = workspace:FindFirstChild("!!! MENU RINGS")
        if menu then
            for _, c in ipairs(menu:GetChildren()) do
                local m = c:FindFirstChild("Megalodon Hunt")
                local p = m and m:FindFirstChild("Megalodon Hunt")
                if p and p:IsA("BasePart") then return p end
            end
        end
        return
    end
    local props = { workspace:FindFirstChild("Props") }
    local menu = workspace:FindFirstChild("!!! MENU RINGS")
    if menu then
        for _, c in ipairs(menu:GetChildren()) do
            if c.Name:match("^Props") then table.insert(props, c) end
        end
    end
    for _, pr in ipairs(props) do
        for _, m in ipairs(pr:GetChildren()) do
            for _, o in ipairs(m:GetDescendants()) do
                if o:IsA("TextLabel") and o.Name == "DisplayName" then
                    local txt = o.ContentText ~= "" and o.ContentText or o.Text
                    if txt:lower() == n:lower() then
                        local anc = o:FindFirstAncestorOfClass("Model")
                        local p = (anc and anc:FindFirstChild("Part")) or m:FindFirstChild("Part")
                        if p and p:IsA("BasePart") then return p end
                    end
                end
            end
        end
    end
end

local function setState(state)
    if st.lastState ~= state then
        notify(state)
        st.lastState = state
    end
end

st.loop = function()
    while st.autoEventActive do
        local tar, nm
        if st.priorityEvent then
            local t = findTarget(st.priorityEvent)
            if t then tar, nm = t, st.priorityEvent end
        end
        if not tar and #st.selectedEvents > 0 then
            for _, n in ipairs(st.selectedEvents) do
                local t = findTarget(n)
                if t then
                    tar, nm = t, n
                    break
                end
            end
        end

        local r = root(st.player.Character)

        if tar and r then
            if not st.origCF then st.origCF = r.CFrame end
            if (r.Position - tar.Position).Magnitude > 40 then
                st.curCF = tar.CFrame + Vector3.new(0, st.offs[nm] or 7, 0)
                st.player.Character:PivotTo(st.curCF)
                float(st.player.Character, r, true)
                task.wait(1)
                setFreeze(st.player.Character, true)
                setState("Event! " .. nm)
            end
        elseif tar == nil and st.curCF and r then
            setFreeze(st.player.Character, false)
            float(st.player.Character, nil, false)
            if st.origCF then
                st.player.Character:PivotTo(st.origCF)
                setState("Event end → Back")
                st.origCF = nil
            end
            st.curCF = nil
        elseif not st.curCF then
            setState("Idle")
        end

        task.wait(0.2)
    end

    setFreeze(st.player.Character, false)
    float(st.player.Character, nil, false)
    if st.origCF and st.player.Character then
        st.player.Character:PivotTo(st.origCF)
        setState("Auto Event off")
    end
    st.origCF, st.curCF = nil, nil
end

st.player.CharacterAdded:Connect(function(nc)
    if st.autoEventActive then
        spawn(LPH_NO_VIRTUALIZE(function()
            local r = nc:WaitForChild("HumanoidRootPart", 5)
            task.wait(0.3)
            if r then
                if st.curCF then
                    nc:PivotTo(st.curCF)
                    float(nc, r, true)
                    task.wait(0.5)
                    setFreeze(nc, true)
                    notify("Respawn → Back")
                elseif st.origCF then
                    nc:PivotTo(st.origCF)
                    setFreeze(nc, false)
                    float(nc, r, true)
                    notify("Back to farm")
                end
            end
        end))
    end
end)

local function getPlayerList()
    local list = {}
    for _, p in ipairs(svc.Players:GetPlayers()) do
        if p ~= player then
            table.insert(list, p.Name)
        end
    end
    return list
end

local locations = {
    ["Ancient Jungle"] = Vector3.new(1274, 8, -184),
    ["Ancient Jungle Outside"] = Vector3.new(1488, 8, -392),
    ["Ancient Ruin"] = Vector3.new(6073, -586, 4622),
    ["Classic Island"] = Vector3.new(1440.77368, 45.9999962, 2777.31909),
    ["Coral Reefs SPOT 1"] = Vector3.new(-3031.88, 2.52, 2276.36),
    ["Coral Reefs SPOT 2"] = Vector3.new(-3270.86, 2.50, 2228.10),
    ["Coral Reefs SPOT 3"] = Vector3.new(-3136.10, 2.61, 2126.11),
    ["Crater Island Ground"] = Vector3.new(1079.57, 3.64, 5080.35),
    ["Crater Island Top"] = Vector3.new(1011.29, 22.68, 5076.27),
    ["Cristmas Island"] = Vector3.new(1143.2380, 23.3806, 1592.4445),
    ["Cristmas Island Lobby"] = Vector3.new(766.19464, 16.0803, 1569.3953),
    ["Crystalline Pessage"] = Vector3.new(6052, -539, 4386),
    ["Fisherman Island Mid"] = Vector3.new(33, 3, 2764),
    ["Fisherman Island Rift Left"] = Vector3.new(-26, 10, 2686),
    ["Fisherman Island Rift Right"] = Vector3.new(95, 10, 2684),
    ["Fisherman Island Underground"] = Vector3.new(-62, 3, 2846),
    ["Ice Sea"] = Vector3.new(2164, 7, 3269),
    ["Iron Cafe"] = Vector3.new(-8627.36035, -547.500183, 179.2005),
    ["Iron Cavern"] = Vector3.new(-8799.15527, -585.000061, 80.0701294),
    ["Kohana SPOT 1"] = Vector3.new(-367.77, 6.75, 521.91),
    ["Kohana SPOT 2"] = Vector3.new(-623.96, 19.25, 419.36),
    ["Kohana Volcano"] = Vector3.new(-561.81, 21.24, 156.72),
    ["Lost Shore"] = Vector3.new(-3737.97, 5.43, -854.68),
    ["Secred Temple"] = Vector3.new(1475, -22, -632),
    ["Sisyphus Statue"] = Vector3.new(-3703.69, -135.57, -1017.17),
    ["Stingray Shores"] = Vector3.new(44.41, 28.83, 3048.93),
    ["Treasure Room"] = Vector3.new(-3602.01, -266.57, -1577.18),
    ["Tropical Grove"] = Vector3.new(-2018.91, 9.04, 3750.59),
    ["Tropical Grove Cave 1"] = Vector3.new(-2151, 3, 3671),
    ["Tropical Grove Cave 2"] = Vector3.new(-2018, 5, 3756),
    ["Tropical Grove Highground"] = Vector3.new(-2139, 53, 3624),
    ["Underground Cellar"] = Vector3.new(2136, -91, -699),
    ["Weather Machine"] = Vector3.new(-1524.88, 2.87, 1915.56),
}
 
function disconnectNotifs()
    for _, ev in ipairs({
        mods.Net["RE/ObtainedNewFishNotification"],
        mods.Net["RE/TextNotification"],
        mods.Net["RE/ClaimNotification"]
    }) do
        for _, conn in ipairs(getconnections(ev.OnClientEvent)) do
            conn:Disconnect()
            table.insert(st.notifConnections, conn)
        end
    end
end

function reconnectNotifs()
    st.notifConnections = {}
end

local Window = Chloex:Window({
    Title   = "Seraphin |",
    Footer  = "Premium",
    Image   = "122018672226954",
    Color   = Color3.fromRGB(255, 255, 255),
    Theme   = 100915844800469,
    Version = 1,
})

function notify(msg)
    Chloex:MakeNotify({
        Title = "Seraphin",
        Description = "Notifier!",
        Content = tostring(msg),
        Color = Color3.fromRGB(255, 255, 255),
        Delay = 4
    })
end

if Window then
    notify("Window loaded!")
end

local Tabs = {
    Info = Window:AddTab({ Name = "Info", Icon = "player" }),
    Exclusive = Window:AddTab({ Name = "Exclusive", Icon = "rbxassetid://107005941750079" }),
    Main = Window:AddTab({ Name = "Main", Icon = "rbxassetid://9920770417" }),
    Auto = Window:AddTab({ Name = "Menu", Icon = "rbxassetid://115745994221305" }),
    Trade = Window:AddTab({ Name = "Trading", Icon = "rbxassetid://15594035945" }),
    Tele = Window:AddTab({ Name = "Teleport", Icon = "rbxassetid://14240466919" }),
    Web = Window:AddTab({ Name = "Webhook", Icon = "rbxassetid://137601480983962" }),
    Misc = Window:AddTab({ Name = "Misc", Icon = "rbxassetid://12120710060" }),
}

If = Tabs.Info:AddSection("Information Script", true)

If:AddParagraph({
    Title = "Seraphin Information",
    Content =
    "This script is still under development. Check for updates on our Discord!\n Please report to us if you find any bugs, errors, or patched!."
})

If:AddParagraph({
    Title = "Seraphin Official Discord!",
    Content = "Join Us!",
    Icon = "discord",
    ButtonText = "Copy Discord Link",
    ButtonCallback = function()
        local link = "https://discord.gg/getseraphin"
        if setclipboard then
            setclipboard(link)
        end
    end
})

Exclusive = Tabs.Exclusive:AddSection("Double Enchant")

Exclusive:AddParagraph({
    Title = "Reminder for you :3",
    Content = "U must nearby in Altar for starting enchant!"
})

Exclusive:AddButton({
    Title = "Teleport to Second Altar",
    Callback = function()
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character:PivotTo(CFrame.new(1481, 128, -592))
        end
    end
})

Data = repl.Data
ItemUtility = mods.ItemUtility
equipItemRemote = api.Events.REEquipItem
equipToolRemote = api.Events.REEquip
activateAltarRemote2 = api.Events.REAltar2
local function getData(stoneId)
    local rod, ench, stones, uuids = "None", "None", 0, {}
    local equipped = Data:Get("EquippedItems") or {}
    local rods = Data:Get({ "Inventory", "Fishing Rods" }) or {}

    for _, u in pairs(equipped) do
        for _, r in ipairs(rods) do
            if r.UUID == u then
                local d = ItemUtility:GetItemData(r.Id)
                rod = (d and d.Data.Name) or r.ItemName or "None"
                if r.Metadata and r.Metadata.EnchantId then
                    local e = ItemUtility:GetEnchantData(r.Metadata.EnchantId)
                    ench = (e and e.Data.Name) or "None"
                end
            end
        end
    end

    for _, it in pairs(Data:GetExpect({ "Inventory", "Items" })) do
        local d = ItemUtility:GetItemData(it.Id)
        if d and d.Data.Type == "Enchant Stones" and it.Id == stoneId then
            stones += 1
            table.insert(uuids, it.UUID)
        end
    end
    return rod, ench, stones, uuids
end

Exclusive:AddButton({
    Title = "Start Double Enchant",
    Callback = function()
        spawn(LPH_NO_VIRTUALIZE(function()
            local rod, ench, stoneCount, uuids = getData(246)
            if rod == "None" or stoneCount <= 0 then return end

            local slot, start = nil, tick()
            while tick() - start < 5 do
                for sl, id in pairs(Data:Get("EquippedItems") or {}) do
                    if id == uuids[1] then
                        slot = sl
                        break
                    end
                end
                if slot then break end
                equipItemRemote:FireServer(uuids[1], "EnchantStones")
                task.wait(0.3)
            end

            if not slot then return end

            equipToolRemote:FireServer(slot)
            task.wait(0.25)
            activateAltarRemote2:FireServer()
        end))
    end
})

Exclusive1 = Tabs.Exclusive:AddSection("Auto Reconnect")

_G.AutoReconnect = false
_G.ReconnectAttempts = 0

function AutoReconnect()
    if not game:GetService("Players"):FindFirstChild(game:GetService("Players").LocalPlayer.Name) then
        while _G.ReconnectAttempts < 5 and _G.AutoReconnect do
            _G.ReconnectAttempts = _G.ReconnectAttempts + 1

            local success = pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId)
            end)

            if success then
                _G.ReconnectAttempts = 0
                break
            else
                wait(5)
            end
        end

        if _G.ReconnectAttempts >= 5 then
            _G.ReconnectAttempts = 0
        end
    end
end

Exclusive1:AddToggle({
    Title = "Auto Reconnect",
    Value = _G.AutoReconnect,
    Callback = function(value)
        _G.AutoReconnect = value
        _G.ReconnectAttempts = 0
    end
})

spawn(LPH_NO_VIRTUALIZE(function()
    while task.wait(1) do
        if _G.AutoReconnect then
            AutoReconnect()
        end
    end
end))

Exclusive2 = Tabs.Exclusive:AddSection("Auto Candy Canes")
local NPCFolder = game:GetService("ReplicatedStorage"):WaitForChild("NPC")
local StateCandy = false
local candyThread = nil
function AutoCandy()
    if StateCandy and not candyThread then
        candyThread = task.spawn(function()
			while StateCandy do
				for _, npc in ipairs(NPCFolder:GetChildren()) do
                    local args = {
                        npc.Name,
                        "ChristmasPresents"
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RF/SpecialDialogueEvent"):InvokeServer(unpack(args))
                end
				task.wait(3605)
			end
			candyThread = nil -- cleanup
		end)
    end
end
Exclusive2:AddToggle({
    Title = "Auto Candy",
    Value = _G.AutoReconnect,
    Callback = function(value)
        StateCandy = value
        if value then
            AutoCandy()
        end
    end
})

Fish = Tabs.Main:AddSection("Fishing")

Fish:AddToggle({
    Title = "Show Fishing Panel",
    Default = false,
    Callback = function(state)
        if state then
            local player = game:GetService("Players").LocalPlayer
            if game.CoreGui:FindFirstChild("ChloeX_FishingPanel") then
                game.CoreGui:FindFirstChild("ChloeX_FishingPanel"):Destroy()
            end

            local gui = Instance.new("ScreenGui")
            gui.Name = "ChloeX_FishingPanel"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
            gui.Parent = game.CoreGui

            local card = Instance.new("Frame", gui)
            card.Size = UDim2.new(0, 400, 0, 210)
            card.AnchorPoint = Vector2.new(0.5, 0.5)
            card.Position = UDim2.new(0.5, 0, 0.5, 0)
            card.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
            card.BorderSizePixel = 0
            card.BackgroundTransparency = 0.05
            card.Active = true
            card.Draggable = true

            local outline = Instance.new("UIStroke", card)
            outline.Thickness = 2
            outline.Color = Color3.fromRGB(80, 150, 255)
            outline.Transparency = 0.35

            local corner = Instance.new("UICorner", card)
            corner.CornerRadius = UDim.new(0, 14)

            local title = Instance.new("TextLabel", card)
            title.Size = UDim2.new(1, -40, 0, 36)
            title.Position = UDim2.new(0, 45, 0, 5)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBold
            title.Text = "Seraphin FIshing Panel"
            title.TextSize = 22
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.TextXAlignment = Enum.TextXAlignment.Left

            local titleGradient = Instance.new("UIGradient", title)
            titleGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 220, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 120, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 220, 255))
            })
            titleGradient.Rotation = 45

            local invLabel = Instance.new("TextLabel", card)
            invLabel.Position = UDim2.new(0, 15, 0, 55)
            invLabel.Size = UDim2.new(1, -30, 0, 22)
            invLabel.Font = Enum.Font.GothamBold
            invLabel.TextSize = 18
            invLabel.BackgroundTransparency = 1
            invLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
            invLabel.Text = "INVENTORY COUNT:"

            local fishCount = Instance.new("TextLabel", card)
            fishCount.Position = UDim2.new(0, 15, 0, 75)
            fishCount.Size = UDim2.new(1, -30, 0, 22)
            fishCount.Font = Enum.Font.Gotham
            fishCount.TextSize = 18
            fishCount.BackgroundTransparency = 1
            fishCount.TextColor3 = Color3.fromRGB(255, 255, 255)
            fishCount.Text = "Fish: 0/0"

            local totalLabel = Instance.new("TextLabel", card)
            totalLabel.Position = UDim2.new(0, 15, 0, 105)
            totalLabel.Size = UDim2.new(1, -30, 0, 22)
            totalLabel.Font = Enum.Font.GothamBold
            totalLabel.TextSize = 18
            totalLabel.BackgroundTransparency = 1
            totalLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
            totalLabel.Text = "TOTAL FISH CAUGHT:"

            local totalCaught = Instance.new("TextLabel", card)
            totalCaught.Position = UDim2.new(0, 15, 0, 125)
            totalCaught.Size = UDim2.new(1, -30, 0, 22)
            totalCaught.Font = Enum.Font.Gotham
            totalCaught.TextSize = 18
            totalCaught.BackgroundTransparency = 1
            totalCaught.TextColor3 = Color3.fromRGB(255, 255, 255)
            totalCaught.Text = "Value: 0"

            local status = Instance.new("TextLabel", card)
            status.Position = UDim2.new(0.5, 0, 0, 165)
            status.AnchorPoint = Vector2.new(0.5, 0)
            status.Size = UDim2.new(0.8, 0, 0, 30)
            status.Font = Enum.Font.GothamBold
            status.TextSize = 22
            status.Text = "FISHING NORMAL"
            status.BackgroundTransparency = 1
            status.TextColor3 = Color3.fromRGB(0, 255, 100)

            local lastCaught = player.leaderstats.Caught.Value
            local lastChange = tick()
            local stuck = false
            st.fishingPanelRunning = true

            spawn(LPH_NO_VIRTUALIZE(function()
                while st.fishingPanelRunning and task.wait(1) do
                    local fishText = ""
                    pcall(function()
                        fishText = player.PlayerGui.Inventory.Main.Top.Options.Fish.Label.BagSize.Text
                    end)
                    local caught = player.leaderstats.Caught.Value
                    fishCount.Text = "Fish: " .. (fishText or "0/0")
                    totalCaught.Text = "Value: " .. tostring(caught)
                    if caught > lastCaught then
                        lastCaught = caught
                        lastChange = tick()
                        if stuck then
                            stuck = false
                            status.Text = "FISHING NORMAL"
                            status.TextColor3 = Color3.fromRGB(0, 255, 100)
                        end
                    end
                    if not stuck and tick() - lastChange >= 10 then
                        stuck = true
                        status.Text = "FISHING STUCK"
                        status.TextColor3 = Color3.fromRGB(255, 70, 70)
                    end
                end
            end))
        else
            st.fishingPanelRunning = false
            local g = game.CoreGui:FindFirstChild("ChloeX_FishingPanel")
            if g then g:Destroy() end
        end
    end
})

Fish:AddSubSection("Fishing")

Fish:AddInput({
    Title = "Fishing Delay",
    Content = "Delay complete fishing!",
    Value = tostring(_G.Delay),
    Callback = function(val)
        local num = tonumber(val)
        if num and num > 0 then
            _G.Delay = num
            print("Fishing Delay set to:", _G.Delay)

            spawn(LPH_NO_VIRTUALIZE(function()
                print("Started")
                while true do
                    if mods.FishingController and mods.FishingController._autoLoop then
                        local fishing = mods.FishingController
                        if fishing:GetCurrentGUID() then
                            print("Waiting", _G.Delay)
                            task.wait(_G.Delay)

                            repeat
                                local ok, err = pcall(function()
                                    api.Events.REFishDone:FireServer()
                                end)
                                if ok then
                                    print("Successfully")
                                else
                                    warn("Failed to Fire REFishDone:", err)
                                end
                                task.wait(0.05)
                            until not fishing:GetCurrentGUID() or not fishing._autoLoop

                            print("loop ended")
                        end
                    end
                    task.wait(0.1)
                end
            end))
        else
            warn("Invalid fishing delay input")
        end
    end
})

shakeDelay = 0
Fish:AddInput({
    Title = "Shake Delay",
    Value = tostring(shakeDelay),
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 0 then
            shakeDelay = num
        end
    end
})

userId = tostring(svc.Players.LocalPlayer.UserId)
CosmeticFolder = workspace:WaitForChild("CosmeticFolder")

Fish:AddDropdown({
    Title = "Fishing Mode",
    Options = { "Auto Perfect", "Legit" },
    Default = "Auto Perfect",
    Multi = false,
    Callback = function(v)
        selectedMode = v
    end
})

function tryCast()
    local gui = svc.PG
    local cam = svc.Camera
    local vim = svc.VIM
    local player = game:GetService("Players").LocalPlayer
    local pos = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local lastGUID

    while mods.FishingController._autoLoop do
        if mods.FishingController:GetCurrentGUID() then
            task.wait(0.05)
        else
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.05)
            local bar = gui:WaitForChild("Charge")
                :WaitForChild("Main")
                :WaitForChild("CanvasGroup")
                :WaitForChild("Bar")

            local tCharge = tick()
            while bar:IsDescendantOf(gui) and bar.Size.Y.Scale < 0.95 do
                task.wait(0.001)
                if tick() - tCharge > 1 then
                    break
                end
            end

            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)

            local tWait = tick()
            local gotShake = false
            while tick() - tWait < 3 do
                local guid = mods.FishingController:GetCurrentGUID()
                if guid and guid ~= lastGUID then
                    gotShake = true
                    print("[DEBUG] Shake detected! GUID:", guid)
                    lastGUID = guid
                    break
                end
                task.wait(0.05)
            end

            if gotShake then
                local prevCaught = player.leaderstats and player.leaderstats.Caught.Value or 0
                local tCatch = tick()
                while tick() - tCatch < 8 do
                    if (player.leaderstats and player.leaderstats.Caught.Value > prevCaught)
                        or not mods.FishingController:GetCurrentGUID() then
                        break
                    end
                    task.wait(0.1)
                end
                while mods.FishingController:GetCurrentGUID() do
                    task.wait(0.05)
                end
                task.wait(1.3)
            end
        end
        task.wait(0.05)
    end
end

Fish:AddToggle({
    Title = "Legit Fishing",
    Default = false,
    Callback = function(state)
        local fishing = mods.FishingController
        local folder = CosmeticFolder
        local id = userId
        local running = state

        fishing._autoLoop = state

        if state then
            if selectedMode == "Auto Perfect" then
                spawn(LPH_NO_VIRTUALIZE(function()
                    while running and fishing._autoLoop do
                        if not folder:FindFirstChild(id) then
                            repeat
                                tryCast()
                                task.wait(0.1)
                            until folder:FindFirstChild(id) or not fishing._autoLoop
                        end
                        while folder:FindFirstChild(id) and fishing._autoLoop do
                            if fishing:GetCurrentGUID() then
                                local start = tick()
                                while fishing:GetCurrentGUID() and fishing._autoLoop do
                                    pcall(function()
                                        fishing:RequestFishingMinigameClick()
                                    end)
                                    if tick() - start >= (_G.Delay) then
                                        task.wait(_G.Delay)
                                        repeat
                                            pcall(function()
                                                api.Events.REFishDone:FireServer()
                                            end)
                                            task.wait(0.05)
                                        until not fishing:GetCurrentGUID() or not fishing._autoLoop
                                        break
                                    end
                                    task.wait()
                                end
                            end
                            task.wait(0.2)
                        end
                        repeat task.wait(0.1) until not folder:FindFirstChild(id) or not fishing._autoLoop
                        if fishing._autoLoop then
                            task.wait(0.2)
                            tryCast()
                        end
                        task.wait(0.2)
                    end
                end))
            elseif selectedMode == "Legit" then
                if not fishing._oldGetPower then
                    fishing._oldGetPower = fishing._getPower
                end
                fishing._getPower = function(...)
                    return 0.999
                end
                spawn(LPH_NO_VIRTUALIZE(function()
                    while running and fishing._autoLoop do
                        if _G.ShakeEnabled and fishing:GetCurrentGUID() then
                            local start = tick()
                            while fishing:GetCurrentGUID() and fishing._autoLoop and _G.ShakeEnabled do
                                pcall(function()
                                    fishing:RequestFishingMinigameClick()
                                end)
                                if tick() - start >= (_G.Delay or 1) then
                                    repeat
                                        pcall(function()
                                            api.Events.REFishDone:FireServer()
                                        end)
                                        task.wait(0.1)
                                    until not fishing:GetCurrentGUID() or not fishing._autoLoop or not _G.ShakeEnabled
                                    break
                                end
                                task.wait(0.1)
                            end
                        elseif not fishing:GetCurrentGUID() then
                            local center = Vector2.new(svc.Camera.ViewportSize.X / 2, svc.Camera.ViewportSize.Y / 2)
                            pcall(function()
                                fishing:RequestChargeFishingRod(center, true)
                            end)
                            task.wait(0.25)
                        end
                        task.wait(0.05)
                    end
                end))
            end
        else
            fishing._autoLoop = false
            if fishing._oldGetPower then
                fishing._getPower = fishing._oldGetPower
                fishing._oldGetPower = nil
            end
        end
    end
})

Fish:AddToggle({
    Title = "Auto Shake",
    Default = false,
    Callback = function(state)
        mods._autoShake = state
        local clickEffect = svc.PG:FindFirstChild("!!! Click Effect")

        if state then
            if clickEffect then
                clickEffect.Enabled = false
            end

            spawn(LPH_NO_VIRTUALIZE(function()
                while mods._autoShake do
                    pcall(function()
                        mods.FishingController:RequestFishingMinigameClick()
                    end)
                    task.wait(shakeDelay)
                end
            end))
        else
            if clickEffect then
                clickEffect.Enabled = true
            end
        end
    end
})

Fish:AddSubSection("Instant Fishing")

Fish:AddInput({
    Title = "Delay Complete Instant",
    Value = tostring(_G.DelayComplete),
    Callback = function(val)
        local num = tonumber(val)
        if num and num >= 0 then
            _G.DelayComplete = num
        end
    end
})

Fish:AddToggle({
    Title = "Instant Fishing",
    Content = "Auto instantly catch fish (Slowed)",
    Default = false,
    Callback = function(s)
        st.autoInstant = s
        if s then
            _G.Celestial.InstantCount = getFishCount()
            spawn(LPH_NO_VIRTUALIZE(function()
                while st.autoInstant do
                    if st.canFish then
                        st.canFish = false
                        local ok, _, serverTime = pcall(function()
                            return api.Functions.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                        end)
                        if ok and typeof(serverTime) == "number" then
                            local yPos = -1.233184814453125
                            local power = 0.999
                            task.wait(0.1)
                            pcall(function()
                                api.Functions.StartMini:InvokeServer(yPos, power, serverTime)
                            end)
                            local started = tick()
                            repeat
                                task.wait(0.05)
                            until (_G.FishMiniData and _G.FishMiniData.LastShift) or tick() - started > 1
                            task.wait(_G.DelayComplete)
                            pcall(function()
                                api.Events.REFishDone:FireServer()
                            end)
                            local startCount = getFishCount()
                            local waitStart = tick()
                            repeat
                                task.wait(0.05)
                            until getFishCount() > startCount or tick() - waitStart > 1
                        end
                        st.canFish = true
                    end
                    task.wait(0.05)
                end
            end))
        end
    end
})

if MiniEvent then
    if _G._MiniEventConn then
        _G._MiniEventConn:Disconnect()
    end
    _G._MiniEventConn = MiniEvent.OnClientEvent:Connect(function(state, data)
        if state and data then
            _G.FishMiniData = data
        end
    end)
end

Fish:AddSubSection("Fast Reel")

function TryRemoteCancel(maxAttempts, retryDelay)
	maxAttempts = maxAttempts or 30      -- berapa kali dicoba
	retryDelay = retryDelay or 0.05      -- jeda antar percobaan

	for attempt = 1, maxAttempts do
		local success, result, result2 = pcall(function()
			return api.Functions.Cancel:InvokeServer()
		end)

		if success then
			if result == true or result2 == true then
				return true, { result, result2 }
			end
		end
		task.wait(retryDelay)
	end
	return false
end

function TryRemoteCharge(maxAttempts, retryDelay)
	maxAttempts = maxAttempts or 30      -- berapa kali dicoba
	retryDelay = retryDelay or 0.05      -- jeda antar percobaan

	for attempt = 1, maxAttempts do
		local success, result = pcall(function()
            local time = workspace:GetServerTimeNow() - 0.35
			return api.Functions.ChargeRod:InvokeServer(nil, nil, nil, time)
		end)

		if success then
			if result then
				return true, { result, result2 }
			end
		end
		task.wait(retryDelay)
	end
	return false
end

function LemparBaitl(callback)
	local cancel, rescancel = TryRemoteCancel(5, 0.02)
	if not cancel then task.wait(0.1) return callback(false) end
	local charger, rescharger = TryRemoteCharge(5, 0.02)
	if not charger then task.wait(0.1) return callback(false) end
	task.spawn(function()
        local CFrame = hrp.CFrame
		local RaycastParams_new = RaycastParams.new()
		RaycastParams_new.IgnoreWater = true
		RaycastParams_new.RespectCanCollide = false
		RaycastParams_new.FilterType = Enum.RaycastFilterType.Exclude
		RaycastParams_new.FilterDescendantsInstances = RaycastUtility:getFilteredTargets(player)
		local workspace_Raycast = workspace:Raycast(CFrame.Position + CFrame.LookVector * (1 * 15 + 10), Vector3.new(0, -80, 0), RaycastParams_new)
		if not workspace_Raycast then
			return callback("Failed rod cast!") 
		end
		if not workspace_Raycast.Instance then
			return callback( "Unable to cast from this far!")
		end
		local EligiblePath = workspace_Raycast.Instance:GetAttribute("EligiblePath")
        if EligiblePath then
			local var59
			local var17 = repl.Data
			if var17 and not var17.Destroyed then
				var59 = var17:Get(EligiblePath)
			end
			if var59 ~= true then
				return callback("You do not have this area unlocked!")
			end
		end

		local send, send1 = api.Functions.StartMini:InvokeServer(unpack({ workspace_Raycast.Position.Y, 1, workspace:GetServerTimeNow() }))
		if callback then
			callback(send1)
		end
	end)
end

local fastReelThread
function fastReeler()
    if _G.FBlatant and not fastReelThread then
		fastReelThread = task.spawn(function()
			while _G.FBlatant do
				LemparBaitl(function(result)
                    if typeof(result) == "table" and result.UUID and result.RandomSeed then
                        local delayReel = tonumber(_G.FishingDelay) + 0.1
                        task.wait(delayReel)
                        api.Events.REFishDone:FireServer()
                    end
                end)
				-- task.wait(0.1)
                local delayBait = tonumber(_G.Reel) + 0.2
				task.wait(delayBait)
			end
			fastReelThread = nil -- cleanup
		end)
	end
end

function Fastest()
    task.spawn(function()
        pcall(function() api.Functions.Cancel:InvokeServer() end)
        local now = workspace:GetServerTimeNow()
        pcall(function() api.Functions.ChargeRod:InvokeServer(now) end)
        pcall(function() api.Functions.StartMini:InvokeServer(-1, 0.999) end)
        task.wait(_G.FishingDelay)
        pcall(function() api.Events.REFishDone:FireServer() end)
    end)
end



Fish:AddInput({
    Title = "Delay Bait",
    Value = tostring(_G.Reel),
    Default = "1.7",
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then _G.Reel = n end
        SaveConfig()
    end
})

Fish:AddInput({
    Title = "Delay Reel",
    Value = tostring(_G.FishingDelay),
    Default = "0.5",
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then _G.FishingDelay = n end
        SaveConfig()
    end
})

Fish:AddToggle({
    Title = "Fast Reel",
    Default = _G.FBlatant,
    Callback = function(s)
        _G.FBlatant = s
        if s then
            fastReeler()
        else
            api.Functions.Cancel:InvokeServer()
        end
    end
})

local UseEnchantCast = false
task.defer(function()
	task.wait(0.1)
	local success, meta = pcall(getmetatable, repl.Data)
	if not (success and meta and type(meta) == "table") then
	end

	-- simpan fungsi lama
	local oldGetExpect = meta.__index.GetExpect

	local function updateHook()
		if UseEnchantCast then
			meta.__index.GetExpect = function(self, key)
				if typeof(key) == "string" and key:lower() == "autofishing" then
					-- print("[🎣] Spoof aktif → autofishing = true (client-only)")
					return false
				end
				return oldGetExpect(self, key)
			end
		else
			meta.__index.GetExpect = oldGetExpect
		end
	end

    Fish:AddToggle({
        Title = "Use Perfection Enchant",
        Default = UseEnchantCast,
        Callback = function(s)
            UseEnchantCast = s
            if s then
                api.Functions.AutoEnabled:InvokeServer(s)
            else	
                api.Functions.AutoEnabled:InvokeServer(s)
            end
            updateHook()
        end
    })

end)



Fish:AddButton({
    Title = "Recovery Fishing",
    Callback = function()
        pcall(function()
            api.Functions.Cancel:InvokeServer()
        end)
    end
})

Fish:AddSubSection("Utility Player")

Fish:AddToggle({
    Title = "No Fishing Animations",
    Default = false,
    Callback = function(state)
        local char = player.Character or player.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then return end

        if state then
            st.stopAnimHookEnabled = true
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0)
            end
            st.stopAnimConn = animator.AnimationPlayed:Connect(function(track)
                if st.stopAnimHookEnabled then
                    task.defer(function()
                        pcall(function()
                            track:Stop(0)
                        end)
                    end)
                end
            end)
        else
            st.stopAnimHookEnabled = false
            if st.stopAnimConn then
                st.stopAnimConn:Disconnect()
                st.stopAnimConn = nil
            end
        end
    end
})

Fish:AddToggle({
    Title = "Auto Equip Rod",
    Content = "Automatically equip your fishing rod",
    Default = false,
    Callback = function(state)
        st.autoEquipRod = state

        local function hasRodEquipped()
            local equippedId = repl.Data:Get("EquippedId")
            if not equippedId then return false end
            local item = mods.PlayerStatsUtility:GetItemFromInventory(repl.Data, function(it)
                return it.UUID == equippedId
            end)
            if not item then return false end
            local data = mods.ItemUtility:GetItemData(item.Id)
            return data and data.Data.Type == "Fishing Rods"
        end

        local function equipRod()
            if not hasRodEquipped() then
                api.Events.REEquip:FireServer(1)
            end
        end

        task.spawn(function()
            while st.autoEquipRod do
                equipRod()
                task.wait(1)
            end
        end)
    end
})

Fish:AddToggle({
    Title = "Freeze Player",
    Default = false,
    Callback = function(state)
        st.frozen = state
        local char = st.player.Character

        local function hasRodEquipped()
            local equippedId = repl.Data:Get("EquippedId")
            if not equippedId then return false end
            local item = mods.PlayerStatsUtility:GetItemFromInventory(repl.Data, function(it)
                return it.UUID == equippedId
            end)
            if not item then return false end
            local data = mods.ItemUtility:GetItemData(item.Id)
            return data and data.Data.Type == "Fishing Rods"
        end

        local function equipRod()
            if not hasRodEquipped() then
                api.Events.REEquip:FireServer(1)
                task.wait(0.5)
            end
        end

        local function setFreeze(c, freeze)
            if not c then return end
            for _, x in ipairs(c:GetDescendants()) do
                if x:IsA("BasePart") then
                    x.Anchored = freeze
                end
            end
        end

        local function apply(c)
            if st.frozen then
                equipRod()
                if hasRodEquipped() then
                    setFreeze(c, true)
                end
            else
                setFreeze(c, false)
            end
        end

        apply(char)

        st.player.CharacterAdded:Connect(function(newChar)
            task.wait(1)
            apply(newChar)
        end)
    end
})

SellGroup = Tabs.Main:AddSection("Sell Item")

SellGroup:AddDropdown({
    Options = { "Delay", "Count" },
    Default = "Delay",
    Title = "Select Sell Mode",
    Callback = function(o)
        st.sellMode = o
        SaveConfig()
    end
})

SellGroup:AddInput({
    Default = "1",
    Title = "Set Value",
    Content = "Delay = Minutes | Count = Backpack Count",
    Placeholder = "Input Here",
    Callback = function(v)
        local n = tonumber(v) or 1
        if st.sellMode == "Delay" then
            st.sellDelay = n * 60
        else
            st.inputSellCount = n
        end
        SaveConfig()
    end
})

local lastCur = 0
local selling = false

SellGroup:AddToggle({
    Title = "Start Selling",
    Default = false,
    Callback = function(s)
        st.autoSellEnabled = s
        if not s then return end

        task.spawn(function()
            local RFSellAllItems = mods.Net["RF/SellAllItems"]

            while st.autoSellEnabled do
                local bagLabel = player:WaitForChild("PlayerGui")
                    :WaitForChild("Inventory")
                    .Main.Top.Options.Fish.Label:FindFirstChild("BagSize")

                local cur, max = 0, 0
                if bagLabel and bagLabel:IsA("TextLabel") then
                    local c, m = bagLabel.Text:match("(%d+)%s*/%s*(%d+)")
                    cur, max = tonumber(c) or 0, tonumber(m) or 0
                end

                if st.sellMode == "Delay" then
                    RFSellAllItems:InvokeServer()
                    task.wait(st.sellDelay)
                
                elseif st.sellMode == "Count" then
                    local target = tonumber(st.inputSellCount) or max
                    if not selling and lastCur < target and cur == target then
                        selling = true
                        RFSellAllItems:InvokeServer()
                    end
                    if selling and cur < target then
                        selling = false
                    end

                    lastCur =  cur
                    task.wait(0.2)
                end
            end
        end)
    end
})

SellGroup:AddSubSection("Auto Sell Enchant Stone")
EnchantStoneID = 10
TargetLeft = 0
AutoSellRunning = false
EnchantStonePanel = SellGroup:AddParagraph({
    Title = "Enchant Stone Left Status",
    Content = "Counting..."
})

SellGroup:AddInput({
    Title = "Target Left",
    Default = "0",
    Callback = function(v)
        num = tonumber(v)
        if num and num >= 0 then
            TargetLeft = num
        end
    end
})

SellGroup:AddToggle({
    Title = "Start Sell Enchant Stone",
    Default = false,
    Callback = function(s)
        AutoSellRunning = s

        if not AutoSellRunning then
            return
        end

        task.spawn(function()
            while AutoSellRunning do
                inv = repl.Data:GetExpect({"Inventory","Items"})
                count = 0
                targetUUID = nil

                for _, item in ipairs(inv) do
                    if item.Id == EnchantStoneID then
                        count += 1
                        if not targetUUID then
                            targetUUID = item.UUID
                        end
                    end
                end

                EnchantStonePanel:SetContent("Enchant Stone : " .. count)

                if count <= TargetLeft then
                    AutoSellRunning = false
                    break
                end

                if not targetUUID then
                    AutoSellRunning = false
                    break
                end

                task.defer(function()
                    api.Functions.SellItem:InvokeServer(targetUUID)
                end)

                task.wait(0.1)
            end
        end)
    end
})

task.spawn(function()
    while task.wait(1) do
        inv = repl.Data:GetExpect({"Inventory","Items"})
        count = 0
        
        for _, item in ipairs(inv) do
            if item.Id == EnchantStoneID then
                count += 1
            end
        end

        EnchantStonePanel:SetContent("Enchant Stone : " .. count)
    end
end)

FG = Tabs.Main:AddSection("Favorite")

FG:AddDropdown({
    Options = #fishNames > 0 and fishNames or { "No Fish Found" },
    Content = "Favorite By Name Fish (Recommended)",
    Multi = true,
    Title = "Name",
    Callback = function(o)
        st.selectedName = toSet(o)
    end
})

FG:AddDropdown({
    Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" },
    Multi = true,
    Title = "Rarity",
    Callback = function(o)
        st.selectedRarity = toSet(o)
    end
})

FG:AddDropdown({
    Options = _G.Variant,
    Multi = true,
    Title = "Variant",
    Callback = function(o)
        if next(st.selectedName) ~= nil then
            st.selectedVariant = toSet(o)
        else
            st.selectedVariant = {}
            warn("Pilih Name dulu sebelum memilih Variant.")
        end
    end
})

FG:AddToggle({
    Title = "Auto Favorite",
    Default = false,
    Callback = function(s)
        st.autoFavEnabled = s
        if s then
            scanInventory()
            repl.Data:OnChange({ "Inventory", "Items" }, scanInventory)
        end
    end
})

FG:AddButton({
    Title    = "Unfavorite Fish",
    Callback = function()
        for _, item in ipairs(repl.Data:GetExpect({ "Inventory", "Items" })) do
            local isFav = rawget(favState, item.UUID)
            if isFav == nil then
                isFav = item.Favorited
            end
            if isFav then
                api.Events.REFav:FireServer(item.UUID)
                rawset(favState, item.UUID, false)
            end
        end
    end
})

Shop = Tabs.Auto:AddSection("Shopping")

ShopParagraph = Shop:AddParagraph({
    Title = "MERCHANT STOCK PANEL",
    Content = "Loading...",
})

Shop:AddButton({
    Title = "Open/Close Merchant",
    Callback = function()
        local merchant = svc.PG:FindFirstChild("Merchant")
        if merchant then
            merchant.Enabled = not merchant.Enabled
        end
    end
})

function UPX()
    local list = {}
    for _, child in ipairs(gui.ItemsFrame:GetChildren()) do
        if child:IsA("ImageLabel") and child.Name ~= "Frame" then
            local frame = child:FindFirstChild("Frame")
            if frame and frame:FindFirstChild("ItemName") then
                local itemName = frame.ItemName.Text
                if not string.find(itemName, "Mystery") then
                    table.insert(list, "- " .. itemName)
                end
            end
        end
    end

    if #list == 0 then
        ShopParagraph:SetContent("No items found\n" .. gui.RefreshMerchant.Text)
    else
        ShopParagraph:SetContent(table.concat(list, "\n") .. "\n\n" .. gui.RefreshMerchant.Text)
    end
end

task.spawn(function()
    while task.wait(1) do
        pcall(UPX)
    end
end)

Shop:AddSubSection("Buy Rod")

Shop:AddDropdown({
    Title = "Select Rod",
    Options = st.rodDisplayNames,
    Callback = function(selected)
        if not selected then return end
        local clean = _cleanName(selected)
        local info  = st.rods[clean]
        if info then
            st.selectedRodId = info.Id
        end
    end
})

Shop:AddButton({
    Title = "Buy Selected Rod",
    Callback = function()
        if not st.selectedRodId then return end
        local info = st.rods[st.selectedRodId] or st.rods[_cleanName(st.selectedRodId)]
        if not info then return end
        pcall(function()
            api.Functions.BuyRod:InvokeServer(info.Id)
        end)
    end
})

Shop:AddSubSection("Buy Baits")

Shop:AddDropdown({
    Title = "Select Bait",
    Options = st.baitDisplayNames,
    Callback = function(selected)
        if not selected then return end
        local clean = _cleanName(selected)
        local info  = st.baits[clean]
        if info then
            st.selectedBaitId = info.Id
        end
    end
})

Shop:AddButton({
    Title = "Buy Selected Bait",
    Callback = function()
        if not st.selectedBaitId then return end
        local info = st.baits[st.selectedBaitId] or st.baits[_cleanName(st.selectedBaitId)]
        if not info then return end
        pcall(function()
            api.Functions.BuyBait:InvokeServer(info.Id)
        end)
    end
})

Shop:AddSubSection("Buy Weather")

weatherinfo = {
    "Cloudy ($10000)",
    "Wind ($10000)",
    "Snow ($15000)",
    "Storm ($35000)",
    "Radiant ($50000)",
    "Shark Hunt ($300000)"
}

WeatherDropdown = Shop:AddDropdown({
    Title = "Select Weather",
    Multi = true,
    Options = weatherinfo,
    Callback = function(selected)
        st.selectedEvents = {}
        if type(selected) == "table" then
            for _, val in ipairs(selected) do
                local clean = val:match("^(.-) %(") or val
                table.insert(st.selectedEvents, clean)
            end
        end
        SaveConfig()
    end
})

Shop:AddToggle({
    Title = "Auto Buy Weather",
    Default = false,
    Callback = function(state)
        st.autoBuyWeather = state
        if not api.Functions.BuyWeather then return end
        if state then
            spawn(LPH_NO_VIRTUALIZE(function()
                while st.autoBuyWeather do
                    local dropdownValue = WeatherDropdown.Value or WeatherDropdown.Selected or {}
                    local selectedNow = {}
                    if type(dropdownValue) == "table" then
                        for _, v in ipairs(dropdownValue) do
                            local clean = v:match("^(.-) %(") or v
                            table.insert(selectedNow, clean)
                        end
                    elseif type(dropdownValue) == "string" then
                        local clean = dropdownValue:match("^(.-) %(") or dropdownValue
                        table.insert(selectedNow, clean)
                    end
                    if #selectedNow > 0 then
                        local active = {}
                        local folder = workspace:FindFirstChild("Weather")
                        if folder then
                            for _, w in ipairs(folder:GetChildren()) do
                                table.insert(active, string.lower(w.Name))
                            end
                        end
                        for _, weather in ipairs(selectedNow) do
                            local lower = string.lower(weather)
                            local isActive = table.find(active, lower)
                            if not isActive then
                                pcall(function()
                                    api.Functions.BuyWeather:InvokeServer(weather)
                                end)
                                task.wait(0.05)
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end))
        end
    end
})

EG = Tabs.Auto:AddSection("Event")

EG:AddDropdown({
    Options = getEvents() or {},
    Multi = false,
    Title = "Priority Event",
    Callback = function(v)
        st.priorityEvent = v
    end
})

EG:AddDropdown({
    Options = getEvents() or {},
    Multi = true,
    Title = "Select Event",
    Callback = function(o)
        st.selectedEvents = {}
        for _, v in pairs(o) do
            table.insert(st.selectedEvents, v)
        end
        st.curCF = nil
        if st.autoEventActive and (#st.selectedEvents > 0 or st.priorityEvent) then
            task.spawn(st.loop)
        end
    end
})

EG:AddToggle({
    Title = "Auto Event",
    Default = false,
    Callback = function(s)
        st.autoEventActive = s
        if s and (#st.selectedEvents > 0 or st.priorityEvent) then
            st.origCF = st.origCF or root(player.Character).CFrame
            task.spawn(st.loop)
        else
            if st.origCF then
                player.Character:PivotTo(st.origCF)
                notify("Auto Event Off")
            end
            st.origCF, st.curCF = nil, nil
        end
    end
})


task.spawn(function()
    local switching = false
    local startPos = nil
    local ThresholdTotalBase = 0
    while task.wait(1) do
        local Data = repl.Data
        if Data then
            local plr = svc.Players.LocalPlayer
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and not startPos then startPos = hrp.CFrame end

            if _G.ThresholdFarm then
                local stats = Data:Get({ "Statistics" }) or {}
                local fish = stats.FishCaught or 0
                if ThresholdTotalBase == 0 then ThresholdTotalBase = ThresholdBase end
                local diff = fish - ThresholdBase
                local progress = (ThresholdTarget > 0) and math.min((diff / ThresholdTarget) * 100, 100) or 0
                ThresholdParagraph:SetContent(string.format("Current : %s\nTarget : %s\nProgress : %.1f%%", diff,
                    ThresholdTarget, progress))

                if hrp and ThresholdPos1 ~= "" and ThresholdPos2 ~= "" and not switching then
                    switching = true
                    task.spawn(function()
                        local pos1 = Vector3.new(unpack(string.split(ThresholdPos1, ",")))
                        local pos2 = Vector3.new(unpack(string.split(ThresholdPos2, ",")))
                        local baseFish = fish
                        local target1 = baseFish + ThresholdTarget
                        while _G.ThresholdFarm do
                            repeat
                                task.wait(1)
                                local s = Data:Get({ "Statistics" }) or {}
                                fish = s.FishCaught or 0
                            until fish >= target1 or not _G.ThresholdFarm
                            if not _G.ThresholdFarm then break end
                            hrp.CFrame = CFrame.new(pos2 + Vector3.new(0, 3, 0))
                            ThresholdBase = fish
                            baseFish = fish
                            target1 = baseFish + ThresholdTarget
                            repeat
                                task.wait(1)
                                local s = Data:Get({ "Statistics" }) or {}
                                fish = s.FishCaught or 0
                            until fish >= target1 or not _G.ThresholdFarm
                            if not _G.ThresholdFarm then break end
                            hrp.CFrame = CFrame.new(pos1 + Vector3.new(0, 3, 0))
                            ThresholdBase = fish
                            baseFish = fish
                            target1 = baseFish + ThresholdTarget
                        end
                        switching = false
                    end)
                end
            end
        else
            task.wait(1)
        end
    end
end)

P1 = Tabs.Tele:AddSection("Teleport To Player")

playerDropdown = P1:AddDropdown({
    Title = "Select Player to Teleport",
    Content = "Choose target player",
    Options = getPlayerList(),
    Default = {},
    Callback = function(value)
        st.trade.teleportTarget = value
    end
})

P1:AddButton({
    Title = "Refresh Player List",
    Content = "Refresh list!",
    Callback = function()
        playerDropdown:SetValues(getPlayerList())
        notify("Player list refreshed!")
    end
})

P1:AddButton({
    Title = "Teleport to Player",
    Content = "Teleport to selected player from dropdown",
    Callback = function()
        local targetName = st.trade.teleportTarget
        if not targetName then
            notify("Please select a player first!")
            return
        end
        local target = svc.Players:FindFirstChild(targetName)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                notify("Teleported to " .. target.Name)
            else
                notify("Your HumanoidRootPart not found.")
            end
        else
            notify("Target not found or not loaded.")
        end
    end
})


P2 = Tabs.Tele:AddSection("Location")

local locationNames = {}
for name, _ in pairs(locations) do
    table.insert(locationNames, name)
end

P2:AddDropdown({
    Title = "Select Location",
    Content = "Choose teleport destination",
    Options = locationNames,
    Default = {},
    Callback = function(value)
        st.teleportTarget = value
    end
})

P2:AddButton({
    Title = "Teleport to Location",
    Content = "Teleport to selected location",
    Callback = function()
        local locName = st.teleportTarget
        if not locName then
            notify("Please select a location first!")
            return
        end
        local pos = locations[locName]
        if pos then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                notify("Teleported to " .. locName)
            end
        end
    end
})

function getGroupedByType(typeName)
    local items = repl.Data:GetExpect({ "Inventory", "Items" })
    local grouped, values = {}, {}
    for _, item in ipairs(items) do
        local info = mods.ItemUtility.GetItemDataFromItemType("Items", item.Id)
        if info and info.Data.Type == typeName then
            local name = info.Data.Name
            grouped[name] = grouped[name] or { count = 0, uuids = {} }
            grouped[name].count += (item.Quantity or 1)
            table.insert(grouped[name].uuids, item.UUID)
        end
    end
    for name, data in pairs(grouped) do
        table.insert(values, ("%s x%d"):format(name, data.count))
    end
    return grouped, values
end

TradeByName = Tabs.Trade:AddSection("Trading Fish")
Name_Monitor = TradeByName:AddParagraph({
    Title = "Panel Name Trading",
    Content = [[
Player : ???
Item   : ???
Amount : 0
Status : Idle
Success: 0 / 0
]]
})

_G.safeSetContent = function(obj, text)
    svc.RunService.Heartbeat:Once(function()
        if obj then
            obj:SetContent(text)
        end
    end)
end

function updateNameStatus(statusText)
    local ts = st.trade
    local color = "200,200,200"
    if statusText and statusText:lower():find("send") then
        color = "51,153,255"
    elseif statusText and statusText:lower():find("complete") then
        color = "0,204,102"
    elseif statusText and statusText:lower():find("time") then
        color = "255,69,0"
    end

    local text = string.format([[
<font color='rgb(173,216,230)'>Player : %s</font>
<font color='rgb(173,216,230)'>Item   : %s</font>
<font color='rgb(173,216,230)'>Amount : %d</font>
<font color='rgb(%s)'>Status : %s</font>
<font color='rgb(173,216,230)'>Success: %d / %d</font>
]],
        ts.selectedPlayer or "???",
        ts.selectedItem or "???",
        ts.tradeAmount or 0,
        color,
        statusText or "Idle",
        ts.successCount or 0,
        ts.totalToTrade or 0
    )
    _G.safeSetContent(Name_Monitor, text)
end

function hasItem(uuid)
    for _, it in ipairs(repl.Data:GetExpect({ "Inventory", "Items" })) do
        if it.UUID == uuid then
            return true
        end
    end
    return false
end

function sendTrade(targetName, uuid, itemName, price)
    local ts = st.trade
    ts.awaiting, ts.lastResult = true, nil
    local completed = false

    local target = svc.Players:FindFirstChild(targetName)
    if not target then
        ts.trading = false
        updateNameStatus("<font color='#ff3333'>Player not found</font>")
        return false
    end

    if itemName then
        updateNameStatus("Sending")
    end

    local ok = pcall(function()
        api.Functions.Trade:InvokeServer(target.UserId, uuid)
    end)
    if not ok then
        return false
    end

    local startTime = tick()
    while ts.trading and not completed do
        if not hasItem(uuid) then
            completed = true
            if itemName then
                ts.successCount += 1
                updateNameStatus("Completed")
            end
        elseif tick() - startTime > 10 then
            return false
        end
        task.wait(0.2)
    end

    return completed
end

function sendTradeWithRetry(targetName, uuid, itemName, price)
    local ts = st.trade
    local retries = 0
    while retries < 3 and ts.trading do
        local ok = sendTrade(targetName, uuid, itemName, price)
        if ok then
            task.wait(2.5)
            return true
        end
        retries += 1
        task.wait(1)
    end
    return false
end

function startTradeByName()
    local ts = st.trade
    if ts.trading then return end
    if not ts.selectedPlayer or not ts.selectedItem then
        return
    end

    ts.trading = true
    ts.successCount = 0

    local itemData = ts.currentGrouped[ts.selectedItem]
    if not itemData then
        ts.trading = false
        updateNameStatus("<font color='#ff3333'>Item not found</font>")
        return
    end

    ts.totalToTrade = math.min(ts.tradeAmount, #itemData.uuids)
    local i = 1
    while ts.trading and ts.successCount < ts.totalToTrade do
        sendTradeWithRetry(ts.selectedPlayer, itemData.uuids[i], ts.selectedItem)
        i += 1
        if i > #itemData.uuids then i = 1 end
        task.wait(2)
    end

    ts.trading = false
    updateNameStatus("<font color='#66ccff'>All trades finished</font>")
end

function chooseFishesByRange(fishes, target)
    table.sort(fishes, function(a, b) return a.Price > b.Price end)
    local chosen, total = {}, 0
    for _, fish in ipairs(fishes) do
        if total + fish.Price <= target then
            table.insert(chosen, fish)
            total += fish.Price
        end
        if total >= target then break end
    end
    if total < target and #fishes > 0 then
        table.insert(chosen, fishes[#fishes])
    end
    return chosen, total
end

itemDropdown = TradeByName:AddDropdown({
    Options = {},
    Multi = false,
    Title = "Select Item",
    Callback = function(value)
        st.trade.selectedItem = value and value:match("^(.-) x") or value
        updateNameStatus()
    end
})

TradeByName:AddButton({
    Title = "Refresh Fish",
    Callback = function()
        local grouped, values = getGroupedByType("Fish")
        st.trade.currentGrouped = grouped
        itemDropdown:SetValues(values or {})
    end,
    SubTitle = "Refresh Stone",
    SubCallback = function()
        local grouped, values = getGroupedByType("Enchant Stones")
        st.trade.currentGrouped = grouped
        itemDropdown:SetValues(values or {})
    end
})

TradeByName:AddInput({
    Title = "Amount to Trade",
    Default = "1",
    Callback = function(value)
        st.trade.tradeAmount = tonumber(value) or 1
        updateNameStatus()
    end
})

playerDropdown = TradeByName:AddDropdown({
    Options = {},
    Multi = false,
    Title = "Select Player",
    Callback = function(value)
        st.trade.selectedPlayer = value
        updateNameStatus()
    end
})

TradeByName:AddButton({
    Title = "Refresh Player",
    Callback = function()
        local names = {}
        for _, plr in ipairs(svc.Players:GetPlayers()) do
            if plr ~= st.player then table.insert(names, plr.Name) end
        end
        playerDropdown:SetValues(names or {})
    end
})

TradeByName:AddToggle({
    Title = "Start By Name",
    Default = false,
    Callback = function(state)
        if state then
            task.spawn(startTradeByName)
        else
            st.trade.trading = false
            updateNameStatus()
        end
    end
})

AcceptTrade = Tabs.Trade:AddSection("Auto Accept")

AcceptTrade:AddToggle({
    Title = "Auto Accept Trade",
    Default = _G.AutoAccept,
    Callback = function(value)
        _G.AutoAccept = value
    end
})

spawn(function()
    while true do
        task.wait(1)
        if _G.AutoAccept then
            pcall(function()
                local promptGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if promptGui and promptGui:FindFirstChild("Blackout") then
                    local blackout = promptGui.Blackout
                    if blackout:FindFirstChild("Options") then
                        local options = blackout.Options
                        local yesButton = options:FindFirstChild("Yes")
                        if yesButton then
                            local vr = game:GetService("VirtualInputManager")
                            local absPos = yesButton.AbsolutePosition
                            local absSize = yesButton.AbsoluteSize
                            local clickX = absPos.X + (absSize.X / 2)
                            local clickY = absPos.Y + (absSize.Y / 2) + 50
                            vr:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
                            task.wait(0.03)
                            vr:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
                        end
                    end
                end
            end)
        end
    end
end)

Bp = Tabs.Misc:AddSection("Miscellaneous")

Bp:AddToggle({
    Title = "Anti Staff",
    Content = "Auto kick if staff/developer joins the server.",
    Default = false,
    Callback = function(state)
        _G.AntiStaff = state
        if state then
            local GroupId = 35102746
            local StaffRoles = {
                [2] = "OG",
                [3] = "Tester",
                [4] = "Moderator",
                [75] = "Community Staff",
                [79] = "Analytics",
                [145] = "Divers / Artist",
                [250] = "Devs",
                [252] = "Partner",
                [254] = "Talon",
                [255] = "Wildes",
                [55] = "Swimmer",
                [30] = "Contrib",
                [35] = "Contrib 2",
                [100] = "Scuba",
                [76] = "CC"
            }

            task.spawn(function()
                while _G.AntiStaff do
                    for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
                        if plr ~= game.Players.LocalPlayer then
                            local rank = plr:GetRankInGroup(GroupId)
                            if StaffRoles[rank] then
                                game.Players.LocalPlayer:Kick("Seraphin Detected Staff, Automatically Kicked!")
                                return
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

local UltraConn

Bp:AddToggle({
    Title = "Boost Fps",
    Default = false,
    Callback = function(state)
        if state then
            local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
            local Lighting = game:GetService("Lighting")

            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 1
            end

            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.FogStart = 9e9

            settings().Rendering.QualityLevel = 1

            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CastShadow = false
                    v.Material = "Plastic"
                    v.Reflectance = 0
                    v.BackSurface = "SmoothNoOutlines"
                    v.BottomSurface = "SmoothNoOutlines"
                    v.FrontSurface = "SmoothNoOutlines"
                    v.LeftSurface = "SmoothNoOutlines"
                    v.RightSurface = "SmoothNoOutlines"
                    v.TopSurface = "SmoothNoOutlines"
                elseif v:IsA("Decal") then
                    v.Transparency = 1
                    v.Texture = ""
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                end
            end

            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("PostEffect") then
                    v.Enabled = false
                end
            end

            UltraConn = workspace.DescendantAdded:Connect(function(child)
                task.spawn(function()
                    if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke") or child:IsA("Fire") or child:IsA("Beam") then
                        svc.RunService.Heartbeat:Wait()
                        child:Destroy()
                    elseif child:IsA("BasePart") then
                        child.CastShadow = false
                    end
                end)
            end)
        else
            if UltraConn then
                UltraConn:Disconnect()
                UltraConn = nil
            end
        end
    end
})

Bp:AddToggle({
    Title = "Bypass Radar",
    Default = false,
    Callback = function(state)
        pcall(function()
            api.Functions.UpdateRadar:InvokeServer(state)
        end)
    end,
})

local cutsceneController
local originalPlay, originalStop

do
    local ok, controller = pcall(function()
        return require(svc.RS.Controllers.CutsceneController)
    end)
    if ok and controller then
        cutsceneController = controller
        originalPlay = cutsceneController.Play
        originalStop = cutsceneController.Stop
    end
end

local function EnableSkip()
    if api.Events.RECutscene then
        api.Events.RECutscene.OnClientEvent:Connect(function(...)
            warn("[CELESTIAL] Cutscene blocked (ReplicateCutscene)", ...)
        end)
    end
    if api.Events.REStop then
        api.Events.REStop.OnClientEvent:Connect(function()
            warn("[CELESTIAL] Cutscene blocked (StopCutscene)")
        end)
    end
    if cutsceneController then
        cutsceneController.Play = function(...)
            warn("[CELESTIAL] Cutscene skipped!")
        end
        cutsceneController.Stop = function(...)
            warn("[CELESTIAL] Cutscene stop skipped")
        end
    end
    warn("[CELESTIAL] All cutscenes disabled successfully!")
end

local function DisableSkip()
    if cutsceneController and originalPlay and originalStop then
        cutsceneController.Play = originalPlay
        cutsceneController.Stop = originalStop
        warn("[CELESTIAL] Cutscenes restored to default")
    end
end

Bp:AddToggle({
    Title = "Auto Skip Cutscene",
    Default = true,
    Callback = function(state)
        st.skipCutscene = state
        if state then
            EnableSkip()
        else
            DisableSkip()
        end
    end,
})

do
    Bp:AddSubSection("Hide Identifier")

    local player = game:GetService("Players").LocalPlayer
    local running = false
    local customHeaderText, customLevelText
    local defaultTitle, defaultHeader, defaultLevel, defaultGradient, defaultRotation

    local function waitForOverhead()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return nil end
        repeat task.wait() until hrp:FindFirstChild("Overhead")
        return hrp:WaitForChild("Overhead", 5)
    end

    local function setupOverhead()
        local overhead = waitForOverhead()
        if not overhead then
            warn("[HideIdent] Overhead not found.")
            return
        end

        local titleLabel = overhead:FindFirstChild("TitleContainer") and overhead.TitleContainer:FindFirstChild("Label")
        local header = overhead:FindFirstChild("Content") and overhead.Content:FindFirstChild("Header")
        local levelLabel = overhead:FindFirstChild("LevelContainer") and overhead.LevelContainer:FindFirstChild("Label")
        local gradient = titleLabel and titleLabel:FindFirstChildOfClass("UIGradient")

        if not (titleLabel and header and levelLabel) then
            warn("[HideIdent] Missing UI components in Overhead.")
            return
        end
        if not gradient then
            gradient = Instance.new("UIGradient", titleLabel)
        end

        _G.hideident = {
            overhead = overhead,
            titleLabel = titleLabel,
            gradient = gradient,
            header = header,
            levelLabel = levelLabel,
        }

        defaultTitle = titleLabel.Text
        defaultHeader = header.Text
        defaultLevel = levelLabel.Text
        defaultGradient = gradient.Color
        defaultRotation = gradient.Rotation

        customHeaderText = customHeaderText or defaultHeader
        customLevelText = customLevelText or defaultLevel
    end

    local function applyCustom()
        local h = _G.hideident
        if not h or not h.overhead or not h.titleLabel then return end

        h.overhead.TitleContainer.Visible = true
        h.titleLabel.Text = "Seraphin"
        h.gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 85, 255)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(145, 186, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(136, 243, 255))
        })
        h.gradient.Rotation = 0
        h.header.Text = (customHeaderText ~= "" and customHeaderText) or "Seraph Rawr"
        h.levelLabel.Text = (customLevelText ~= "" and customLevelText) or "???"
    end

    setupOverhead()

    player.CharacterAdded:Connect(function()
        task.wait(2)
        setupOverhead()
        if running then
            task.spawn(function()
                while running do
                    applyCustom()
                    task.wait(1)
                end
            end)
        end
    end)

    Bp:AddInput({
        Title = "Input Name",
        Default = defaultHeader or "",
        Callback = function(v)
            customHeaderText = v
        end
    })

    Bp:AddInput({
        Title = "Input Level",
        Default = defaultLevel or "",
        Callback = function(v)
            customLevelText = v
        end
    })

    Bp:AddToggle({
        Title = "Start Hide",
        Default = false,
        Callback = function(state)
            running = state
            if state then
                task.spawn(function()
                    while running do
                        local ok, err = pcall(applyCustom)
                        if not ok then warn("[HideIdent] Error:", err) end
                        task.wait(1)
                    end
                end)
            else
                local h = _G.hideident
                if not h or not h.overhead then return end
                h.overhead.TitleContainer.Visible = false
                h.titleLabel.Text = defaultTitle
                h.header.Text = defaultHeader
                h.levelLabel.Text = defaultLevel
                h.gradient.Color = defaultGradient
                h.gradient.Rotation = defaultRotation
            end
        end
    })
end

Bp:AddSubSection("Boost Player")

Bp:AddToggle({
    Title = "Disable Notification",
    Default = false,
    Callback = function(state)
        st.disableNotifs = state
        if state then
            disconnectNotifs()
        else
            reconnectNotifs()
        end
    end
})

Bp:AddToggle({
    Title = "Disable Fish Notification",
    Default = false,
    Callback = function(v)
        local gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local notif = gui:FindFirstChild("Small Notification")
        if notif and notif:FindFirstChild("Display") then
            notif.Display.Visible = not v
        end
    end
})

Bp:AddToggle({
    Title = "Disable Char Effect",
    Default = false,
    Callback = function(state)
        if state then
            st.dummyCons = {}
            for _, ev in ipairs({
                api.Events.REPlayFishEffect,
                api.Events.RETextEffect
            }) do
                for _, conn in ipairs(getconnections(ev.OnClientEvent)) do
                    conn:Disconnect()
                end
                local con = ev.OnClientEvent:Connect(function() end)
                table.insert(st.dummyCons, con)
            end
        else
            if st.dummyCons then
                for _, c in ipairs(st.dummyCons) do
                    c:Disconnect()
                end
            end
            st.dummyCons = {}
        end
    end
})

Bp:AddToggle({
    Title = "Delete Fishing Effects",
    Default = false,
    Callback = function(state)
        st.DelEffects = state
        if state then
            task.spawn(function()
                while st.DelEffects do
                    local cosmetic = workspace:FindFirstChild("CosmeticFolder")
                    if cosmetic then
                        cosmetic:Destroy()
                    end
                    task.wait(60)
                end
            end)
        end
    end
})

Bp:AddToggle({
    Title = "Hide Rod On Hand",
    Default = false,
    Callback = function(state)
        st.IrRod = state
        if state then
            task.spawn(function()
                while st.IrRod do
                    for _, char in ipairs(workspace.Characters:GetChildren()) do
                        local toolFolder = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")
                        if toolFolder then
                            toolFolder:Destroy()
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

X1 = Tabs.Web:AddSection("Webhook")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local httpRequest = syn and syn.request or http and http.request or http_request or (fluxus and fluxus.request) or
    request
if not httpRequest then return end

local ItemUtility, Replion, DataService
local fishDB = {}
local rarityList = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET" }
local tierToRarity = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"
}
local knownFishUUIDs = {}

pcall(function()
    ItemUtility = require(ReplicatedStorage.Shared.ItemUtility)
    Replion = require(ReplicatedStorage.Packages.Replion)
    DataService = Replion.Client:WaitReplion("Data")
end)

function buildFishDatabase()
    local RS = game:GetService("ReplicatedStorage")
    local itemsContainer = RS:WaitForChild("Items")
    if not itemsContainer then return end

    for _, itemModule in ipairs(itemsContainer:GetChildren()) do
        local success, itemData = pcall(require, itemModule)
        if success and type(itemData) == "table" and itemData.Data and itemData.Data.Type == "Fish" then
            local data = itemData.Data
            if data.Id and data.Name then
                fishDB[data.Id] = {
                    Name = data.Name,
                    Tier = data.Tier,
                    Icon = data.Icon,
                    SellPrice = itemData.SellPrice
                }
            end
        end
    end
end

function getInventoryFish()
    if not (DataService and ItemUtility) then return {} end
    local inventoryItems = DataService:GetExpect({ "Inventory", "Items" })
    local fishes = {}
    for _, v in pairs(inventoryItems) do
        local itemData = ItemUtility.GetItemDataFromItemType("Items", v.Id)
        if itemData and itemData.Data.Type == "Fish" then
            table.insert(fishes, { Id = v.Id, UUID = v.UUID, Metadata = v.Metadata })
        end
    end
    return fishes
end

function getPlayerCoins()
    if not DataService then return "N/A" end
    local success, coins = pcall(function() return DataService:Get("Coins") end)
    if success and coins then return string.format("%d", coins):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") end
    return "N/A"
end

function getThumbnailURL(assetString)
    local assetId = assetString:match("rbxassetid://(%d+)")
    if not assetId then return nil end
    local api = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%s&type=Asset&size=420x420&format=Png",
        assetId)
    local success, response = pcall(function() return HttpService:JSONDecode(game:HttpGet(api)) end)
    return success and response and response.data and response.data[1] and response.data[1].imageUrl
end

function sendTestWebhook()
    if not httpRequest or not _G.WebhookURL or not _G.WebhookURL:match("discord.com/api/webhooks") then
        WindUI:Notify({ Title = "Error", Content = "Webhook URL Empty" })
        return
    end

    local payload = {
        username = "Seraphin Webhook",
        avatar_url = "https://i.imgur.com/IvNLsLU.png",
        embeds = { {
            title = "Test Webhook Connected",
            description = "Webhook connection successful!",
            color = 0x00FF00
        } }
    }

    pcall(function()
        httpRequest({
            Url = _G.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

function sendNewFishWebhook(newlyCaughtFish)
    if not httpRequest or not _G.WebhookURL or not _G.WebhookURL:match("discord.com/api/webhooks") then return end

    local newFishDetails = fishDB[newlyCaughtFish.Id]
    if not newFishDetails then return end

    local newFishRarity = tierToRarity[newFishDetails.Tier] or "Unknown"
    if #_G.WebhookRarities > 0 and not table.find(_G.WebhookRarities, newFishRarity) then return end

    local fishWeight           = (newlyCaughtFish.Metadata and newlyCaughtFish.Metadata.Weight and string.format("%.2f Kg", newlyCaughtFish.Metadata.Weight)) or
    "N/A"
    local mutation             = (newlyCaughtFish.Metadata and newlyCaughtFish.Metadata.VariantId and tostring(newlyCaughtFish.Metadata.VariantId)) or
    "None"
    local sellPrice            = (newFishDetails.SellPrice and ("$" .. string.format("%d", newFishDetails.SellPrice):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "") .. " Coins")) or
    "N/A"
    local currentCoins         = getPlayerCoins()

    local totalFishInInventory = #getInventoryFish()
    local backpackInfo         = string.format("%d/5000", totalFishInInventory)

    local playerName           = game.Players.LocalPlayer.Name

    local payload              = {
        content = nil,
        embeds = { {
            title = "Seraphin Fish caught!",
            description = string.format("Congrats! **%s** You obtained new **%s** here for full detail fish :",
                playerName, newFishRarity),
            url = "https://discord.gg/getseraphin",
            color = 10027263,
            fields = {
                { name = "Name Fish :",        value = "```\n" .. newFishDetails.Name .. "```" },
                { name = "Rarity :",           value = "```" .. newFishRarity .. "```" },
                { name = "Weight :",           value = "```" .. fishWeight .. "```" },
                { name = "Mutation :",         value = "```" .. mutation .. "```" },
                { name = "Sell Price :",       value = "```" .. sellPrice .. "```" },
                { name = "Backpack Counter :", value = "```" .. backpackInfo .. "```" },
                { name = "Current Coin :",     value = "```" .. currentCoins .. "```" },
            },
            footer = {
                text = "Seraphin Webhook",
                icon_url = "https://i.imgur.com/IvNLsLU.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
            thumbnail = {
                url = getThumbnailURL(newFishDetails.Icon)
            }
        } },
        username = "Seraphin Webhook",
        avatar_url = "https://i.imgur.com/IvNLsLU.png",
        attachments = {}
    }

    pcall(function()
        httpRequest({
            Url = _G.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

X1:AddInput({
    Title = "URL Webhook",
    Placeholder = "Paste your Discord Webhook URL here",
    Value = _G.WebhookURL or "",
    Callback = function(text)
        _G.WebhookURL = text
    end
})

X1:AddDropdown({
    Title = "Rarity Filter",
    Options = rarityList,
    Multi = true,
    Value = _G.WebhookRarities or {},
    Callback = function(selected_options)
        _G.WebhookRarities = selected_options
    end
})

X1:AddToggle({
    Title = "Send Webhook",
    Value = _G.DetectNewFishActive or false,
    Callback = function(state)
        _G.DetectNewFishActive = state
    end
})

X1:AddButton({
    Title = "Test Webhook",
    Callback = sendTestWebhook
})

buildFishDatabase()

spawn(LPH_NO_VIRTUALIZE(function()
    local initialFishList = getInventoryFish()
    for _, fish in ipairs(initialFishList) do
        if fish and fish.UUID then
            knownFishUUIDs[fish.UUID] = true
        end
    end
end))

spawn(LPH_NO_VIRTUALIZE(function()
    while wait(0.1) do
        if _G.DetectNewFishActive then
            local currentFishList = getInventoryFish()
            for _, fish in ipairs(currentFishList) do
                if fish and fish.UUID and not knownFishUUIDs[fish.UUID] then
                    knownFishUUIDs[fish.UUID] = true
                    sendNewFishWebhook(fish)
                end
            end
        end
        wait(3)
    end
end))

NU = Tabs.Auto:AddSection("Auto Enchant")

local enchantNames = {
    "Big Hunter 1", "Cursed 1", "Empowered 1", "Glistening 1",
    "Gold Digger 1", "Leprechaun 1", "Leprechaun 2",
    "Mutation Hunter 1", "Mutation Hunter 2", "Prismatic 1",
    "Reeler 1", "Stargazer 1", "Stormhunter 1", "XPerienced 1"
}

local enchantIdMap = {
    ["Big Hunter 1"] = 3,
    ["Cursed 1"] = 12,
    ["Empowered 1"] = 9,
    ["Glistening 1"] = 1,
    ["Gold Digger 1"] = 4,
    ["Leprechaun 1"] = 5,
    ["Leprechaun 2"] = 6,
    ["Mutation Hunter 1"] = 7,
    ["Mutation Hunter 2"] = 14,
    ["Prismatic 1"] = 13,
    ["Reeler 1"] = 2,
    ["Stargazer 1"] = 8,
    ["Stormhunter 1"] = 11,
    ["XPerienced 1"] = 10
}

local equipItemRemote = api.Events.REEquipItem
local equipToolRemote = api.Events.REEquip
local activateAltarRemote = api.Events.REAltar

local Data = repl.Data

local function countDisplayImageButtons()
    local ok, backpackGui = pcall(function()
        return player.PlayerGui.Backpack
    end)
    if not ok or not backpackGui then return 0 end
    local display = backpackGui:FindFirstChild("Display")
    if not display then return 0 end
    local count = 0
    for _, child in ipairs(display:GetChildren()) do
        if child:IsA("ImageButton") then
            count += 1
        end
    end
    return count
end

local function findEnchantStones()
    if not Data then return {} end
    local inv = Data:GetExpect({ "Inventory", "Items" })
    if not inv then return {} end
    local stones = {}
    for _, item in pairs(inv) do
        local def = mods.ItemUtility:GetItemData(item.Id)
        if def and def.Data and def.Data.Type == "Enchant Stones" then
            table.insert(stones, { UUID = item.UUID, Quantity = item.Quantity or 1 })
        end
    end
    return stones
end

local function getEquippedRodName()
    local equipped = Data:Get("EquippedItems") or {}
    local rods = Data:GetExpect({ "Inventory", "Fishing Rods" }) or {}
    for _, uuid in pairs(equipped) do
        for _, rod in ipairs(rods) do
            if rod.UUID == uuid then
                local d = mods.ItemUtility:GetItemData(rod.Id)
                if d and d.Data and d.Data.Name then
                    return d.Data.Name
                elseif rod.ItemName then
                    return rod.ItemName
                end
            end
        end
    end
    return "None"
end

local function getCurrentRodEnchant()
    local equipped = Data:Get("EquippedItems") or {}
    local rods = Data:GetExpect({ "Inventory", "Fishing Rods" }) or {}
    for _, uuid in pairs(equipped) do
        for _, rod in ipairs(rods) do
            if rod.UUID == uuid and rod.Metadata and rod.Metadata.EnchantId then
                return rod.Metadata.EnchantId
            end
        end
    end
    return nil
end

local Paragraph = NU:AddParagraph({
    Title = "Enchant Panel",
    Content = "Loading...",
})

spawn(LPH_NO_VIRTUALIZE(function()
    while task.wait(1) do
        local stones = findEnchantStones()
        local total = 0
        for _, s in ipairs(stones) do total += s.Quantity end
        local rodName = getEquippedRodName()
        local currentEnchantId = getCurrentRodEnchant()
        local currentEnchantName = "None"
        for name, id in pairs(enchantIdMap) do
            if id == currentEnchantId then
                currentEnchantName = name
                break
            end
        end
        Paragraph:SetContent(
            "Rod Active <font color='rgb(0,191,255)'>= " .. rodName .. "</font>\n" ..
            "Enchant Now <font color='rgb(200,0,255)'>= " .. currentEnchantName .. "</font>\n" ..
            "Enchant Stone Left <font color='rgb(255,215,0)'>= " .. total .. "</font>"
        )
    end
end))

NU:AddButton({
    Title = "Teleport to Altar",
    Callback = function()
        local target = CFrame.new(3234.83667, -1302.85486, 1398.39087, 0.464485794, -1.12043161e-07, -0.885580599,
            6.74793981e-08, 1, -9.11265872e-08, 0.885580599, -1.74314394e-08, 0.464485794)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char:PivotTo(target)
        end
    end
})

NU:AddButton({
    Title = "Teleport to Second Altar",
    Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char:PivotTo(CFrame.new(1481, 128, -592))
        end
    end
})

local TargetEnchantDropdown = NU:AddDropdown({
    Title = "Target Enchant",
    Options = enchantNames,
    Default = _G.TargetEnchant or enchantNames[1],
    Callback = function(selected)
        _G.TargetEnchant = selected
    end
})

NU:AddToggle({
    Title = "Auto Enchant",
    Value = _G.AutoEnchant,
    Callback = function(state)
        _G.AutoEnchant = state
    end
})

spawn(LPH_NO_VIRTUALIZE(function()
    while task.wait(0.5) do
        if _G.AutoEnchant then
            local currentEnchantId = getCurrentRodEnchant()
            local targetEnchantId = enchantIdMap[_G.TargetEnchant]
            if not targetEnchantId then
                _G.AutoEnchant = false
            elseif currentEnchantId == targetEnchantId then
                _G.AutoEnchant = false
            else
                local stones = findEnchantStones()
                if #stones > 0 then
                    local uuid = stones[1].UUID
                    equipItemRemote:FireServer(uuid, "EnchantStones")
                    task.wait(0.3)

                    local slot = math.max(countDisplayImageButtons() - 2, 1)
                    equipToolRemote:FireServer(slot)
                    task.wait(0.4)

                    activateAltarRemote:FireServer()
                    task.wait(5)
                end
            end
        end
    end
end))

local Save = Tabs.Auto:AddSection("Save position")
function SavePosition(cf)
    local data = { cf:GetComponents() }
    writefile(PositionFile, svc.HttpService:JSONEncode(data))
end

function LoadPosition()
    if isfile(PositionFile) then
        local success, data = pcall(function()
            return svc.HttpService:JSONDecode(readfile(PositionFile))
        end)
        if success and typeof(data) == "table" then
            return CFrame.new(unpack(data))
        end
    end
    return nil
end

function TeleportLastPos(char)
    task.spawn(function()
        local hrp = char:WaitForChild("HumanoidRootPart")
        local last = LoadPosition()

        if last then
            task.wait(2)
            hrp.CFrame = last
            notify("Teleported to your last position...")
        end
    end)
end

player.CharacterAdded:Connect(TeleportLastPos)
if player.Character then
    TeleportLastPos(player.Character)
end
Save:AddButton({
    Title = "Save Position",
    Callback = function()
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            SavePosition(hrp.CFrame)
            notify("Position saved successfully!")
        end
    end,
    SubTitle = "Reset Position",
    SubCallback = function()
        if isfile(PositionFile) then
            delfile(PositionFile)
        end
        notify("Last position has been reset.")
    end
})

XAdm = Tabs.Auto:AddSection("Event Features")
countdownParagraph = XAdm:AddParagraph({
    Title = "Ancient Lochness Monster Countdown",
    Content = "<font color='#ff4d4d'><b>waiting for ... for joined event!</b></font>"
})
st.FarmPosition = st.FarmPosition or nil
st.autoCountdownUpdate = false
XAdm:AddToggle({
    Title = "Auto Admin Event",
    Default = false,
    Callback = function(state)
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        st.autoCountdownUpdate = state

        local function getLabel()
            local ok, lbl = pcall(function()
                return workspace["!!! MENU RINGS"]["Event Tracker"].Main.Gui.Content.Items.Countdown.Label
            end)
            return ok and lbl or nil
        end

        local function tpEventSpot(hrp)
            hrp.CFrame = CFrame.new(Vector3.new(6063, -586, 4715))
        end

        local function tpBackToFarm(hrp)
            if st.FarmPosition then
                hrp.CFrame = st.FarmPosition
                countdownParagraph:SetContent("<font color='#00ff99'><b>✅ Returned to saved farm position!</b></font>")
            else
                countdownParagraph:SetContent("<font color='#ff4d4d'><b>❌ No saved farm position found!</b></font>")
            end
        end

        if state then
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                st.FarmPosition = hrp.CFrame
                countdownParagraph:SetContent(string.format(
                    "<font color='#00ff99'><b>Farm position saved!</b></font>"
                ))
            end

            local labelPath = getLabel()
            if not labelPath then
                countdownParagraph:SetContent("<font color='#ff4d4d'><b>Label not found!</b></font>")
                return
            end

            task.spawn(function()
                local inEvent = false
                while st.autoCountdownUpdate do
                    task.wait(1)

                    local text = ""
                    pcall(function() text = labelPath.Text or "" end)

                    if text == "" then
                        countdownParagraph:SetContent("<font color='#ff4d4d'><b>Waiting for countdown...</b></font>")
                    else
                        countdownParagraph:SetContent(string.format(
                            "<font color='#4de3ff'><b>Timer: %s</b></font>", text
                        ))

                        local char = player.Character or player.CharacterAdded:Wait()
                        local hrp = char:WaitForChild("HumanoidRootPart", 5)
                        if not hrp then
                            countdownParagraph:SetContent(
                                "<font color='#ff4d4d'><b>⚠️ HRP not found, retrying...</b></font>")
                        else
                            local h, m, s = text:match("(%d+)H%s*(%d+)M%s*(%d+)S")
                            h, m, s = tonumber(h), tonumber(m), tonumber(s)

                            if h == 3 and m == 59 and s == 59 and not inEvent then
                                countdownParagraph:SetContent(
                                    "<font color='#00ff99'><b>Event started! Teleporting...</b></font>")
                                tpEventSpot(hrp)
                                inEvent = true
                            elseif h == 3 and m == 49 and s == 59 and inEvent then
                                countdownParagraph:SetContent(
                                    "<font color='#ffaa00'><b>Event ended! Returning...</b></font>")
                                tpBackToFarm(hrp)
                                inEvent = false
                            end
                        end
                    end

                    if not labelPath or not labelPath.Parent then
                        labelPath = getLabel()
                        if not labelPath then
                            countdownParagraph:SetContent(
                                "<font color='#ff4d4d'><b>Label lost. Reconnecting...</b></font>")
                            task.wait(2)
                            labelPath = getLabel()
                        end
                    end
                end
            end)
        else
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                tpBackToFarm(hrp)
            end
            countdownParagraph:SetContent("<font color='#ff4d4d'><b>Auto Admin Event disabled.</b></font>")
        end
    end
})

local TT = Tabs.Auto:AddSection("Totem")

TotemPanel = TT:AddParagraph({
    Title = "Nearest Totem Detector",
    Content = "Scanning Totems..."
})

function GetTT()
    local playerPos = st.char and st.char:FindFirstChild("HumanoidRootPart") and st.char.HumanoidRootPart.Position or
        Vector3.zero
    local foundTotems = {}
    for _, placed in pairs(workspace.Totems:GetChildren()) do
        if placed:IsA("Model") then
            local handle = placed:FindFirstChild("Handle")
            local overhead = handle and handle:FindFirstChild("Overhead")
            local content = overhead and overhead:FindFirstChild("Content")
            local header = content and content:FindFirstChild("Header")
            local timerLabel = content and content:FindFirstChild("TimerLabel")
            local pos = placed:GetPivot().Position
            local dist = (playerPos - pos).Magnitude
            local timeLeft = timerLabel and timerLabel.Text or "??"
            local TotemName = header and header.Text or "??"
            table.insert(foundTotems, {
                Name = TotemName,
                Distance = dist,
                TimeLeft = timeLeft
            })
        end
    end
    return foundTotems
end

function UpdTT()
    local found = GetTT()
    if #found == 0 then
        TotemPanel:SetContent("No active totems detected.")
        return
    end
    local lines = {}
    for _, t in ipairs(found) do
        table.insert(lines, string.format("%s • %.1f studs • %s", t.Name, t.Distance, t.TimeLeft))
    end
    TotemPanel:SetContent(table.concat(lines, "\n"))
end

task.spawn(function()
    while task.wait(1) do
        pcall(UpdTT)
    end
end)

function GetTTUUID(selectedName)
    if not Data then
        Data = mods.Replion.Client:WaitReplion("Data")
        if not Data then
            return nil
        end
    end

    if not Totems then
        Totems = require(game:GetService("ReplicatedStorage"):WaitForChild("Totems"))
        if not Totems then
            return nil
        end
    end

    local invTotems = Data:GetExpect({ "Inventory", "Totems" }) or {}
    for _, item in ipairs(invTotems) do
        local name = "Unknown Totem"
        if typeof(Totems) == "table" then
            for _, def in pairs(Totems) do
                if def.Data and def.Data.Id == item.Id then
                    name = def.Data.Name
                    break
                end
            end
        end
        if name == selectedName then
            return item.UUID, name
        end
    end
    return nil
end

local function SafeShowRealPanel()
    if RealTotemPanel and RealTotemPanel.Show then
        RealTotemPanel:Show()
    end
end

local function TrySpawnTotem(uuid)
    if not uuid then return end
    local ok, err = pcall(function()
        api.Events.Totem:FireServer(uuid)
    end)
    if not ok then
        warn("[Chloe X] Totem spawn failed:", tostring(err))
    end
end

TT:AddButton({
    Title = "Teleport To Nearest Totem",
    Callback = function()
        local hrp = st.char and st.char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local list = GetTT()
        if #list == 0 then return end
        table.sort(list, function(a, b) return a.Distance < b.Distance end)
        local nearest = list[1]
        for _, t in pairs(workspace.Totems:GetChildren()) do
            if t:IsA("Model") then
                local pos = t:GetPivot().Position
                if math.abs((pos - hrp.Position).Magnitude - nearest.Distance) < 1 then
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                    break
                end
            end
        end
    end
})

TotemsFolder = svc.RS:WaitForChild("Totems")
st.Totems = st.Totems or {}
st.TotemDisplayName = st.TotemDisplayName or {}
for _, moduleTotem in ipairs(TotemsFolder:GetChildren()) do
    if moduleTotem:IsA("ModuleScript") then
        local ok, data = pcall(require, moduleTotem)
        if ok and typeof(data) == "table" and data.Data then
            local name = data.Data.Name or "Unknown"
            local id = data.Data.Id or "Unknown"
            local entry = { Name = name, Id = id }
            st.Totems[id] = entry
            st.Totems[name] = entry
            table.insert(st.TotemDisplayName, name)
        end
    end
end

selectedTotem = nil
TotemDropdown = TT:AddDropdown({
    Title = "Select Totem to Auto Place",
    Options = st.TotemDisplayName or { "No Totems Found" },
    Default = st.TotemDisplayName and st.TotemDisplayName[1] or "No Totems Found",
    Callback = function(opt)
        selectedTotem = opt
    end
})

TT:AddToggle({
    Title = "Auto Place Totem (Beta)",
    Content = "Place Totem every 60 minutes automatically.",
    Default = false,
    Callback = function(state)
        TotemActive = state
        if state then
            if not selectedTotem then
                TotemActive = false
                return
            end

            local uuid, name = GetTTUUID(selectedTotem)
            if not uuid then
                TotemActive = false
                return
            end

            task.spawn(function()
                local notifShown = 0
                while TotemActive do
                    TrySpawnTotem(uuid)
                    if notifShown < 3 then
                        notifShown += 1
                    elseif notifShown == 3 then
                        notifShown += 1
                        task.wait(1)
                        task.wait(0.5)
                        SafeShowRealPanel()
                    end
                    for i = 3600, 1, -1 do
                        if not TotemActive then break end
                        task.wait(1)
                    end
                    uuid, name = GetTTUUID(selectedTotem)
                    if not uuid then
                        TotemActive = false
                        break
                    end
                end
            end)
        else
            SafeShowRealPanel()
        end
    end
})


local totemList = {
    ["Luck Totem"] = 1,
    ["Mutation Totem"] = 2,
    ["Shiny Totem"] = 3
}

TT:AddDropdown({
    Title = "Choose Totem",
    Options = {"Luck Totem", "Mutation Totem", "Shiny Totem"},
    Value = "",
    Callback = function(option)
        _G.SelectedTotemId = totemList[option]
        SaveConfig()
    end
})

TT:AddToggle({
    Title = "Auto Spawn Totem",
    Value = _G.AutoSpawnTotem,
    Callback = function(value)
        _G.AutoSpawnTotem = value
        SaveConfig()
    end
})

TT:AddToggle({
    Title = "Auto Spawn 9 Totem",
    Value = _G.AutoSpawn9Totem,
    Callback = function(value)
        _G.AutoSpawn9Totem = value
        SaveConfig()
    end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local net = ReplicatedStorage.Packages["_Index"]["sleitnick_net@0.2.0"].net

local TOTEM_SCALE = 1.01
local baseOffsets = {
    Vector3.new(-48.4, -1.5, 45.6),
    Vector3.new(51.2, -1.5, 37.4),
    Vector3.new(-9.2, -0.8, -47.6),
}
local layerOffsetY = 101

local function enableFly()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    _G.nowe = true
    _G.tpwalking = false
    local speeds = 5
    char.Animate.Disabled = true
    
    for _, v in next, hum:GetPlayingAnimationTracks() do
        v:AdjustSpeed(0)
    end
    
    for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
        hum:SetStateEnabled(state, false)
    end
    
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    
    for i = 1, speeds do
        task.spawn(function()
            local hb = game:GetService("RunService").Heartbeat
            while _G.nowe and hb:Wait() and char and hum and hum.Parent do
                if hum.MoveDirection.Magnitude > 0 then
                    char:TranslateBy(hum.MoveDirection)
                end
            end
        end)
    end
    
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if root then
        if _G.FlyBV then _G.FlyBV:Destroy() end
        local bv = Instance.new("BodyVelocity", root)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        _G.FlyBV = bv
        
        task.spawn(function()
            while _G.nowe and task.wait() and root and root.Parent do
               bv.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end

local function disableFly()
    _G.nowe = false
    if _G.FlyBV then
        _G.FlyBV:Destroy()
        _G.FlyBV = nil
    end
    
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            char.Animate.Disabled = false
            
            for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                hum:SetStateEnabled(state, true)
            end
            
            for _, v in next, hum:GetPlayingAnimationTracks() do
                v:AdjustSpeed(1)
            end
        end
    end
end

local noclipEnabled = false
local noclipConnection

local function enableNoclip()
    if noclipEnabled then return end
    
    local char = player.Character
    if not char then return end
    
    noclipEnabled = true
    
    noclipConnection = RunService.Stepped:Connect(function()
        if not noclipEnabled or not char then 
            noclipConnection:Disconnect()
            return
        end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    noclipEnabled = false
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

local function build9PositionsFromCenter(centerCF)
    local basePos = centerCF.Position
    local tpPositions = {}

    for i = 1, 3 do
        local o = baseOffsets[i]
        local pos = Vector3.new(
            basePos.X + o.X * TOTEM_SCALE,
            basePos.Y + o.Y,
            basePos.Z + o.Z * TOTEM_SCALE
        )
        tpPositions[#tpPositions + 1] = CFrame.new(pos)
    end

    for i = 1, 3 do
        local p = tpPositions[i].Position
        tpPositions[#tpPositions + 1] = CFrame.new(p.X, p.Y + layerOffsetY, p.Z)
    end

    for i = 1, 3 do
        local p = tpPositions[i].Position
        tpPositions[#tpPositions + 1] = CFrame.new(p.X, p.Y - layerOffsetY, p.Z)
    end
    
    return tpPositions
end

local Client = require(game:GetService("ReplicatedStorage").Packages.Replion).Client
local dataStore = Client:WaitReplion("Data")

local function spawnTotemAtCurrentPosition()
    if not _G.AutoSpawn9Totem or not _G.SelectedTotemId then 
        print("a")
        return false 
    end
    
    pcall(function()
        local inventory = dataStore:Get("Inventory.Totems")
        print("b", inventory)
        
        if not inventory then 
            print("c")
            return 
        end
        
        print("d")
        for key, itemData in pairs(inventory) do
            print("e", key, "f", itemData)
            if type(itemData) == "table" then
                print("g", itemData.Id, "h", itemData.UUID, "i", typeof(itemData.Id))
            end
        end
        
        for key, itemData in pairs(inventory) do
            if type(itemData) == "table" and itemData.Id == _G.SelectedTotemId then
                local args = {itemData.UUID}
                net["RE/SpawnTotem"]:FireServer(unpack(args))
                return true
            end
        end
    end)
    return false
end

local isRunning9Totem = false

function runAutoSpawnAt9Points()
    if isRunning9Totem then
        return
    end
    
    isRunning9Totem = true
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (char and hrp) then 
        isRunning9Totem = false
        return 
    end

    local startingCF = hrp.CFrame

    enableFly()
    enableNoclip()

    local posList = build9PositionsFromCenter(startingCF)

    for i, cf in ipairs(posList) do
        if not _G.AutoSpawn9Totem then
            break
        end
        
        hrp.CFrame = cf
        wait(1)

        local spawnSuccess = spawnTotemAtCurrentPosition()
        
        if i < #posList then
            wait(2)
        end
    end

    wait(1)
    hrp.CFrame = startingCF

    disableFly()
    disableNoclip()
    isRunning9Totem = false
end

spawn(function()
    while wait(0.2) do
        if _G.AutoSpawn9Totem and _G.SelectedTotemId then
            runAutoSpawnAt9Points()
            wait(1800)
        end
    end
end)

spawn(function()
    while wait(0.2) do
        if _G.AutoSpawnTotem and _G.SelectedTotemId then
            pcall(function()
                local inventory = dataStore:Get("Inventory.Totems")
                if not inventory then 
                    return 
                end
                
                local foundTotem = false
                for key, itemData in pairs(inventory) do
                    if type(itemData) == "table" and itemData.Id == _G.SelectedTotemId then
                        local args = {itemData.UUID}
                        net["RE/SpawnTotem"]:FireServer(unpack(args))
                        foundTotem = true
                        break
                    end
                end
                
                if foundTotem then
                    wait(1800)
                else
                    print("b")
                    wait(5)
                end
            end)
        end
    end
end)

--// ANTI IDLE
local GC = getconnections or get_signal_cons
if GC then
    for _, v in pairs(GC(player.Idled)) do
        if v.Disable then
            v:Disable()
        elseif v.Disconnect then
            v:Disconnect()
        end
    end
else
    local VirtualUser = cloneref and cloneref(game:GetService("VirtualUser")) or game:GetService("VirtualUser")
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

--BoosterNotip
task.defer(function()
	task.wait(1)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local notifModule = ReplicatedStorage.Controllers:FindFirstChild("TextNotificationController")
	local ok, ctrl = pcall(require, notifModule)
	local oldTween = ctrl.Tween
	ctrl.Tween = function(self, tile, duration, opts, ...)
        if _G.FBlatant then
		    duration = 6.6
        else
            duration = 3
        end
		if opts and opts.destroyTile then
			opts.destroyTile = true
		end
		return oldTween(self, tile, duration, opts, ...)
	end
end)

--bypass cooldown for stable
local blockedFunctions = {
	"OnCooldown",
    -- "Run",
}

function patchFishingController()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local fishingModule = ReplicatedStorage.Controllers:FindFirstChild("FishingController")
	if not fishingModule then
		return
	end

	local ok, FC = pcall(require, fishingModule)
	if not ok or type(FC) ~= "table" then
		return
	end

	for key, fn in pairs(FC) do
		if type(fn) == "function" and table.find(blockedFunctions, key) then
			FC[key] = function(...)
				return false
			end
		end
	end

end
patchFishingController()
