--!nonstrict
-- Original 24-unit vector glyphs. No font, network, texture atlas, or asset permission dependency.
local Gui = require(script.Parent.Gui)
local Icons = {}
local glyphs = {}
local function path(...)
    return { Kind = "Path", Points = { ... } }
end
local function circle(x, y, radius)
    return { Kind = "Circle", X = x, Y = y, Radius = radius }
end
local function rect(x, y, w, h)
    return path(x, y, x + w, y, x + w, y + h, x, y + h, x, y)
end
glyphs.home =
    { path(3, 11, 12, 3, 21, 11), path(5, 10, 5, 21, 10, 21, 10, 15, 14, 15, 14, 21, 19, 21, 19, 10) }
glyphs.user = { circle(12, 7, 4), path(4, 21, 4, 18, 7, 14, 17, 14, 20, 18, 20, 21) }
glyphs.users = {
    circle(9, 7, 3),
    circle(18, 8, 2),
    path(2, 21, 2, 17, 5, 13, 13, 13, 16, 17, 16, 21),
    path(18, 13, 22, 16, 22, 21),
}
glyphs.settings = {
    circle(12, 12, 4),
    path(
        10,
        2,
        14,
        2,
        15,
        5,
        18,
        6,
        21,
        6,
        23,
        10,
        20,
        12,
        20,
        15,
        21,
        18,
        18,
        21,
        15,
        20,
        12,
        22,
        9,
        20,
        6,
        21,
        3,
        18,
        4,
        15,
        2,
        12,
        4,
        9,
        3,
        6,
        6,
        3,
        9,
        4,
        10,
        2
    ),
}
glyphs.search = { circle(10, 10, 6), path(15, 15, 21, 21) }
glyphs.eye = { path(2, 12, 6, 7, 12, 5, 18, 7, 22, 12, 18, 17, 12, 19, 6, 17, 2, 12), circle(12, 12, 3) }
glyphs["eye-off"] =
    { path(3, 3, 21, 21), path(2, 12, 6, 7, 12, 5, 18, 7, 22, 12, 19, 16), path(15, 19, 9, 19, 3, 14, 2, 12) }
