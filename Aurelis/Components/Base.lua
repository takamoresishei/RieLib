--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Signal = require(script.Parent.Parent.Utility.Signal)
local Table = require(script.Parent.Parent.Utility.Table)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local TextService = game:GetService("TextService")
local Base = {}
Base.__index = Base

function Base.new(owner, options, kind, controlHeight)
    options = options or {}
    local self = setmetatable({
        App = owner.App,
        Window = owner.Window,
        Theme = owner.Theme,
        Maid = Cleanup.new(),
        Owner = owner,
        Options = options,
        Kind = kind,
        Title = options.Title or kind,
        Description = options.Description,
        Disabled = options.Disabled == true,
        Destroyed = false,
        Changed = Signal.new(),
        ControlHeight = controlHeight or 32,
    }, Base)
    self.Context = self
    owner._nextOrder = (owner._nextOrder or 0) + 1
    self.Root = Gui.new(self, "Frame", {
        Name = kind,
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundTransparency = 1,
        LayoutOrder = owner._nextOrder,
    }, { BackgroundColor3 = "SurfaceElevated" }, owner.Content)
    self.Maid:Give(self.Root)
    table.insert(owner.Components, self)
    self.Maid:Give(function()
        self.App.Search:Unregister(self)
        Table.removeValue(owner.Components, self)
    end)
    Gui.corner(self, self.Root, 8)
    self.Hit = Gui.new(
        self,
        "TextButton",
        { Size = UDim2.fromScale(1, 1), ZIndex = 1 },
        { BackgroundColor3 = "SurfaceElevated" },
        self.Root
    )
    Gui.corner(self, self.Hit, 8)
    self.TitleLabel = Gui.label(
        self,
        self.Root,
        self.Title,
        { Position = UDim2.fromOffset(10, 8), ZIndex = 2, TextTruncate = Enum.TextTruncate.AtEnd }
    )
    self.DescriptionLabel = Gui.label(
        self,
        self.Root,
        self.Description or "",
        { Position = UDim2.fromOffset(10, 29), TextSize = 11, TextWrapped = true, ZIndex = 2 },
        "TextMuted"
    )
    self.Control = Gui.new(self, "CanvasGroup", {
        Size = UDim2.fromOffset(200, self.ControlHeight),
        Position = UDim2.new(1, -210, 0, 8),
        ZIndex = 3,
        GroupTransparency = self.Disabled and 0.55 or 0,
    }, nil, self.Root)
    self.FocusStroke = Gui.stroke(self, self.Root, true)
    self.FocusStroke.Transparency = 1
    self.App.Input:Feedback(self, self.Hit, function()
        return self.Disabled
    end)
    self.Maid:Give(self.Hit.SelectionGained:Connect(function()
        self.FocusStroke.Transparency = 0.2
    end))
    self.Maid:Give(self.Hit.SelectionLost:Connect(function()
        self.FocusStroke.Transparency = 1
    end))
    self.Maid:Give(self.App.Input.SelectionChanged:Connect(function(selected)
        local focused = selected and (selected == self.Root or selected:IsDescendantOf(self.Root))
        self.FocusStroke.Transparency = focused and not self.Disabled and 0.2 or 1
    end))
    self.Maid:Give(self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:_layout()
    end))
    self.Maid:Give(function()
        self.App.Input:Cancel(self)
        self.App.Overlay:CloseOwner(self)
        self.App.Tooltips:HideOwner(self)
    end)
    self.Maid:Give(self.App.Tooltips:Attach(self, self.Hit, function()
        return self.Options.Tooltip
    end))
    self.Maid:Give(self.App.ContextMenus:Attach(self))
    self:SetIcon(options.Icon)
    self.App.Search:Register(self)
    self.Maid:Give(self.Changed)
    self.Maid:Give(self.Root.Destroying:Connect(function()
        self:Destroy()
    end))
    self:SetVisible(options.Visible ~= false)
    self:_layout()
    return self
end
function Base:_layout()
    if self.Destroyed then
        return
    end
    local width = self.Root.AbsoluteSize.X / self.Window.Scale
    local compact = width > 0 and width < 380
    local iconOffset = self.Icon and 26 or 0
    local controlWidth = compact and math.max(1, width - 20) or math.clamp(width * 0.43, 110, 224)
    local labelWidth = math.max(20, width - (compact and 20 or controlWidth + 36) - iconOffset)
    local descHeight = 0
    if self.Description and self.Description ~= "" then
        descHeight =
            TextService:GetTextSize(self.Description, 11, Enum.Font.Gotham, Vector2.new(labelWidth, 1000)).Y
    end
    local labelHeight = 22 + (descHeight > 0 and descHeight + 3 or 0)
    self.TitleLabel.Position = UDim2.fromOffset(10 + iconOffset, 8)
    self.TitleLabel.Size = UDim2.fromOffset(labelWidth, 20)
    self.DescriptionLabel.Position = UDim2.fromOffset(10 + iconOffset, 31)
    self.DescriptionLabel.Size = UDim2.fromOffset(labelWidth, descHeight)
    self.DescriptionLabel.Visible = descHeight > 0
    self.Control.Position = compact and UDim2.fromOffset(10, labelHeight + 12)
        or UDim2.new(1, -controlWidth - 10, 0, 8)
    self.Control.Size = UDim2.fromOffset(controlWidth, self.ControlHeight)
    self.Root.Size = UDim2.new(
        1,
        0,
        0,
        compact and labelHeight + self.ControlHeight + 22 or math.max(labelHeight, self.ControlHeight) + 16
    )
