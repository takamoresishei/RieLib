--!strict
local Table = {}
function Table.copy(value)
    if typeof(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = Table.copy(item)
    end
    return result
end
function Table.equal(a, b)
    if typeof(a) ~= typeof(b) then
        return false
    end
    if typeof(a) ~= "table" then
        return a == b
    end
    for key, value in pairs(a) do
        if not Table.equal(value, b[key]) then
            return false
        end
    end
    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end
    return true
end
function Table.removeValue(list, item)
    local index = table.find(list, item)
    if index then
        table.remove(list, index)
    end
end
return Table