glyphs.code = { path(8, 5, 2, 12, 8, 19), path(16, 5, 22, 12, 16, 19), path(14, 3, 10, 21) }
glyphs.terminal = { rect(2, 3, 20, 18), path(6, 8, 10, 12, 6, 16), path(13, 16, 18, 16) }
glyphs.folder = { path(2, 7, 2, 21, 22, 21, 22, 7, 12, 7, 9, 3, 2, 3, 2, 7) }
glyphs.save = { path(3, 2, 18, 2, 22, 6, 22, 22, 2, 22, 2, 2, 3, 2), rect(6, 2, 10, 7), rect(6, 14, 12, 8) }
glyphs.download = { path(12, 2, 12, 16, 7, 11), path(12, 16, 17, 11), path(3, 16, 3, 22, 21, 22, 21, 16) }
glyphs.upload = { path(12, 17, 12, 3, 7, 8), path(12, 3, 17, 8), path(3, 16, 3, 22, 21, 22, 21, 16) }
glyphs.refresh = { path(20, 8, 17, 4, 9, 3, 4, 7, 3, 13, 6, 19, 13, 21, 19, 18), path(20, 2, 20, 8, 14, 8) }
glyphs.play = { path(6, 3, 21, 12, 6, 21, 6, 3) }
glyphs.pause = { rect(5, 3, 4, 18), rect(15, 3, 4, 18) }
glyphs.stop = { rect(5, 5, 14, 14) }
glyphs.trash = {
    path(3, 6, 21, 6),
    path(6, 6, 7, 22, 17, 22, 18, 6),
    path(9, 6, 9, 2, 15, 2, 15, 6),
    path(10, 10, 10, 18),
    path(14, 10, 14, 18),
}
glyphs.edit = { path(3, 16, 16, 3, 21, 8, 8, 21, 2, 22, 3, 16), path(13, 6, 18, 11) }
glyphs.copy = { rect(8, 8, 14, 14), path(4, 17, 2, 17, 2, 2, 17, 2, 17, 4) }
glyphs.check = { path(4, 12, 10, 18, 21, 5) }
glyphs.x = { path(5, 5, 19, 19), path(19, 5, 5, 19) }
glyphs.warning = { path(12, 2, 23, 22, 1, 22, 12, 2), path(12, 8, 12, 14), circle(12, 18, 0.7) }
glyphs.info = { circle(12, 12, 10), path(12, 11, 12, 18), circle(12, 6, 0.7) }
glyphs["chevron-right"] = { path(9, 5, 16, 12, 9, 19) }
glyphs["chevron-left"] = { path(15, 5, 8, 12, 15, 19) }
glyphs["chevron-down"] = { path(5, 9, 12, 16, 19, 9) }
glyphs["chevron-up"] = { path(5, 15, 12, 8, 19, 15) }
glyphs["arrow-up"] = { path(12, 22, 12, 2, 5, 9), path(12, 2, 19, 9) }
glyphs["arrow-down"] = { path(12, 2, 12, 22, 5, 15), path(12, 22, 19, 15) }
glyphs["arrow-left"] = { path(22, 12, 2, 12, 9, 5), path(2, 12, 9, 19) }
glyphs["arrow-right"] = { path(2, 12, 22, 12, 15, 5), path(22, 12, 15, 19) }
glyphs.plus = { path(12, 4, 12, 20), path(4, 12, 20, 12) }
glyphs.minus = { path(4, 12, 20, 12) }
glyphs.activity = { path(1, 12, 5, 12, 9, 3, 14, 21, 18, 12, 23, 12) }
glyphs.bell = { path(4, 17, 6, 13, 6, 7, 9, 3, 15, 3, 18, 7, 18, 13, 20, 17, 4, 17), path(9, 21, 15, 21) }
glyphs.menu = { path(3, 5, 21, 5), path(3, 12, 21, 12), path(3, 19, 21, 19) }
glyphs.grid = { rect(3, 3, 7, 7), rect(14, 3, 7, 7), rect(3, 14, 7, 7), rect(14, 14, 7, 7) }
glyphs.maximize = { rect(4, 4, 16, 16) }
glyphs.restore = { rect(3, 7, 14, 14), path(7, 3, 21, 3, 21, 17) }
glyphs.move = {
    path(12, 1, 12, 23),
    path(1, 12, 23, 12),
    path(8, 5, 12, 1, 16, 5),
    path(8, 19, 12, 23, 16, 19),
    path(5, 8, 1, 12, 5, 16),
    path(19, 8, 23, 12, 19, 16),
}
glyphs.zap = { path(13, 1, 3, 14, 11, 14, 10, 23, 21, 9, 13, 9, 13, 1) }
glyphs.shield = { path(12, 2, 21, 6, 20, 15, 16, 20, 12, 23, 8, 20, 4, 15, 3, 6, 12, 2) }
glyphs.lock = { rect(4, 10, 16, 12), path(7, 10, 7, 6, 9, 2, 15, 2, 17, 6, 17, 10), path(12, 15, 12, 18) }
glyphs.unlock = { rect(4, 10, 16, 12), path(7, 10, 7, 6, 9, 2, 15, 2, 18, 5), path(12, 15, 12, 18) }
glyphs.clock = { circle(12, 12, 10), path(12, 5, 12, 12, 17, 15) }
glyphs.heart = { path(12, 21, 2, 11, 2, 6, 6, 2, 10, 2, 12, 5, 14, 2, 18, 2, 22, 6, 22, 11, 12, 21) }
glyphs.star = { path(12, 2, 15, 8, 22, 9, 17, 14, 18, 22, 12, 18, 6, 22, 7, 14, 2, 9, 9, 8, 12, 2) }
glyphs.link = {
    path(9, 8, 14, 3, 19, 3, 22, 6, 22, 11, 17, 16),
    path(7, 8, 2, 13, 2, 18, 6, 22, 11, 22, 16, 17),
    path(8, 16, 16, 8),
}
glyphs.globe = {
    circle(12, 12, 10),
    path(2, 12, 22, 12),
    path(12, 2, 8, 7, 7, 12, 8, 17, 12, 22, 16, 17, 17, 12, 16, 7, 12, 2),
}
glyphs.wifi = {
    path(2, 7, 7, 3, 17, 3, 22, 7),
    path(6, 12, 10, 9, 14, 9, 18, 12),
    path(9, 16, 12, 14, 15, 16),
    circle(12, 20, 1),
}
glyphs.cpu = {
    rect(6, 6, 12, 12),
    rect(9, 9, 6, 6),
    path(9, 1, 9, 6),
    path(15, 1, 15, 6),
    path(9, 18, 9, 23),
    path(15, 18, 15, 23),
    path(1, 9, 6, 9),
    path(1, 15, 6, 15),
    path(18, 9, 23, 9),
    path(18, 15, 23, 15),
}
glyphs.chart = {
    path(3, 2, 3, 22, 23, 22),
    path(7, 18, 7, 13),
    path(12, 18, 12, 8),
    path(17, 18, 17, 4),
    path(22, 18, 22, 10),
}
glyphs.palette = {
    path(12, 2, 5, 4, 2, 10, 3, 17, 9, 22, 14, 22, 16, 19, 14, 16, 17, 13, 21, 13, 22, 9, 19, 4, 12, 2),
    circle(7, 9, 1),
    circle(12, 6, 1),
    circle(17, 8, 1),
    circle(6, 14, 1),
}
glyphs.sliders = {
    path(5, 2, 5, 8),
    path(5, 14, 5, 22),
    rect(2, 8, 6, 6),
    path(12, 2, 12, 14),
    rect(9, 14, 6, 5),
    path(12, 19, 12, 22),
    path(20, 2, 20, 5),
    rect(17, 5, 6, 6),
    path(20, 11, 20, 22),
}
glyphs.keyboard = {
    rect(1, 5, 22, 14),
    path(5, 9, 7, 9),
    path(11, 9, 13, 9),
    path(17, 9, 19, 9),
    path(5, 13, 7, 13),
    path(11, 13, 13, 13),
    path(17, 13, 19, 13),
    path(7, 16, 17, 16),
}
glyphs.file = {
    path(4, 2, 14, 2, 21, 9, 21, 22, 4, 22, 4, 2),
    path(14, 2, 14, 9, 21, 9),
    path(8, 14, 17, 14),
    path(8, 18, 15, 18),
}
glyphs.filter = { path(2, 3, 22, 3, 15, 12, 15, 20, 9, 23, 9, 12, 2, 3) }
glyphs.help =
    { circle(12, 12, 10), path(8, 8, 9, 5, 14, 5, 16, 8, 15, 10, 12, 12, 12, 15), circle(12, 19, 0.7) }
