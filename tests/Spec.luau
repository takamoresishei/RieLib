local passed, failed = 0, 0
local function expect(condition, message)
    assert(condition, message or "Expectation failed")
end
local function equal(a, b, message)
    expect(__require("Aurelis/Utility/Table").equal(a, b), message or (tostring(a) .. " ~= " .. tostring(b)))
end
local function test(name, callback)
    local ok, message = pcall(callback)
    if ok then
        passed += 1
        print("PASS " .. name)
    else
        failed += 1
        print("FAIL " .. name .. "\n  " .. tostring(message))
    end
end
local State = __require("Aurelis/Core/State")
local Cleanup = __require("Aurelis/Core/Cleanup")
local Application = __require("Aurelis/Core/Application")
local Math = __require("Aurelis/Utility/Math")
local function workspace(callback)
    local app = Application.new()
    local window = app:CreateWindow({ Title = "Tests", Blur = true })
    local tab = window:AddTab({ Title = "Player", Icon = "user" })
    local section = tab:AddSection({ Title = "Movement", Collapsible = true })
    local ok, message = pcall(callback, app, window, section, tab)
    app:Destroy()
    Mock.step(0)
    if not ok then
        error(message, 2)
    end
    expect(Cleanup.Stats.Resources == 0, "Leaked tracked resources: " .. Cleanup.Stats.Resources)
    expect(Cleanup.Stats.Connections == 0, "Leaked tracked connections: " .. Cleanup.Stats.Connections)
end

