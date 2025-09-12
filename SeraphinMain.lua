-- Universal Script Loader
local games = {
    [119048529960596] = "https://raw.githubusercontent.com/nniellx/SeraphinHub/main/RestaurantTycoon3.lua",
}

local id = game.PlaceId
print("Detected PlaceId:", id)

local url = games[id] or "https://raw.githubusercontent.com/nniellx/SeraphinHub/main/MainHub.lua"
print("Loading script from:", url)

local success, err = pcall(function()
    loadstring(game:HttpGet(url))()
end)

if not success then
    warn("Error saat load script:", err)
end
