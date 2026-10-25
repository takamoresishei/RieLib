--!nonstrict
local Cleanup = require(script.Parent.Cleanup)
local State = require(script.Parent.State)
local Flags = require(script.Parent.Flags)
local Theme = require(script.Parent.Theme)
local Motion = require(script.Parent.Motion)
local Input = require(script.Parent.Input)
local Window = require(script.Parent.Window)
local Config = require(script.Parent.Parent.Services.Config)
local Commands = require(script.Parent.Parent.Services.Commands)
local NotificationCenter = require(script.Parent.Parent.Services.NotificationCenter)
local Performance = require(script.Parent.Parent.Services.Performance)
local Overlay = require(script.Parent.Parent.Overlay.DropdownOverlay)
local Tooltip = require(script.Parent.Parent.Overlay.Tooltip)
local ContextMenu = require(script.Parent.Parent.Overlay.ContextMenu)
local Modal = require(script.Parent.Parent.Overlay.Modal)
local Palette = require(script.Parent.Parent.Overlay.CommandPalette)
local Search = require(script.Parent.Parent.Overlay.Search)
local Notification = require(script.Parent.Parent.Overlay.Notification)
local Icons = require(script.Parent.Parent.Utility.Icons)
local Gui = require(script.Parent.Parent.Utility.Gui)
local UIS = game:GetService("UserInputService")
local Application = {}
Application.__index = Application

function Application.new(options)
    options = options or {}
    local self = setmetatable({
        Version = "1.0.0",
        Maid = Cleanup.new(),
        Windows = {},
        FocusedWindow = nil,
        Destroyed = false,
        Options = options,
        Icons = Icons,
        State = State.new,
        Computed = State.computed,
        New = Application.new,
        Clipboard = options.Clipboard,
    }, Application)
    self.App = self
    self.Motion = Motion.new()
    self.Theme = Theme.new(self.Motion, options.Theme or "Eclipse")
    self.FlagStore = Flags.new()
    self.Flags = self.FlagStore.Values
    self.Config = Config.new(self.FlagStore, options.ConfigAdapter)
    self.Commands = Commands.new()
    self.NotificationCenter = NotificationCenter.new()
    self.Performance = Performance.new(self)
    self.Search = Search.new(self)
    self.Overlay = Overlay.new(self)
    self.Tooltips = Tooltip.new(self)
    self.ContextMenus = ContextMenu.new(self)
    self.Modal = Modal.new(self)
    self.Palette = Palette.new(self)
    return self
end
function Application:Call(callback, ...)
    local ok, result = pcall(callback, ...)
    if not ok then
        warn("[Aurelis callback] " .. tostring(result))
    end
    return ok, result
