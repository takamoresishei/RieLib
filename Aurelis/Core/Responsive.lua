--!strict
local Responsive = {}
function Responsive.breakpoint(width)
    return width >= 700 and "Desktop" or (width >= 500 and "Compact" or "Mobile")
end
function Responsive.initialSize(preferred, viewport, minimum)
    -- Leave room around a floating window, including on short landscape phone screens.
    if viewport.X < 1 or viewport.Y < 1 then
        return preferred
    end
    return Vector2.new(
        math.min(preferred.X, math.max(minimum.X, math.floor(viewport.X * 0.82))),
        math.min(preferred.Y, math.max(minimum.Y, math.floor(viewport.Y * 0.82)))
    )
end
function Responsive.geometry(position, size, viewport, minimum)
    local maximum = Vector2.new(math.max(1, viewport.X - 16), math.max(1, viewport.Y - 16))
    local actual = Vector2.new(
        math.clamp(size.X, math.min(minimum.X, maximum.X), maximum.X),
        math.clamp(size.Y, math.min(minimum.Y, maximum.Y), maximum.Y)
    )
    return Vector2.new(
        math.clamp(position.X, 8, math.max(8, viewport.X - actual.X - 8)),
        math.clamp(position.Y, 8, math.max(8, viewport.Y - actual.Y - 8))
    ),
        actual
end
return Responsive
