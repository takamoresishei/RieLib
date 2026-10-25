--!nonstrict
local Signal = require(script.Parent.Parent.Utility.Signal)
local Table = require(script.Parent.Parent.Utility.Table)
local Theme = {}
Theme.__index = Theme
local rgb = Color3.fromRGB
local eclipse = {
    Background = rgb(12, 13, 18),
    Surface = rgb(20, 22, 29),
    SurfaceElevated = rgb(28, 30, 39),
    Border = rgb(45, 48, 61),
    BorderStrong = rgb(77, 81, 100),
    TextPrimary = rgb(239, 240, 247),
    TextSecondary = rgb(161, 166, 188),
    TextMuted = rgb(111, 117, 139),
    Accent = rgb(155, 137, 255),
    AccentHover = rgb(177, 163, 255),
    Success = rgb(102, 209, 167),
    Warning = rgb(241, 189, 111),
    Danger = rgb(238, 112, 132),
    Radius = 12,
    Transparency = 0.02,
    AnimationSpeed = 1,
}
local function variant(overrides)
    local tokens = Table.copy(eclipse)
    for key, value in pairs(overrides) do
        tokens[key] = value
    end
    return tokens
end
Theme.Themes = {
    Eclipse = eclipse,
    Obsidian = variant({
        Background = rgb(14, 14, 16),
        Surface = rgb(23, 23, 27),
        Accent = rgb(209, 162, 119),
    }),
    Graphite = variant({
        Background = rgb(29, 31, 35),
        Surface = rgb(37, 40, 46),
        Accent = rgb(142, 183, 220),
    }),
    Tokyo = variant({ Background = rgb(19, 20, 32), Surface = rgb(28, 29, 46), Accent = rgb(255, 143, 179) }),
    OLED = variant({
        Background = rgb(0, 0, 0),
        Surface = rgb(8, 8, 10),
        SurfaceElevated = rgb(19, 19, 23),
        Accent = rgb(208, 211, 232),
    }),
    Frost = variant({ Background = rgb(22, 32, 42), Surface = rgb(30, 44, 56), Accent = rgb(125, 211, 227) }),
    Light = variant({
        Background = rgb(236, 239, 245),
        Surface = rgb(249, 250, 253),
        SurfaceElevated = rgb(255, 255, 255),
        Border = rgb(215, 219, 230),
        BorderStrong = rgb(157, 166, 187),
        TextPrimary = rgb(27, 32, 47),
        TextSecondary = rgb(80, 90, 112),
        TextMuted = rgb(113, 123, 145),
        Accent = rgb(103, 79, 210),
        AccentHover = rgb(123, 101, 226),
    }),
}
function Theme.new(motion, name)
    assert(name == nil or Theme.Themes[name], "Unknown theme: " .. tostring(name))
    return setmetatable({
        Name = name or "Eclipse",
        Tokens = Table.copy(Theme.Themes[name or "Eclipse"] or eclipse),
        Changed = Signal.new(),
        Motion = motion,
        _bindings = {},
    }, Theme)
end
function Theme:Set(theme)
    local tokens = type(theme) == "string" and Theme.Themes[theme] or theme
    assert(type(tokens) == "table", "Unknown theme")
    if type(theme) == "string" then
        self.Name = theme
    end
    for key, value in pairs(tokens) do
        if eclipse[key] ~= nil then
            if typeof(eclipse[key]) == "Color3" then
                assert(typeof(value) == "Color3", key .. " requires Color3")
            else
                assert(
                    type(value) == "number" and value == value and math.abs(value) < math.huge,
                    "Invalid theme number"
                )
            end
        end
    end
    for key, value in pairs(tokens) do
        if eclipse[key] ~= nil then
            self.Tokens[key] = value
        end
    end
    self.Tokens.Radius = math.clamp(self.Tokens.Radius, 0, 24)
    self.Tokens.Transparency = math.clamp(self.Tokens.Transparency, 0, 0.65)
    self.Tokens.AnimationSpeed = math.clamp(self.Tokens.AnimationSpeed, 0, 4)
    self.Motion.Speed = self.Tokens.AnimationSpeed
    for object, mapping in pairs(self._bindings) do
        self:_apply(object, mapping, true)
    end
    self.Changed:Fire(self.Tokens)
end
function Theme:_apply(object, mapping, animated)
    local values = {}
    for property, token in pairs(mapping) do
        values[property] = type(token) == "function" and token(self.Tokens) or self.Tokens[token]
    end
    if animated and object:IsA("GuiObject") then
        self.Motion:Tween(object, values, "Normal")
    else
        for property, value in pairs(values) do
            object[property] = value
        end
    end
end
function Theme:Bind(object, mapping)
    self._bindings[object] = mapping
    self:_apply(object, mapping, false)
    return function()
        self._bindings[object] = nil
        self.Motion:Cancel(object)
    end
end
function Theme:Destroy()
    self.Changed:Destroy()
    table.clear(self._bindings)
end
return Theme
