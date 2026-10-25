# AURELIS UI

A desktop application framework inside Roblox. Original vector icons, layered Eclipse surfaces, responsive navigation, and a small public Luau API.

**RieLib is the repository name. AURELIS UI is the framework name.** Version 1.0.0 is the initial implementation; Roblox Studio/device visual and performance sign-off is still required. See [validation](docs/VALIDATION.md).

## Start in Roblox Studio

1. Download [`dist/Aurelis.rbxmx`](dist/Aurelis.rbxmx), then insert the model into `ReplicatedStorage`. The imported root must be named `Aurelis`.
2. Copy [`examples/Showcase.client.lua`](examples/Showcase.client.lua) into a `LocalScript` under `StarterPlayerScripts`.
3. Press **Play**. Use **Right Shift** to hide/show, **Ctrl + K** for commands, and **Ctrl + F** to search every registered control.

Alternatively, run `rojo serve default.project.json` and connect Studio's Rojo plugin. The project maps the entire source tree and the showcase LocalScript.

```lua
local Aurelis = require(game:GetService("ReplicatedStorage"):WaitForChild("Aurelis"))

local Window = Aurelis:CreateWindow({
    Title = "Aurelis",
    Subtitle = "Universal Workspace",
    Size = UDim2.fromOffset(600, 380),
    MinimumSize = Vector2.new(320, 240),
    Acrylic = true,
    Blur = true,
    Theme = "Eclipse",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Player = Window:AddTab({Title = "Player", Icon = "user"})
local Movement = Player:AddSection({Title = "Movement", Collapsible = true})
Movement:AddToggle({Title = "Enabled", Flag = "movement.enabled", Default = false})
Movement:AddSlider({Title = "Speed", Min = 0, Max = 100, Default = 16, Flag = "movement.speed"})
```

## Single-file distribution

[`dist/Aurelis.lua`](dist/Aurelis.lua) returns the application object. [`dist/Showcase.lua`](dist/Showcase.lua) creates all seven showcase tabs and returns `app, window`. Both are generated from the modular source with an internal dependency loader; they do not fetch modules or icon assets at runtime.

In a compatible client environment exposing `loadstring` and `game:HttpGet`:

```lua
local Aurelis = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/takamoresishei/RieLib/main/dist/Aurelis.lua"
))()
local Window = Aurelis:CreateWindow({Title = "My workspace", Theme = "Eclipse"})
Window:AddTab({Title = "Home", Icon = "home"}):AddLabel({Title = "Status", Value = "Ready"})
```

For the complete demonstration, load `dist/Showcase.lua` instead. Standard Roblox LocalScripts use the ModuleScript installation above. Parent defaults to `LocalPlayer.PlayerGui`; privileged GUI parenting and filesystem/clipboard capabilities are optional injected integrations.

## Included

- Draggable, resizable windows with minimize, maximize, soft close/restore, snapping, focus order and mobile drawers.
- Buttons, toggles, sliders, range sliders, dropdowns, validated/masked inputs, keybinds, color editors, segmented controls, labels, progress, charts, cards, skeletons and empty states.
- Nested pages, collapsible sections, clickable breadcrumbs, badges, delayed edge-aware tooltips and mouse/touch context menus.
- Notification history and bounded toasts; focus-guarded dialogs; fuzzy commands; global component search with reveal/highlight.
- Seven semantic themes, live theme editing, typed flag normalization, versioned configuration adapters, reactive/computed state and centralized motion/cleanup.
- An opt-in developer monitor and a headless Luau contract suite, including 150 controls across 10 tabs and 30 sections.

## Documentation

| Guide | Contents |
| --- | --- |
| [Installation](docs/INSTALLATION.md) | Studio, Rojo, bundle, optional platform adapters |
| [API](docs/API.md) | Application, window, navigation, overlays and state |
| [Components](docs/COMPONENTS.md) | Options, runtime methods, values and examples |
| [Themes](docs/THEMES.md) | Tokens, built-in themes and live customization |
| [Configuration](docs/CONFIGURATION.md) | Flags, schema, storage, migration and validation |
| [Architecture](docs/ARCHITECTURE.md) | Full source tree, resource ownership and performance design |
| [Validation](docs/VALIDATION.md) | Reproducible checks and remaining engine/device verification |

## Build and check

Python 3.10+ and the official Luau CLI are sufficient. No Python packages are required.

```sh
python tools/build.py
python tools/test.py
```

`tools/test.py` verifies deterministic artifacts, compiles all source/example/distribution files, and runs the behavior suite. Set `LUAU` and `LUAU_COMPILE` or pass `--luau` / `--compiler` to use custom executable paths. CI pins Luau 0.744 and checks the downloaded archive digest.

The showcase is a UI workspace demonstration. Player/Visuals controls store configuration and update interface state; they do not alter game characters or call gameplay remotes.

MIT licensed. All vector glyphs in this repository are original procedural geometry.