end
function Base:CanInteract()
    return not self.Destroyed
        and not self.Disabled
        and self.Window.Visible
        and not self.Window.Minimized
        and not self.App.Modal.Active
end
function Base:Value(default, normalize, render)
    self.Normalize, self.Render = normalize, render
    local normalized = normalize(default)
    assert(normalized ~= nil, "Invalid default for " .. self.Title)
    self.Default, self._value = Table.copy(normalized), Table.copy(normalized)
    local function apply(value, silent)
        if self.Destroyed then
            return
        end
        self._value = Table.copy(value)
        render(self, self:GetValue())
        self.Changed:Fire(self:GetValue())
        if not silent and self.Options.Callback then
            self.App:Call(self.Options.Callback, self:GetValue())
        end
    end
    self._apply = apply
    if self.Options.Flag then
        self.Maid:Give(
            self.App.FlagStore:Register(
                self.Options.Flag,
                normalized,
                normalize,
                apply,
                self.Options.ConfigPriority
            )
        )
    end
    render(self, self:GetValue())
    return self
end
function Base:SetValue(value, silent)
    if self.Destroyed or not self.Normalize then
        return false, "Component has no value"
    end
    local ok, normalized = pcall(self.Normalize, value)
    if not ok or normalized == nil then
        return false, "Invalid component value"
    end
    if self.Options.Flag then
        return self.App.FlagStore:Set(self.Options.Flag, normalized, silent)
    end
    if not Table.equal(normalized, self._value) then
        self._apply(normalized, silent == true)
    end
    return true
end
function Base:GetValue()
    return Table.copy(self._value)
end
function Base:Reset()
    return self:SetValue(self.Default)
end
function Base:SetDisabled(disabled)
    self.Disabled = disabled == true
    self.Control.GroupTransparency = self.Disabled and 0.55 or 0
    self.Hit.Selectable = not self.Disabled
    if self.Disabled then
        self.App.Input:Cancel(self)
        self.App.Overlay:CloseOwner(self)
    end
    if self.Disabled then
        local field = game:GetService("UserInputService"):GetFocusedTextBox()
        if field and field:IsDescendantOf(self.Root) then
            field:ReleaseFocus()
        end
        if self.Render then
            self.Render(self, self:GetValue())
        end
    end
    if self.OnDisabled then
        self:OnDisabled()
    end
    return self
end
function Base:SetVisible(visible)
    self.Root.Visible = visible == true
    if not self.Root.Visible then
        self.App.Input:Cancel(self)
        self.App.Overlay:CloseOwner(self)
    end
    return self
end
function Base:SetTitle(title)
    self.Title = tostring(title)
    self.TitleLabel.Text = self.Title
    return self
end
function Base:SetDescription(description)
    self.Description = description
    self.DescriptionLabel.Text = description or ""
    self:_layout()
    return self
end
function Base:SetTooltip(tooltip)
    self.Options.Tooltip = tooltip
    return self
end
function Base:SetIcon(name)
    if self.IconMaid then
        self.Maid:Remove(self.IconMaid)
        self.IconMaid = nil
        self.Icon = nil
    end
    if name then
        self.IconMaid = Cleanup.new()
        self.Maid:Give(self.IconMaid)
        local ctx = { App = self.App, Theme = self.Theme, Maid = self.IconMaid }
        self.Icon = Icons:Create(ctx, self.Root, name, { Position = UDim2.fromOffset(10, 10), ZIndex = 2 })
        self.IconMaid:Give(self.Icon)
    end
    self:_layout()
    return self
end
function Base:Update(options)
    if options.Title then
        self:SetTitle(options.Title)
    end
    if options.Description ~= nil then
        self:SetDescription(options.Description)
    end
    if options.Tooltip ~= nil then
        self:SetTooltip(options.Tooltip)
    end
    if options.Icon ~= nil then
        self:SetIcon(options.Icon == false and nil or options.Icon)
    end
    if options.Disabled ~= nil then
        self:SetDisabled(options.Disabled)
    end
    if options.Visible ~= nil then
        self:SetVisible(options.Visible)
    end
    if options.Callback then
        self.Options.Callback = options.Callback
    end
    return self
end
function Base:Bind(state)
    if self._binding then
        self.Maid:Remove(self._binding)
    end
    self._binding = state:Subscribe(function(value)
        self:SetValue(value, true)
    end)
    self.Maid:Give(self._binding)
    return self
end
function Base:Highlight()
    self.FocusStroke.Color = self.Theme.Tokens.Accent
    self.FocusStroke.Transparency = 0
    self.App.Motion:Tween(self.FocusStroke, { Transparency = 1 }, "Slow")
end
function Base:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Maid:Destroy()
end
return Base
