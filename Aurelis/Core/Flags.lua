--!nonstrict
local Signal = require(script.Parent.Parent.Utility.Signal)
local Table = require(script.Parent.Parent.Utility.Table)
local Flags = {}
Flags.__index = Flags
function Flags.new()
    local self = setmetatable({ _entries = {}, Changed = Signal.new() }, Flags)
    self.Values = setmetatable({}, {
        __index = function(_, key)
            return self:Get(key)
        end,
        __newindex = function(_, key, value)
            self:Set(key, value)
        end,
    })
    return self
end
function Flags:Register(key, default, normalize, apply, priority)
    assert(type(key) == "string" and key ~= "", "Flag must be a non-empty string")
    assert(not self._entries[key], "Duplicate flag: " .. key)
    local entry = {
        Default = Table.copy(default),
        Value = Table.copy(default),
        Normalize = normalize,
        Apply = apply,
        Priority = priority or 0,
    }
    self._entries[key] = entry
    return function()
        if self._entries[key] == entry then
            self._entries[key] = nil
        end
    end
end
function Flags:Get(key)
    local entry = self._entries[key]
    if entry then
        return Table.copy(entry.Value)
    end
    return nil
end
function Flags:Set(key, value, silent)
    local entry = self._entries[key]
    if not entry then
        return false, "Unknown flag: " .. tostring(key)
    end
    local ok, normalized = pcall(entry.Normalize, value)
    if not ok or normalized == nil then
        return false, "Invalid value for " .. key
    end
    if Table.equal(entry.Value, normalized) then
        return true
    end
    entry.Value = Table.copy(normalized)
    entry.Apply(Table.copy(normalized), silent == true)
    self.Changed:Fire(key, Table.copy(normalized))
    return true
end
function Flags:Snapshot()
    local result = {}
    for key, entry in pairs(self._entries) do
        result[key] = Table.copy(entry.Value)
    end
    return result
end
function Flags:Destroy()
    self.Changed:Destroy()
    table.clear(self._entries)
end
return Flags
