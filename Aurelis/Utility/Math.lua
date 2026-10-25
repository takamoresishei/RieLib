--!strict
local Math = {}
function Math.finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Math.round(value, minimum, maximum, increment)
    assert(Math.finite(minimum) and Math.finite(maximum) and maximum >= minimum, "Invalid bounds")
    increment = increment or 1
    assert(Math.finite(increment) and increment > 0, "Increment must be positive")
    value = Math.finite(value) and value or minimum
    if value <= minimum then
        return minimum
    end
    if value >= maximum then
        return maximum
    end
    local rounded = minimum + math.floor((value - minimum) / increment + 0.5) * increment
    return math.clamp(tonumber(string.format("%.8f", rounded)), minimum, maximum)
end
function Math.fraction(value, minimum, maximum)
    return maximum == minimum and 0 or math.clamp((value - minimum) / (maximum - minimum), 0, 1)
end
function Math.place(anchor, size, viewport, preferBelow, anchorHeight)
    local x = math.clamp(anchor.X, 8, math.max(8, viewport.X - size.X - 8))
    local y = anchor.Y
    if preferBelow and y + size.Y > viewport.Y - 8 then
        y = anchor.Y - size.Y - (anchorHeight or 0) - 12
    end
    return Vector2.new(x, math.clamp(y, 8, math.max(8, viewport.Y - size.Y - 8)))
end
-- Subsequence fuzzy matching, rewarding word starts and adjacent characters.
function Math.fuzzy(query, candidate)
    query, candidate = string.lower(query), string.lower(candidate)
    if query == "" then
        return 0
    end
    local cursor, score, previous = 1, 0, -2
    for index = 1, #query do
        local found = string.find(candidate, string.sub(query, index, index), cursor, true)
        if not found then
            return nil
        end
        score += 10 + (found == previous + 1 and 12 or 0)
        if found == 1 or string.match(string.sub(candidate, found - 1, found - 1), "[%s/._-]") then
            score += 8
        end
        previous, cursor = found, found + 1
    end
    return score - #candidate * 0.02
end
return Math
