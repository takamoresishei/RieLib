# Components

All pages, sections and cards support the factories below. The framework does not attach game logic to controls. Callbacks are invoked after a valid value changes; initialization is silent. Callback errors are reported through `warn` without breaking other listeners.

## Shared options and handles

`Title`, `Description`, `Icon`, `Tooltip`, `Flag`, `Disabled`, `Visible`, and `ConfigPriority` are shared options. Flags are optional and unique per app. `ConfigPriority` defaults to 0; lower numbers load first. Context menus can be replaced with `ContextMenu={{Title="Action", Callback=function() ... end, Danger=false}}`.

Every component exposes:

| Method | Behavior |
| --- | --- |
| `SetDisabled(boolean)` | Disable interactions and apply muted feedback; closes an owned popup |
| `SetVisible(boolean)` | Change row visibility |
| `SetTitle(text)` / `SetDescription(text)` | Change the row's copy and reflow |
| `SetIcon(nameOrNil)` / `SetTooltip(text)` | Update optional adornments |
| `Update(options)` | Apply shared fields, including `Callback`; `Icon=false` clears the icon |
| `Highlight()` | Brief accent outline |
| `Destroy()` | Remove UI, listeners, flags, bindings, pointer tracking and search entry |

Value components additionally implement `SetValue(value, silent?)`, `GetValue()`, `Reset()`, `Bind(state)`, and `Changed:Connect(callback)`. `SetValue` returns `true` or `false, message`; invalid values do not change state. `silent=true` suppresses the application callback while keeping rendering and change signals current. `GetValue` returns a defensive copy for tables. Buttons/empty states are action components; their generic value methods return no value.

Rows share hover, press, selection/focus, disabled, context-menu and tooltip behavior. Mouse hover and keyboard selection show delayed tooltips. Touch context menus use a 0.55 s long press, cancelled after 10 px of movement. All handlers are scoped to the component or the app's central input router.

## Button

```lua
local Button = Section:AddButton({
    Title="Run action", Description="Execute the selected action.", Text="Run",
    Icon="play", Variant="Primary", Callback=function() print("Action") end,
})
Button:SetLoading(true)
Button:SetLoading(false)
```

Variants: `Default`, `Primary`, `Secondary`, `Ghost`, `Danger`. `Text` defaults to the title. Loading displays **Working…** and blocks activation. `Button:Activate()` uses the same disabled/loading guards as UI activation. Press feedback compresses the button subtly.

## Toggle

```lua
local Toggle = Section:AddToggle({Title="Enabled",Flag="feature.enabled",Default=false,Callback=function(value) print(value) end})
Toggle:SetValue(true)
```

Value is strictly boolean, including a preserved `false`. The thumb and track animate on changes.

## Slider and range slider

```lua
Section:AddSlider({Title="Speed",Min=0,Max=100,Default=50,Increment=1,Suffix="%",Flag="movement.speed"})
Section:AddRangeSlider({Title="Distance",Min=0,Max=1000,Default={100,500},Increment=10})
```

Bounds must be finite and ordered. Increment must be positive. Values clamp to bounds and round to the increment lattice based at `Min`. Sliders support mouse/touch tracking, direct numerical entry, a drag value bubble, and arrow keys when the row is selected. Ranges store an ascending `{minimum, maximum}` pair, select the nearest thumb on pointer down, and constrain the active thumb to avoid crossing. Both endpoints have numerical inputs. Zero-length domains are supported.

## Dropdown

```lua
local Mode = Section:AddDropdown({Title="Mode",Values={"Normal","Balanced","Performance"},Default="Balanced"})
local Layers = Section:AddDropdown({Title="Layers",Values={"Status","Metrics","History"},Default={"Status"},Multi=true})
Mode:SetValues({"Normal","Fast"})
Mode:SetValue("Fast")
```

Options must be unique strings. Single selection stores a string; multi selection stores a deduplicated string array. Unknown options are rejected. `SetValues` closes the popup and removes invalid selections; single selection falls back to the first available option or `""` for an empty list. The popup contains search, scrolling, selected indicators and keyboard navigation. Enter toggles a multi selection without closing; Escape/outside click closes. Only one app popover remains open. A popup near the lower edge opens upward and clamps to the viewport.

## Input

