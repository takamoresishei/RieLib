--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Math = require(script.Parent.Parent.Utility.Math)
local Chart = {}
function Chart.new(owner, options)
    local self = Base.new(owner, options, "Chart", 72)
    self:Value(options.Values or {}, function(value)
        if type(value) ~= "table" or #value > 120 then
            return nil
        end
        local result = {}
        for _, number in ipairs(value) do
            if not Math.finite(number) then
                return nil
            end
            table.insert(result, number)
        end
        return result
    end, function(_, values)
        if self.Bars then
            self.Maid:Remove(self.Bars)
        end
        self.Bars = Cleanup.new()
        self.Maid:Give(self.Bars)
        local ctx = { App = self.App, Theme = self.Theme, Maid = self.Bars }
        if #values == 0 then
            self.Bars:Give(
                Gui.label(
                    ctx,
                    self.Control,
                    "No samples",
                    { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center },
                    "TextMuted"
                )
            )
            return
        end
        local maximum = 1
        for _, value in ipairs(values) do
            maximum = math.max(maximum, value)
        end
        for index, value in ipairs(values) do
            local fraction = math.clamp(value / maximum, 0, 1)
            local bar = Gui.new(ctx, "Frame", {
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.fromScale((index - 1) / #values, 1),
                Size = UDim2.new(1 / #values, -3, fraction, 0),
                BackgroundTransparency = 0.15,
            }, { BackgroundColor3 = "Accent" }, self.Control)
            self.Bars:Give(bar)
            Gui.corner(ctx, bar, 2)
        end
    end)
    return self
end
return Chart
