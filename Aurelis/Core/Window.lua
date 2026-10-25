--!nonstrict
local Cleanup = require(script.Parent.Cleanup)
local Theme = require(script.Parent.Theme)
local Responsive = require(script.Parent.Responsive)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local Sidebar = require(script.Parent.Parent.Navigation.Sidebar)
local Tab = require(script.Parent.Parent.Navigation.Tab)
local Breadcrumb = require(script.Parent.Parent.Navigation.Breadcrumb)
local Table = require(script.Parent.Parent.Utility.Table)
local Signal = require(script.Parent.Parent.Utility.Signal)
local Math = require(script.Parent.Parent.Utility.Math)
local Window = {}
Window.__index = Window

function Window.new(app, options)
    if options.Size then
        assert(typeof(options.Size) == "UDim2", "Size requires UDim2")
    end
    if options.MinimumSize then
        assert(
            typeof(options.MinimumSize) == "Vector2"
                and Math.finite(options.MinimumSize.X)
                and Math.finite(options.MinimumSize.Y)
                and options.MinimumSize.X > 0
                and options.MinimumSize.Y > 0,
            "MinimumSize requires positive Vector2"
        )
    end
    assert(options.Theme == nil or Theme.Themes[options.Theme], "Unknown window theme")
    local self = setmetatable({
        App = app,
        Maid = Cleanup.new(),
        Title = options.Title or "Aurelis",
        Options = options,
        Tabs = {},
        SelectedPage = nil,
        Visible = true,
        Minimized = false,
        Maximized = false,
        Closed = false,
        Destroyed = false,
        DrawerOpen = false,
        Scale = 1,
        MinimumSize = options.MinimumSize or Vector2.new(520, 340),
        ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
    }, Window)
    self.Window = self
    self.PageChanged = Signal.new()
    self.Maid:Give(self.PageChanged)
    self.Theme = Theme.new(app.Motion, options.Theme or "Eclipse")
    self.Maid:Give(self.Theme)
    local viewport = app.Root.AbsoluteSize
    self._pendingCenter = viewport.X < 1 or viewport.Y < 1
    local given = options.Size or UDim2.fromOffset(720, 480)
    self._size =
        Vector2.new(given.X.Offset + given.X.Scale * viewport.X, given.Y.Offset + given.Y.Scale * viewport.Y)
    self._position = Vector2.new(
        (viewport.X - self._size.X) / 2 + #app.Windows * 22,
        (viewport.Y - self._size.Y) / 2 + #app.Windows * 22
    )
    self.Root = Gui.new(self, "Frame", {
        Name = "AurelisWindow",
        Size = UDim2.fromOffset(self._size.X, self._size.Y),
        Position = UDim2.fromOffset(self._position.X, self._position.Y),
        Active = true,
    }, nil, app.Root)
    self.Maid:Give(self.Root)
    self.Launcher = Gui.button(
        self,
        app.Dock,
        self.Title .. "  ·  restore",
        { Size = UDim2.new(1, -4, 0, 34), BackgroundTransparency = 0.08, Visible = false, TextSize = 11 }
    )
    self.Maid:Give(self.Launcher)
    Gui.stroke(self, self.Launcher)
    self.Maid:Give(self.Launcher.Activated:Connect(function()
        self:Restore()
    end))
    self.UIScale = Gui.new(self, "UIScale", { Scale = 1 }, nil, self.Root)
    local shadow = Gui.new(self, "Frame", {
        Position = UDim2.fromOffset(2, 7),
        Size = UDim2.new(1, 2, 1, 2),
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0.72,
        ZIndex = 0,
    }, nil, self.Root)
    Gui.corner(self, shadow)
    self.Body = Gui.new(self, "CanvasGroup", {
        Name = "Shell",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = options.Acrylic and 0.06 or 0,
        GroupTransparency = 1,
        ZIndex = 1,
    }, { BackgroundColor3 = "Background" }, self.Root)
    Gui.corner(self, self.Body)
    Gui.stroke(self, self.Body, true)
    if options.Acrylic then
        Gui.new(
            self,
            "UIGradient",
            { Rotation = 75, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(219, 222, 236)) },
            nil,
            self.Body
        )
    end
    self.Titlebar = Gui.new(self, "Frame", { Size = UDim2.new(1, 0, 0, 46), Active = true }, nil, self.Body)
    local separator = Gui.new(
        self,
        "Frame",
        { Position = UDim2.new(0, 12, 1, -1), Size = UDim2.new(1, -24, 0, 1), BackgroundTransparency = 0.55 },
        { BackgroundColor3 = "Border" },
        self.Titlebar
    )
    separator.ZIndex = 2
    self.Logo = Gui.button(
        self,
        self.Titlebar,
        "",
        { Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(30, 30) }
    )
    Icons:Create(
        self,
        self.Logo,
        "sparkles",
        { Size = UDim2.fromOffset(17, 17), Position = UDim2.fromOffset(6, 6) },
        "Accent"
    )
    self.TitleLabel = Gui.label(self, self.Titlebar, self.Title, {
        Position = UDim2.fromOffset(48, 0),
        Size = UDim2.fromOffset(110, 46),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    self.Subtitle = Gui.label(self, self.Titlebar, options.Subtitle or "Universal Workspace", {
        Position = UDim2.fromOffset(165, 0),
        Size = UDim2.new(1, -360, 0, 46),
        TextSize = 10,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, "TextMuted")
    local function titleButton(icon, offset, callback)
        local button = Gui.button(
            self,
            self.Titlebar,
            "",
            { Position = UDim2.new(1, offset, 0, 8), Size = UDim2.fromOffset(28, 30) }
        )
        Icons:Create(
            self,
            button,
            icon,
            { Position = UDim2.fromOffset(7, 8), Size = UDim2.fromOffset(14, 14) }
        )
        self.Maid:Give(button.Activated:Connect(callback))
        return button
    end
    self.SearchButton = titleButton("search", -162, function()
        app.Search:Open(self)
    end)
    self.NotificationButton = titleButton("bell", -132, function()
        app.Notifications:Open(self, self.NotificationButton)
    end)
    titleButton("minus", -102, function()
        self:Minimize()
    end)
    titleButton("maximize", -72, function()
        self:Maximize()
    end)
    local close = titleButton("x", -42, function()
        self:Close()
    end)
    self.Maid:Give(close.MouseEnter:Connect(function()
        close.BackgroundColor3 = self.Theme.Tokens.Danger
    end))
    self.Maid:Give(close.MouseLeave:Connect(function()
        close.BackgroundColor3 = self.Theme.Tokens.SurfaceElevated
    end))
    self.PageHeader = Gui.label(self, self.Body, "Workspace", {
        Position = UDim2.fromOffset(204, 62),
        Size = UDim2.new(1, -224, 0, 26),
        TextSize = 20,
        Font = Enum.Font.GothamMedium,
    })
    self.BreadcrumbHost = Gui.new(
        self,
        "Frame",
        { Position = UDim2.fromOffset(204, 92), Size = UDim2.new(1, -224, 0, 26), ClipsDescendants = true },
        nil,
        self.Body
    )
    self.Breadcrumb = Breadcrumb.new(self, self.BreadcrumbHost)
    self.Maid:Give(self.Breadcrumb)
    self.ContentHost = Gui.new(
        self,
        "Frame",
        { Position = UDim2.fromOffset(204, 124), Size = UDim2.new(1, -220, 1, -166), ClipsDescendants = true },
        nil,
        self.Body
    )
    self.DrawerShade = Gui.new(self, "TextButton", {
        Position = UDim2.fromOffset(0, 46),
        Size = UDim2.new(1, 0, 1, -46),
        BackgroundColor3 = Color3.new(),
        BackgroundTransparency = 0.5,
        Visible = false,
        ZIndex = 4,
    }, nil, self.Body)
    self.Maid:Give(self.DrawerShade.Activated:Connect(function()
        self:ToggleSidebar(false)
    end))
    self.Sidebar = Sidebar.new(self)
    self.Maid:Give(self.Sidebar)
    self.Maid:Give(self.Logo.Activated:Connect(function()
        if self.Breakpoint == "Mobile" then
            self:ToggleSidebar()
        else
            self.Sidebar:SetCollapsed(not self.Sidebar.Collapsed)
        end
    end))
    local status = Gui.new(self, "Frame", {
        Position = UDim2.new(0, 16, 1, -29),
        Size = UDim2.new(1, -32, 0, 22),
        Visible = options.StatusBar ~= false,
    }, nil, self.Body)
    self.StatusHost = status
    local statusText =
        Gui.label(self, status, "Ready", { Size = UDim2.new(0.46, 0, 1, 0), TextSize = 10 }, "TextMuted")
    local details = Gui.label(self, status, "v1.0.0", {
        Position = UDim2.fromScale(0.46, 0),
        Size = UDim2.fromScale(0.54, 1),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, "TextMuted")
    self.StatusBar = { Values = { Status = "Ready", Version = "1.0.0" } }
    function self.StatusBar:Set(values)
        for key, value in pairs(values) do
            self.Values[key] = value
        end
        statusText.Text = tostring(self.Values.Status or "")
        local parts = {}
        if self.Values.FPS then
            table.insert(parts, tostring(self.Values.FPS) .. " FPS")
        end
        if self.Values.Latency then
            table.insert(parts, tostring(self.Values.Latency) .. " ms")
        end
        if self.Values.Version then
            table.insert(parts, "v" .. tostring(self.Values.Version))
        end
        details.Text = table.concat(parts, "    ")
    end
    local resize = Gui.new(
        self,
        "TextButton",
        { Position = UDim2.new(1, -28, 1, -28), Size = UDim2.fromOffset(28, 28), ZIndex = 8 },
        nil,
        self.Body
    )
    self.ResizeHandle = resize
    Icons:Create(
        self,
        resize,
        "resize",
        { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(13, 13) }
    )
    self.Maid:Give(resize.InputBegan:Connect(function(input)
        if self.Maximized or self.Minimized or app.Modal.Active then
            return
        end
        self:Focus()
        local origin = app.Input:Position(input)
        local size = self._size
        app.Input:Track(self, input, function(point)
            self._size = size + (point - origin) / self.Scale
            self:_geometry()
        end)
    end))
    local lastClick = -math.huge
    self.Maid:Give(self.Titlebar.InputBegan:Connect(function(input)
        if
            input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end
        if app.Modal.Active then
            return
        end
        local point = app.Input:Position(input)
        if point.X > self.Root.AbsolutePosition.X + self.Root.AbsoluteSize.X - 174 * self.Scale then
            return
        end
        if app.Input:Contains(self.Logo, point) then
            return
        end
        self:Focus()
        local now = os.clock()
        if now - lastClick < 0.3 then
            lastClick = 0
            self:Maximize()
            return
        end
        lastClick = now
        if self.Maximized then
            self:Restore()
        end
        local start = app.Input:Position(input)
        local origin = self._position
        app.Input:Track(self, input, function(position)
            self._position = origin + (position - start) / self.Scale
            self:_geometry()
        end, function(position)
            local screen = app.Root.AbsoluteSize
            if position.Y < 16 then
                self:Maximize()
            elseif position.X < 16 then
                self:Snap("Left")
            elseif position.X > screen.X - 16 then
                self:Snap("Right")
            end
        end)
    end))
    self.Maid:Give(app.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:_geometry()
    end))
    self.Maid:Give(self.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:_layout(false)
    end))
    self.Maid:Give(self.Theme.Changed:Connect(function()
        self.Sidebar:Refresh()
        self.Body.BackgroundTransparency = options.Acrylic and math.max(0.04, self.Theme.Tokens.Transparency)
            or self.Theme.Tokens.Transparency
    end))
    self.Maid:Give(function()
        app.Input:Cancel(self)
        if
            app.Overlay.Active
            and (app.Overlay.Active.Owner == self or app.Overlay.Active.Context.Window == self)
        then
            app.Overlay:Close("WindowDestroyed")
        end
        for _, tab in ipairs(table.clone(self.Tabs)) do
            tab:Destroy()
        end
        Table.removeValue(app.Windows, self)
        app:_updateDock()
        if app.FocusedWindow == self then
            app.FocusedWindow = nil
        end
        app:_updateBlur()
    end)
    self.Maid:Give(self.Root.Destroying:Connect(function()
        self:Destroy()
    end))
    self:_geometry()
    self:_layout(false)
    app.Motion:Tween(self.Body, { GroupTransparency = 0 }, "Slow")
    return self
end
function Window:_geometry()
    local viewport = self.App.Root.AbsoluteSize / self.Scale
    if viewport.X < 1 or viewport.Y < 1 then
        return
    end
    if self._pendingCenter then
        self._pendingCenter = false
        self._position = (viewport - self._size) / 2
    end
    if self.Maximized then
        self._position = Vector2.new(8, 8)
        self._size = viewport - Vector2.new(16, 16)
    end
    self._position, self._size = Responsive.geometry(self._position, self._size, viewport, self.MinimumSize)
    self.Root.Position = UDim2.fromOffset(self._position.X * self.Scale, self._position.Y * self.Scale)
    self.Root.Size = UDim2.fromOffset(self._size.X, self.Minimized and 46 or self._size.Y)
    self:_layout(false)
    self.App:_updateDock()
end
function Window:_layout(animate)
    if not self.Sidebar then
        return
    end
    local viewport = self.App.Root.AbsoluteSize.X
    local width = self._size.X
    local breakpoint = Responsive.breakpoint(math.min(viewport, width))
    if self.Breakpoint ~= breakpoint then
        self.Breakpoint = breakpoint
        self.Sidebar.Collapsed = breakpoint == "Compact"
        self.DrawerOpen = false
    end
    local mobile = breakpoint == "Mobile"
    local sidebarWidth = mobile and math.min(220, width - 36) or self.Sidebar.Collapsed and 54 or 174
    local left = mobile and 16 or sidebarWidth + 30
    local sidebarProps = {
        Size = UDim2.new(0, sidebarWidth, 1, -104),
        Position = UDim2.fromOffset(mobile and not self.DrawerOpen and -sidebarWidth - 12 or 12, 60),
    }
    self.Sidebar.Root.Visible = not self.Minimized and (not mobile or self.DrawerOpen)
    self.DrawerShade.Visible = mobile and self.DrawerOpen and not self.Minimized
    self.PageHeader.Visible = not self.Minimized
    self.ContentHost.Visible = not self.Minimized
    self.BreadcrumbHost.Visible = not self.Minimized
    if self.StatusHost then
        self.StatusHost.Visible = not self.Minimized and self.Options.StatusBar ~= false
    end
    if self.ResizeHandle then
        self.ResizeHandle.Visible = not self.Minimized and not self.Maximized
    end
    self.Subtitle.Visible = width >= 620
    self.TitleLabel.Size = UDim2.fromOffset(math.max(45, math.min(110, width - 234)), 46)
    local function set(object, props)
        if animate then
            self.App.Motion:Tween(object, props, "Normal")
        else
            for key, value in pairs(props) do
                object[key] = value
            end
        end
    end
    set(self.Sidebar.Root, sidebarProps)
    set(self.PageHeader, { Position = UDim2.fromOffset(left, 62), Size = UDim2.new(1, -left - 16, 0, 26) })
    set(
        self.BreadcrumbHost,
        { Position = UDim2.fromOffset(left, 92), Size = UDim2.new(1, -left - 16, 0, 26) }
    )
    set(self.ContentHost, {
        Position = UDim2.fromOffset(left, 124),
        Size = UDim2.new(1, -left - 16, 1, -(self.Options.StatusBar == false and 140 or 166)),
    })
    self.Sidebar:Refresh()
end
function Window:AddTab(options)
    assert(not self.Destroyed, "Window is destroyed")
    options = options or {}
    self.App.Icons:Get(options.Icon or "folder")
    local tab = Tab.new(self, options or {})
    table.insert(self.Tabs, tab)
    self.Sidebar:Add(tab)
    if not self.SelectedPage then
        self:SelectTab(tab)
    end
    return tab
end
function Window:SelectTab(target)
    local found = nil
    local function visit(pages)
        for _, page in ipairs(pages) do
            if page == target or page.Id == target or page.Title == target then
                found = page
                return
            end
            visit(page.Pages)
            if found then
                return
            end
        end
    end
    visit(self.Tabs)
    if not found or found.Destroyed then
        return false
    end
    if self.SelectedPage then
        self.SelectedPage.Root.Visible = false
    end
    self.SelectedPage = found
    found.Root.Visible = true
    found.Root.GroupTransparency = 1
    self.App.Motion:Tween(found.Root, { GroupTransparency = 0 }, "Normal")
    self.PageHeader.Text = found.Title
    self.Breadcrumb:Set(found)
    self.Sidebar:Refresh()
    self:ToggleSidebar(false)
    self.PageChanged:Fire(found)
    return true
end
function Window:ToggleSidebar(open)
    self.DrawerOpen = open == nil and not self.DrawerOpen or open == true
    self:_layout(true)
end
function Window:Focus()
    self.App:Focus(self)
    return self
end
function Window:SetVisible(visible)
    self.Visible = visible == true
    self.Root.Visible = self.Visible
    if self.Visible then
        self.Closed = false
    end
    if not self.Visible then
        local overlay = self.App.Overlay.Active
        if overlay and overlay.Context.Window == self then
            self.App.Overlay:Close("WindowHidden")
        end
        self.App.Tooltips:Hide()
        self.App.Input:CancelWindow(self)
    end
    self.App:_updateBlur()
    self.App:_updateDock()
    return self
end
function Window:Hide()
    return self:SetVisible(false)
end
function Window:Show()
    self.Closed = false
    self:SetVisible(true)
    self:Focus()
    return self
end
function Window:Close()
    self.Closed = true
    return self:Hide()
end
function Window:Minimize()
    if self.Minimized then
        return self:Restore()
    end
    self.Minimized = true
    self.App.Overlay:Close("WindowMinimized")
    self:_geometry()
    self.App:_updateBlur()
    return self
end
function Window:Maximize()
    if self.Maximized then
        return self:Restore()
    end
    self._restore = { Position = self._position, Size = self._size }
    self.Maximized = true
    self.Minimized = false
    self:_geometry()
    self:Show()
    return self
end
function Window:Restore()
    self.Maximized = false
    self.Minimized = false
    if self._restore then
        self._position = self._restore.Position
        self._size = self._restore.Size
        self._restore = nil
    end
    self:_geometry()
    self:Show()
    return self
end
function Window:Snap(side)
    assert(side == "Left" or side == "Right", "Snap expects Left or Right")
    if not self._restore then
        self._restore = { Position = self._position, Size = self._size }
    end
    self.Maximized = false
    self.Minimized = false
    local viewport = self.App.Root.AbsoluteSize / self.Scale
    if viewport.X < self.MinimumSize.X * 2 + 24 then
        self:Maximize()
        return self
    end
    local half = (viewport.X - 24) / 2
    self._size = Vector2.new(half, viewport.Y - 16)
    self._position = Vector2.new(side == "Left" and 8 or half + 16, 8)
    self:_geometry()
    return self
end
function Window:SetScale(scale)
    assert(type(scale) == "number" and scale == scale, "Invalid scale")
    self.Scale = math.clamp(scale, 0.65, 1.5)
    self.UIScale.Scale = self.Scale
    self:_geometry()
    return self
end
function Window:SetTheme(theme)
    self.Theme:Set(theme)
    return self
end
function Window:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Maid:Destroy()
end
return Window
