--!strict
-- Synchronous, disconnect-safe signals. A listener added during Fire waits until the next Fire.
local Signal = {}
Signal.__index = Signal
export type Connection = { Connected: boolean, Disconnect: (Connection) -> () }

function Signal.new()
    return setmetatable({ _listeners = {}, _destroyed = false }, Signal)
end

function Signal:Connect(callback)
    assert(not self._destroyed, "Signal is destroyed")
    assert(type(callback) == "function", "Expected a listener")
    local owner = self
    local connection = { Connected = true }
    function connection:Disconnect()
        self.Connected = false
        owner._listeners[self] = nil
    end
    self._listeners[connection] = callback
    return connection
end

function Signal:Fire(...)
    local snapshot = {}
    for connection, callback in pairs(self._listeners) do
        table.insert(snapshot, { connection, callback })
    end
    for _, entry in ipairs(snapshot) do
        if entry[1].Connected then
            local ok, err = pcall(entry[2], ...)
            if not ok then
                warn("[Aurelis signal] " .. tostring(err))
            end
        end
    end
end

function Signal:Destroy()
    self._destroyed = true
    for connection in pairs(self._listeners) do
        connection:Disconnect()
    end
end

return Signal
