--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local EmptyState = {}
function EmptyState.new(owner, options)
    local self = Base.new(owner, options, "EmptyState", 32)
    self.TitleLabel.Visible = false
    self.DescriptionLabel.Visible = false
    self.Control.Visible = false
    self._layout = function()
        self.Root.Size = UDim2.new(1, 0, 0, options.Action and 174 or 136)
    end
    Icons:Create(
        self,
        self.Root,
        options.Icon or "folder",
        { Size = UDim2.fromOffset(24, 24), Position = UDim2.new(0.5, -12, 0, 16) }
    )
    Gui.label(self, self.Root, options.Title or "Nothing here yet", {
        Position = UDim2.fromOffset(10, 51),
        Size = UDim2.new(1, -20, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    Gui.label(self, self.Root, options.Description or "", {
        Position = UDim2.fromOffset(16, 79),
        Size = UDim2.new(1, -32, 0, 38),
        TextWrapped = true,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, "TextMuted")
    if options.Action then
        local button = Gui.button(self, self.Root, options.Action.Title or "Create", {
            Position = UDim2.new(0.5, -90, 0, 127),
            Size = UDim2.fromOffset(180, 32),
            BackgroundTransparency = 0.2,
        })
        self.Maid:Give(button.Activated:Connect(function()
            if self:CanInteract() then
                self.App:Call(options.Action.Callback)
            end
        end))
    end
    self:_layout()
    return self
end
return EmptyState
