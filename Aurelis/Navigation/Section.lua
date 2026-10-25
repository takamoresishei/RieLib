--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local Table = require(script.Parent.Parent.Utility.Table)
local Container = require(script.Parent.Container)
local Section = {}
Section.__index = Section
function Section.new(owner, options)
    local self = setmetatable({
        App = owner.App,
        Window = owner.Window,
        Theme = owner.Theme,
        Maid = Cleanup.new(),
        Owner = owner,
        Page = owner.Page or owner,
        Title = options.Title or "Section",
        Collapsed = options.Collapsed == true,
        Collapsible = options.Collapsible == true,
        Destroyed = false,
    }, Section)
    Container.attach(self)
    owner._nextOrder = (owner._nextOrder or 0) + 1
    self.Root = Gui.new(self, "Frame", {
        Name = "Section",
        Size = UDim2.new(1, 0, 0, 60),
        ClipsDescendants = true,
        BackgroundTransparency = 0,
        LayoutOrder = owner._nextOrder,
    }, { BackgroundColor3 = "Surface" }, owner.Content)
    self.Maid:Give(self.Root)
    Gui.corner(self, self.Root)
    Gui.stroke(self, self.Root)
    table.insert(owner.Components, self)
    self.Maid:Give(function()
        self:DestroyChildren()
        Table.removeValue(owner.Components, self)
    end)
    local headerHeight = options.Description and 60 or 44
    self.Header = Gui.new(self, "TextButton", { Size = UDim2.new(1, 0, 0, headerHeight) }, nil, self.Root)
    if options.Icon then
        Icons:Create(self, self.Header, options.Icon, { Position = UDim2.fromOffset(14, 13) })
    end
    Gui.label(self, self.Header, self.Title, {
        Position = UDim2.fromOffset(options.Icon and 42 or 14, 12),
        Size = UDim2.new(1, -64, 0, 20),
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    if options.Description then
        Gui.label(self, self.Header, options.Description, {
            Position = UDim2.fromOffset(14, 35),
            Size = UDim2.new(1, -28, 0, 18),
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, "TextMuted")
    end
    local chevron = nil
    if self.Collapsible then
        chevron = Icons:Create(
            self,
            self.Header,
            "chevron-down",
            { Position = UDim2.new(1, -30, 0, 16), Size = UDim2.fromOffset(12, 12) }
        )
    end
    self.Content = Gui.new(
        self,
        "Frame",
        { Position = UDim2.fromOffset(8, headerHeight), Size = UDim2.new(1, -16, 0, 0) },
        nil,
        self.Root
    )
    local layout = Gui.list(self, self.Content, 3)
    local function resize(animate)
        if self.Destroyed then
            return
        end
        local height = layout.AbsoluteContentSize.Y / self.Window.Scale
        self.Content.Size = UDim2.new(1, -16, 0, height)
        local size = UDim2.new(1, 0, 0, headerHeight + (self.Collapsed and 0 or height + 10))
        if animate then
            self.App.Motion:Tween(self.Root, { Size = size }, "Normal")
        else
            self.Root.Size = size
        end
    end
    self._resize = resize
    self.Maid:Give(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        resize(false)
    end))
    self.Maid:Give(self.Header.Activated:Connect(function()
        if self.Collapsible then
            self:SetCollapsed(not self.Collapsed)
        end
    end))
    self.Maid:Give(self.Root.Destroying:Connect(function()
        self:Destroy()
    end))
    self.Chevron = chevron
    self.HeaderHeight = headerHeight
    resize(false)
    return self
end
function Section:SetCollapsed(collapsed)
    self.Collapsed = collapsed == true
    if self.Chevron then
        self.App.Motion:Tween(self.Chevron, { Rotation = self.Collapsed and -90 or 0 }, "Normal")
    end
    self._resize(true)
    return self
end
function Section:SetVisible(visible)
    self.Root.Visible = visible == true
    return self
end
function Section:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    self.Maid:Destroy()
end
return Section
