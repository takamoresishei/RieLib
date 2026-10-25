# Installation

## ModuleScript model

Download `dist/Aurelis.rbxmx` using GitHub's download/raw button. In Studio, insert it with **Insert from File**, then move the root `Aurelis` ModuleScript to `ReplicatedStorage`. Keep its child folders and ModuleScripts together. Require it from a client `LocalScript`.

Use `examples/Minimal.client.lua` for a small integration or `examples/Showcase.client.lua` for the seven-page demo. The library requires a local player; it is not a server UI or a plugin widget.

## Rojo source workflow

Install Rojo and its Studio plugin. From the repository root:

```sh
rojo serve default.project.json
```

Connect Studio to the local Rojo server and sync. The project maps `Aurelis/` to `ReplicatedStorage.Aurelis` and the showcase to `StarterPlayer.StarterPlayerScripts`. `Aurelis/init.lua` becomes the root ModuleScript.

## Bundle workflow

`dist/Aurelis.lua` contains a dependency loader and all framework modules. It returns the same singleton as `require(ReplicatedStorage.Aurelis)`. `dist/Showcase.lua` additionally invokes the showcase module and returns the application and window. There are no runtime dependency downloads inside either artifact.

```lua
local Aurelis = loadstring(game:HttpGet("https://raw.githubusercontent.com/takamoresishei/RieLib/main/dist/Aurelis.lua"))()
local Window = Aurelis:CreateWindow({Title = "Tools", Theme = "Eclipse"})
```

This path requires a client host that supplies these two functions. Standard Studio client scripts should use the ModuleScript distribution. A host may supply a custom `Parent` to `CreateWindow`, or an application default using `Aurelis.New({Parent = guiContainer})`.

## Independent applications

```lua
local App = Aurelis.New({DisplayOrder = 120})
local Window = App:CreateWindow({Title = "Separate state"})
-- App has separate flags, commands, configuration, history and overlays.
App:Destroy()
```

Multiple windows in one app share input, commands, flags, notification history and the overlay portal. Use distinct flag names. Themes can be set per window.

## Optional filesystem and clipboard

The default configuration adapter retains configs for the lifetime of the application object. To persist across launches, inject an adapter. In hosts providing sandboxed filesystem functions:

```lua
local Config = require(game.ReplicatedStorage.Aurelis.Services.Config)
Aurelis.Config:UseAdapter(Config.FileAdapter({
    readfile = readfile, writefile = writefile, delfile = delfile,
    listfiles = listfiles, isfolder = isfolder, makefolder = makefolder,
}, "AurelisConfigs"))
Aurelis.Clipboard = setclipboard
```

For a bundled library, the identical adapter constructor is available as `Aurelis.Config.FileAdapter(...)` through the service metatable. No globals are probed automatically. Studio games can provide a server-backed adapter or export/import config JSON explicitly. Server-side storage authorization remains the integrating game's responsibility.

Without a clipboard adapter, **Copy value** presents the value in an input dialog for platform-native text selection. Icons use local geometry, so asset permissions and HTTP settings do not affect them. Engine `BlurEffect` blurs the world behind the GUI; Acrylic adds translucent surface treatment.

## Updating

Replace the complete ModuleScript model, or sync the complete source tree. Destroy the old application before initializing another copy during hot reload. Rebuild `dist/` after source changes with `python tools/build.py`. The generated SHA-256 manifest records each distribution file's exact contents.
