--!nonstrict
-- One portal and one input layer for all popovers. Replacing a popover destroys its scope.
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Overlay = {}
Overlay.__index = Overlay
function Overlay.new(app)
    return setmetatable({ App = app, Active = nil }, Overlay)
end
function Overlay:Open(owner, anchor, size, build, options)
    options = options or {}
    self:Close("Replaced")
    local maid = Cleanup.new()
    local ctx =
        { App = self.App, Window = owner.Window or owner, Theme = owner.Theme or self.App.Theme, Maid = maid }
    local active = {
        Owner = owner,
        Context = ctx,
        Maid = maid,
        Options = options,
        PreviousSelection = GuiService.SelectedObject,
    }
    self.Active = active
    if options.Blocking then
        active.Dim = Gui.new(ctx, "TextButton", {
            Name = "ModalBackdrop",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(),
            BackgroundTransparency = 0.45,
            ZIndex = 1,
        }, nil, self.App.Layer)
        maid:Give(active.Dim)
    end
    local viewport = self.App.Root.AbsoluteSize
    size = Vector2.new(
        math.min(size.X, math.max(1, viewport.X - 16)),
        math.min(size.Y, math.max(1, viewport.Y - 16))
    )
    local panel = Gui.new(ctx, "CanvasGroup", {
        Name = "AurelisOverlay",
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundTransparency = 0,
        GroupTransparency = 1,
        ZIndex = 2,
        ClipsDescendants = true,
    }, { BackgroundColor3 = "SurfaceElevated" }, self.App.Layer)
    active.Panel = panel
    maid:Give(panel)
    Gui.corner(ctx, panel)
    Gui.stroke(ctx, panel, true)
    local function place()
        if self.Active ~= active then
            return
        end
        local screen = self.App.Root.AbsoluteSize
        panel.Size = UDim2.fromOffset(
            math.min(size.X, math.max(1, screen.X - 16)),
            math.min(size.Y, math.max(1, screen.Y - 16))
        )
        if options.Centered then
            panel.Position = UDim2.fromOffset(
                math.max(8, (screen.X - panel.AbsoluteSize.X) / 2),
                math.max(8, (screen.Y - panel.AbsoluteSize.Y) / 2)
            )
        else
            local point = typeof(anchor) == "Vector2" and anchor
                or anchor.AbsolutePosition + Vector2.new(0, anchor.AbsoluteSize.Y + 6)
            local placed = Math.place(
                point,
                panel.AbsoluteSize,
                screen,
                true,
                typeof(anchor) == "Instance" and anchor.AbsoluteSize.Y or 0
            )
            panel.Position = UDim2.fromOffset(placed.X, placed.Y)
        end
    end
    place()
    maid:Give(self.App.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(place))
    if typeof(anchor) == "Instance" then
        maid:Give(anchor:GetPropertyChangedSignal("AbsolutePosition"):Connect(place))
        maid:Give(anchor.Destroying:Connect(function()
            self:Close("OwnerDestroyed")
        end))
    end
    maid:Give(self.App.Input:OnBegan(function(input, processed)
        if self.Active ~= active then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape and not options.Critical then
            self:Close("Escape")
            return true
        end
        local pointer = input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        if pointer and not self.App.Input:Contains(panel, self.App.Input:Position(input)) then
            if not options.Blocking then
                self:Close("Outside")
            end
            return options.Blocking == true
        end
        if options.OnInput and options.OnInput(input, processed) then
            return true
        end
        if options.Blocking and input.KeyCode ~= Enum.KeyCode.Unknown then
            return true
        end
    end, 1000))
    local ok, err = pcall(build, ctx, panel, active)
    if not ok then
        self:Close("Error")
        error(err, 2)
    end
    self.App.Motion:Tween(panel, { GroupTransparency = 0 }, "Normal")
    self.App:_updateBlur()
    return active
end
function Overlay:Close(reason)
    local active = self.Active
    if not active then
        return
    end
    self.Active = nil
    local focused = UIS:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(active.Panel) then
        focused:ReleaseFocus()
    end
    active.Maid:Destroy()
    if active.Options.OnClose then
        active.Options.OnClose(reason or "Closed")
    end
    if reason ~= "Replaced" and active.PreviousSelection and active.PreviousSelection.Parent then
        GuiService.SelectedObject = active.PreviousSelection
    end
    self.App:_updateBlur()
end
function Overlay:CloseOwner(owner)
    if self.Active and self.Active.Owner == owner then
        self:Close("OwnerClosed")
    end
end
function Overlay:Destroy()
    self:Close("Destroyed")
end
return Overlay
