--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local Progress = {}
function Progress.new(owner, options)
    local self = Base.new(owner, options, "Progress", 36)
    local label = Gui.label(
        self,
        self.Control,
        "",
        { Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Right },
        "TextSecondary"
    )
    local rail = Gui.new(
        self,
        "Frame",
        { Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 5), BackgroundTransparency = 0 },
        { BackgroundColor3 = "Border" },
        self.Control
    )
    Gui.corner(self, rail, 9)
    local fill = Gui.new(
        self,
        "Frame",
        { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 0 },
        { BackgroundColor3 = "Accent" },
        rail
    )
    Gui.corner(self, fill, 9)
    self:Value(options.Default or 0, function(value)
        if not Math.finite(value) then
            return nil
        end
        return math.clamp(value, 0, 1)
    end, function(_, value)
        label.Text = string.format("%d%%", value * 100 + 0.5)
        self.App.Motion:Tween(fill, { Size = UDim2.fromScale(value, 1) }, "Normal")
    end)
    return self
end
return Progress
