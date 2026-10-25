--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Table = require(script.Parent.Parent.Utility.Table)
local Keybind = {}
local modes = { "Toggle", "Hold", "Always" }
function Keybind.new(owner, options)
    local baseOptions = Table.copy(options)
    baseOptions.Callback = nil
    local self = Base.new(owner, baseOptions, "Keybind", 34)
    self.Active = false
    self.Listening = false
    local button =
        Gui.button(self, self.Control, "", { Size = UDim2.new(0.62, -4, 1, 0), BackgroundTransparency = 0.2 })
    local modeButton = Gui.button(
        self,
        self.Control,
        options.Mode or "Toggle",
        { Position = UDim2.fromScale(0.62, 0), Size = UDim2.fromScale(0.38, 1), TextSize = 10 }
    )
    Gui.stroke(self, button)
    function self:_activate(active)
        if active == self.Active then
            return
        end
        self.Active = active
        if options.Callback then
            self.App:Call(options.Callback, active)
        end
    end
    self:Value(
        { Key = options.Default or Enum.KeyCode.Unknown, Mode = options.Mode or "Toggle" },
        function(value)
            if typeof(value) == "EnumItem" then
                value = {
                    Key = value,
                    Mode = self:GetValue() and self:GetValue().Mode or options.Mode or "Toggle",
                }
            end
            if
                type(value) ~= "table"
                or typeof(value.Key) ~= "EnumItem"
                or value.Key.EnumType ~= Enum.KeyCode
                or not table.find(modes, value.Mode)
            then
                return nil
            end
            return { Key = value.Key, Mode = value.Mode }
        end,
        function(_, value)
            button.Text = value.Key == Enum.KeyCode.Unknown and "Unbound" or value.Key.Name
            modeButton.Text = value.Mode
            self:_activate(value.Mode == "Always" and not self.Disabled)
        end
    )
    function self:SetMode(mode)
        return self:SetValue({ Key = self:GetValue().Key, Mode = mode })
    end
    function self:SetKey(key)
        return self:SetValue({ Key = key, Mode = self:GetValue().Mode })
    end
    function self:IsActive()
        return self.Active
    end
    function self:OnDisabled()
        self:_activate(not self.Disabled and self:GetValue().Mode == "Always")
    end
    self.Maid:Give(button.Activated:Connect(function()
        if not self:CanInteract() then
            return
        end
        self.Listening = not self.Listening
        button.Text = self.Listening and "Listening…" or self:GetValue().Key.Name
    end))
    self.Maid:Give(modeButton.Activated:Connect(function()
        if self:CanInteract() then
            self:SetMode(modes[(table.find(modes, self:GetValue().Mode) % #modes) + 1])
        end
    end))
    self.Maid:Give(self.App.Input:OnBegan(function(input, processed)
        if self.Listening then
            if input.KeyCode == Enum.KeyCode.Unknown then
                return
            end
            self.Listening = false
            if input.KeyCode ~= Enum.KeyCode.Escape then
                self:SetKey(input.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or input.KeyCode)
            end
            button.Text = self:GetValue().Key.Name
            return true
        end
        if processed or self.App.Input:IsTyping() or not self:CanInteract() then
            return
        end
        local value = self:GetValue()
        if input.KeyCode == value.Key and value.Key ~= Enum.KeyCode.Unknown then
            if value.Mode == "Toggle" then
                self:_activate(not self.Active)
            elseif value.Mode == "Hold" then
                self:_activate(true)
            end
        end
    end, 900))
    self.Maid:Give(self.App.Input.Ended:Connect(function(input)
        if self:GetValue().Mode == "Hold" and input.KeyCode == self:GetValue().Key then
            self:_activate(false)
        end
    end))
    self.Maid:Give(function()
        self:_activate(false)
    end)
    return self
end
return Keybind