```lua
Section:AddInput({
    Title="Profile", Type="Text", Default="Universal", Placeholder="Profile name",
    CharacterLimit=32, Live=true,
    Validate=function(value) return #value>=2, "Use at least two characters" end,
    Callback=function(value) print(value) end,
})
Section:AddInput({Title="Retries",Type="Number",Default=3,Min=0,Max=10})
Section:AddInput({Title="Masked value",Type="Password",CharacterLimit=64})
```

Types: `Text`, `Number`, `Password`. Number values remain numbers. Text/password values remain strings. `Validate` returns `boolean, message?`; rejected edits show an error below the field. `CharacterLimit` is a nonnegative integer and counts valid UTF-8 characters. `Live=true` applies valid edits as they change. Otherwise, blur or Enter commits; `SubmitOnEnter=true` commits only on Enter and restores the previous value on an ordinary blur. Password masking is a display treatment; the underlying TextBox still contains the text and this control is not a secret-storage system.

## Keybind

```lua
local Bind = Section:AddKeybind({Title="Preview",Default=Enum.KeyCode.F6,Mode="Toggle",Flag="preview.key",Callback=function(active) print(active) end})
Bind:SetKey(Enum.KeyCode.F7)
Bind:SetMode("Hold")
```

Click the key field to display **Listening…**. Escape cancels capture; Backspace unbinds. The adjacent mode button cycles `Toggle`, `Hold`, `Always`. `GetValue()` returns `{Key=Enum.KeyCode, Mode=string}`; `SetValue` accepts that table or a KeyCode. `IsActive()` reports activation. `Callback(active)` receives a boolean, while `Changed` reports binding changes. Processed keys, typing and modal focus suppress activation. Hold releases centrally on input end. Disabling/destroying resets active state.

## Color picker

```lua
local Color = Section:AddColorPicker({Title="Accent",Default=Color3.fromRGB(120,90,255),Alpha=1,Flag="accent"})
Color:SetValue(Color3.fromRGB(150,110,255))
Color:SetAlpha(0.5)
print(Color:GetValue(), Color:GetAlpha())
```

Includes an SV square, full hue strip, checker-backed alpha strip, RGB fields (0–255), HSV fields (0–360/0–100/0–100), HEX input, preview and eight recent colors. SV/hue/alpha support mouse and touch. `GetValue()` returns Color3. Alpha is stored separately; a flagged picker automatically registers `Flag..".alpha"`, or uses explicit `AlphaFlag`. `SetAlpha(alpha, silent?)` clamps to 0–1. Color callbacks receive Color3; alpha callbacks also supply alpha as their second argument. Opening/closing the editor records the most recent color. Invalid HEX edits restore the current value.

## Segmented control

```lua
Section:AddSegmented({Title="Preset",Values={"Normal","Performance","Quality"},Default="Normal"})
```

Stores one of the provided values, with an animated selection surface. Keep labels short and the number of segments small so each remains readable on compact layouts.

## Labels, progress and charts

```lua
local Label = Section:AddLabel({Title="Status",Value="Ready",Status=true})
local Progress = Section:AddProgress({Title="Progress",Default=0.25})
local Chart = Section:AddChart({Title="Activity",Values={2,6,4,9,7}})
Progress:SetValue(0.75)
Chart:SetValue({3,8,5,10})
```

Labels stringify string/number/boolean values. `Status=true` uses the success token. Progress stores a fraction clamped to 0–1. Charts are lightweight, event-driven bar charts with up to 120 finite samples; they have no frame loop. Empty arrays show **No samples**. These display components retain the shared context/lifecycle API.

## Cards, sections, skeletons and empty states

```lua
local Card = Dashboard:AddCard({Title="Session",Icon="activity"})
local Status = Card:AddMetric({Label="Status",Value="Ready",Status=true})
Card:AddProgress({Title="Task",Default=0})
Card:SetLoading(true)
Card:SetLoading(false)

Settings:AddEmptyState({
    Title="No configurations yet",Icon="save",
    Description="Create a configuration to save your current interface settings.",
    Action={Title="Create configuration",Callback=function() Aurelis.Config:Save("Default") end},
})
```

Cards are section containers with `AddMetric({Label,Value,Status?,Icon?,Flag?})` and `SetLoading(boolean)`. Skeletons are static bars that cover loaded content without continuous shimmer. `Collapsible=true` enables the animated section header; `Collapsed=true` sets its initial state. `Section:SetCollapsed(boolean)` updates height and chevron. Empty states supply original icons, explanation and an optional working action.
