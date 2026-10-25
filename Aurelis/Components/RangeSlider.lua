--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local RangeSlider = {}
function RangeSlider.new(owner, options)
    local self = Base.new(owner, options, "RangeSlider", 44)
    local minimum, maximum, step = options.Min or 0, options.Max or 100, options.Increment or 1
    Math.round(minimum, minimum, maximum, step)
    local fields = {}
    for index = 1, 2 do
        fields[index] = Gui.new(self, "TextBox", {
            Size = UDim2.new(0.48, 0, 0, 22),
            Position = UDim2.fromScale((index - 1) * 0.52, 0),
            ClearTextOnFocus = false,
            TextXAlignment = index == 1 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
        }, { TextColor3 = "TextSecondary" }, self.Control)
    end
    local hit = Gui.new(
        self,
        "TextButton",
        { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 22) },
        nil,
        self.Control
    )
    local rail = Gui.new(
        self,
        "Frame",
        { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), BackgroundTransparency = 0 },
        { BackgroundColor3 = "Border" },
        hit
    )
    Gui.corner(self, rail, 9)
    local fill = Gui.new(self, "Frame", { BackgroundTransparency = 0 }, { BackgroundColor3 = "Accent" }, rail)
    local thumbs = {}
    for i = 1, 2 do
        thumbs[i] = Gui.new(self, "Frame", {
            Size = UDim2.fromOffset(12, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 0,
        }, { BackgroundColor3 = "TextPrimary" }, rail)
        Gui.corner(self, thumbs[i], 9)
    end
    self:Value(options.Default or { minimum, maximum }, function(value)
        if type(value) ~= "table" or not Math.finite(value[1]) or not Math.finite(value[2]) then
            return nil
        end
        local a, b =
            Math.round(value[1], minimum, maximum, step), Math.round(value[2], minimum, maximum, step)
        return { math.min(a, b), math.max(a, b) }
    end, function(_, value)
        local a, b = Math.fraction(value[1], minimum, maximum), Math.fraction(value[2], minimum, maximum)
        fields[1].Text = tostring(value[1])
        fields[2].Text = tostring(value[2])
        thumbs[1].Position = UDim2.fromScale(a, 0.5)
        thumbs[2].Position = UDim2.fromScale(b, 0.5)
        fill.Position = UDim2.fromScale(a, 0)
        fill.Size = UDim2.fromScale(b - a, 1)
    end)
    self.Maid:Give(hit.InputBegan:Connect(function(input)
        if not self:CanInteract() then
            return
        end
        local point = self.App.Input:Position(input)
        local value = self:GetValue()
        local fraction =
            math.clamp((point.X - hit.AbsolutePosition.X) / math.max(1, hit.AbsoluteSize.X), 0, 1)
        local selected = math.abs(fraction - Math.fraction(value[1], minimum, maximum))
                    <= math.abs(fraction - Math.fraction(value[2], minimum, maximum))
                and 1
            or 2
        self.App.Input:Track(self, input, function(position)
            local nextValue = self:GetValue()
            local nextNumber = Math.round(
                minimum
                    + (maximum - minimum)
                        * math.clamp(
                            (position.X - hit.AbsolutePosition.X) / math.max(1, hit.AbsoluteSize.X),
                            0,
                            1
                        ),
                minimum,
                maximum,
                step
            )
            nextValue[selected] = selected == 1 and math.min(nextNumber, nextValue[2])
                or math.max(nextNumber, nextValue[1])
            self:SetValue(nextValue)
        end)
    end))
    for i, field in ipairs(fields) do
        self.Maid:Give(field.Focused:Connect(function()
            if not self:CanInteract() then
                field:ReleaseFocus()
            end
        end))
        self.Maid:Give(field.FocusLost:Connect(function()
            local number = tonumber(field.Text)
            if number and self:CanInteract() then
                local value = self:GetValue()
                value[i] = number
                self:SetValue(value)
            end
            self.Render(self, self:GetValue())
        end))
    end
    return self
end
return RangeSlider
