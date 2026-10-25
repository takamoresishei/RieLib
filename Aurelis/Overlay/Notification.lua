--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local Notification = {}
Notification.__index = Notification
local styles = {
    Info = { "info", "Accent" },
    Success = { "check", "Success" },
    Warning = { "warning", "Warning" },
    Error = { "x", "Danger" },
}
function Notification.new(app)
    local self =
        setmetatable({ App = app, Theme = app.Theme, Maid = Cleanup.new(), Toasts = {} }, Notification)
    self.Host = Gui.new(self, "Frame", {
        Name = "Toasts",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, math.min(320, math.max(1, app.Root.AbsoluteSize.X - 32)), 1, -32),
        ZIndex = 20,
    }, nil, app.Layer)
    self.Maid:Give(self.Host)
    Gui.new(self, "UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }, nil, self.Host)
    self.Maid:Give(app.NotificationCenter.Changed:Connect(function(kind, item)
        if kind == "Added" and item.Duration > 0 then
            self:Toast(item)
        end
    end))
    self.Maid:Give(app.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self.Host.Size = UDim2.new(0, math.min(320, app.Root.AbsoluteSize.X - 32), 1, -32)
    end))
    return self
end
function Notification:Toast(item)
    while #self.Toasts >= 4 do
        self.Toasts[1].Dismiss()
    end
    local maid = Cleanup.new()
    self.Maid:Give(maid)
    local ctx = { App = self.App, Theme = self.Theme, Maid = maid }
    local row =
        Gui.new(ctx, "Frame", { Size = UDim2.new(1, 0, 0, 90), LayoutOrder = item.Id }, nil, self.Host)
    maid:Give(row)
    local toast = Gui.new(ctx, "CanvasGroup", {
        Name = "Toast",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0,
        GroupTransparency = 1,
    }, { BackgroundColor3 = "SurfaceElevated" }, row)
    Gui.corner(ctx, toast)
    Gui.stroke(ctx, toast)
    local style = styles[item.Type] or styles.Info
    Icons:Create(
        ctx,
        toast,
        style[1],
        { Position = UDim2.fromOffset(14, 18), Size = UDim2.fromOffset(18, 18) },
        style[2]
    )
    Gui.label(ctx, toast, item.Title, {
        Position = UDim2.fromOffset(44, 12),
        Size = UDim2.new(1, -76, 0, 25),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamMedium,
    })
    Gui.label(ctx, toast, item.Content, {
        Position = UDim2.fromOffset(44, 38),
        Size = UDim2.new(1, -58, 0, 39),
        TextSize = 11,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, "TextSecondary")
    local close =
        Gui.button(ctx, toast, "×", { Position = UDim2.new(1, -30, 0, 9), Size = UDim2.fromOffset(22, 22) })
    local entry = {}
    table.insert(self.Toasts, entry)
    local dismissed, pending = false, nil
    entry.Dismiss = function()
        if dismissed then
            return
        end
        dismissed = true
        if pending then
            pcall(task.cancel, pending)
            pending = nil
        end
        local index = table.find(self.Toasts, entry)
        if index then
            table.remove(self.Toasts, index)
        end
        self.Maid:Remove(maid)
    end
    maid:Give(close.Activated:Connect(entry.Dismiss))
    pending = task.delay(item.Duration, function()
        pending = nil
        entry.Dismiss()
    end)
    maid:Give(function()
        if pending then
            pcall(task.cancel, pending)
            pending = nil
        end
    end)
    self.App.Motion:Tween(toast, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, "Normal")
    return entry
end
function Notification:Open(window, anchor)
    if self.App.Modal.Active then
        return
    end
    self.App.Overlay:Open(window, anchor, Vector2.new(350, 390), function(ctx, panel)
        Gui.label(
            ctx,
            panel,
            "Notifications",
            { Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 26), TextSize = 16 }
        )
        local clear = Gui.button(
            ctx,
            panel,
            "Clear all",
            { Position = UDim2.new(1, -92, 0, 12), Size = UDim2.fromOffset(78, 26), TextSize = 10 }
        )
        local list = Gui.new(ctx, "ScrollingFrame", {
            Position = UDim2.fromOffset(12, 52),
            Size = UDim2.new(1, -24, 1, -64),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
        }, { ScrollBarImageColor3 = "Border" }, panel)
        Gui.list(ctx, list, 7)
        local rows = nil
        local function render()
            if rows then
                ctx.Maid:Remove(rows)
            end
            rows = Cleanup.new()
            ctx.Maid:Give(rows)
            local rowctx = { App = ctx.App, Theme = ctx.Theme, Maid = rows }
            local history = self.App.NotificationCenter.History
            if #history == 0 then
                rows:Give(
                    Gui.label(
                        rowctx,
                        list,
                        "You're all caught up",
                        { Size = UDim2.new(1, 0, 0, 100), TextXAlignment = Enum.TextXAlignment.Center },
                        "TextMuted"
                    )
                )
            end
            for index, item in ipairs(history) do
                local frame = Gui.new(
                    rowctx,
                    "Frame",
                    { Size = UDim2.new(1, -4, 0, 75), LayoutOrder = index },
                    nil,
                    list
                )
                rows:Give(frame)
                local style = styles[item.Type] or styles.Info
                Icons:Create(
                    rowctx,
                    frame,
                    style[1],
                    { Position = UDim2.fromOffset(4, 7), Size = UDim2.fromOffset(16, 16) },
                    style[2]
                )
                Gui.label(rowctx, frame, item.Title, {
                    Position = UDim2.fromOffset(28, 2),
                    Size = UDim2.new(1, -66, 0, 24),
                    TextSize = 12,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                local elapsed = os.time() - item.Time
                Gui.label(
                    rowctx,
                    frame,
                    elapsed < 60 and "now" or tostring(math.floor(elapsed / 60)) .. "m",
                    { Position = UDim2.new(1, -32, 0, 2), Size = UDim2.fromOffset(30, 24), TextSize = 9 },
                    "TextMuted"
                )
                Gui.label(rowctx, frame, item.Content, {
                    Position = UDim2.fromOffset(28, 29),
                    Size = UDim2.new(1, -32, 0, 40),
                    TextSize = 10,
                    TextWrapped = true,
                    TextYAlignment = Enum.TextYAlignment.Top,
                }, "TextSecondary")
            end
        end
        ctx.Maid:Give(clear.Activated:Connect(function()
            self.App.NotificationCenter:Clear()
        end))
        ctx.Maid:Give(self.App.NotificationCenter.Changed:Connect(render))
        render()
    end)
end
function Notification:Destroy()
    self.Maid:Destroy()
    table.clear(self.Toasts)
end
return Notification
