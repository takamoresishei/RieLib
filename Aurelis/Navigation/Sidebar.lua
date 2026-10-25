--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local Sidebar = {}
Sidebar.__index = Sidebar
function Sidebar.new(window)
    local self = setmetatable({
        Window = window,
        App = window.App,
        Theme = window.Theme,
        Maid = Cleanup.new(),
        Entries = {},
        Collapsed = false,
        Drawer = false,
    }, Sidebar)
    self.Root = Gui.new(self, "Frame", {
        Name = "Navigation",
        Position = UDim2.fromOffset(12, 60),
        Size = UDim2.new(0, 174, 1, -104),
        BackgroundTransparency = 0,
        ZIndex = 5,
    }, { BackgroundColor3 = "Surface" }, window.Body)
    self.Maid:Give(self.Root)
    Gui.corner(self, self.Root)
    Gui.stroke(self, self.Root)
    self.Brand = Gui.label(self, self.Root, "A U R E L I S", {
        Position = UDim2.fromOffset(40, 14),
        Size = UDim2.new(1, -48, 0, 22),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
    }, "TextSecondary")
    Icons:Create(
        self,
        self.Root,
        "sparkles",
        { Position = UDim2.fromOffset(16, 17), Size = UDim2.fromOffset(15, 15) },
        "Accent"
    )
    self.Scroll = Gui.new(self, "ScrollingFrame", {
        Position = UDim2.fromOffset(8, 52),
        Size = UDim2.new(1, -16, 1, -94),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
    }, { ScrollBarImageColor3 = "Border" }, self.Root)
    Gui.list(self, self.Scroll, 4)
    self.Indicator = Gui.new(self, "Frame", {
        Size = UDim2.fromOffset(3, 20),
        Position = UDim2.fromOffset(0, 60),
        BackgroundTransparency = 0,
        Visible = false,
        ZIndex = 3,
    }, { BackgroundColor3 = "Accent" }, self.Root)
    Gui.corner(self, self.Indicator, 3)
    self.CollapseButton = Gui.button(
        self,
        self.Root,
        "",
        { Position = UDim2.new(0, 10, 1, -36), Size = UDim2.new(1, -20, 0, 28) }
    )
    Icons:Create(
        self,
        self.CollapseButton,
        "menu",
        { Position = UDim2.new(0.5, -7, 0.5, -7), Size = UDim2.fromOffset(14, 14) }
    )
    self.Maid:Give(self.CollapseButton.Activated:Connect(function()
        if self.Window.Breakpoint == "Mobile" then
            self.Window:ToggleSidebar()
        else
            self:SetCollapsed(not self.Collapsed)
        end
    end))
    self.Maid:Give(self.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self:RefreshIndicator(false)
    end))
    return self
end
function Sidebar:Add(page)
    local maid = Cleanup.new()
    self.Maid:Give(maid)
    local ctx = { App = self.App, Theme = self.Theme, Maid = maid }
    local row = Gui.new(ctx, "Frame", {
        Size = UDim2.new(1, -2, 0, 36),
        LayoutOrder = page.Options.Bottom and 100000 + #self.Window.Tabs or #self.Entries + 1,
    }, nil, self.Scroll)
    maid:Give(row)
    if page.Options.Separator then
        local line = Gui.new(
            ctx,
            "Frame",
            { Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -8, 0, 1), BackgroundTransparency = 0.5 },
            { BackgroundColor3 = "Border" },
            row
        )
        line.ZIndex = 2
    end
    local button = Gui.button(ctx, row, "", { Size = UDim2.fromScale(1, 1) })
    local indent = page.Parent and 9 or 0
    local icon = Icons:Create(
        ctx,
        button,
        page.Icon,
        { Position = UDim2.fromOffset(11 + indent, 10), Size = UDim2.fromOffset(16, 16) }
    )
    local label = Gui.label(ctx, button, page.Title, {
        Position = UDim2.fromOffset(38 + indent, 0),
        Size = UDim2.new(1, -66 - indent, 1, 0),
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, "TextSecondary")
    local badge = Gui.label(ctx, button, page.Options.Badge or "", {
        Position = UDim2.new(1, -30, 0, 7),
        Size = UDim2.fromOffset(24, 22),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, "Accent")
    local entry =
        { Page = page, Row = row, Button = button, Icon = icon, Label = label, Badge = badge, Maid = maid }
    table.insert(self.Entries, entry)
    maid:Give(button.Activated:Connect(function()
        self.Window:SelectTab(page)
    end))
    maid:Give(self.App.Tooltips:Attach(self, button, function()
        return self.Collapsed and page.Title or nil
    end))
    maid:Give(row:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        self:RefreshIndicator(false)
    end))
    self:Refresh()
end
function Sidebar:Remove(page)
    for index, entry in ipairs(self.Entries) do
        if entry.Page == page then
            self.Maid:Remove(entry.Maid)
            table.remove(self.Entries, index)
            break
        end
    end
    self:Refresh()
end
function Sidebar:RefreshIndicator(animate)
    for _, entry in ipairs(self.Entries) do
        if entry.Page == self.Window.SelectedPage then
            local y = (entry.Row.AbsolutePosition.Y - self.Root.AbsolutePosition.Y) / self.Window.Scale + 8
            self.Indicator.Visible = y >= 48 and y + 20 <= self.Root.AbsoluteSize.Y - 40
            if animate then
                self.App.Motion:Tween(self.Indicator, { Position = UDim2.fromOffset(0, y) }, "Normal")
            else
                self.Indicator.Position = UDim2.fromOffset(0, y)
            end
            return
        end
    end
    self.Indicator.Visible = false
end
function Sidebar:Refresh()
    local orderByPage = {}
    local serial = 0
    local function order(pages)
        for _, page in ipairs(pages) do
            serial += 1
            orderByPage[page] = page.Options.Bottom and 100000 + serial or serial
            order(page.Pages)
        end
    end
    order(self.Window.Tabs)
    for _, entry in ipairs(self.Entries) do
        entry.Row.LayoutOrder = orderByPage[entry.Page] or 0
        local active = entry.Page == self.Window.SelectedPage
        entry.Label.Visible = not self.Collapsed
        entry.Badge.Visible = not self.Collapsed
        entry.Label.TextColor3 = active and self.Theme.Tokens.TextPrimary or self.Theme.Tokens.TextSecondary
        entry.Badge.Text = tostring(entry.Page.Options.Badge or "")
        entry.Button.BackgroundTransparency = active and 0.1 or 1
        self.App.Motion:Tween(entry.Icon, { Rotation = active and -3 or 0 }, "Fast")
    end
    self.Brand.Visible = not self.Collapsed
    self:RefreshIndicator(true)
end
function Sidebar:SetCollapsed(collapsed)
    self.Collapsed = collapsed == true
    self.Window:_layout(true)
    self:Refresh()
end
function Sidebar:Destroy()
    self.Maid:Destroy()
end
return Sidebar
