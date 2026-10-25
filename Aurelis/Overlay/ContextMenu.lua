--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local ContextMenu = {}
ContextMenu.__index = ContextMenu
function ContextMenu.new(app)
    return setmetatable({ App = app, Registry = {}, Maid = Cleanup.new(), Pending = nil }, ContextMenu)
end
function ContextMenu:_cancel()
    if self.Pending then
        pcall(task.cancel, self.Pending)
        self.Pending = nil
    end
    self.Touch = nil
end
function ContextMenu:Start()
    local function find(point)
        for index = #self.App.Windows, 1, -1 do
            local window = self.App.Windows[index]
            if window.Visible and self.App.Input:Contains(window.Root, point) then
                for owner in pairs(self.Registry) do
                    if
                        owner.Window == window
                        and not owner.Destroyed
                        and self.App.Input:Contains(owner.Root, point)
                    then
                        return owner
                    end
                end
                return nil
            end
        end
    end
    self.Maid:Give(self.App.Input:OnBegan(function(input)
        local right = input.UserInputType == Enum.UserInputType.MouseButton2
        local touch = input.UserInputType == Enum.UserInputType.Touch
        if not right and not touch then
            return
        end
        self:_cancel()
        local point = self.App.Input:Position(input)
        local owner = find(point)
        if not owner then
            return
        end
        if right then
            owner.Window:Focus()
            self:Open(owner, point, owner.Options.ContextMenu)
            return true
        end
        self.Touch = { Input = input, Point = point }
        self.Pending = task.delay(0.55, function()
            self.Pending = nil
            self.Touch = nil
            if not owner.Destroyed then
                self.App.Input:Cancel(owner)
                self:Open(owner, point, owner.Options.ContextMenu)
            end
        end)
    end, 950))
    self.Maid:Give(self.App.Input.Changed:Connect(function(input)
        if
            self.Touch
            and input == self.Touch.Input
            and (self.App.Input:Position(input) - self.Touch.Point).Magnitude > 10
        then
            self:_cancel()
        end
    end))
    self.Maid:Give(self.App.Input.Ended:Connect(function(input)
        if self.Touch and input == self.Touch.Input then
            self:_cancel()
        end
    end))
    self.Maid:Give(function()
        self:_cancel()
    end)
end
function ContextMenu:Open(owner, point, custom)
    if self.App.Modal.Active or owner.Destroyed then
        return
    end
    local entries = custom
        or {
            {
                Title = "Reset",
                Callback = function()
                    owner:Reset()
                end,
            },
            {
                Title = "Copy value",
                Callback = function()
                    local value = owner:GetValue()
                    local text = type(value) == "table" and self.App.Config:EncodeValue(value)
                        or tostring(value)
                    if self.App.Clipboard then
                        self.App:Call(self.App.Clipboard, text)
                    else
                        self.App.Modal:Show(
                            owner.Window,
                            { Title = "Copy value", Kind = "Input", Default = text, ConfirmText = "Done" }
                        )
                    end
                end,
            },
            {
                Title = owner.Disabled and "Enable" or "Disable",
                Callback = function()
                    owner:SetDisabled(not owner.Disabled)
                end,
            },
            {
                Title = "Remove",
                Danger = true,
                Callback = function()
                    owner:Destroy()
                end,
            },
        }
    self.App.Overlay:Open(owner, point, Vector2.new(190, #entries * 36 + 12), function(ctx, panel)
        Gui.padding(ctx, panel, 6)
        Gui.list(ctx, panel, 2)
        for index, entry in ipairs(entries) do
            local button = Gui.button(ctx, panel, entry.Title, {
                Size = UDim2.new(1, 0, 0, 32),
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = index,
            })
            Gui.padding(ctx, button, 8)
            if entry.Danger then
                button.TextColor3 = ctx.Theme.Tokens.Danger
            end
            ctx.Maid:Give(button.Activated:Connect(function()
                self.App.Overlay:Close("Selected")
                self.App:Call(entry.Callback)
            end))
        end
    end)
end
function ContextMenu:Attach(owner)
    self.Registry[owner] = true
    return function()
        self.Registry[owner] = nil
    end
end
function ContextMenu:Destroy()
    self.Maid:Destroy()
    table.clear(self.Registry)
end
return ContextMenu
