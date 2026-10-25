--!nonstrict
local Math = require(script.Parent.Parent.Utility.Math)
local Search = {}
Search.__index = Search
function Search.new(app)
    return setmetatable({ App = app, _components = {} }, Search)
end
function Search:Register(component)
    self._components[component] = true
end
function Search:Unregister(component)
    self._components[component] = nil
end
function Search:Path(component)
    local parts = { component.Title }
    local owner = component.Owner
    while owner and owner ~= component.Window do
        table.insert(parts, 1, owner.Title)
        owner = owner.Owner or owner.Parent
    end
    return table.concat(parts, " > ")
end
function Search:Query(query, window)
    local results = {}
    for component in pairs(self._components) do
        if not component.Destroyed and (not window or component.Window == window) then
            local path = self:Path(component)
            local score = Math.fuzzy(query, path .. " " .. (component.Description or ""))
            if score then
                table.insert(results, {
                    Name = component.Title,
                    Path = path,
                    Score = score,
                    Callback = function()
                        self:Reveal(component)
                    end,
                })
            end
        end
    end
    table.sort(results, function(a, b)
        return a.Score == b.Score and a.Path < b.Path or a.Score > b.Score
    end)
    return results
end
function Search:Reveal(component)
    if component.Destroyed then
        return
    end
    local owner = component.Owner
    while owner do
        if owner.SetCollapsed then
            owner:SetCollapsed(false)
            self.App.Motion:Cancel(owner.Root)
            owner._resize(false)
        end
        if owner.Root then
            owner.Root.Visible = true
        end
        owner = owner.Owner
    end
    local page = component.Owner.Page or component.Owner
    component.Window:Show()
    component.Window:SelectTab(page)
    component:SetVisible(true)
    task.defer(function()
        if component.Destroyed or page.Destroyed then
            return
        end
        local scroller = page.Scroller
        local offset = component.Root.AbsolutePosition.Y
            - scroller.AbsolutePosition.Y
            + scroller.CanvasPosition.Y
        scroller.CanvasPosition = Vector2.new(0, math.max(0, offset - 18))
        component:Highlight()
        game:GetService("GuiService").SelectedObject = component.Hit
    end)
end
function Search:Open(window)
    self.App.Palette:Open(window, function(query)
        return self:Query(query)
    end, "Search every control…")
end
function Search:Destroy()
    table.clear(self._components)
end
return Search
