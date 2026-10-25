# Public API

All examples execute on the Roblox client. `Aurelis` is the object returned by the root module or the distribution bundle.

## Application

| Call | Result / behavior |
| --- | --- |
| `Aurelis.New(options?)` | Isolated application; options include `Parent`, `DisplayOrder`, `Theme`, `ConfigAdapter`, `Clipboard` |
| `Aurelis:CreateWindow(options)` | New window, focused above the app's other windows |
| `Aurelis:GetValue(flag)` | Defensive copy of a registered value, or nil |
| `Aurelis:SetValue(flag, value, silent?)` | `success, error?`; validates before applying |
| `Aurelis.Flags[flag]` | Read/write proxy for the same state store |
| `Aurelis:SetTheme(nameOrOverrides)` | Update app overlays and every window live |
| `Aurelis:Notify(options)` | Add history entry; optional bounded toast; returns the history item |
| `Aurelis:Dialog(options, window?)` | Open a modal; defaults to focused window |
| `Aurelis:OpenCommandPalette(window?)` | Open fuzzy command search |
| `Aurelis:SetDeveloperOverlay(boolean)` | Start/stop the opt-in performance panel |
| `Aurelis:Destroy()` | Idempotent teardown of windows, listeners, effects and owned instances |

`Version` is `1.0.0`. `Flags` supports direct indexing; use `Aurelis.FlagStore:Snapshot()` for enumeration. `Icons:Get(name)` returns an icon descriptor; `Icons:List()` returns sorted supported names. `Aurelis.Clipboard = function(text)` supplies optional copy integration.

## Window

```lua
local Window = Aurelis:CreateWindow({
    Title = "Aurelis", Subtitle = "Universal Workspace",
    Size = UDim2.fromOffset(720, 480), MinimumSize = Vector2.new(520, 340),
    Acrylic = true, Blur = true, Theme = "Eclipse",
    ToggleKey = Enum.KeyCode.RightShift, StatusBar = true,
})
```

| Method | Behavior |
| --- | --- |
| `AddTab({Title, Id?, Icon?, Badge?, Bottom?, Separator?})` | Add a navigation entry and scrollable content page |
| `SelectTab(titleOrIdOrPage)` | Select any tab or nested page; returns boolean |
| `Focus()` | Raise and focus within the app |
| `Hide()` / `Show()` / `SetVisible(boolean)` | Reversible visibility |
| `Close()` | Soft close; restore with `Show`, `Restore` or the toggle key |
| `Minimize()` | Collapse to title bar; calling again restores |
| `Maximize()` | Fit usable viewport; calling again restores previous geometry |
| `Restore()` | Unminimize/unmaximize, recover saved geometry, show and focus |
| `Snap("Left" or "Right")` | Half-screen snap; maximize if two minimum-width windows cannot fit |
| `SetScale(number)` | Set scale from 0.65 to 1.5 and re-clamp to viewport |
| `SetTheme(nameOrOverrides)` | Update this window without reconstruction |
| `ToggleSidebar(boolean?)` | Open/close mobile drawer |
| `Destroy()` | Permanent teardown |

Drag the title area and resize from the lower-right hitbox with mouse or touch. Double-click/tap the title area to maximize/restore. Drag to the top edge to maximize, or to a side edge to snap. Minimum size yields to the actual available viewport on small devices. Breakpoints are desktop ≥700 px, compact 500–699 px and mobile <500 px, using the available viewport/window width. Content rows reflow when their available width drops below 380 px.

`Window.PageChanged:Connect(function(page))` observes navigation. `SelectedPage`, `Visible`, `Minimized`, `Maximized`, `Closed`, and `Destroyed` expose current state. `Window.Maid:Give(resource)` ties integrating code's resources to the window lifecycle.

```lua
Window.StatusBar:Set({Status = "Ready", FPS = 60, Latency = 42, Version = "1.0.0"})
```

