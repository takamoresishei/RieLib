--!nonstrict
local Math = require(script.Parent.Parent.Utility.Math)
local Commands = {}
Commands.__index = Commands
function Commands.new()
    return setmetatable({ _items = {}, _next = 0 }, Commands)
end
function Commands:Register(options)
    assert(
        type(options.Name) == "string" and type(options.Callback) == "function",
        "Command needs Name and Callback"
    )
    self._next += 1
    local item = {
        Name = options.Name,
        Keywords = options.Keywords or {},
        Callback = options.Callback,
        Order = self._next,
    }
    self._items[item] = true
    local service = self
    return {
        Destroy = function()
            service._items[item] = nil
        end,
    }
end
function Commands:Search(query)
    local results = {}
    for item in pairs(self._items) do
        local score = Math.fuzzy(query, item.Name .. " " .. table.concat(item.Keywords, " "))
        if score then
            table.insert(
                results,
                { Name = item.Name, Callback = item.Callback, Score = score, Order = item.Order }
            )
        end
    end
    table.sort(results, function(a, b)
        return a.Score == b.Score and a.Order < b.Order or a.Score > b.Score
    end)
    return results
end
function Commands:Destroy()
    table.clear(self._items)
end
return Commands
