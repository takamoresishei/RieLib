--!nonstrict
local TweenService = game:GetService("TweenService")
local Motion = {}
Motion.__index = Motion
local presets = {
    Instant = { 0, Enum.EasingStyle.Linear },
    Fast = { 0.12, Enum.EasingStyle.Quad },
    Normal = { 0.19, Enum.EasingStyle.Quart },
    Slow = { 0.26, Enum.EasingStyle.Quart },
    Spring = { 0.24, Enum.EasingStyle.Back },
}
function Motion.new()
    return setmetatable({ Speed = 1, _active = {}, ActiveCount = 0 }, Motion)
end
function Motion:_remove(object, entry, cancel)
    local bucket = self._active[object]
    if not bucket or not bucket[entry] then
        return
    end
    bucket[entry] = nil
    if next(bucket) == nil then
        self._active[object] = nil
    end
    self.ActiveCount -= 1
    entry.Connection:Disconnect()
    if cancel then
        entry.Tween:Cancel()
    end
end
function Motion:Cancel(object)
    local bucket = self._active[object]
    if not bucket then
        return
    end
    local entries = {}
    for entry in pairs(bucket) do
        table.insert(entries, entry)
    end
    for _, entry in ipairs(entries) do
        self:_remove(object, entry, true)
    end
end
function Motion:Tween(object, properties, preset)
    local bucket = self._active[object]
    if bucket then
        local conflicts = {}
        for entry in pairs(bucket) do
            for property in pairs(properties) do
                if entry.Properties[property] ~= nil then
                    table.insert(conflicts, entry)
                    break
                end
            end
        end
        for _, entry in ipairs(conflicts) do
            self:_remove(object, entry, true)
        end
    end
    local settings = presets[preset or "Normal"] or presets.Normal
    if self.Speed <= 0 or settings[1] == 0 then
        for key, value in pairs(properties) do
            object[key] = value
        end
        return nil
    end
    local tween = TweenService:Create(
        object,
        TweenInfo.new(settings[1] / math.max(self.Speed, 0.05), settings[2], Enum.EasingDirection.Out),
        properties
    )
    local entry = { Tween = tween, Properties = properties }
    entry.Connection = tween.Completed:Connect(function()
        self:_remove(object, entry, false)
    end)
    self._active[object] = self._active[object] or {}
    self._active[object][entry] = true
    self.ActiveCount += 1
    tween:Play()
    return tween
end
function Motion:Destroy()
    local objects = {}
    for object in pairs(self._active) do
        table.insert(objects, object)
    end
    for _, object in ipairs(objects) do
        self:Cancel(object)
    end
end
return Motion
