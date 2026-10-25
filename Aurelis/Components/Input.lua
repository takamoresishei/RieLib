--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local Input = {}
local function limit(text, count)
    if not count then
        return text
    end
    local ok, length = pcall(utf8.len, text)
    if ok and length and length > count then
        return string.sub(text, 1, utf8.offset(text, count + 1) - 1)
    end
    return text
end
function Input.new(owner, options)
    if options.CharacterLimit then
        assert(
            type(options.CharacterLimit) == "number"
                and options.CharacterLimit >= 0
                and options.CharacterLimit % 1 == 0,
            "CharacterLimit must be a non-negative integer"
        )
    end
    local self = Base.new(owner, options, "Input", 56)
    local kind = options.Type or (options.Password and "Password" or "Text")
    self.Field = Gui.new(
        self,
        "TextBox",
        {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 0.25,
            PlaceholderText = options.Placeholder or "Enter value…",
            ClearTextOnFocus = false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextTransparency = kind == "Password" and 1 or 0,
        },
        { BackgroundColor3 = "Background", TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" },
        self.Control
    )
    Gui.corner(self, self.Field, 7)
    Gui.stroke(self, self.Field)
    Gui.padding(self, self.Field, 8)
    self.ErrorLabel = Gui.label(self, self.Control, "", {
        Position = UDim2.fromOffset(2, 36),
        Size = UDim2.new(1, -4, 0, 18),
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, "Danger")
    local mask = nil
    if kind == "Password" then
        mask = Gui.label(
            self,
            self.Field,
            "",
            { Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2 }
        )
    end
    local rendering = false
    local function normalize(value)
        if kind == "Number" then
            if not Math.finite(value) then
                return nil
            end
            if options.Min and value < options.Min then
                return nil
            end
            if options.Max and value > options.Max then
                return nil
            end
        else
            if type(value) ~= "string" then
                return nil
            end
            value = limit(value, options.CharacterLimit)
        end
        if options.Validate then
            local valid = options.Validate(value)
            if not valid then
                return nil
            end
        end
        return value
    end
    self:Value(
        options.Default ~= nil and options.Default or (kind == "Number" and 0 or ""),
        normalize,
        function(_, value)
            rendering = true
            self.Field.Text = tostring(value)
            self.ErrorLabel.Text = ""
            rendering = false
            if mask then
                mask.Text = string.rep("•", utf8.len(tostring(value)) or #tostring(value))
            end
        end
    )
    function self:ValidateText()
        local text = limit(self.Field.Text, options.CharacterLimit)
        if text ~= self.Field.Text then
            rendering = true
            self.Field.Text = text
            rendering = false
        end
        if mask then
            mask.Text = text == "" and (options.Placeholder or "Enter value…")
                or string.rep("•", utf8.len(text) or #text)
        end
        local value = kind == "Number" and tonumber(text) or text
        if kind == "Number" and not tonumber(text) then
            self.ErrorLabel.Text = "Enter a valid number"
            return false
        end
        local ok, normalized = pcall(normalize, value)
        if not ok or normalized == nil then
            local message = "Invalid value"
            if options.Validate then
                local safe, _, reason = pcall(options.Validate, value)
                if safe and reason then
                    message = tostring(reason)
                end
            end
            self.ErrorLabel.Text = message
            return false
        end
        self.ErrorLabel.Text = ""
        return true, normalized
    end
    self.Maid:Give(self.Field:GetPropertyChangedSignal("Text"):Connect(function()
        if rendering or not self:CanInteract() then
            return
        end
        local valid, value = self:ValidateText()
        if valid and options.Live then
            self:SetValue(value)
        end
    end))
    self.Maid:Give(self.Field.Focused:Connect(function()
        if not self:CanInteract() then
            self.Field:ReleaseFocus()
            return
        end
        self.FocusStroke.Transparency = 0.2
    end))
    self.Maid:Give(self.Field.FocusLost:Connect(function(enter)
        self.FocusStroke.Transparency = 1
        if not self:CanInteract() then
            return
        end
        local valid, value = self:ValidateText()
        if valid and (options.SubmitOnEnter ~= true or enter or options.Live) then
            self:SetValue(value)
        elseif valid then
            self.Render(self, self:GetValue())
        end
    end))
    return self
end
return Input
