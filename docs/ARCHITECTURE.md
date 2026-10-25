# Architecture and source map

The public entry point returns an application object. Source modules form the authoritative implementation; the bundle/model are deterministic generated distributions. Roblox module paths are resolved at build time into the bundle's private loader.

## Full framework source tree

| Directory | Modules |
| --- | --- |
| `Aurelis/` | `init.lua`, `Types.lua` |
| `Aurelis/Core/` | `Application.lua`, `Window.lua`, `State.lua`, `Flags.lua`, `Theme.lua`, `Motion.lua`, `Input.lua`, `Cleanup.lua`, `Responsive.lua` |
| `Aurelis/Navigation/` | `Sidebar.lua`, `Tab.lua`, `Page.lua`, `Section.lua`, `Breadcrumb.lua`, `Container.lua` |
| `Aurelis/Components/` | `Base.lua`, `Button.lua`, `Toggle.lua`, `Slider.lua`, `RangeSlider.lua`, `Dropdown.lua`, `Input.lua`, `Keybind.lua`, `ColorPicker.lua`, `Segmented.lua`, `Progress.lua`, `Label.lua`, `Chart.lua`, `Card.lua`, `EmptyState.lua` |
| `Aurelis/Overlay/` | `Tooltip.lua`, `DropdownOverlay.lua`, `ContextMenu.lua`, `Modal.lua`, `Notification.lua`, `CommandPalette.lua`, `Search.lua` |
| `Aurelis/Services/` | `Config.lua`, `NotificationCenter.lua`, `Commands.lua`, `Performance.lua` |
| `Aurelis/Utility/` | `Icons.lua`, `Signal.lua`, `Math.lua`, `Table.lua`, `Gui.lua` |
| `Aurelis/Demo/` | `Showcase.lua` |

| Supporting path | Purpose |
| --- | --- |
| `default.project.json` | Rojo Studio integration |
| `examples/Minimal.client.lua` | Minimal usable integration |
| `examples/Showcase.client.lua` | Seven-page showcase launcher |
| `examples/StudioSmoke.client.lua` | Real-engine smoke checks for Studio Play |
| `tests/RobloxMock.luau` | Deterministic headless service/event/property harness |
| `tests/Spec.luau` | Behavioral and lifecycle contract suite |
| `tools/build.py` | Dependency bundler, model XML builder, SHA-256 manifest |
| `tools/test.py` | Artifact verification, compiler checks, Luau contract runner |
| `stylua.toml` | Consistent Luau formatting |
| `.github/workflows/ci.yml` | Pinned compiler and contract checks |
| `dist/Aurelis.lua` | Self-contained framework bundle |
| `dist/Showcase.lua` | Self-contained showcase bundle |
| `dist/Aurelis.rbxmx` | Importable ModuleScript source model |
| `dist/manifest.json` | Version and artifact digests |

## Ownership

The application owns one ScreenGui, one input router, one overlay portal, a restore dock, global services, and its optional world blur. Windows own their themes, shell, navigation, page tree, component scopes, state integrations and launcher. Components own instances, local GUI handlers, state subscriptions and registration cleanup. Closing hides a window; destroying releases it permanently.

`Cleanup` accepts functions, instances, disconnectable resources and destroyable objects. Duplicate registration is idempotent. Nested scopes clean dynamic icon geometry, dropdown results, notification rows, charts and popovers. Failed component constructors remove their partially created rows. Cleanup counters expose tracked resources/connections for development; they are not a profiler for unrelated game scripts.

## Input and focus

Global input is connected once per application. Pointer motion/end, key capture, context-menu long press and focus changes route through that service. A single active pointer owns a drag/slider gesture; hiding a window cancels its active pointer. Context menus find the topmost visible component only when a relevant pointer action occurs.

InputObject positions already use the same safe-area coordinate space as GuiBase2d.AbsolutePosition. Raw GetMouseLocation coordinates are converted with GuiService.GetGuiInset. This distinction follows the official [GuiBase2d documentation](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d) and [UserInputService documentation](https://create.roblox.com/docs/reference/engine/classes/UserInputService).

Window focus reorders sibling ZIndex groups. The app portal sits above windows; popup scopes are mutually exclusive and are replaced atomically. Modal scopes dim, guard selection/text focus, trap app keybinds, and restore prior selection when possible. Hidden/minimized windows appear in the scrollable restore dock so touch users can recover them without a keyboard.

## State and configuration

Controls register normalizers in the flag store. Config import first validates/normalizes candidate entries, then applies valid entries in deterministic priority/name order. Invalid entries are reported and skipped. State/Computed is a separate lightweight reactive mechanism with dependency collection and explicit teardown. Binding state to controls is one-way and silent.

## Rendering and motion

Gui helpers build Roblox-native instances and register semantic theme mappings. They never download images or icons. Vector glyphs share a 24-unit grid. Theme changes update bound instances in place. Motion tracks disjoint property tweens concurrently and cancels conflicting ones. Completed tweens disconnect immediately, and scope teardown cancels remaining tweens on owned objects.

Layout uses list layouts and automatic scroll canvases, with measured/collapsible section heights. Breakpoints collapse navigation or switch to an overlay drawer. Compact component rows move controls below labels. Scrolling, filtering, theme changes and state edits are event-driven. Skeletons remain static. The optional performance monitor uses Heartbeat only while acquired and samples on a 0.75 s cadence. Invisible showcase Developer pages release their monitor subscription.

No framerate benchmark is inferred from the headless stress test. That test checks construction, independent state, serialization and destruction of 150 controls; real renderer/GPU/input costs require Studio/device measurements.
