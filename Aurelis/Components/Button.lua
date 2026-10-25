--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Button = {}
function Button.new(owner, options)
    local self = Base.new(owner, options, "Button", 34)
    local variant = options.Variant or "Default"
    local token = variant == "Primary" and "Accent" or variant == "Danger" and "Danger" or "SurfaceElevated"
    self.Button = Gui.new(
        self,
        "TextButton",
        {
            Size = UDim2.fromScale(1, 1),
            Text = options.Text or options.Title or "Run",
            TextXAlignment = Enum.TextXAlignment.Center,
            BackgroundTransparency = variant == "Ghost" and 1 or 0,
        },
        { BackgroundColor3 = token, TextColor3 = variant == "Primary" and "Background" or "TextPrimary" },
        self.Control
    )
    Gui.corner(self, self.Button, 7)
    if variant == "Default" or variant == "Secondary" then
        Gui.stroke(self, self.Button)
    end
    local scale = Gui.new(self, "UIScale", { Scale = 1 }, nil, self.Button)
    self.Maid:Give(self.Button.MouseEnter:Connect(function()
        if self:CanInteract() and not self.Loading then
            self.App.Motion:Tween(self.Button, { BackgroundTransparency = 0.18 }, "Fast")
        end
    end))
    self.Maid:Give(self.Button.MouseLeave:Connect(function()
        self.App.Motion:Tween(self.Button, { BackgroundTransparency = variant == "Ghost" and 1 or 0 }, "Fast")
        self.App.Motion:Tween(scale, { Scale = 1 }, "Fast")
    end))
    self.Maid:Give(self.Button.InputBegan:Connect(function(input)
        if
            self:CanInteract()
            and not self.Loading
            and (
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            )
        then
            self.App.Motion:Tween(scale, { Scale = 0.97 }, "Fast")
        end
    end))
    self.Maid:Give(self.Button.InputEnded:Connect(function()
        self.App.Motion:Tween(scale, { Scale = 1 }, "Fast")
    end))
    self.Maid:Give(self.Button.SelectionGained:Connect(function()
        self.FocusStroke.Transparency = 0.2
    end))
    self.Maid:Give(self.Button.SelectionLost:Connect(function()
        self.FocusStroke.Transparency = 1
    end))
    function self:Activate()
        if not self:CanInteract() or self.Loading then
            return
        end
        if self.Options.Callback then
            self.App:Call(self.Options.Callback)
        end
    end
    self.Maid:Give(self.Button.Activated:Connect(function()
        self:Activate()
    end))
    function self:SetLoading(loading)
        self.Loading = loading == true
        self.Button.Text = self.Loading and "Working…" or (self.Options.Text or self.Title)
        self.Button.Selectable = not self.Loading and not self.Disabled
        return self
    end
    return self
end
return Button
