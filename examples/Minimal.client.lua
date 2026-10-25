local Aurelis = require(game:GetService("ReplicatedStorage"):WaitForChild("Aurelis"))
local Window = Aurelis:CreateWindow({ Title = "My workspace", Theme = "Eclipse", Blur = true })
local Player = Window:AddTab({ Title = "Player", Icon = "user" })
local Movement = Player:AddSection({ Title = "Movement", Collapsible = true })
Movement:AddToggle({
    Title = "Enabled",
    Flag = "movement.enabled",
    Default = false,
    Callback = function(value)
        print("Enabled", value)
    end,
})
Movement:AddSlider({
    Title = "Speed",
    Min = 0,
    Max = 100,
    Default = 16,
    Flag = "movement.speed",
    Callback = function(value)
        print("Speed", value)
    end,
})
