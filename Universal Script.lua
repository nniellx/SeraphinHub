-- Universal Script Loader
local games = {
    [119048529960596] = "https://raw.githubusercontent.com/nniellx/SeraphinHub/main/RestaurantTycoon3.lua",
    -- tambahin game lain kalau perlu
}

local id = game.PlaceId
local url = games[id] or "https://raw.githubusercontent.com/nniellx/SeraphinHub/main/Universal%20Script.lua"
loadstring(game:HttpGet(url))()
