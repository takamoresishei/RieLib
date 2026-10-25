--!nonstrict
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Cleanup = require(script.Parent.Cleanup)
local Signal = require(script.Parent.Parent.Utility.Signal)
local Input = {}
Input.__index = Input
function Input.new(app)
    local self = setmetatable({ App = app, Maid = Cleanup.new(), _listeners = {}, _pointer = nil }, Input)
    self.Changed = Signal.new()
    self.Ended = Signal.new()
    self.TextFocused = Signal.new()
    self.SelectionChanged = Signal.new()
    self.Maid:Give(self.Changed)
    self.Maid:Give(self.Ended)
    self.Maid:Give(self.TextFocused)
    self.Maid:Give(self.SelectionChanged)
    self.Maid:Give(UIS.TextBoxFocused:Connect(function(field)
        self.TextFocused:Fire(field)
    end))
    self.Maid:Give(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
        self.SelectionChanged:Fire(GuiService.SelectedObject)
    end))
    self.Maid:Give(UIS.InputBegan:Connect(function(input, processed)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            self.App.LastPointer = self:Position(input)
        end
        local snapshot = table.clone(self._listeners)
        for _, entry in ipairs(snapshot) do
            if entry.Connected and entry.Callback(input, processed) then
                break
            end
        end
    end))
    self.Maid:Give(UIS.InputChanged:Connect(function(input)
        local pointer = self._pointer
        if
            pointer
            and (
                input == pointer.Input
                or (pointer.Mouse and input.UserInputType == Enum.UserInputType.MouseMovement)
            )
        then
            pointer.Update(self:Position(input))
        end
        self.Changed:Fire(input)
    end))
    self.Maid:Give(UIS.InputEnded:Connect(function(input)
        local pointer = self._pointer
        if
            pointer
            and (
                pointer.Input == input
                or (pointer.Mouse and input.UserInputType == Enum.UserInputType.MouseButton1)
            )
        then
            self._pointer = nil
            if pointer.Finish then
                pointer.Finish(self:Position(input))
            end
        end
        self.Ended:Fire(input)
    end))
    return self
end
function Input:Position(input)
    -- InputObject.Position already uses CoreUISafeInsets, like AbsolutePosition.
    -- GetMouseLocation is in physical screen coordinates and needs the inset conversion.
    if input then
        return Vector2.new(input.Position.X, input.Position.Y)
    end
    local position = UIS:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    return Vector2.new(position.X - inset.X, position.Y - inset.Y)
end
function Input:Contains(object, point)
    if not object or not object.Parent or not object.Visible then
        return false
    end
    local ancestor = object.Parent
    while ancestor and ancestor:IsA("GuiObject") do
        if not ancestor.Visible then
            return false
        end
        ancestor = ancestor.Parent
    end
    local p, s = object.AbsolutePosition, object.AbsoluteSize
    return point.X >= p.X and point.Y >= p.Y and point.X <= p.X + s.X and point.Y <= p.Y + s.Y
end
function Input:OnBegan(callback, priority)
    local entry = { Callback = callback, Priority = priority or 0, Connected = true }
    table.insert(self._listeners, entry)
    table.sort(self._listeners, function(a, b)
        return a.Priority > b.Priority
    end)
    local owner = self
    function entry:Disconnect()
        if not self.Connected then
            return
        end
        self.Connected = false
        local index = table.find(owner._listeners, self)
        if index then
            table.remove(owner._listeners, index)
        end
    end
    return entry
end
function Input:Track(owner, input, update, finish)
    if
        input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch
    then
        return
    end
    if self._pointer and self._pointer.Finish then
        self._pointer.Finish(self:Position(input))
    end
    self._pointer = {
        Owner = owner,
        Input = input,
        Mouse = input.UserInputType == Enum.UserInputType.MouseButton1,
        Update = update,
        Finish = finish,
    }
    update(self:Position(input))
end
function Input:Cancel(owner)
    if self._pointer and self._pointer.Owner == owner then
        local pointer = self._pointer
        self._pointer = nil
        if pointer.Finish then
            pointer.Finish(self:Position())
        end
    end
end
function Input:CancelWindow(window)
    local owner = self._pointer and self._pointer.Owner
    if owner and (owner == window or owner.Window == window) then
        self:Cancel(owner)
    end
end
function Input:Feedback(ctx, button, disabled)
    local function can()
        return not disabled or not disabled()
    end
    ctx.Maid:Give(button.MouseEnter:Connect(function()
        if can() then
            ctx.App.Motion:Tween(button, { BackgroundTransparency = 0.25 }, "Fast")
        end
    end))
    ctx.Maid:Give(button.MouseLeave:Connect(function()
        ctx.App.Motion:Tween(button, { BackgroundTransparency = 1 }, "Fast")
    end))
    ctx.Maid:Give(button.InputBegan:Connect(function(input)
        if
            can()
            and (
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            ctx.App.Motion:Tween(button, { BackgroundTransparency = 0.05 }, "Fast")
        end
    end))
    ctx.Maid:Give(button.SelectionGained:Connect(function()
        if can() then
            button.BackgroundTransparency = 0.25
        end
    end))
    ctx.Maid:Give(button.SelectionLost:Connect(function()
        button.BackgroundTransparency = 1
    end))
end
function Input:IsTyping()
    return UIS:GetFocusedTextBox() ~= nil
end
function Input:Destroy()
    self._pointer = nil
    table.clear(self._listeners)
    self.Maid:Destroy()
end
return Input
