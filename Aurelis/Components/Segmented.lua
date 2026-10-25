--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Segmented = {}
function Segmented.new(owner, options)
    local self = Base.new(owner, options, "Segmented", 34)
    local values = table.clone(options.Values or { "Normal", "Performance", "Quality" })
    assert(#values > 0, "Segmented needs values")
    local track = Gui.new(
        self,
        "Frame",
        { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 },
        { BackgroundColor3 = "Background" },
        self.Control
    )
    Gui.corner(self, track, 8)
    Gui.stroke(self, track)
    local indicator = Gui.new(self, "Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1 / #values, -6, 1, -6),
        BackgroundTransparency = 0,
    }, { BackgroundColor3 = "SurfaceElevated" }, track)
    Gui.corner(self, indicator, 5)
    local buttons = {}
    for i, value in ipairs(values) do
        local button = Gui.new(self, "TextButton", {
            Position = UDim2.fromScale((i - 1) / #values, 0),
            Size = UDim2.fromScale(1 / #values, 1),
            Text = tostring(value),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 2,
        }, { TextColor3 = "TextSecondary" }, track)
        buttons[i] = button
        self.Maid:Give(button.Activated:Connect(function()
            if self:CanInteract() then
                self:SetValue(value)
            end
        end))
    end
    self:Value(options.Default or values[1], function(value)
        return table.find(values, value) and value or nil
    end, function(_, value)
        local index = table.find(values, value)
        self.App.Motion:Tween(indicator, { Position = UDim2.new((index - 1) / #values, 3, 0, 3) }, "Normal")
        for i, button in ipairs(buttons) do
            button.TextColor3 = i == index and self.Theme.Tokens.Accent or self.Theme.Tokens.TextSecondary
        end
    end)
    self.Maid:Give(self.Theme.Changed:Connect(function()
        self.Render(self, self:GetValue())
    end))
    return self
end
return Segmented