end
function Application:_start(parent)
    if self.Root then
        return
    end
    assert(not self.Destroyed, "Application is destroyed")
    parent = parent or self.Options.Parent
    if not parent then
        local player = game:GetService("Players").LocalPlayer
        assert(player, "Aurelis must run on the client")
        parent = player:WaitForChild("PlayerGui")
    end
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "Aurelis"
    self.Screen.ResetOnSpawn = false
    self.Screen.IgnoreGuiInset = false
    self.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Screen.DisplayOrder = self.Options.DisplayOrder or 100
    self.Screen.Parent = parent
    self.Maid:Give(self.Screen)
    self.Root = Gui.new(self, "Frame", { Name = "Workspace", Size = UDim2.fromScale(1, 1) }, nil, self.Screen)
    self.Layer = Gui.new(
        self,
        "Frame",
        { Name = "OverlayPortal", Size = UDim2.fromScale(1, 1), ZIndex = 10000 },
        nil,
        self.Root
    )
    self.Dock = Gui.new(self, "ScrollingFrame", {
        Name = "WindowDock",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.fromOffset(184, 220),
        Visible = false,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ZIndex = 0,
    }, nil, self.Layer)
    Gui.new(self, "UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
    }, nil, self.Dock)
    self.Input = Input.new(self)
    self.Maid:Give(self.Input)
    self.ContextMenus:Start()
    self.Maid:Give(self.ContextMenus)
    self.Notifications = Notification.new(self)
    self.Maid:Give(self.Notifications)
    self.Maid:Give(self.Screen.Destroying:Connect(function()
        self:Destroy()
    end))
    self.Maid:Give(self.Input:OnBegan(function(input, processed)
        local key = input.KeyCode
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            local point = self.Input:Position(input)
            for index = #self.Windows, 1, -1 do
                local window = self.Windows[index]
                if window.Visible and self.Input:Contains(window.Root, point) then
                    self:Focus(window)
                    break
                end
            end
            return
        end
        if self.Modal.Active then
            return
        end
        local ctrl = UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
        local window = self.FocusedWindow or self.Windows[#self.Windows]
        if ctrl and window then
            if key == Enum.KeyCode.K then
                self:OpenCommandPalette(window)
                return true
            elseif key == Enum.KeyCode.F then
                self.Search:Open(window)
                return true
            end
        end
        if processed or self.Input:IsTyping() then
            return
        end
        if window and key == window.ToggleKey then
            window:SetVisible(not window.Visible)
            return true
        end
    end, 10))
    self.Maid:Give(self.Commands:Register({
        Name = "Toggle Interface",
        Keywords = { "hide", "show", "menu" },
        Callback = function()
            local window = self.FocusedWindow or self.Windows[#self.Windows]
            if window then
                window:SetVisible(not window.Visible)
            end
        end,
    }))
end
function Application:CreateWindow(options)
    options = options or {}
    self:_start(options.Parent)
    local window = Window.new(self, options)
    table.insert(self.Windows, window)
    self:Focus(window)
    return window
end
function Application:_updateDock()
    if not self.Dock then
        return
    end
    local any = false
    for index, window in ipairs(self.Windows) do
        if window.Launcher then
            window.Launcher.Visible = not window.Visible or window.Minimized
            window.Launcher.LayoutOrder = index
            any = any or window.Launcher.Visible
        end
    end
    self.Dock.Visible = any
    self.Dock.Size = UDim2.fromOffset(
        math.min(184, math.max(1, self.Root.AbsoluteSize.X - 24)),
        math.min(220, math.max(1, self.Root.AbsoluteSize.Y - 24))
    )
end
function Application:Focus(window)
    if window.Destroyed then
        return
    end
    if self.Overlay.Active and self.Overlay.Active.Context.Window ~= window and not self.Modal.Active then
        self.Overlay:Close("FocusChanged")
    end
    local index = table.find(self.Windows, window)
    if index then
        table.remove(self.Windows, index)
        table.insert(self.Windows, window)
    end
    self.FocusedWindow = window
    for order, item in ipairs(self.Windows) do
        item.Root.ZIndex = order
    end
    self:_updateDock()
    self:_updateBlur()
end
function Application:_updateBlur()
    if self.Destroyed then
        return
    end
    local enabled = false
    for _, window in ipairs(self.Windows) do
        if window.Visible and not window.Minimized and window.Options.Blur then
            enabled = true
            break
        end
    end
    local modal = self.Modal and self.Modal.Active ~= nil
    if (enabled or modal) and not self.BlurEffect then
        self.BlurEffect = Instance.new("BlurEffect")
        self.BlurEffect.Name = "AurelisWorldBlur"
        self.BlurEffect.Size = 0
        self.BlurEffect.Parent = game:GetService("Lighting")
    end
    if self.BlurEffect then
        self.Motion:Tween(self.BlurEffect, { Size = modal and 14 or enabled and 7 or 0 }, "Normal")
    end
end
function Application:GetValue(flag)
    return self.FlagStore:Get(flag)
end
function Application:SetValue(flag, value, silent)
    return self.FlagStore:Set(flag, value, silent)
end
function Application:SetTheme(theme)
    self.Theme:Set(theme)
    for _, window in ipairs(self.Windows) do
        window:SetTheme(theme)
    end
    return self
end
function Application:Notify(options)
    self:_start()
    return self.NotificationCenter:Push(options or {})
end
function Application:Dialog(options, window)
    self:_start()
    window = window or self.FocusedWindow
    assert(window, "Create a window before opening a dialog")
    return self.Modal:Show(window, options)
end
function Application:OpenCommandPalette(window)
    window = window or self.FocusedWindow
    if window then
        self.Palette:Open(window, function(query)
            return self.Commands:Search(query)
        end, "Search commands…")
    end
end
function Application:SetDeveloperOverlay(enabled)
    self:_start()
    if self._devScope then
        self.Maid:Remove(self._devScope)
        self._devScope = nil
    end
    if not enabled then
        return
    end
    local scope = Cleanup.new()
    self.Maid:Give(scope)
    self._devScope = scope
    local ctx = { App = self, Theme = self.Theme, Maid = scope }
    local panel = Gui.new(ctx, "Frame", {
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(226, 184),
        BackgroundTransparency = 0.04,
        ZIndex = 30,
    }, { BackgroundColor3 = "SurfaceElevated" }, self.Layer)
    scope:Give(panel)
    Gui.corner(ctx, panel)
    Gui.stroke(ctx, panel)
    Gui.label(
        ctx,
        panel,
        "A U R E L I S   /   D E V",
        { Position = UDim2.fromOffset(14, 12), Size = UDim2.new(1, -28, 0, 24), TextSize = 10 },
        "Accent"
    )
    local labels = {}
    for index, key in ipairs({ "FPS", "UI Instances", "Connections", "Active Tweens", "Memory" }) do
        labels[index] = Gui.label(ctx, panel, key, {
            Position = UDim2.fromOffset(14, 43 + (index - 1) * 25),
            Size = UDim2.new(1, -28, 0, 21),
            TextSize = 11,
        }, "TextSecondary")
    end
    scope:Give(self.Performance:Acquire(function(values)
        labels[1].Text = "FPS                         " .. values.FPS
        labels[2].Text = "UI Instances            " .. values.Instances
        labels[3].Text = "Connections             " .. values.Connections
        labels[4].Text = "Active Tweens           " .. values.Tweens
        labels[5].Text = string.format("Client memory       %.1f MB", values.Memory)
    end))
end
function Application:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Overlay:Destroy()
    self.Tooltips:Destroy()
    for _, window in ipairs(table.clone(self.Windows)) do
        window:Destroy()
    end
    self.Maid:Destroy()
    self.Performance:Destroy()
    self.Motion:Destroy()
    self.Theme:Destroy()
    self.Commands:Destroy()
    self.FlagStore:Destroy()
    self.NotificationCenter:Destroy()
    self.Search:Destroy()
    if self.BlurEffect then
        self.BlurEffect:Destroy()
        self.BlurEffect = nil
    end
end
return Application
