--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Breadcrumb = {}
Breadcrumb.__index = Breadcrumb
function Breadcrumb.new(window, host)
    return setmetatable(
        { Window = window, App = window.App, Theme = window.Theme, Maid = Cleanup.new(), Host = host },
        Breadcrumb
    )
end
function Breadcrumb:Set(page)
    self.Maid:Destroy()
    self.Maid = Cleanup.new()
    local chain = {}
    local current = page
    while current do
        table.insert(chain, 1, current)
        current = current.Parent
    end
    local layout = Gui.new(self, "UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, nil, self.Host)
    self.Maid:Give(layout)
    for index, item in ipairs(chain) do
        if index > 1 then
            self.Maid:Give(
                Gui.label(
                    self,
                    self.Host,
                    "/",
                    { Size = UDim2.fromOffset(8, 22), LayoutOrder = index * 2 - 1, TextSize = 10 },
                    "TextMuted"
                )
            )
        end
        local width = game:GetService("TextService")
            :GetTextSize(item.Title, 10, Enum.Font.Gotham, Vector2.new(1000, 22)).X + 8
        local button = Gui.button(
            self,
            self.Host,
            item.Title,
            { Size = UDim2.fromOffset(width, 24), LayoutOrder = index * 2, TextSize = 10 }
        )
        self.Maid:Give(button)
        self.Maid:Give(button.Activated:Connect(function()
            self.Window:SelectTab(item)
        end))
    end
end
function Breadcrumb:Destroy()
    self.Maid:Destroy()
end
return Breadcrumb
