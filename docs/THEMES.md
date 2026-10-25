# Themes and visual system

AURELIS uses semantic tokens. Every owned theme binding is released with its component scope; switching a theme updates existing instances. Color changes on GUI objects animate where practical. Structural properties such as corner radius update directly. Interaction-state colors are reapplied from the current tokens.

## Built-in themes

| Theme | Treatment |
| --- | --- |
| Eclipse | Near-black blue-grey layers, lavender accent; default |
| Obsidian | Neutral dark surfaces, warm sand accent |
| Graphite | Raised charcoal surfaces, muted blue accent |
| Tokyo | Indigo-black surfaces, soft pink accent |
| OLED | True-black background, pale neutral accent |
| Frost | Cool slate surfaces, cyan accent |
| Light | Pale surfaces, dark text, violet accent |

```lua
Window:SetTheme("Tokyo")
Aurelis:SetTheme("Light") -- App overlays and every window
Window:SetTheme({Accent=Color3.fromRGB(120,90,255),Radius=14})
```

An override table merges into the current window theme. A named theme replaces all standard tokens. `Window.Theme.Name` reports the last selected named theme; overrides do not invent a new name.

## Tokens

| Token | Type / role |
| --- | --- |
| Background | Color3, application shell and input wells |
| Surface | Color3, navigation and section/card surfaces |
| SurfaceElevated | Color3, popovers and hover/selection surfaces |
| Border / BorderStrong | Color3, dividers and selected boundaries |
| TextPrimary | Color3, main text |
| TextSecondary | Color3, secondary text and icons |
| TextMuted | Color3, descriptions and supporting metadata |
| Accent / AccentHover | Color3, primary interactions and accent treatment |
| Success / Warning / Danger | Color3, semantic feedback |
| Radius | Number 0–24, major surface radius; default 12 |
| Transparency | Number 0–0.65, shell transparency; default 0.02 |
| AnimationSpeed | Number 0–4, motion multiplier; 0 disables animation |

Fixed compact control radii of 5–8 px and pill/circle radii remain intentionally smaller than major surfaces. Borders are one pixel with low-opacity treatment. Icons use a shared original 24-unit vector grid. Acrylic is a translucent, lightly graded shell; the engine's Lighting BlurEffect affects the 3D world behind the GUI. The framework does not claim per-panel backdrop capture/blur of sibling GUI layers.

## Live editor

The showcase Settings page provides built-in theme selection, color editors for Accent/Background/Surface/Border/TextPrimary, corner radius, transparency, animation speed, scale and menu key. Theme-token edits update the live interface. Theme changes silently synchronize the editor's controls and flags so their displayed values match the preview.

For another app, compose the same controls:

```lua
Settings:AddColorPicker({
    Title="Accent",Default=Window.Theme.Tokens.Accent,
    Callback=function(color) Window:SetTheme({Accent=color}) end,
})
Settings:AddSlider({
    Title="Motion",Min=0,Max=3,Increment=0.1,Default=1,
    Callback=function(value) Window:SetTheme({AnimationSpeed=value}) end,
})
```

Window themes are independent. Motion scheduling belongs to the application, so `AnimationSpeed` changes affect the app's shared scheduler. If two windows need independent motion speeds, use separate application objects. Set `Aurelis.Motion.Speed=0` for instant transitions without reconstructing the GUI.
