--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local Slider = {}
function Slider.new(owner, options)
    local self = Base.new(owner, options, "Slider", 44)
    local minimum, maximum, increment = options.Min or 0, options.Max or 100, options.Increment or 1
    Math.round(minimum, minimum, maximum, increment)
    self.Field = Gui.new(self, "TextBox", {
        Size = UDim2.new(1, 0, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Right,
        ClearTextOnFocus = false,
    }, { TextColor3 = "TextSecondary" }, self.Control)
    local track = Gui.new(
        self,
        "TextButton",
        { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 20) },
        nil,
        self.Control
    )
    local rail = Gui.new(
        self,
        "Frame",
        { Position = UDim2.new(0, 0, 0.5, -2), Size = UDim2.new(1, 0, 0, 4), BackgroundTransparency = 0 },
        { BackgroundColor3 = "Border" },
        track
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
    local thumb = Gui.new(self, "Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 0,
    }, { BackgroundColor3 = "TextPrimary" }, rail)
    Gui.corner(self, thumb, 9)
    local bubble = Gui.label(self, self.Control, "", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromOffset(64, 22),
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 0,
        Visible = false,
        ZIndex = 5,
    }, "TextPrimary")
    self:Value(options.Default or minimum, function(value)
        if not Math.finite(value) then
            return nil
        end
        return Math.round(value, minimum, maximum, increment)
    end, function(_, value)
        self.Field.Text = tostring(value) .. (options.Suffix or "")
        local fraction = Math.fraction(value, minimum, maximum)
        fill.Size = UDim2.fromScale(fraction, 1)
        thumb.Position = UDim2.fromScale(fraction, 0.5)
        bubble.Text = tostring(value)
        bubble.Position = UDim2.new(fraction, 0, 0, 23)
    end)
    self.Maid:Give(track.InputBegan:Connect(function(input)
        if not self:CanInteract() then
            return
        end
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        bubble.Visible = true
        self.App.Input:Track(self, input, function(point)
            local fraction =
                math.clamp((point.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            self:SetValue(minimum + (maximum - minimum) * fraction)
        end, function()
            bubble.Visible = false
        end)
    end))
    self.Maid:Give(self.Field.Focused:Connect(function()
        if not self:CanInteract() then
            self.Field:ReleaseFocus()
            return
        end
        self.Field.Text = tostring(self:GetValue())
        self.FocusStroke.Transparency = 0.2
    end))
    self.Maid:Give(self.Field.FocusLost:Connect(function()
        if self:CanInteract() then
            self:SetValue(tonumber(self.Field.Text))
        end
        self.Render(self, self:GetValue())
        self.FocusStroke.Transparency = 1
    end))
    self.Maid:Give(self.App.Input:OnBegan(function(input)
        if game:GetService("GuiService").SelectedObject ~= self.Hit or not self:CanInteract() then
            return
        end
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right then
            self:SetValue(self:GetValue() + (input.KeyCode == Enum.KeyCode.Right and increment or -increment))
            return true
        end
    end))
    return self
end
return Slider
