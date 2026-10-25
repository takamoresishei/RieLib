--!nonstrict
-- Requires are deliberately lazy: cards and sections can themselves contain components.
local Container = {}
function Container.attach(target)
    target.Components = {}
    for name, method in pairs(Container) do
        if name ~= "attach" then
            target[name] = method
        end
    end
    return target
end
local factories = {
    AddButton = function()
        return require(script.Parent.Parent.Components.Button)
    end,
    AddToggle = function()
        return require(script.Parent.Parent.Components.Toggle)
    end,
    AddSlider = function()
        return require(script.Parent.Parent.Components.Slider)
    end,
    AddRangeSlider = function()
        return require(script.Parent.Parent.Components.RangeSlider)
    end,
    AddDropdown = function()
        return require(script.Parent.Parent.Components.Dropdown)
    end,
    AddInput = function()
        return require(script.Parent.Parent.Components.Input)
    end,
    AddKeybind = function()
        return require(script.Parent.Parent.Components.Keybind)
    end,
    AddColorPicker = function()
        return require(script.Parent.Parent.Components.ColorPicker)
    end,
    AddSegmented = function()
        return require(script.Parent.Parent.Components.Segmented)
    end,
    AddProgress = function()
        return require(script.Parent.Parent.Components.Progress)
    end,
    AddLabel = function()
        return require(script.Parent.Parent.Components.Label)
    end,
    AddChart = function()
        return require(script.Parent.Parent.Components.Chart)
    end,
    AddEmptyState = function()
        return require(script.Parent.Parent.Components.EmptyState)
    end,
    AddCard = function()
        return require(script.Parent.Parent.Components.Card)
    end,
    AddSection = function()
        return require(script.Parent.Section)
    end,
}
for name, load in pairs(factories) do
    Container[name] = function(self, options)
        local count = #self.Components
        local ok, result = pcall(function()
            return load().new(self, options or {})
        end)
        if not ok then
            -- Constructor errors must not leave a half-created row or flag behind.
            for index = #self.Components, count + 1, -1 do
                self.Components[index]:Destroy()
            end
            error(result, 2)
        end
        return result
    end
end
function Container:DestroyChildren()
    local children = table.clone(self.Components)
    for _, component in ipairs(children) do
        component:Destroy()
    end
end
return Container
