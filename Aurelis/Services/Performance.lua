--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Signal = require(script.Parent.Parent.Utility.Signal)
local Performance = {}
Performance.__index = Performance
function Performance.new(app)
    return setmetatable({
        App = app,
        Changed = Signal.new(),
        Users = 0,
        _scope = nil,
        Latest = { FPS = 0, Instances = 0, Connections = 0, Tweens = 0, Memory = 0 },
    }, Performance)
end
function Performance:Acquire(callback)
    self.Users += 1
    local listener = self.Changed:Connect(callback)
    if not self._scope then
        self._scope = Cleanup.new()
        local elapsed, frames = 0, 0
        self._scope:Give(game:GetService("RunService").Heartbeat:Connect(function(dt)
            elapsed += dt
            frames += 1
            if elapsed < 0.75 then
                return
            end
            local memory = gcinfo() / 1024
            pcall(function()
                memory = game:GetService("Stats"):GetTotalMemoryUsageMb()
            end)
            self.Latest = {
                FPS = math.floor(frames / elapsed + 0.5),
                Instances = #self.App.Root:GetDescendants(),
                Connections = Cleanup.Stats.Connections,
                Tweens = self.App.Motion.ActiveCount,
                Memory = memory,
            }
            elapsed, frames = 0, 0
            self.Changed:Fire(self.Latest)
        end))
    end
    local released = false
    return {
        Disconnect = function()
            if released then
                return
            end
            released = true
            listener:Disconnect()
            self.Users -= 1
            if self.Users == 0 and self._scope then
                self._scope:Destroy()
                self._scope = nil
            end
        end,
    }
end
function Performance:Destroy()
    if self._scope then
        self._scope:Destroy()
        self._scope = nil
    end
    self.Changed:Destroy()
end
return Performance
