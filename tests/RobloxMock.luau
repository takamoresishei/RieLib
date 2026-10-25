-- A deterministic headless contract harness. It does not simulate Roblox rendering or GPU costs.
local nativeTypeof = typeof
local function typeof(value)
    local mt = type(value) == "table" and getmetatable(value)
    return mt and mt.__type or nativeTypeof(value)
end
local function event()
    local self = { listeners = {} }
    function self:Connect(callback)
        local connection = { Connected = true }
        self.listeners[connection] = callback
        function connection:Disconnect()
            self.Connected = false
        end
        return connection
    end
    function self:Fire(...)
        local snapshot = {}
        for connection, callback in pairs(self.listeners) do
            if connection.Connected then
                table.insert(snapshot, { connection, callback })
            end
        end
        for _, entry in ipairs(snapshot) do
            if entry[1].Connected then
                entry[2](...)
            end
        end
    end
    return self
end
local Vector2 = {}
local vectorMt = { __type = "Vector2" }
function Vector2.new(x, y)
    return setmetatable({ X = x or 0, Y = y or 0 }, vectorMt)
end
vectorMt.__add = function(a, b)
    return Vector2.new(a.X + b.X, a.Y + b.Y)
end
vectorMt.__sub = function(a, b)
    return Vector2.new(a.X - b.X, a.Y - b.Y)
end
vectorMt.__mul = function(a, b)
    if type(a) == "number" then
        return Vector2.new(a * b.X, a * b.Y)
    end
    return Vector2.new(a.X * b, a.Y * b)
end
vectorMt.__div = function(a, b)
    return Vector2.new(a.X / b, a.Y / b)
end
vectorMt.__eq = function(a, b)
    return a.X == b.X and a.Y == b.Y
end
vectorMt.__index = function(a, key)
    if key == "Magnitude" then
        return math.sqrt(a.X * a.X + a.Y * a.Y)
    end
end
local Vector3 = {
    new = function(x, y, z)
        return { X = x, Y = y, Z = z }
    end,
}
local UDim = {
    new = function(scale, offset)
        return { Scale = scale, Offset = offset }
    end,
}
local UDim2 = {}
function UDim2.new(xs, xo, ys, yo)
    return setmetatable(
        { X = UDim.new(xs or 0, xo or 0), Y = UDim.new(ys or 0, yo or 0) },
        { __type = "UDim2" }
    )
end
function UDim2.fromOffset(x, y)
    return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
    return UDim2.new(x, 0, y, 0)
end
local Color3 = {}
local colorMt = { __type = "Color3" }
colorMt.__index = colorMt
function Color3.new(r, g, b)
    return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, colorMt)
end
function Color3.fromRGB(r, g, b)
    return Color3.new(r / 255, g / 255, b / 255)
