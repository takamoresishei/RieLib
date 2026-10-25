--!nonstrict
local Cleanup = {}
Cleanup.__index = Cleanup
Cleanup.Stats = { Connections = 0, Resources = 0 }

local function release(item)
    if type(item) == "function" then
        item()
    elseif typeof(item) == "Instance" then
        item:Destroy()
    elseif item.Disconnect then
        item:Disconnect()
    elseif item.Destroy then
        item:Destroy()
    elseif item.Cancel then
        item:Cancel()
    end
end

function Cleanup.new()
    return setmetatable({ _items = {}, _dead = false }, Cleanup)
end
function Cleanup:Give(item)
    if self._dead then
        release(item)
        return item
    end
    if self._items[item] ~= nil then
        return item
    end
    local connection = typeof(item) == "RBXScriptConnection"
        or (type(item) == "table" and item.Disconnect ~= nil)
    self._items[item] = connection
    Cleanup.Stats.Resources += 1
    if connection then
        Cleanup.Stats.Connections += 1
    end
    return item
end
function Cleanup:Remove(item)
    local connection = self._items[item]
    if connection == nil then
        return
    end
    self._items[item] = nil
    Cleanup.Stats.Resources -= 1
    if connection then
        Cleanup.Stats.Connections -= 1
    end
    local ok, err = pcall(release, item)
    if not ok then
        warn("[Aurelis cleanup] " .. tostring(err))
    end
end
function Cleanup:Destroy()
    if self._dead then
        return
    end
    self._dead = true
    local items = {}
    for item in pairs(self._items) do
        table.insert(items, item)
    end
    for index = #items, 1, -1 do
        self:Remove(items[index])
    end
end
return Cleanup
