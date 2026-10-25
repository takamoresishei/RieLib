--!nonstrict
local Gui = require(script.Parent.Parent.Utility.Gui)
local Signal = require(script.Parent.Parent.Utility.Signal)
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Modal = {}
Modal.__index = Modal
function Modal.new(app)
    return setmetatable({ App = app, Active = nil }, Modal)
end
function Modal:Show(window, options)
    options = options or {}
    local controller = { Result = Signal.new(), Closed = false }
    local field, confirm, focusIndex = nil, nil, 1
    local focusables = {}
    local function finish(accepted, value)
        if controller.Closed then
            return
        end
        controller.Closed = true
        controller.Result:Fire(accepted, value)
        controller.Result:Destroy()
        if accepted and options.OnConfirm then
            self.App:Call(options.OnConfirm, value)
        end
        if not accepted and options.OnCancel then
            self.App:Call(options.OnCancel)
        end
    end
    function controller:Close()
        self._service.App.Overlay:Close("Cancelled")
    end
    controller._service = self
    self.App.Overlay:Open(
        window,
        nil,
        Vector2.new(options.Width or 420, options.Kind == "Input" and 270 or 226),
        function(ctx, panel, overlay)
            self.Active = controller
            Gui.new(ctx, "UIScale", { Scale = 0.97 }, nil, panel)
            local scale = panel:FindFirstChildOfClass("UIScale")
            self.App.Motion:Tween(scale, { Scale = 1 }, "Spring")
            Gui.label(ctx, panel, options.Title or "Aurelis", {
                Position = UDim2.fromOffset(22, 20),
                Size = UDim2.new(1, -44, 0, 27),
                TextSize = 18,
                Font = Enum.Font.GothamMedium,
            })
            Gui.label(ctx, panel, options.Content or "", {
                Position = UDim2.fromOffset(22, 59),
                Size = UDim2.new(1, -44, 0, 67),
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextSize = 12,
            }, "TextSecondary")
            local errorLabel = Gui.label(
                ctx,
                panel,
                "",
                { Position = UDim2.new(0, 22, 1, -97), Size = UDim2.new(1, -44, 0, 18), TextSize = 10 },
                "Danger"
            )
            if options.Kind == "Input" then
                field = Gui.new(ctx, "TextBox", {
                    Position = UDim2.fromOffset(22, 129),
                    Size = UDim2.new(1, -44, 0, 34),
                    Text = tostring(options.Default or ""),
                    PlaceholderText = options.Placeholder or "Enter value…",
                    ClearTextOnFocus = false,
                    BackgroundTransparency = 0,
                }, { BackgroundColor3 = "Background", TextColor3 = "TextPrimary" }, panel)
                Gui.corner(ctx, field, 7)
                Gui.stroke(ctx, field)
                Gui.padding(ctx, field, 8)
                table.insert(focusables, field)
            end
            local cancel = Gui.button(
                ctx,
                panel,
                options.CancelText or "Cancel",
                { Position = UDim2.new(1, -224, 1, -58), Size = UDim2.fromOffset(94, 36) }
            )
            table.insert(focusables, cancel)
            confirm = Gui.button(
                ctx,
                panel,
                options.ConfirmText or (options.Kind == "Destructive" and "Delete" or "Confirm"),
                {
                    Position = UDim2.new(1, -122, 1, -58),
                    Size = UDim2.fromOffset(100, 36),
                    BackgroundTransparency = 0,
                }
            )
            confirm.BackgroundColor3 = options.Kind == "Destructive" and ctx.Theme.Tokens.Danger
                or ctx.Theme.Tokens.Accent
            confirm.TextColor3 = ctx.Theme.Tokens.Background
            table.insert(focusables, confirm)
            local function submit()
                if controller.Closed then
                    return
                end
                local value = field and field.Text or true
                if options.Validate then
                    local ok, valid, message = pcall(options.Validate, value)
                    if not ok or not valid then
                        errorLabel.Text = tostring(message or "Please enter a valid value")
                        return
                    end
                end
                controller.Closed = true
                self.App.Overlay:Close("Confirmed")
                controller.Result:Fire(true, value)
                controller.Result:Destroy()
                if options.OnConfirm then
                    self.App:Call(options.OnConfirm, value)
                end
            end
            controller.Confirm = submit
            ctx.Maid:Give(confirm.Activated:Connect(submit))
            ctx.Maid:Give(cancel.Activated:Connect(function()
                self.App.Overlay:Close("Cancelled")
            end))
            if options.Kind == "Information" then
                cancel.Visible = false
            end
            if field then
                field:CaptureFocus()
                ctx.Maid:Give(field.FocusLost:Connect(function(enter)
                    if enter and not controller.Closed then
                        submit()
                    end
                end))
            else
                GuiService.SelectedObject = options.Kind == "Destructive" and cancel or confirm
            end
            overlay.Focusables = focusables
            ctx.Maid:Give(self.App.Input.TextFocused:Connect(function(target)
                if target:IsDescendantOf(panel) then
                    return
                end
                target:ReleaseFocus()
                if field then
                    field:CaptureFocus()
                else
                    GuiService.SelectedObject = confirm
                end
            end))
            ctx.Maid:Give(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
                local target = GuiService.SelectedObject
                if target and not target:IsDescendantOf(panel) then
                    GuiService.SelectedObject = confirm
                end
            end))
        end,
        {
            Centered = true,
            Blocking = true,
            Critical = options.Critical == true,
            OnClose = function()
                if self.Active == controller then
                    self.Active = nil
                end
                finish(false, nil)
            end,
            OnInput = function(input)
                if input.KeyCode == Enum.KeyCode.Tab then
                    local backwards = UIS:IsKeyDown(Enum.KeyCode.LeftShift)
                        or UIS:IsKeyDown(Enum.KeyCode.RightShift)
                    focusIndex = ((focusIndex - 1 + (backwards and -1 or 1)) % #focusables) + 1
                    local target = focusables[focusIndex]
                    if target:IsA("TextBox") then
                        target:CaptureFocus()
                    else
                        if field then
                            field:ReleaseFocus()
                        end
                        GuiService.SelectedObject = target
                    end
                    return true
                elseif input.KeyCode == Enum.KeyCode.Return and not field and confirm then
                    controller.Confirm()
                    return true
                end
            end,
        }
    )
    return controller
end
function Modal:Destroy()
    if self.Active then
        self.App.Overlay:Close("Destroyed")
    end
end
return Modal