test("reactive state and dynamic computed dependencies", function()
    local select = State.new(true)
    local a = State.new(10)
    local b = State.new(20)
    local display = State.computed(function()
        return select:Get() and a:Get() or b:Get()
    end)
    local notifications = 0
    local connection = display:Subscribe(function()
        notifications += 1
    end)
    equal(display:Get(), 10)
    a:Set(11)
    equal(display:Get(), 11)
    select:Set(false)
    equal(display:Get(), 20)
    a:Set(12)
    equal(notifications, 3)
    b:Set(21)
    equal(display:Get(), 21)
    connection:Disconnect()
    display:Destroy()
    a:Destroy()
    b:Destroy()
    select:Destroy()
end)
test("signal disconnect during dispatch", function()
    local signal = __require("Aurelis/Utility/Signal").new()
    local calls = 0
    local listener
    listener = signal:Connect(function()
        calls += 1
        listener:Disconnect()
    end)
    signal:Fire()
    signal:Fire()
    equal(calls, 1)
    signal:Destroy()
end)
test("cleanup idempotence and late resource release", function()
    local maid = Cleanup.new()
    local count = 0
    maid:Give(function()
        count += 1
    end)
    maid:Destroy()
    maid:Destroy()
    maid:Give(function()
        count += 1
    end)
    equal(count, 2)
    equal(Cleanup.Stats.Resources, 0)
end)
test("slider numeric bounds and increment are stable", function()
    equal(Math.round(17.8, 10, 30, 0.5), 18)
    equal(Math.round(-500, 10, 30, 1), 10)
    equal(Math.round(99, 10, 30, 3), 30)
    expect(not pcall(Math.round, 1, 0, 5, 0))
    expect(not pcall(Math.round, 1, 5, 0, 1))
    for index = -1000, 1000 do
        local value = Math.round(index / 7, -4, 37, 0.25)
        expect(value >= -4 and value <= 37)
    end
end)
test("fuzzy search ranks contiguous word starts", function()
    expect(Math.fuzzy("spd", "Player Movement Speed") ~= nil)
    equal(Math.fuzzy("zzq", "Speed"), nil)
    expect(Math.fuzzy("speed", "Speed") > Math.fuzzy("speed", "Session progress editor"))
end)
test("flags retain false, reject duplicates and normalize updates", function()
    workspace(function(app, _, section)
        local toggle = section:AddToggle({ Title = "Enabled", Flag = "enabled", Default = false })
        equal(app.Flags.enabled, false)
        equal(app:GetValue("enabled"), false)
        app.Flags.enabled = true
        equal(toggle:GetValue(), true)
        expect(not app:SetValue("enabled", "yes"))
        equal(toggle:GetValue(), true)
        expect(not pcall(function()
            section:AddToggle({ Flag = "enabled" })
        end))
    end)
end)
test("all value components normalize and update at runtime", function()
    workspace(function(app, _, section)
        local slider = section:AddSlider({ Min = 0, Max = 100, Increment = 5, Default = 50, Flag = "speed" })
        slider:SetValue(73)
        equal(slider:GetValue(), 75)
        slider:SetValue(200)
        equal(slider:GetValue(), 100)
        expect(not slider:SetValue(0 / 0))
        local range = section:AddRangeSlider({ Min = 0, Max = 100, Default = { 80, 20 } })
        equal(range:GetValue(), { 20, 80 })
        range:SetValue({ -10, 300 })
        equal(range:GetValue(), { 0, 100 })
        local segmented = section:AddSegmented({ Values = { "A", "B" } })
        segmented:SetValue("B")
        equal(segmented:GetValue(), "B")
        expect(not segmented:SetValue("C"))
        local progress = section:AddProgress({})
        progress:SetValue(3)
        equal(progress:GetValue(), 1)
        local color = section:AddColorPicker({ Flag = "color" })
        color:SetValue(Color3.fromRGB(120, 90, 255))
        color:SetAlpha(0.3)
        equal(color:GetValue(), Color3.fromRGB(120, 90, 255))
        equal(app:GetValue("color.alpha"), 0.3)
        local label = section:AddLabel({ Value = "Ready" })
        local status = State.new("Ready")
        label:Bind(status)
        status:Set("Running")
        equal(label:GetValue(), "Running")
        status:Destroy()
        local chart = section:AddChart({ Values = { 1, 3, 2 } })
        chart:SetValue({ 3, 4 })
        equal(chart:GetValue(), { 3, 4 })
        local button = section:AddButton({
            Title = "Run",
            Callback = function()
                app.Flags.speed = 5
            end,
        })
        button:SetLoading(true)
        button:Activate()
        equal(app.Flags.speed, 100)
        button:SetLoading(false)
        button:Activate()
        equal(app.Flags.speed, 5)
    end)
end)
test("component common lifecycle and update API", function()
    workspace(function(app, _, section)
        local component = section:AddToggle({
            Title = "Old",
            Description = "Details",
            Icon = "home",
            Tooltip = "Help",
            Flag = "test",
        })
        component:Update({
            Title = "New",
            Description = "Changed",
            Icon = "settings",
            Tooltip = "More",
            Disabled = true,
            Visible = false,
        })
        equal(component.Title, "New")
        expect(component.Disabled)
        expect(not component.Root.Visible)
        component:SetDisabled(false)
        component:SetVisible(true)
        component:SetValue(true)
        component:Reset()
        equal(component:GetValue(), false)
        component:Destroy()
        component:Destroy()
        equal(app:GetValue("test"), nil)
    end)
end)
test("dropdown search, multi selection, keyboard and replacement", function()
    workspace(function(app, _, section)
        local dropdown = section:AddDropdown({
            Title = "Mode",
            Values = { "Normal", "Balanced", "Performance" },
            Default = "Balanced",
        })
        dropdown:Open()
        expect(app.Overlay.Active ~= nil)
        Mock.press(Enum.KeyCode.Down)
        Mock.press(Enum.KeyCode.Return)
        equal(dropdown:GetValue(), "Balanced")
        expect(app.Overlay.Active == nil)
        dropdown:SetValues({ "New", "Other" })
        equal(dropdown:GetValue(), "New")
        local multi = section:AddDropdown({ Multi = true, Values = { "A", "B" }, Default = { "A" } })
        multi:SetValue({ "A", "B", "B" })
        equal(multi:GetValue(), { "A", "B" })
        multi:SetValues({ "B" })
        equal(multi:GetValue(), { "B" })
        dropdown:Open()
        local first = app.Overlay.Active
        multi:Open()
        expect(first.Maid._dead)
        expect(app.Overlay.Active.Owner == multi)
        multi:SetDisabled(true)
        expect(app.Overlay.Active == nil)
        dropdown:SetValues({})
        equal(dropdown:GetValue(), "")
    end)
end)
test("text validation, password presentation and numeric input", function()
    workspace(function(_, _, section)
        local input = section:AddInput({
            Default = "OK",
            Live = true,
            CharacterLimit = 5,
            Validate = function(value)
                return #value >= 2, "Too short"
            end,
        })
        input.Field:CaptureFocus()
        input.Field.Text = "x"
        equal(input:GetValue(), "OK")
        equal(input.ErrorLabel.Text, "Too short")
        input.Field.Text = "abcdef"
        equal(input:GetValue(), "abcde")
        local numeric = section:AddInput({ Type = "Number", Default = 5, Min = 1, Max = 10, Live = true })
        numeric.Field:CaptureFocus()
        numeric.Field.Text = "bad"
        equal(numeric:GetValue(), 5)
        numeric.Field.Text = "8"
        equal(numeric:GetValue(), 8)
        local password = section:AddInput({ Type = "Password", Default = "secret" })
        equal(password.Field.TextTransparency, 1)
    end)
end)
test("keybind toggle, hold, always, capture and text focus", function()
    workspace(function(app, _, section)
        local active = false
        local bind = section:AddKeybind({
            Default = Enum.KeyCode.F6,
            Mode = "Toggle",
            Callback = function(value)
                active = value
            end,
        })
        Mock.press(Enum.KeyCode.F6)
        expect(active)
        Mock.press(Enum.KeyCode.F6)
        expect(not active)
        bind:SetMode("Hold")
        Mock.press(Enum.KeyCode.F6)
        expect(active)
        Mock.release(Enum.KeyCode.F6)
        expect(not active)
        bind:SetMode("Always")
        expect(active)
        bind:SetDisabled(true)
        expect(not active)
        bind:SetDisabled(false)
        expect(active)
        bind:SetMode("Toggle")
        local text = section:AddInput({})
        text.Field:CaptureFocus()
        Mock.press(Enum.KeyCode.F6)
        expect(not active)
        text.Field:ReleaseFocus()
        bind.Listening = true
        Mock.press(Enum.KeyCode.F7)
        equal(bind:GetValue().Key, Enum.KeyCode.F7)
        expect(not bind.Listening)
        app:Dialog({ Title = "Focus guard" })
        Mock.press(Enum.KeyCode.F7)
        expect(not active)
        Mock.press(Enum.KeyCode.Escape)
        expect(app.Modal.Active == nil)
    end)
end)
test("config round trip preserves typed flags and alpha", function()
    workspace(function(app, _, section)
        local toggle = section:AddToggle({ Flag = "enabled", Default = false })
        local slider = section:AddSlider({ Flag = "speed", Default = 5, Max = 100 })
        local color =
            section:AddColorPicker({ Flag = "color", Default = Color3.fromRGB(12, 34, 56), Alpha = 0.4 })
        local key = section:AddKeybind({ Flag = "key", Default = Enum.KeyCode.F6 })
        expect(app.Config:Save("Default"))
        toggle:SetValue(true)
        slider:SetValue(90)
        color:SetAlpha(1)
        key:SetKey(Enum.KeyCode.F7)
        local ok, report = app.Config:Load("Default")
        expect(ok)
        expect(#report.Applied == 5)
        equal(toggle:GetValue(), false)
        equal(slider:GetValue(), 5)
        equal(color:GetAlpha(), 0.4)
        equal(key:GetValue().Key, Enum.KeyCode.F6)
        expect(app.Config:Rename("Default", "Main"))
        equal(app.Config:List(), { "Main" })
        expect(app.Config:Delete("Main"))
        equal(app.Config:List(), {})
        expect(not app.Config:Save("../escape"))
        expect(not app.Config:Load("missing"))
    end)
end)
test("configs skip invalid values and reject future schemas", function()
    workspace(function(app, _, section)
        section:AddToggle({ Flag = "enabled", Default = false })
        section:AddSlider({ Flag = "speed", Min = 0, Max = 100, Default = 10 })
        local ok, report = app.Config:Import('{"Flags":{"enabled":"wrong","speed":500,"unknown":true}}')
        expect(ok)
        equal(#report.Skipped, 2)
        equal(app.Flags.enabled, false)
        equal(app.Flags.speed, 100)
        expect(not app.Config:Import('{"SchemaVersion":999,"Flags":{}}'))
        expect(not app.Config:Import("broken"))
    end)
end)
test("configuration rename protects existing destination", function()
    workspace(function(app)
        expect(app.Config:Save("One"))
        expect(app.Config:Save("Two"))
        expect(not app.Config:Rename("One", "Two"))
        equal(app.Config:List(), { "One", "Two" })
    end)
end)
test("theme token updates preserve component instances", function()
    workspace(function(app, window, section)
        local toggle = section:AddToggle({ Default = true })
        local root = toggle.Root
        for _, name in ipairs({ "Eclipse", "Obsidian", "Graphite", "Tokyo", "OLED", "Frost", "Light" }) do
            window:SetTheme(name)
        end
        expect(toggle.Root == root)
        equal(toggle:GetValue(), true)
        window:SetTheme({ Accent = Color3.fromRGB(1, 2, 3), Radius = 14 })
        equal(window.Theme.Tokens.Radius, 14)
        expect(not pcall(function()
            window:SetTheme({ Radius = 0 / 0 })
        end))
        expect(#app.Icons:List() >= 50)
    end)
end)
test("color editor opens and closes with no retained pointer scope", function()
    workspace(function(app, _, section)
        local color = section:AddColorPicker({ Default = Color3.fromRGB(120, 90, 255) })
        color:Open()
        expect(app.Overlay.Active.Owner == color)
        app.Overlay:Close("Escape")
        equal(#color.Recent, 1)
        color:Open()
        color:Destroy()
        expect(app.Overlay.Active == nil)
    end)
end)
test("commands and global search navigate nested pages and sections", function()
    workspace(function(app, window, _, tab)
        local nested = tab:AddPage({ Title = "Movement", Icon = "move" })
        local section = nested:AddSection({ Title = "Controls", Collapsible = true, Collapsed = true })
        local slider = section:AddSlider({ Title = "Speed", Min = 0, Max = 100, Default = 16 })
        local results = app.Search:Query("speed", window)
        equal(#results, 1)
        results[1].Callback()
        Mock.step(0)
        expect(window.SelectedPage == nested)
        expect(not section.Collapsed)
        expect(slider.Root.Visible)
        local count = 0
        local command = app.Commands:Register({
            Name = "Open Settings",
            Keywords = { "configuration" },
            Callback = function()
                count += 1
            end,
        })
        app.Commands:Search("opset")[1].Callback()
        equal(count, 1)
        command:Destroy()
        equal(#app.Commands:Search("opset"), 0)
    end)
end)
test("notification history survives toast expiration and clears", function()
    workspace(function(app)
        for index = 1, 6 do
            app:Notify({ Title = tostring(index), Duration = 1, Type = "Success" })
        end
        equal(#app.Notifications.Toasts, 4)
        equal(#app.NotificationCenter.History, 6)
        Mock.step(2)
        equal(#app.Notifications.Toasts, 0)
        equal(#app.NotificationCenter.History, 6)
        app.NotificationCenter:Clear()
        equal(#app.NotificationCenter.History, 0)
    end)
end)
test("modals validate, confirm, cancel and release keyboard focus", function()
    workspace(function(app)
        local value = nil
        local modal = app:Dialog({
            Title = "Name",
            Kind = "Input",
            Default = "hi",
            Validate = function(text)
                return #text >= 2
            end,
            OnConfirm = function(text)
                value = text
            end,
        })
        expect(app.Modal.Active == modal)
        expect(Mock.focused ~= nil)
        modal.Confirm()
        equal(value, "hi")
        expect(app.Modal.Active == nil)
        expect(Mock.focused == nil)
        local cancel = app:Dialog({ Kind = "Destructive", Critical = true })
        Mock.press(Enum.KeyCode.Escape)
        expect(app.Modal.Active == cancel)
        cancel:Close()
        expect(app.Modal.Active == nil)
    end)
end)
test("responsive window geometry, focus, snap, minimize and restore", function()
    workspace(function(app, window)
        local second = app:CreateWindow({ Title = "Other" })
        expect(app.FocusedWindow == second)
        window:Focus()
        expect(window.Root.ZIndex > second.Root.ZIndex)
        local size = window._size
        window:Maximize()
        expect(window.Maximized)
        window:Restore()
        equal(window._size, size)
        window:Minimize()
        expect(window.Minimized)
        window:Restore()
        expect(not window.Minimized)
        window:Close()
        expect(not window.Visible)
        window:Restore()
        expect(window.Visible)
        window:Snap("Left")
        expect(window._position.X >= 8)
        Mock.viewport = Vector2.new(390, 760)
        window:_geometry()
        equal(window.Breakpoint, "Mobile")
        expect(window._size.X <= 374)
        window:ToggleSidebar(true)
        expect(window.DrawerShade.Visible)
        window:SetScale(0.8)
        expect(
            window.Root.AbsoluteSize.X + window.Root.AbsolutePosition.X <= Mock.viewport.X,
            "Scaled window leaves viewport"
        )
        Mock.viewport = Vector2.new(1280, 800)
    end)
end)
test("performance monitor is demand driven and stops on release", function()
    workspace(function(app)
        equal(app.Performance.Users, 0)
        app:SetDeveloperOverlay(true)
        equal(app.Performance.Users, 1)
        Mock.step(1)
        expect(app.Performance.Latest.Instances > 0)
        app:SetDeveloperOverlay(false)
        equal(app.Performance.Users, 0)
        expect(app.Performance._scope == nil)
    end)
end)
test("150 controls / 10 tabs / 30 sections remain independently addressable", function()
    workspace(function(app, window)
        for i = 1, 10 do
            local tab = window:AddTab({ Title = "Tab " .. i, Icon = "grid" })
            for j = 1, 3 do
                local section = tab:AddSection({ Title = "Section " .. j, Collapsible = true })
                for k = 1, 5 do
                    section:AddSlider({
                        Title = "Control " .. k,
                        Flag = i .. "." .. j .. "." .. k,
                        Min = 0,
                        Max = 100,
                        Default = k,
                    })
                end
            end
        end
        local count = 0
        for _ in pairs(app.FlagStore:Snapshot()) do
            count += 1
        end
        equal(count, 150)
        local snapshot = app.Config:Export()
        expect(app.Config:Import(snapshot))
        app:SetValue("10.3.5", 87)
        equal(app:GetValue("10.3.5"), 87)
    end)
end)
test("full showcase builds, navigates, exports and destroys", function()
    local app = Application.new()
    local window = nil
    local ok, message = pcall(function()
        window = __require("Aurelis/Demo/Showcase")(app)
        equal(#window.Tabs, 7)
        window:SelectTab("Settings")
        expect(app.Config:Save("Showcase"))
        expect(app.Config:Load("Showcase"))
        window:SelectTab("Developer")
        Mock.step(1)
        window:SelectTab("Dashboard")
        app:OpenCommandPalette()
        Mock.press(Enum.KeyCode.Down)
        Mock.press(Enum.KeyCode.Escape)
    end)
    app:Destroy()
    Mock.step(1)
    if not ok then
        error(message)
    end
    equal(Cleanup.Stats.Resources, 0)
    equal(Cleanup.Stats.Connections, 0)
end)
test("input objects and raw mouse positions use the correct inset spaces", function()
    workspace(function(app)
        local previous = services.GuiService.GetGuiInset
        services.GuiService.GetGuiInset = function()
            return Vector2.new(0, 36), Vector2.new()
        end
        equal(app.Input:Position({ Position = Vector3.new(80, 90, 0) }), Vector2.new(80, 90))
        equal(app.Input:Position(), Vector2.new(100, 64))
        services.GuiService.GetGuiInset = previous
    end)
end)
test("constructor failure rolls back rows and owned resources", function()
    workspace(function(app, window, section)
        local before = Cleanup.Stats.Resources
        expect(not pcall(function()
            section:AddToggle({ Icon = "not-an-icon" })
        end))
        expect(not pcall(function()
            section:AddSlider({ Min = 10, Max = 0 })
        end))
        expect(not pcall(function()
            section:AddSection({ Icon = "missing" })
        end))
        equal(#section.Components, 0)
        equal(Cleanup.Stats.Resources, before)
        local windows = #app.Windows
        expect(not pcall(function()
            app:CreateWindow({ Theme = "Missing" })
        end))
        equal(#app.Windows, windows)
    end)
end)
test("theme changes do not cancel independent size animations", function()
    workspace(function(app, _, section)
        local object = section.Root
        app.Motion:Cancel(object)
        app.Motion:Tween(object, { Size = UDim2.fromOffset(200, 100) }, "Normal")
        app.Motion:Tween(object, { BackgroundTransparency = 0.2 }, "Fast")
        local count = 0
        for _ in pairs(app.Motion._active[object]) do
            count += 1
        end
        equal(count, 2)
        app.Motion:Tween(object, { BackgroundTransparency = 0.5 }, "Fast")
        count = 0
        for _ in pairs(app.Motion._active[object]) do
            count += 1
        end
        equal(count, 2)
        app.Motion:Cancel(object)
        expect(app.Motion._active[object] == nil)
    end)
end)
test("modal confirmation can open a second modal", function()
    workspace(function(app)
        local second = nil
        local first = app:Dialog({
            Title = "First",
            OnConfirm = function()
                second = app:Dialog({ Title = "Second" })
            end,
        })
        first.Confirm()
        expect(app.Modal.Active == second)
        expect(second ~= nil)
    end)
end)
test("hidden and minimized windows can be restored by touch launcher", function()
    workspace(function(app, window)
        window:Hide()
        expect(window.Launcher.Visible)
        expect(app.Dock.Visible)
        window.Launcher.Activated:Fire()
        expect(window.Visible)
        expect(not window.Launcher.Visible)
        window:Minimize()
        expect(window.Launcher.Visible)
        expect(not window.StatusHost.Visible)
        expect(not window.ResizeHandle.Visible)
        window.Launcher.Activated:Fire()
        expect(not window.Minimized)
        expect(window.StatusHost.Visible)
    end)
end)
test("layout notifications converge and sections measure their content", function()
    workspace(function(_, window, section)
        section:AddSlider({
            Title = "Speed",
            Default = 16,
            Description = "A description that wraps to fit compact space.",
        })
        Mock.layout()
        expect(section.Root.Size.Y.Offset > 44)
        section:SetCollapsed(true)
        equal(section.Root.Size.Y.Offset, 44)
        section:SetCollapsed(false)
        expect(section.Root.Size.Y.Offset > 44)
        window:SetScale(0.8)
        Mock.layout()
        expect(section.Root.Size.Y.Offset > 44)
    end)
end)
test("title hit target drags with mouse and releases its pointer", function()
    workspace(function(app, window)
        local origin = window._position
        local point = window.Root.AbsolutePosition + Vector2.new(70, 22)
        expect(app.Input:Contains(window.DragHandle, point), "Title text is outside drag hit target")
        local searchPoint = window.SearchButton.AbsolutePosition + Vector2.new(8, 8)
        expect(not app.Input:Contains(window.DragHandle, searchPoint), "Drag target covers a title button")
        local down = {
            UserInputType = Enum.UserInputType.MouseButton1,
            KeyCode = Enum.KeyCode.Unknown,
            Position = Vector3.new(point.X, point.Y, 0),
        }
        window.DragHandle.InputBegan:Fire(down)
        services.UserInputService.InputChanged:Fire({
            UserInputType = Enum.UserInputType.MouseMovement,
            Position = Vector3.new(point.X + 80, point.Y + 40, 0),
        })
        equal(window._position, origin + Vector2.new(80, 40))
        down.Position = Vector3.new(point.X + 80, point.Y + 40, 0)
        services.UserInputService.InputEnded:Fire(down)
        expect(app.Input._pointer == nil)
        local stopped = window._position
        services.UserInputService.InputChanged:Fire({
            UserInputType = Enum.UserInputType.MouseMovement,
            Position = Vector3.new(point.X + 120, point.Y + 80, 0),
        })
        equal(window._position, stopped, "Window moved after mouse release")
    end)
end)
test("touch dragging tracks one finger at scale and keeps compact size at edges", function()
    workspace(function(app, window)
        window:SetScale(0.8)
        local origin, size = window._position, window._size
        local point = window.Root.AbsolutePosition + Vector2.new(70, 18)
        local touch = {
            UserInputType = Enum.UserInputType.Touch,
            KeyCode = Enum.KeyCode.Unknown,
            Position = Vector3.new(point.X, point.Y, 0),
        }
        window.DragHandle.InputBegan:Fire(touch)
        services.UserInputService.InputChanged:Fire({
            UserInputType = Enum.UserInputType.Touch,
            Position = Vector3.new(point.X + 160, point.Y + 80, 0),
        })
        equal(window._position, origin, "A second finger moved the window")
        touch.Position = Vector3.new(point.X + 40, point.Y + 24, 0)
        services.UserInputService.InputChanged:Fire(touch)
        equal(window._position, origin + Vector2.new(50, 30))
        touch.Position = Vector3.new(2, 2, 0)
        services.UserInputService.InputChanged:Fire(touch)
        services.UserInputService.InputEnded:Fire(touch)
        equal(window._size, size)
        expect(not window.Maximized, "A touch drag unexpectedly maximized the window")
        expect(app.Input._pointer == nil)
    end)
end)
test("compact startup leaves drag room on phone portrait and landscape viewports", function()
    workspace(function(app)
        local previous = Mock.viewport
        local ok, message = pcall(function()
            Mock.viewport = Vector2.new(844, 390)
            local window = app:CreateWindow({ Title = "Phone" })
            expect(window._size.X <= 600 and window._size.Y <= 319)
            expect(window._position.Y > 8, "Landscape window leaves no vertical drag room")
            Mock.viewport = Vector2.new(390, 760)
            app.Root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
            expect(window._size.X <= 320)
            expect(window.Root.AbsoluteSize.X + window.Root.AbsolutePosition.X <= 382)
        end)
        Mock.viewport = previous
        if not ok then
            error(message)
        end
    end)
end)
print(string.format("\n%d passed; %d failed", passed, failed))
if failed > 0 then
    error("Aurelis test failures: " .. failed)
end
