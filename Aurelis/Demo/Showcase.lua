--!nonstrict
-- A complete client demonstration. Player/Visuals are workspace settings; no game remotes or gameplay hooks.
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Showcase = function(Aurelis)
    local Window = Aurelis:CreateWindow({
        Title = "AURELIS",
        Subtitle = "Universal Workspace",
        Size = UDim2.fromOffset(880, 590),
        MinimumSize = Vector2.new(520, 340),
        Theme = "Eclipse",
        Acrylic = true,
        Blur = true,
        ToggleKey = Enum.KeyCode.RightShift,
    })
    local Dashboard = Window:AddTab({ Title = "Dashboard", Icon = "home" })
    local Player = Window:AddTab({ Title = "Player", Icon = "user" })
    local Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" })
    local Automation = Window:AddTab({ Title = "Automation", Icon = "zap", Badge = "1" })
    local Utilities = Window:AddTab({ Title = "Utilities", Icon = "folder" })
    local Developer = Window:AddTab({ Title = "Developer", Icon = "code" })
    local Settings = Window:AddTab({ Title = "Settings", Icon = "settings", Bottom = true, Separator = true })
    local Status = Aurelis.State("Ready")
    local Speed = Aurelis.State(16)
    local Display = Aurelis.Computed(function()
        return "Movement · " .. tostring(Speed:Get())
    end)
    Window.Maid:Give(Status)
    Window.Maid:Give(Speed)
    Window.Maid:Give(Display)
    local function notify(title, content, kind)
        Aurelis:Notify({ Title = title, Content = content or "", Type = kind or "Info", Duration = 4 })
    end
    local welcome = Dashboard:AddCard({
        Title = "Your workspace, in focus.",
        Description = "AURELIS / ECLIPSE — a quieter way to build tools.",
        Icon = "sparkles",
    })
    welcome:AddLabel({
        Title = "Interface",
        Value = "Aurelis 1.0.0",
        Description = "Search any control with Ctrl + F. Commands with Ctrl + K.",
    })
    welcome:AddButton({
        Title = "Quick actions",
        Text = "Open command palette",
        Icon = "terminal",
        Variant = "Primary",
        Callback = function()
            Aurelis:OpenCommandPalette(Window)
        end,
    })
    local session = Dashboard:AddCard({ Title = "Session", Icon = "activity" })
    session:AddMetric({ Label = "Status", Value = "Ready", Status = true }):Bind(Status)
    session:AddMetric({ Label = "Workspace", Value = "Local / Client" })
    session:AddMetric({ Label = "Profile", Value = "Eclipse" })
    session:AddChart({
        Title = "Sample activity",
        Description = "Example data, not network latency.",
        Values = { 2, 4, 3, 8, 7, 9, 6, 10, 8, 5, 9, 12 },
    })
    local recent = Dashboard:AddCard({ Title = "Recent notifications", Icon = "bell" })
    local recentRows = {}
    local function updateRecent()
        for _, row in ipairs(recentRows) do
            row:Destroy()
        end
        table.clear(recentRows)
        for index, item in ipairs(Aurelis.NotificationCenter.History) do
            if index > 3 then
                break
            end
            table.insert(
                recentRows,
                recent:AddLabel({ Title = item.Title, Value = item.Type, Description = item.Content })
            )
        end
        if #recentRows == 0 then
            table.insert(
                recentRows,
                recent:AddEmptyState({
                    Title = "You're all caught up",
                    Icon = "bell",
                    Description = "Workspace updates will appear here.",
                })
            )
        end
    end
    Window.Maid:Give(Aurelis.NotificationCenter.Changed:Connect(updateRecent))
    updateRecent()
    local movement = Player:AddPage({ Title = "Movement", Icon = "move" })
    local movementSection = movement:AddSection({
        Title = "Movement",
        Description = "Settings stored as typed flags.",
        Collapsible = true,
    })
    local enabled = movementSection:AddToggle({
        Title = "Enabled",
        Description = "Activate the workspace preview.",
        Flag = "movement.enabled",
        Default = false,
        Tooltip = "This demo changes workspace state. It does not modify your character.",
        Callback = function(value)
            Status:Set(value and "Active" or "Ready")
        end,
    })
    movementSection:AddSlider({
        Title = "Speed",
        Min = 0,
        Max = 100,
        Default = 16,
        Increment = 1,
        Suffix = " u/s",
        Flag = "movement.speed",
        Callback = function(value)
            Speed:Set(value)
        end,
    })
    movementSection:AddDropdown({
        Title = "Mode",
        Values = { "Normal", "Balanced", "Performance" },
        Default = "Balanced",
        Flag = "player.mode",
    })
    movementSection:AddInput({
        Title = "Profile name",
        Placeholder = "My workspace",
        Default = "Universal",
        CharacterLimit = 32,
        Flag = "player.profile",
        Live = true,
        Validate = function(value)
            return #value >= 2, "Use at least two characters"
        end,
    })
    movementSection:AddKeybind({
        Title = "Preview shortcut",
        Default = Enum.KeyCode.F6,
        Mode = "Toggle",
        Flag = "player.shortcut",
        Callback = function(active)
            enabled:SetValue(active)
        end,
    })
    movementSection:AddLabel({ Title = "Reactive display", Value = "" }):Bind(Display)
    Player:AddCard({ Title = "Player workspace", Icon = "user" }):AddButton({
        Title = "Movement controls",
        Text = "Open Movement",
        Callback = function()
            movement:Select()
        end,
    })
    local palette = Visuals:AddSection({ Title = "Appearance", Collapsible = true })
    local visualAccent = palette:AddColorPicker({
        Title = "Highlight color",
        Default = Color3.fromRGB(155, 137, 255),
        Flag = "visuals.color",
        Callback = function(color)
            Window:SetTheme({ Accent = color })
        end,
    })
    palette:AddRangeSlider({
        Title = "Distance",
        Min = 0,
        Max = 1000,
        Default = { 100, 500 },
        Increment = 10,
        Flag = "visuals.distance",
    })
    palette:AddSegmented({
        Title = "Rendering preset",
        Values = { "Normal", "Performance", "Quality" },
        Default = "Normal",
        Flag = "visuals.preset",
    })
    palette:AddDropdown({
        Title = "Visible layers",
        Multi = true,
        Values = { "Navigation", "Status", "Metrics", "Notifications" },
        Default = { "Navigation", "Metrics" },
        Flag = "visuals.layers",
    })
    local job = Automation:AddCard({
        Title = "Workspace task",
        Description = "A finite simulated task to demonstrate progress and cancellation.",
        Icon = "play",
    })
    local progress = job:AddProgress({ Title = "Progress", Default = 0 })
    local jobStatus = Aurelis.State("Stopped")
    Window.Maid:Give(jobStatus)
    job:AddLabel({ Title = "Status", Value = "Stopped", Status = true }):Bind(jobStatus)
    local pending, running = nil, false
    local function stop()
        running = false
        if pending then
            pcall(task.cancel, pending)
            pending = nil
        end
        if not Window.Destroyed then
            jobStatus:Set("Stopped")
        end
    end
    local function tick()
        pending = nil
        if not running or Window.Destroyed then
            return
        end
        local nextValue = math.min(1, progress:GetValue() + 0.05)
        progress:SetValue(nextValue)
        if nextValue >= 1 then
            running = false
            jobStatus:Set("Complete")
            notify("Task complete", "Workspace task finished.", "Success")
        else
            pending = task.delay(0.25, tick)
        end
    end
    Window.Maid:Give(stop)
    job:AddButton({
        Title = "Start task",
        Text = "Start",
        Variant = "Primary",
        Icon = "play",
        Callback = function()
            stop()
            running = true
            progress:SetValue(0)
            jobStatus:Set("Running")
            tick()
        end,
    })
    job:AddButton({ Title = "Stop task", Text = "Stop", Icon = "stop", Callback = stop })
    local utility = Utilities:AddSection({
        Title = "Interaction lab",
        Description = "Right-click a row or hold it on touch to open its context menu.",
        Collapsible = true,
    })
    utility:AddButton({
        Title = "Save snapshot",
        Description = "Save current flags using the configured storage adapter.",
        Icon = "save",
        Tooltip = "The default adapter stores configs for this app session.",
        Callback = function()
            local ok, err = Aurelis.Config:Save("Default")
            notify(
                ok and "Configuration saved" or "Save failed",
                ok and "Default is ready to load." or tostring(err),
                ok and "Success" or "Error"
            )
        end,
    })
    utility:AddButton({
        Title = "Confirmation",
        Text = "Open dialog",
        Callback = function()
            Aurelis:Dialog({
                Title = "Apply workspace changes?",
                Content = "Your current workspace settings will remain available in flags.",
                OnConfirm = function()
                    notify("Applied", "Workspace confirmed.", "Success")
                end,
            }, Window)
        end,
    })
    utility:AddButton({
        Title = "Input dialog",
        Text = "Rename workspace",
        Callback = function()
            Aurelis:Dialog({
                Title = "Workspace name",
                Kind = "Input",
                Default = Window.Subtitle.Text,
                Validate = function(value)
                    return #value >= 2, "Use at least two characters"
                end,
                OnConfirm = function(value)
                    Window.Subtitle.Text = value
                end,
            }, Window)
        end,
    })
    utility:AddButton({
        Title = "Destructive dialog",
        Text = "Clear history",
        Variant = "Danger",
        Callback = function()
            Aurelis:Dialog({
                Title = "Clear notification history?",
                Content = "Current history entries will be removed.",
                Kind = "Destructive",
                ConfirmText = "Clear",
                OnConfirm = function()
                    Aurelis.NotificationCenter:Clear()
                end,
            }, Window)
        end,
    })
    utility:AddInput({
        Title = "Numeric input",
        Type = "Number",
        Default = 5,
        Min = 1,
        Max = 60,
        Live = true,
        Flag = "utilities.interval",
        Tooltip = "Only numbers from 1 to 60 are accepted.",
    })
    utility:AddInput({
        Title = "Masked input",
        Type = "Password",
        Placeholder = "Local demo text",
        CharacterLimit = 48,
    })
    local load = Utilities:AddCard({ Title = "Skeleton preview", Icon = "layers" })
    load:AddMetric({ Label = "State", Value = "Loaded" })
    load:AddMetric({ Label = "Assets", Value = "Embedded vectors" })
    utility:AddToggle({
        Title = "Show skeleton",
        Default = false,
        Callback = function(value)
            load:SetLoading(value)
        end,
    })
    local monitor = Developer:AddCard({ Title = "UI performance", Icon = "cpu" })
    local fps = monitor:AddMetric({ Label = "FPS", Value = "Monitor inactive" })
    local instanceCount = monitor:AddMetric({ Label = "UI instances", Value = "—" })
    local connections = monitor:AddMetric({ Label = "Connections", Value = "—" })
    monitor:AddToggle({
        Title = "Developer overlay",
        Default = false,
        Callback = function(value)
            Aurelis:SetDeveloperOverlay(value)
        end,
    })
    local inspector = Developer:AddSection({ Title = "State & flags", Collapsible = true })
    local stateRow = inspector:AddLabel({ Title = "Session state", Value = "" }):Bind(Status)
    local flagCount = inspector:AddLabel({ Title = "Registered flags", Value = "0" })
    local changedFlag = inspector:AddLabel({ Title = "Last changed", Value = "None" })
    local function updateFlags(key, value)
        local count = 0
        for _ in pairs(Aurelis.FlagStore:Snapshot()) do
            count += 1
        end
        flagCount:SetValue(tostring(count))
        if key then
            changedFlag:SetValue(key .. " = " .. tostring(value))
        end
    end
    Window.Maid:Give(Aurelis.FlagStore.Changed:Connect(updateFlags))
    inspector:AddButton({
        Title = "Inspect flags",
        Text = "Open snapshot",
        Callback = function()
            Aurelis:Dialog({
                Title = "Flag snapshot",
                Kind = "Input",
                Default = Aurelis.Config:Export(),
                ConfirmText = "Done",
                Content = "Serialized current state. Use your platform's text selection to copy it.",
            }, Window)
        end,
    })
    local notificationTest = Developer:AddSection({ Title = "Notification testing" })
    for _, kind in ipairs({ "Info", "Success", "Warning", "Error" }) do
        notificationTest:AddButton({
            Title = kind,
            Text = "Send " .. kind,
            Callback = function()
                notify(kind .. " notification", "A notification generated by the showcase.", kind)
            end,
        })
    end
    local performanceConnection = nil
    Window.Maid:Give(Window.PageChanged:Connect(function(page)
        if performanceConnection then
            performanceConnection:Disconnect()
            performanceConnection = nil
        end
        if page == Developer then
            performanceConnection = Aurelis.Performance:Acquire(function(values)
                fps:SetValue(tostring(values.FPS))
                instanceCount:SetValue(tostring(values.Instances))
                connections:SetValue(tostring(values.Connections))
                Window.StatusBar:Set({ FPS = values.FPS })
            end)
        end
    end))
    Window.Maid:Give(function()
        if performanceConnection then
            performanceConnection:Disconnect()
        end
    end)
    local theme = Settings:AddSection({
        Title = "Theme editor",
        Description = "Changes apply live without rebuilding the interface.",
        Icon = "palette",
        Collapsible = true,
    })
    theme:AddDropdown({
        Title = "Theme",
        Values = { "Eclipse", "Obsidian", "Graphite", "Tokyo", "OLED", "Frost", "Light" },
        Default = "Eclipse",
        Flag = "settings.theme",
        ConfigPriority = -100,
        Callback = function(value)
            Aurelis:SetTheme(value)
        end,
    })
    local themeControls = {}
    for _, token in ipairs({ "Accent", "Background", "Surface", "Border", "TextPrimary" }) do
        themeControls[token] = theme:AddColorPicker({
            Title = token == "TextPrimary" and "Text" or token,
            Default = Window.Theme.Tokens[token],
            Flag = "theme." .. token,
            Callback = function(value)
                Window:SetTheme({ [token] = value })
            end,
        })
    end
    themeControls.Radius = theme:AddSlider({
        Title = "Corner radius",
        Min = 0,
        Max = 24,
        Increment = 1,
        Default = 12,
        Flag = "theme.radius",
        Callback = function(value)
            Window:SetTheme({ Radius = value })
        end,
    })
    themeControls.Transparency = theme:AddSlider({
        Title = "Transparency",
        Min = 0,
        Max = 0.65,
        Increment = 0.01,
        Default = 0.02,
        Flag = "theme.transparency",
        Callback = function(value)
            Window:SetTheme({ Transparency = value })
        end,
    })
    themeControls.AnimationSpeed = theme:AddSlider({
        Title = "Animation speed",
        Min = 0,
        Max = 3,
        Increment = 0.1,
        Default = 1,
        Suffix = "×",
        Flag = "theme.motion",
        Callback = function(value)
            Window:SetTheme({ AnimationSpeed = value })
        end,
    })
    Window.Maid:Give(Window.Theme.Changed:Connect(function(tokens)
        for token, control in pairs(themeControls) do
            control:SetValue(tokens[token], true)
        end
        visualAccent:SetValue(tokens.Accent, true)
    end))
    theme:AddSlider({
        Title = "UI scale",
        Min = 0.65,
        Max = 1.5,
        Increment = 0.05,
        Default = 1,
        Flag = "settings.scale",
        Callback = function(value)
            Window:SetScale(value)
        end,
    })
    theme:AddKeybind({
        Title = "Menu key",
        Default = Enum.KeyCode.RightShift,
        Mode = "Toggle",
        Flag = "settings.menuKey",
    })
    Window.Maid:Give(Aurelis.FlagStore.Changed:Connect(function(key, value)
        if key == "settings.menuKey" then
            Window.ToggleKey = value.Key
        end
    end))
    local configs = Settings:AddSection({
        Title = "Configurations",
        Description = "Session storage by default. Inject a persistent adapter for cross-session saving.",
        Icon = "save",
        Collapsible = true,
    })
    local configName = "Default"
    configs:AddInput({
        Title = "Name",
        Default = "Default",
        Live = true,
        CharacterLimit = 64,
        Validate = function(value)
            return #value > 0 and string.match(value, "^[%w _%-]+$") ~= nil,
                "Use letters, digits, spaces, _ or -"
        end,
        Callback = function(value)
            configName = value
        end,
    })
    local configList = configs:AddDropdown({
        Title = "Saved configurations",
        Values = {},
        Default = "",
        Callback = function(value)
            if value ~= "" then
                configName = value
            end
        end,
    })
    local refreshConfigs
    local empty = configs:AddEmptyState({
        Title = "No configurations yet",
        Icon = "save",
        Description = "Create a configuration to save your current interface settings.",
        Action = {
            Title = "Create configuration",
            Callback = function()
                local ok, err = Aurelis.Config:Save(configName)
                if ok then
                    refreshConfigs()
                else
                    notify("Save failed", tostring(err), "Error")
                end
            end,
        },
    })
    refreshConfigs = function()
        local names = Aurelis.Config:List()
        configList:SetValues(names)
        empty:SetVisible(#names == 0)
    end
    configs:AddButton({
        Title = "Save",
        Icon = "save",
        Variant = "Primary",
        Callback = function()
            local ok, err = Aurelis.Config:Save(configName)
            refreshConfigs()
            notify(ok and "Configuration saved" or "Save failed", tostring(err), ok and "Success" or "Error")
        end,
    })
    configs:AddButton({
        Title = "Load",
        Icon = "download",
        Callback = function()
            local ok, result = Aurelis.Config:Load(configName)
            notify(
                ok and "Configuration loaded" or "Load failed",
                ok and tostring(#result.Applied) .. " flags applied" or tostring(result),
                ok and "Success" or "Error"
            )
        end,
    })
    configs:AddButton({
        Title = "Rename",
        Icon = "edit",
        Callback = function()
            Aurelis:Dialog({
                Title = "Rename configuration",
                Kind = "Input",
                Default = configName,
                OnConfirm = function(value)
                    local ok, err = Aurelis.Config:Rename(configName, value)
                    if ok then
                        configName = value
                        refreshConfigs()
                    else
                        notify("Rename failed", tostring(err), "Error")
                    end
                end,
            }, Window)
        end,
    })
    configs:AddButton({
        Title = "Delete",
        Icon = "trash",
        Variant = "Danger",
        Callback = function()
            Aurelis:Dialog({
                Title = "Delete " .. configName .. "?",
                Kind = "Destructive",
                OnConfirm = function()
                    local ok, err = Aurelis.Config:Delete(configName)
                    refreshConfigs()
                    if not ok then
                        notify("Delete failed", tostring(err), "Error")
                    end
                end,
            }, Window)
        end,
    })
    local commands = {
        {
            "Open Dashboard",
            function()
                Dashboard:Select()
            end,
        },
        {
            "Open Player",
            function()
                movement:Select()
            end,
        },
        {
            "Open Settings",
            function()
                Settings:Select()
            end,
        },
        {
            "Change Theme",
            function()
                Window:SetTheme(Window.Theme.Name == "Light" and "Eclipse" or "Light")
            end,
        },
        {
            "Save Configuration",
            function()
                Aurelis.Config:Save(configName)
                refreshConfigs()
            end,
        },
        {
            "Restore Window",
            function()
                Window:Restore()
            end,
        },
    }
    for _, command in ipairs(commands) do
        Window.Maid:Give(
            Aurelis.Commands:Register({ Name = command[1], Keywords = { "workspace" }, Callback = command[2] })
        )
    end
    refreshConfigs()
    updateFlags()
    Dashboard:Select()
    notify("Interface initialized", "Welcome to AURELIS. Press Ctrl + K to explore.", "Success")
    return Window
end
return Showcase
