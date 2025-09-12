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
