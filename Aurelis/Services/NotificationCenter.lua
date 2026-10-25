--!nonstrict
local Signal = require(script.Parent.Parent.Utility.Signal)
local Math = require(script.Parent.Parent.Utility.Math)
local NotificationCenter = {}
NotificationCenter.__index = NotificationCenter
function NotificationCenter.new()
    return setmetatable(
        { History = {}, Changed = Signal.new(), _serial = 0, Limit = 100 },
        NotificationCenter
    )
end
function NotificationCenter:Push(options)
    self._serial += 1
    local duration = tonumber(options.Duration)
    if not Math.finite(duration) then
        duration = 4
    end
    local kind = options.Type or "Info"
    if not table.find({ "Info", "Success", "Warning", "Error" }, kind) then
        kind = "Info"
    end
    local item = {
        Id = self._serial,
        Title = tostring(options.Title or "Notification"),
        Content = tostring(options.Content or ""),
        Type = kind,
        Duration = math.clamp(duration, 0, 120),
        Time = os.time(),
    }
    table.insert(self.History, 1, item)
    if #self.History > self.Limit then
        table.remove(self.History)
    end
    self.Changed:Fire("Added", item)
    return item
end
function NotificationCenter:Clear()
    table.clear(self.History)
    self.Changed:Fire("Cleared")
end
function NotificationCenter:Destroy()
    self.Changed:Destroy()
    table.clear(self.History)
end
return NotificationCenter
