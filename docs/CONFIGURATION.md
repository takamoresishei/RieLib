# Flags and configurations

Flags form one typed state store per application. A component registers its flag, default, normalizer and apply function. Reads return a defensive copy. UI edits, direct API edits and configuration imports use the same normalizer.

```lua
Section:AddSlider({Title="Speed",Flag="player.movement.speed",Min=0,Max=100,Default=16})
print(Aurelis.Flags["player.movement.speed"])
Aurelis:SetValue("player.movement.speed",75)
Aurelis.Flags["player.movement.speed"] = 50
```

Duplicate flag names are rejected. Destroying a component unregisters its flags. Unknown flag updates return `false, message`. Non-finite numbers and mismatched value types are rejected; bounded controls clamp and round legal numeric values.

## Save/load

```lua
local ok, result = Aurelis.Config:Save("Default")
local loaded, report = Aurelis.Config:Load("Default")
if loaded then print(#report.Applied, #report.Skipped) end
Aurelis.Config:Rename("Default","Main")
print(Aurelis.Config:List())
Aurelis.Config:Delete("Main")
```

Save/load/delete/rename return `success, resultOrError`. List returns sorted names from the configured adapter. Names contain 1–64 letters/digits/spaces/underscores/hyphens; path separators and traversal are rejected. Rename refuses an existing destination and attempts to roll back the new copy if deleting the old one fails.

The default adapter keeps files in memory for the application session. Persistence is an explicit integration: see [Installation](INSTALLATION.md). The framework does not label an in-memory save as cross-session persistence.

## Serialization and compatibility

```json
{
  "SchemaVersion": 1,
  "Flags": {
    "movement.enabled": false,
    "movement.speed": 16,
    "accent": {"__aurelis":"Color3","R":0.5,"G":0.25,"B":1},
    "accent.alpha": 0.8
  }
}
```

Color3 values and KeyCode enum items use tagged records. Keybinds retain both Key and Mode. Pickers automatically use a second `Flag..".alpha"` flag. Text, boolean, number and supported array values retain their types.

`Config:Export()` returns current JSON. `Config:Import(json, silent?)` returns `success, reportOrError`. `Config:Load(name, silent?)` uses the same importer. Imports are limited to 1 MiB and 16 nested levels. A document without SchemaVersion is accepted as version 0 if it has a Flags object. Future schema versions, malformed JSON and invalid envelopes fail without changing flags. Unknown/invalid individual values are skipped and reported; valid values are normalized before application. This is tolerant loading, not an all-or-nothing transaction.

Valid entries apply by ascending `ConfigPriority`, then flag name. Callbacks run by default. This lets a theme preset load before its per-token overrides; the showcase uses priority -100 for the theme preset. `silent=true` updates controls/signals without invoking application callbacks. Components must be registered before loading; imports do not create controls or queue unknown flags for later registration.

## Adapter contract

```lua
Aurelis.Config:UseAdapter({
    Read=function(name) return jsonText end,
    Write=function(name,jsonText) ... end,
    Delete=function(name) ... end,
    List=function() return {"Default","Main"} end,
})
```

These are plain functions invoked without `self`. The callbacks run synchronously and may yield if the host requires it; errors are caught by mutation/load methods. Keep IO latency in mind when invoking them from UI callbacks. Custom adapters own storage durability and any network authorization. `Config.MemoryAdapter()` and `Config.FileAdapter(fs,folder)` are provided through both the source Config module and `Aurelis.Config`'s metatable.
