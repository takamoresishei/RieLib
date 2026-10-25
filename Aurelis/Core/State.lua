--!nonstrict
local Signal = require(script.Parent.Parent.Utility.Signal)
local Table = require(script.Parent.Parent.Utility.Table)
local State = {}
State.__index = State
local collecting = nil

function State.new(value)
    return setmetatable({ _value = Table.copy(value), Changed = Signal.new(), _dead = false }, State)
end
function State:Get()
    if collecting then
        collecting[self] = true
    end
    return Table.copy(self._value)
end
function State:Set(value)
    assert(not self._dead, "State is destroyed")
    assert(not self._compute, "Computed state is read-only")
    if Table.equal(value, self._value) then
        return
    end
    self._value = Table.copy(value)
    self.Changed:Fire(self:Get())
end
function State:Subscribe(callback, immediate)
    local connection = self.Changed:Connect(callback)
    if immediate ~= false then
        callback(self:Get())
    end
    return connection
end
function State:Destroy()
    if self._dead then
        return
    end
    self._dead = true
    if self._subscriptions then
        for _, connection in ipairs(self._subscriptions) do
            connection:Disconnect()
        end
    end
    self.Changed:Destroy()
end
function State.computed(callback)
    local state = State.new(nil)
    state._compute, state._subscriptions = callback, {}
    local running = false
    local function evaluate()
        assert(not running, "Computed state cycle")
        running = true
        local parentCollector, dependencies = collecting, {}
        collecting = dependencies
        local ok, value = pcall(callback)
        collecting, running = parentCollector, false
        if not ok then
            error(value, 2)
        end
        for _, connection in ipairs(state._subscriptions) do
            connection:Disconnect()
        end
        table.clear(state._subscriptions)
        for dependency in pairs(dependencies) do
            assert(dependency ~= state, "Computed state cannot depend on itself")
            table.insert(state._subscriptions, dependency.Changed:Connect(evaluate))
        end
        if not Table.equal(value, state._value) then
            state._value = Table.copy(value)
            state.Changed:Fire(state:Get())
        end
    end
    evaluate()
    return state
end
return State
