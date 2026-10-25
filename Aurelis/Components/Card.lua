--!nonstrict
local Section = require(script.Parent.Parent.Navigation.Section)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Card = {}
function Card.new(owner, options)
    local self = Section.new(owner, options)
    function self:AddMetric(metric)
        return self:AddLabel({
            Title = metric.Label or metric.Title,
            Value = metric.Value or "",
            Status = metric.Status,
            Icon = metric.Icon,
            Flag = metric.Flag,
        })
    end
    local skeleton = Gui.new(self, "Frame", {
        Name = "Skeleton",
        Position = UDim2.fromOffset(16, self.HeaderHeight + 8),
        Size = UDim2.new(1, -32, 1, -self.HeaderHeight - 16),
        Visible = false,
    }, nil, self.Root)
    for index = 1, 3 do
        local bar = Gui.new(self, "Frame", {
            Size = UDim2.new(index == 2 and 0.58 or 0.85, 0, 0, 12),
            Position = UDim2.fromOffset(0, (index - 1) * 26),
            BackgroundTransparency = 0.55,
        }, { BackgroundColor3 = "BorderStrong" }, skeleton)
        Gui.corner(self, bar, 4)
    end
    function self:SetLoading(loading)
        self.Loading = loading == true
        skeleton.Visible = self.Loading
        self.Content.Visible = not self.Loading
        return self
    end
    return self
end
return Card
