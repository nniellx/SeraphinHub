local games = {
    [119048529960596] = "https://raw.githubusercontent.com/nniellx/SeraphinHub/main/RestaurantTycoon3.lua",
}

local id = game.PlaceId
local url = games[id] or "https://raw.githubusercontent.com/nniellx/SeraphinHub/main/MainHub.lua"
loadstring(game:HttpGet(url))()