glyphs.logout = { path(10, 3, 3, 3, 3, 21, 10, 21), path(8, 12, 22, 12, 17, 7), path(22, 12, 17, 17) }
glyphs.sparkles = { path(12, 1, 15, 9, 23, 12, 15, 15, 12, 23, 9, 15, 1, 12, 9, 9, 12, 1) }
glyphs.resize = { path(7, 21, 21, 7), path(14, 21, 21, 14), path(20, 21, 21, 20) }
glyphs.sun = {
    circle(12, 12, 4),
    path(12, 1, 12, 4),
    path(12, 20, 12, 23),
    path(1, 12, 4, 12),
    path(20, 12, 23, 12),
    path(4, 4, 6, 6),
    path(18, 18, 20, 20),
    path(4, 20, 6, 18),
    path(18, 6, 20, 4),
}
glyphs.moon = { path(19, 3, 12, 3, 6, 7, 3, 13, 5, 19, 11, 22, 17, 20, 21, 15, 15, 15, 11, 11, 12, 6, 19, 3) }
glyphs.database = {
    path(3, 5, 7, 2, 17, 2, 21, 5, 17, 8, 7, 8, 3, 5, 3, 19, 7, 22, 17, 22, 21, 19, 21, 5),
    path(3, 12, 7, 15, 17, 15, 21, 12),
}
glyphs.flag = { path(4, 23, 4, 2, 12, 2, 14, 5, 22, 5, 22, 16, 14, 16, 12, 13, 4, 13) }
glyphs.layers =
    { path(2, 8, 12, 2, 22, 8, 12, 14, 2, 8), path(2, 13, 12, 19, 22, 13), path(2, 18, 12, 24, 22, 18) }

function Icons:Get(name)
    assert(glyphs[name], "Unknown Aurelis icon: " .. tostring(name))
    return { Name = name, Paths = glyphs[name] }
end
function Icons:List()
    local result = {}
    for name in pairs(glyphs) do
        table.insert(result, name)
    end
    table.sort(result)
    return result
end
function Icons:Create(ctx, parent, name, properties, token)
    local descriptor = type(name) == "table" and name or self:Get(name)
    local props = { Size = UDim2.fromOffset(18, 18) }
    for key, value in pairs(properties or {}) do
        props[key] = value
    end
    local root = Gui.new(ctx, "Frame", props, nil, parent)
    for _, primitive in ipairs(descriptor.Paths) do
        if primitive.Kind == "Circle" then
            local ring = Gui.new(ctx, "Frame", {
                Position = UDim2.fromScale(
                    (primitive.X - primitive.Radius) / 24,
                    (primitive.Y - primitive.Radius) / 24
                ),
                Size = UDim2.fromScale(primitive.Radius / 12, primitive.Radius / 12),
            }, nil, root)
            Gui.corner(ctx, ring, 99)
            Gui.new(ctx, "UIStroke", { Thickness = 1.4 }, { Color = token or "TextSecondary" }, ring)
        else
            local points = primitive.Points
            for index = 1, #points - 2, 2 do
                local x, y, x2, y2 = points[index], points[index + 1], points[index + 2], points[index + 3]
                local length = math.sqrt((x2 - x) ^ 2 + (y2 - y) ^ 2)
                Gui.new(ctx, "Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale((x + x2) / 48, (y + y2) / 48),
                    Size = UDim2.new(length / 24, 0, 0, 1.4),
                    Rotation = math.deg(math.atan2(y2 - y, x2 - x)),
                    BackgroundTransparency = 0,
                }, { BackgroundColor3 = token or "TextSecondary" }, root)
            end
        end
    end
    return root
end
return Icons