end
function Color3.fromHex(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end
function colorMt:ToHex()
    return string.format(
        "%02x%02x%02x",
        math.floor(self.R * 255 + 0.5),
        math.floor(self.G * 255 + 0.5),
        math.floor(self.B * 255 + 0.5)
    )
end
function Color3.fromHSV(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    local list = { { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } }
    local c = list[i % 6 + 1]
    return Color3.new(c[1], c[2], c[3])
end
function colorMt:ToHSV()
    local maximum, minimum = math.max(self.R, self.G, self.B), math.min(self.R, self.G, self.B)
    local delta = maximum - minimum
    local h = 0
    if delta ~= 0 then
        if maximum == self.R then
            h = ((self.G - self.B) / delta) % 6
        elseif maximum == self.G then
            h = (self.B - self.R) / delta + 2
        else
            h = (self.R - self.G) / delta + 4
        end
    end
    return h / 6, maximum == 0 and 0 or delta / maximum, maximum
end
colorMt.__eq = function(a, b)
    return math.abs(a.R - b.R) < 1e-7 and math.abs(a.G - b.G) < 1e-7 and math.abs(a.B - b.B) < 1e-7
end
local Enum = setmetatable({}, {
    __index = function(self, kind)
        local enum = setmetatable({}, {
            __index = function(group, key)
                local item = setmetatable({ Name = key, EnumType = group }, {
                    __type = "EnumItem",
                    __tostring = function()
                        return "Enum." .. kind .. "." .. key
                    end,
                })
                rawset(group, key, item)
                return item
            end,
        })
        rawset(self, kind, enum)
        return enum
    end,
})
local NumberSequenceKeypoint = {
    new = function(t, v)
        return { Time = t, Value = v }
    end,
}
local ColorSequenceKeypoint = NumberSequenceKeypoint
local NumberSequence = {
    new = function(...)
        return { ... }
    end,
}
local ColorSequence = NumberSequence
local TweenInfo = {
    new = function(...)
        return { ... }
    end,
}
local Mock =
    { time = 0, tasks = {}, viewport = Vector2.new(1280, 800), objects = {}, focused = nil, keys = {} }
local task = {}
function task.delay(seconds, callback)
    local item = { due = Mock.time + seconds, callback = callback, cancelled = false }
    table.insert(Mock.tasks, item)
    return item
end
function task.defer(callback)
    return task.delay(0, callback)
end
function task.cancel(item)
    item.cancelled = true
end
local properties, methods = {}, {}
local instanceMt = { __type = "Instance" }
local guiClasses = {
    Frame = true,
    CanvasGroup = true,
    ScrollingFrame = true,
    TextLabel = true,
    TextButton = true,
    TextBox = true,
    ImageLabel = true,
    ImageButton = true,
}
local events = {
    InputBegan = true,
    InputChanged = true,
    InputEnded = true,
    MouseEnter = true,
    MouseLeave = true,
    Activated = true,
    Focused = true,
    FocusLost = true,
    SelectionGained = true,
    SelectionLost = true,
    Destroying = true,
}
local function children(object)
    return rawget(object, "_children")
end
local function props(object)
    return rawget(object, "_props")
end
function methods:IsA(class)
    return class == self.ClassName
        or (class == "GuiObject" and guiClasses[self.ClassName])
        or (class == "GuiButton" and (self.ClassName == "TextButton" or self.ClassName == "ImageButton"))
end
function methods:GetChildren()
    return table.clone(children(self))
end
function methods:GetDescendants()
    local result = {}
    local function visit(parent)
        for _, child in ipairs(children(parent)) do
            table.insert(result, child)
            visit(child)
        end
    end
    visit(self)
    return result
end
function methods:FindFirstChild(name)
    for _, child in ipairs(children(self)) do
        if child.Name == name then
            return child
        end
    end
end
function methods:FindFirstChildOfClass(class)
    for _, child in ipairs(children(self)) do
        if child:IsA(class) then
            return child
        end
    end
end
function methods:WaitForChild(name)
    return assert(self:FindFirstChild(name), "Missing mock child " .. name)
end
function methods:IsDescendantOf(parent)
    local current = self.Parent
    while current do
        if current == parent then
            return true
        end
        current = current.Parent
    end
    return false
end
function methods:GetPropertyChangedSignal(property)
    local signals = rawget(self, "_signals")
    if not signals[property] then
        signals[property] = event()
    end
    return signals[property]
end
function methods:CaptureFocus()
    if Mock.focused and Mock.focused ~= self then
        Mock.focused:ReleaseFocus()
    end
    Mock.focused = self
    self.Focused:Fire()
    if Mock.onTextFocused then
        Mock.onTextFocused(self)
    end
end
function methods:ReleaseFocus(enter)
    if Mock.focused ~= self then
        return
    end
    Mock.focused = nil
    self.FocusLost:Fire(enter == true)
end
function methods:IsFocused()
    return Mock.focused == self
end
function methods:Destroy()
    if rawget(self, "_destroyed") then
        return
    end
    rawset(self, "_destroyed", true)
    self.Destroying:Fire()
    if Mock.focused == self then
        Mock.focused = nil
    end
    for _, child in ipairs(self:GetChildren()) do
        child:Destroy()
    end
    self.Parent = nil
end
local function localScale(object)
    local scale = object:FindFirstChildOfClass("UIScale")
    return scale and scale.Scale or 1
end
local function inheritedScale(object)
    local value = 1
    local parent = object
    while parent do
        value *= localScale(parent)
        parent = parent.Parent
    end
    return value
end
local function calculateSize(object)
    if object.ClassName == "ScreenGui" or object.ClassName == "PlayerGui" then
        return Mock.viewport
    end
    if not object:IsA("GuiObject") then
        return Vector2.new()
    end
    local p = props(object)
    local dim = p.Size or UDim2.new()
    local parent = object.Parent
    local parentSize = parent and parent.AbsoluteSize or Mock.viewport
    local factor = inheritedScale(object)
    local x = parentSize.X * dim.X.Scale + dim.X.Offset * factor
    local y = parentSize.Y * dim.Y.Scale + dim.Y.Offset * factor
    if p.AutomaticSize == Enum.AutomaticSize.Y then
        local list = object:FindFirstChildOfClass("UIListLayout")
        if list then
            y = 0
            local count = 0
            for _, child in ipairs(children(object)) do
                if child:IsA("GuiObject") and child.Visible then
                    -- Content lists use explicit vertical offsets, so they can be measured without a recursive parent query.
                    local size = props(child).Size or UDim2.new()
                    y += size.Y.Offset * factor
                    count += 1
                end
            end
            y += math.max(0, count - 1) * list.Padding.Offset * factor
        end
    end
    return Vector2.new(math.max(0, x), math.max(0, y))
end
instanceMt.__index = function(self, key)
    if methods[key] then
        return methods[key]
    end
    if events[key] then
        local signals = rawget(self, "_events")
        if not signals[key] then
            signals[key] = event()
        end
        return signals[key]
    end
    if key == "AbsoluteSize" then
        return calculateSize(self)
    end
    if key == "AbsolutePosition" then
        local parent = self.Parent
        if not parent or not parent:IsA("GuiObject") then
            return Vector2.new()
        end
        local position = self.Position or UDim2.new()
        local size = parent.AbsoluteSize
        local anchor = self.AnchorPoint or Vector2.new()
        local factor = inheritedScale(parent)
        return parent.AbsolutePosition
            + Vector2.new(
                size.X * position.X.Scale + position.X.Offset * factor,
                size.Y * position.Y.Scale + position.Y.Offset * factor
            )
            - Vector2.new(self.AbsoluteSize.X * anchor.X, self.AbsoluteSize.Y * anchor.Y)
    end
    if key == "AbsoluteContentSize" then
        local parent = self.Parent
        local width, height, count = 0, 0, 0
        if parent then
            for _, child in ipairs(children(parent)) do
                if child:IsA("GuiObject") and child.Visible then
                    local s = child.AbsoluteSize
                    width = math.max(width, s.X)
                    height += s.Y
                    count += 1
                end
            end
        end
        local gap = self.Padding and self.Padding.Offset or 0
        return Vector2.new(width, height + math.max(0, count - 1) * gap * inheritedScale(parent))
    end
    local value = props(self)[key]
    if value ~= nil then
        return value
    end
    return methods.FindFirstChild(self, key)
end
instanceMt.__newindex = function(self, key, value)
    local p = props(self)
    local old = p[key]
    if key == "Parent" and old ~= value then
        if old then
            local index = table.find(children(old), self)
            if index then
                table.remove(children(old), index)
            end
        end
        if value then
            table.insert(children(value), self)
        end
    end
    p[key] = value
    if old ~= value then
        local signal = rawget(self, "_signals")[key]
        if signal then
            signal:Fire()
        end
    end
end
local Instance = {}
function Instance.new(class)
    local object = setmetatable({
        _props = {
            ClassName = class,
            Name = class,
            Visible = true,
            Size = UDim2.new(),
            Position = UDim2.new(),
            AnchorPoint = Vector2.new(),
            BackgroundTransparency = 1,
            Text = "",
            Padding = UDim.new(0, 0),
            CanvasPosition = Vector2.new(),
            Scale = 1,
            Rotation = 0,
        },
        _children = {},
        _signals = {},
        _events = {},
    }, instanceMt)
    table.insert(Mock.objects, object)
    return object
end
local function jsonEncode(value)
    if value == nil then
        return "null"
    end
    if type(value) == "boolean" or type(value) == "number" then
        return tostring(value)
    end
    if type(value) == "string" then
        local text =
            value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
        return '"' .. text .. '"'
    end
    local array = #value > 0
    local parts = {}
    if array then
        for _, item in ipairs(value) do
            table.insert(parts, jsonEncode(item))
        end
    else
        for key, item in pairs(value) do
            table.insert(parts, jsonEncode(tostring(key)) .. ":" .. jsonEncode(item))
        end
        table.sort(parts)
    end
    return (array and "[" or "{") .. table.concat(parts, ",") .. (array and "]" or "}")
end
local function jsonDecode(text)
    local cursor = 1
    local parse
    local function skip()
        while text:sub(cursor, cursor):match("%s") do
            cursor += 1
        end
    end
    local function stringValue()
        cursor += 1
        local result = ""
        while cursor <= #text do
            local char = text:sub(cursor, cursor)
            cursor += 1
            if char == '"' then
                return result
            end
            if char == "\\" then
                char = text:sub(cursor, cursor)
                cursor += 1
                char = ({ n = "\n", r = "\r", t = "\t" })[char] or char
            end
            result ..= char
        end
        error("Unterminated JSON string")
    end
    parse = function()
        skip()
        local char = text:sub(cursor, cursor)
        if char == '"' then
            return stringValue()
        end
        if char == "{" or char == "[" then
            local closing = char == "{" and "}" or "]"
            local object = char == "{"
            local result = {}
            cursor += 1
            skip()
            if text:sub(cursor, cursor) == closing then
                cursor += 1
                return result
            end
            while cursor <= #text do
                local key = nil
                if object then
                    skip()
                    assert(text:sub(cursor, cursor) == '"', "Invalid JSON key")
                    key = stringValue()
                    skip()
                    assert(text:sub(cursor, cursor) == ":")
                    cursor += 1
                end
                local value = parse()
                if object then
                    result[key] = value
                else
                    table.insert(result, value)
                end
                skip()
                local delimiter = text:sub(cursor, cursor)
                cursor += 1
                if delimiter == closing then
                    return result
                end
                assert(delimiter == ",", "Invalid JSON separator")
            end
            error("Unterminated JSON object")
        end
        for token, value in pairs({ ["true"] = true, ["false"] = false }) do
            if text:sub(cursor, cursor + #token - 1) == token then
                cursor += #token
                return value
            end
        end
        local number = text:sub(cursor):match("^%-?%d+%.?%d*[eE]?[+-]?%d*")
        assert(number and tonumber(number), "Invalid JSON token")
        cursor += #number
        return tonumber(number)
    end
    local value = parse()
    skip()
    assert(cursor > #text, "Trailing JSON")
    return value
end
local services = {}
local game = {
    GetService = function(_, name)
        assert(services[name], "Unimplemented mock service " .. name)
        return services[name]
    end,
}
services.UserInputService = {
    InputBegan = event(),
    InputChanged = event(),
    InputEnded = event(),
    TextBoxFocused = event(),
    GetMouseLocation = function()
        return Vector2.new(100, 100)
    end,
    GetFocusedTextBox = function()
        return Mock.focused
    end,
    IsKeyDown = function(_, key)
        return Mock.keys[key] == true
    end,
}
services.GuiService = Instance.new("GuiService")
services.GuiService.GetGuiInset = function()
    return Vector2.new(), Vector2.new()
end
Mock.onTextFocused = function(field)
    services.UserInputService.TextBoxFocused:Fire(field)
end
services.RunService = { Heartbeat = event() }
services.Stats = {
    GetTotalMemoryUsageMb = function()
        return 123
    end,
}
services.Lighting = Instance.new("Lighting")
services.Players = { LocalPlayer = Instance.new("Player") }
local playerGui = Instance.new("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = services.Players.LocalPlayer
services.TextService = {
    GetTextSize = function(_, text, size, _, bounds)
        return Vector2.new(
            math.min(#text * size * 0.55, bounds.X),
            math.max(1, math.ceil(#text * size * 0.55 / math.max(1, bounds.X))) * size
        )
    end,
}
services.HttpService = {
    JSONEncode = function(_, value)
        return jsonEncode(value)
    end,
    JSONDecode = function(_, value)
        return jsonDecode(value)
    end,
}
services.TweenService = {
    Create = function(_, object, _, values)
        local tween = { Completed = event() }
        function tween:Play()
            for key, value in pairs(values) do
                object[key] = value
            end
            task.defer(function()
                self.Completed:Fire()
            end)
        end
        function tween:Cancel()
            self.Completed:Fire()
        end
        return tween
    end,
}
local function warn(...)
    error(table.concat({ ... }, " "), 2)
end
function Mock.step(dt)
    Mock.time += dt or 0
    services.RunService.Heartbeat:Fire(dt or 0)
    for _ = 1, 1000 do
        local ran = false
        for index = #Mock.tasks, 1, -1 do
            local item = Mock.tasks[index]
            if item.cancelled or item.due <= Mock.time then
                table.remove(Mock.tasks, index)
                if not item.cancelled then
                    item.callback()
                    ran = true
                end
            end
        end
        if not ran then
            return
        end
    end
    error("Scheduler did not settle")
end
function Mock.layout()
    for _ = 1, 8 do
        for _, object in ipairs(Mock.objects) do
            if not rawget(object, "_destroyed") then
                for property, signal in pairs(rawget(object, "_signals")) do
                    if
                        property == "AbsoluteSize"
                        or property == "AbsoluteContentSize"
                        or property == "AbsolutePosition"
                    then
                        local value = object[property]
                        local previous = rawget(signal, "previous")
                        if previous ~= value then
                            rawset(signal, "previous", value)
                            signal:Fire()
                        end
                    end
                end
            end
        end
    end
end
function Mock.press(key, processed)
    services.UserInputService.InputBegan:Fire(
        { KeyCode = key, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.new(0, 0, 0) },
        processed or false
    )
end
function Mock.release(key)
    services.UserInputService.InputEnded:Fire({ KeyCode = key, UserInputType = Enum.UserInputType.Keyboard })
end
