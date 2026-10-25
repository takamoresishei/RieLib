--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Container = require(script.Parent.Container)
local Table = require(script.Parent.Parent.Utility.Table)
local Page = {}
Page.__index = Page
function Page.new(window, options, parent)
    local self = setmetatable({
        App = window.App,
        Window = window,
        Theme = window.Theme,
        Maid = Cleanup.new(),
        Title = options.Title or "Page",
        Id = options.Id or options.Title,
        Icon = options.Icon or "folder",
        Parent = parent,
        Pages = {},
        Destroyed = false,
        Options = options,
    }, Page)
    self.Page = self
    Container.attach(self)
    self.Root = Gui.new(
        self,
        "CanvasGroup",
        { Name = self.Title, Size = UDim2.fromScale(1, 1), Visible = false, GroupTransparency = 0 },
        nil,
        window.ContentHost
    )
    self.Maid:Give(self.Root)
    self.Scroller = Gui.new(self, "ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        BorderSizePixel = 0,
    }, { ScrollBarImageColor3 = "BorderStrong" }, self.Root)
    Gui.padding(self, self.Scroller, 2)
    self.Content = Gui.new(
        self,
        "Frame",
        { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y },
        nil,
        self.Scroller
    )
    Gui.list(self, self.Content, 12)
    self.Maid:Give(function()
        self:DestroyChildren()
        for _, page in ipairs(table.clone(self.Pages)) do
            page:Destroy()
        end
        if parent then
            Table.removeValue(parent.Pages, self)
        else
            Table.removeValue(window.Tabs, self)
        end
        window.Sidebar:Remove(self)
        if window.SelectedPage == self then
            window.SelectedPage = nil
        end
    end)
    self.Maid:Give(self.Root.Destroying:Connect(function()
        self:Destroy()
    end))
    return self
end
function Page:AddPage(options)
    options = options or {}
    self.App.Icons:Get(options.Icon or "folder")
    local page = Page.new(self.Window, options, self)
    table.insert(self.Pages, page)
    self.Window.Sidebar:Add(page)
    return page
end
function Page:Select()
    self.Window:SelectTab(self)
    return self
end
function Page:SetBadge(value)
    self.Options.Badge = value
    self.Window.Sidebar:Refresh()
    return self
end
function Page:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Maid:Destroy()
end
return Page
