# Validation status

Checked on 2026-10-25 with the official Luau 0.744 Linux CLI.

| Check | Result |
| --- | --- |
| Framework source | 49 modules compiled |
| Sources + examples + generated Lua distributions | 54 files compiled |
| Behavioral/lifecycle contracts | 29 passed, 0 failed |
| Distribution reproducibility | Generated bundle/model contents match source |
| Lifecycle accounting | Owned tracked resources/connections return to baseline after destruction |
| Stress construction | 150 controls, 10 tabs, 30 sections; typed state and config paths checked |
| Roblox Studio rendering/input | Not executed in this build environment |
| Android/Delta/device renderer | Not executed in this build environment |
| GPU/FPS target certification | Not measured; no 60 FPS claim is made from mocks |

The deterministic headless harness executes real framework code against test services and input/property events. It covers reactive dependencies, disconnect-safe signals, cleanup, slider rounding, false-valued flags, every value component, dropdown replacement/keyboard selection, validation, keybind modes, typed config round trips, invalid/future schemas, theme mutation without reconstruction, color popup lifecycle, nested search reveal, notification history, modal focus/callback chaining, multiple windows, mobile bounds/scale, demand-driven monitoring, constructor rollback, overlapping tween properties and the touch restore dock. Its layout model is intentionally limited; it is not the Roblox renderer or a substitute for device QA.

## Reproduce

```sh
python tools/build.py
python tools/test.py --luau /path/to/luau --compiler /path/to/luau-compile
```

CI pins the official archive and verifies its SHA-256 before running the same checks. `python tools/build.py --check` checks artifact freshness without rewriting files. Source formatting uses StyLua with the repository's config; generated distributions are excluded from manual formatting.

## Real-engine smoke test

Install `dist/Aurelis.rbxmx` as described in [Installation](INSTALLATION.md). Run `examples/StudioSmoke.client.lua` as a LocalScript under StarterPlayerScripts, by itself, with the showcase launcher disabled. It asserts actual engine section measurement, typed flags/configuration, popup replacement, theme identity preservation, soft close/restore, and resource teardown. It prints **AURELIS: engine smoke checks passed** when complete.

That script is included for reproducibility; it has not been reported as executed here.

## Visual and device sign-off

1. Run the seven-page showcase in Studio Play. Inspect Eclipse, all other themes, tooltips, transitions, icons and long descriptions at 1920×1080 and 1280×720.
2. Resize through 700/699/500/499 px; test 390 px portrait and a short landscape viewport. Verify the drawer, row reflow, scroll bounds, popups near each edge and text entry with the mobile keyboard.
3. Drag and resize by mouse and touch. Double-click/tap the title area, snap left/right/top, minimize, close, use the dock to restore, and overlap two windows.
4. Exercise dropdown search/up/down/Enter, multi selection and a second popup. Edit SV/hue/alpha/RGB/HSV/HEX. Confirm invalid edits cannot corrupt flags.
5. Open each modal kind; test Escape, Tab, destructive default focus, input validation and callbacks that open a second dialog. Verify background controls cannot receive app input.
6. Search for a control inside a collapsed section/nested page; confirm navigation, scrolling and highlight. Inspect notification history after toasts expire.
7. With a persistent adapter, save/relaunch/load, rename/delete, and load malformed/outdated configuration fixtures.
8. Enable the developer panel, construct the 150-control fixture, measure responsiveness and memory on target devices, then destroy/recreate repeatedly. Use Studio MicroProfiler for renderer or input bottlenecks. Measure baseline and peak counts instead of assuming the headless construction result proves a framerate.

Current integration limits are explicit: filesystem and clipboard are injected platform capabilities; default config storage is session-local; blur is a world Lighting effect; password masking is visual; motion speed is shared by windows in one application. The showcase's Player/Visuals/Automation settings demonstrate UI state and a finite simulated task rather than gameplay automation.
