--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local Tooltip = {}
Tooltip.__index = Tooltip
function Tooltip.new(app)
    return setmetatable({ App = app, _scope = nil, _owner = nil }, Tooltip)
end
function Tooltip:Hide()
    if self._scope then
        self._scope:Destroy()
        self._scope = nil
    end
    self._owner = nil
end
function Tooltip:HideOwner(owner)
    if self._owner == owner then
        self:Hide()
    end
end
function Tooltip:Show(owner, target, text)
    self:Hide()
    if not text or text == "" or self.App.Modal.Active then
        return
    end
    self._owner = owner
    self._scope = Cleanup.new()
    local ctx = { App = self.App, Theme = owner.Theme, Maid = self._scope }
    local width = math.min(260, self.App.Root.AbsoluteSize.X - 20)
    local measure = game:GetService("TextService")
        :GetTextSize(text, 11, Enum.Font.Gotham, Vector2.new(width - 20, 1000))
    local size = Vector2.new(width, measure.Y + 18)
    local point = Math.place(
        target.AbsolutePosition + Vector2.new(0, target.AbsoluteSize.Y + 8),
        size,
        self.App.Root.AbsoluteSize,
        true,
        target.AbsoluteSize.Y
    )
    local label = Gui.label(ctx, self.App.Layer, text, {
        Position = UDim2.fromOffset(point.X, point.Y),
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundTransparency = 0,
        TextWrapped = true,
        TextSize = 11,
        ZIndex = 10,
    }, "TextPrimary")
    self._scope:Give(label)
    self._scope:Give(
        owner.Theme:Bind(label, { BackgroundColor3 = "SurfaceElevated", TextColor3 = "TextPrimary" })
    )
    Gui.padding(ctx, label, 9)
    Gui.corner(ctx, label, 7)
    Gui.stroke(ctx, label)
end
function Tooltip:Attach(owner, target, getText)
    local maid = Cleanup.new()
    local pending = nil
    local function stop()
        if pending then
            pcall(task.cancel, pending)
            pending = nil
        end
        self:HideOwner(owner)
    end
    local function schedule()
        stop()
        pending = task.delay(0.45, function()
            pending = nil
            if not owner.Destroyed and target.Parent then
                self:Show(owner, target, getText())
            end
        end)
    end
    maid:Give(target.MouseEnter:Connect(schedule))
    maid:Give(target.SelectionGained:Connect(schedule))
    maid:Give(target.MouseLeave:Connect(stop))
    maid:Give(target.SelectionLost:Connect(stop))
    maid:Give(target.InputBegan:Connect(stop))
    maid:Give(stop)
    return maid
end
function Tooltip:Destroy()
    self:Hide()
end
return Tooltip
