--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Icons = require(script.Parent.Parent.Utility.Icons)
local Table = require(script.Parent.Parent.Utility.Table)
local Dropdown = {}
function Dropdown.new(owner, options)
    local self = Base.new(owner, options, "Dropdown", 34)
    self.Values = table.clone(options.Values or {})
    local function validateValues(values)
        assert(type(values) == "table", "Values must be an array")
        local seen = {}
        for _, value in ipairs(values) do
            assert(type(value) == "string" and not seen[value], "Dropdown values must be unique strings")
            seen[value] = true
        end
    end
    validateValues(self.Values)
    self.Button = Gui.button(self, self.Control, "", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.3,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    Gui.padding(self, self.Button, 9)
    Gui.stroke(self, self.Button)
    self.Chevron = Icons:Create(
        self,
        self.Button,
        "chevron-down",
        { Position = UDim2.new(1, -18, 0.5, -6), Size = UDim2.fromOffset(12, 12) }
    )
    self:Value(options.Default or (options.Multi and {} or self.Values[1] or ""), function(value)
        if options.Multi then
            if type(value) ~= "table" then
                return nil
            end
            local result = {}
            for _, item in ipairs(value) do
                if not table.find(self.Values, item) then
                    return nil
                end
                if not table.find(result, item) then
                    table.insert(result, item)
                end
            end
            return result
        end
        if value == "" and #self.Values == 0 then
            return ""
        end
        return table.find(self.Values, value) and value or nil
    end, function(_, value)
        self.Button.Text = options.Multi and (#value == 0 and "Select…" or table.concat(value, ", "))
            or tostring(value)
        if self.Refresh then
            self.Refresh()
        end
    end)
    function self:Open()
        if not self:CanInteract() then
            return
        end
        if self.App.Overlay.Active and self.App.Overlay.Active.Owner == self then
            self.App.Overlay:Close("Toggle")
            return
        end
        local cursor, filtered, refresh = 1, {}, nil
        local function selectValue(value)
            if options.Multi then
                local current = self:GetValue()
                local index = table.find(current, value)
                if index then
                    table.remove(current, index)
                else
                    table.insert(current, value)
                end
                self:SetValue(current)
            else
                self:SetValue(value)
                self.App.Overlay:Close("Selected")
            end
        end
        self.App.Motion:Tween(self.Chevron, { Rotation = 180 }, "Normal")
        self.App.Overlay:Open(
            self,
            self.Button,
            Vector2.new(math.max(220, self.Button.AbsoluteSize.X), math.min(310, #self.Values * 34 + 54)),
            function(ctx, panel)
                local search = Gui.new(ctx, "TextBox", {
                    Position = UDim2.fromOffset(10, 8),
                    Size = UDim2.new(1, -20, 0, 30),
                    PlaceholderText = "Search options…",
                    ClearTextOnFocus = false,
                }, { TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" }, panel)
                local list = Gui.new(ctx, "ScrollingFrame", {
                    Position = UDim2.fromOffset(6, 44),
                    Size = UDim2.new(1, -12, 1, -50),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 3,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                }, { ScrollBarImageColor3 = "BorderStrong" }, panel)
                Gui.list(ctx, list, 2)
                local rows = nil
                refresh = function()
                    if rows then
                        ctx.Maid:Remove(rows)
                    end
                    rows = require(script.Parent.Parent.Core.Cleanup).new()
                    ctx.Maid:Give(rows)
                    local rowctx = { App = ctx.App, Theme = ctx.Theme, Maid = rows }
                    table.clear(filtered)
                    local query = string.lower(search.Text)
                    for _, value in ipairs(self.Values) do
                        if string.find(string.lower(value), query, 1, true) then
                            table.insert(filtered, value)
                        end
                    end
                    cursor = math.clamp(cursor, 1, math.max(1, #filtered))
                    if #filtered == 0 then
                        rows:Give(
                            Gui.label(
                                rowctx,
                                list,
                                "No matching options",
                                { Size = UDim2.new(1, 0, 0, 32), TextXAlignment = Enum.TextXAlignment.Center },
                                "TextMuted"
                            )
                        )
                    end
                    for index, value in ipairs(filtered) do
                        local selected = options.Multi and table.find(self:GetValue(), value) ~= nil
                            or self:GetValue() == value
                        local button = Gui.button(rowctx, list, (selected and "✓  " or "    ") .. value, {
                            Size = UDim2.new(1, -2, 0, 32),
                            LayoutOrder = index,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BackgroundTransparency = index == cursor and 0.15 or 1,
                        })
                        rows:Give(button)
                        Gui.padding(rowctx, button, 8)
                        if selected then
                            button.TextColor3 = ctx.Theme.Tokens.Accent
                        end
                        rows:Give(button.Activated:Connect(function()
                            selectValue(value)
                        end))
                    end
                    list.CanvasPosition =
                        Vector2.new(0, math.max(0, (cursor - 1) * 34 - list.AbsoluteSize.Y + 34))
                end
                self.Refresh = refresh
                ctx.Maid:Give(search:GetPropertyChangedSignal("Text"):Connect(function()
                    cursor = 1
                    refresh()
                end))
                refresh()
                search:CaptureFocus()
            end,
            {
                OnClose = function()
                    self.Refresh = nil
                    if not self.Destroyed then
                        self.App.Motion:Tween(self.Chevron, { Rotation = 0 }, "Normal")
                    end
                end,
                OnInput = function(input)
                    if input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.Up then
                        cursor = math.clamp(
                            cursor + (input.KeyCode == Enum.KeyCode.Down and 1 or -1),
                            1,
                            math.max(1, #filtered)
                        )
                        if refresh then
                            refresh()
                        end
                        return true
                    elseif input.KeyCode == Enum.KeyCode.Return then
                        if filtered[cursor] then
                            selectValue(filtered[cursor])
                        end
                        return true
                    end
                end,
            }
        )
    end
    function self:SetValues(values)
        validateValues(values)
        self.App.Overlay:CloseOwner(self)
        self.Values = table.clone(values)
        local value = self:GetValue()
        if options.Multi then
            local valid = {}
            for _, item in ipairs(value) do
                if table.find(values, item) then
                    table.insert(valid, item)
                end
            end
            self:SetValue(valid)
        elseif not table.find(values, value) then
            self:SetValue(values[1] or "")
        end
        return self
    end
    self.Maid:Give(self.Button.Activated:Connect(function()
        self:Open()
    end))
    return self
end
return Dropdown
