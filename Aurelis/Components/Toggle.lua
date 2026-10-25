--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Toggle = {}
function Toggle.new(owner, options)
    local self = Base.new(owner, options, "Toggle", 32)
    self.Track = Gui.new(self, "TextButton", {
        Size = UDim2.fromOffset(42, 24),
        Position = UDim2.new(1, -44, 0.5, -12),
        BackgroundTransparency = 0,
    }, { BackgroundColor3 = "BorderStrong" }, self.Control)
    Gui.corner(self, self.Track, 99)
    local thumb = Gui.new(
        self,
        "Frame",
        { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundTransparency = 0 },
        { BackgroundColor3 = "TextPrimary" },
        self.Track
    )
    Gui.corner(self, thumb, 99)
    local check = Gui.label(
        self,
        thumb,
        "",
        { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, TextSize = 10 },
        "Background"
    )
    self:Value(options.Default == true, function(value)
        if type(value) == "boolean" then
            return value
        end
        return nil
    end, function(_, value)
        self.App.Motion:Tween(thumb, { Position = UDim2.fromOffset(value and 21 or 3, 3) }, "Normal")
        self.App.Motion:Tween(
            self.Track,
            { BackgroundColor3 = value and self.Theme.Tokens.Accent or self.Theme.Tokens.BorderStrong },
            "Normal"
        )
        check.Text = value and "✓" or ""
    end)
    local function flip()
        if self:CanInteract() then
            self:SetValue(not self:GetValue())
        end
    end
    self.Maid:Give(self.Track.Activated:Connect(flip))
    self.Maid:Give(self.Hit.Activated:Connect(flip))
    self.Maid:Give(self.Theme.Changed:Connect(function()
        self.Render(self, self:GetValue())
    end))
    return self
end
return Toggle