Status fields are caller-supplied. The developer monitor measures client FPS, instance count, tracked connections, active tweens and client memory. It acquires a Heartbeat listener only while someone subscribes; `Aurelis.Performance:Acquire(callback)` returns a disconnectable handle.

## Navigation and containers

```lua
local Player = Window:AddTab({Title = "Player", Icon = "user", Badge = "2"})
local Movement = Player:AddPage({Title = "Movement", Icon = "move"})
local Section = Movement:AddSection({Title = "Movement", Description = "Settings", Collapsible = true})
Section:SetCollapsed(true)
Movement:Select()
Player:SetBadge("3")
```

Pages, sections and cards expose the component factories in [COMPONENTS.md](COMPONENTS.md). Sections may contain nested sections/cards. `SetVisible(boolean)` is supported by sections and components. `Destroy()` removes each object, its descendants, flags, search registration and resource scope. Breadcrumbs navigate to the corresponding parent page. Bottom navigation entries and separators are configured on tabs.

## Commands and search

```lua
local Registration = Aurelis.Commands:Register({
    Name = "Open Settings", Keywords = {"configuration", "appearance"},
    Callback = function() Window:SelectTab("Settings") end,
})
Window.Maid:Give(Registration)
```

`Registration:Destroy()` unregisters. `Commands:Search(query)` returns fuzzy-ranked records. Ctrl + K opens the palette; arrows move, Enter runs, Escape closes. Ctrl + F searches registered controls across app windows. Selecting a search result shows its window/page, expands ancestor sections, scrolls to the row and highlights it. `Aurelis.Search:Query(query, window?)` and `:Reveal(component)` are available for custom navigation.

## Notifications and modals

```lua
Aurelis:Notify({Title="Saved", Content="Configuration saved.", Type="Success", Duration=4})
Aurelis:Dialog({
    Title="Workspace name", Kind="Input", Default="Universal",
    Validate=function(value) return #value>=2, "Use at least two characters" end,
    OnConfirm=function(value) print(value) end,
    OnCancel=function() print("Cancelled") end,
}, Window)
```

Notification types: `Info`, `Success`, `Warning`, `Error`. History is capped at 100 entries; at most four toasts are shown. `Duration=0` creates a history-only entry. The bell opens scrollable history with **Clear all**. `Aurelis.NotificationCenter.History` holds newest-first records, and `:Clear()` empties it.

Modal kinds: default confirmation, `Information`, `Input`, `Destructive`. Options include `Content`, `ConfirmText`, `CancelText`, `Critical`, `Width`, `Validate`, `OnConfirm`, and `OnCancel`. Noncritical dialogs accept Escape. The backdrop dims the UI and world blur increases; text/selection focus is guarded inside the modal. The returned controller exposes `Confirm()`, `Close()`, and `Result:Connect(function(accepted, value))`. `Close()` cancels even a critical dialog programmatically. Callbacks may open another dialog.

## Reactive state and motion

```lua
local Speed = Aurelis.State(16)
local Display = Aurelis.Computed(function() return "Speed: " .. Speed:Get() end)
Section:AddLabel({Title="Preview", Value=""}):Bind(Display)
Speed:Set(75)
Window.Maid:Give(Display)
Window.Maid:Give(Speed)
```

State implements `Get`, `Set`, `Subscribe(callback, immediate?)` and `Destroy`. Computed state tracks dependencies on each evaluation and is read-only. Disconnect subscribers or give them to a cleanup scope. Values are defensively copied. `Component:Bind(state)` is one-way and silent: state changes update the component without invoking its application callback.

```lua
Aurelis.Motion:Tween(Object, {BackgroundTransparency = 0}, "Fast")
```

Presets: `Instant` 0 s, `Fast` 0.12 s, `Normal` 0.19 s, `Slow` 0.26 s, `Spring` 0.24 s with Back easing. `Motion.Speed=0` applies values immediately. New tweens cancel previous tweens affecting the same properties; disjoint properties can animate concurrently, so a theme change does not cancel a height transition. Completion removes each tween's listener. Owned GUI objects cancel active tweens during teardown.
