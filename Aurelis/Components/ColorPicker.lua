--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Math = require(script.Parent.Parent.Utility.Math)
local ColorPicker = {}
function ColorPicker.new(owner, options)
    local self = Base.new(owner, options, "ColorPicker", 34)
    self.Alpha = math.clamp(tonumber(options.Alpha) or 1, 0, 1)
    self.Recent = {}
    self.Button = Gui.button(
        self,
        self.Control,
        "",
        { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left }
    )
    Gui.stroke(self, self.Button)
    Gui.padding(self, self.Button, 8)
    local swatch = Gui.new(self, "Frame", {
        Size = UDim2.fromOffset(24, 20),
        Position = UDim2.new(1, -32, 0.5, -10),
        BackgroundTransparency = 0,
    }, nil, self.Button)
    Gui.corner(self, swatch, 5)
    self:Value(options.Default or Color3.fromRGB(155, 137, 255), function(value)
        if
            typeof(value) ~= "Color3"
            or not Math.finite(value.R)
            or not Math.finite(value.G)
            or not Math.finite(value.B)
        then
            return nil
        end
        return Color3.new(math.clamp(value.R, 0, 1), math.clamp(value.G, 0, 1), math.clamp(value.B, 0, 1))
    end, function(_, value)
        self.Button.Text = "#" .. value:ToHex():upper()
        swatch.BackgroundColor3 = value
        swatch.BackgroundTransparency = 1 - self.Alpha
        if self.Refresh then
            self.Refresh()
        end
    end)
    local function alphaApply(value, silent)
        self.Alpha = value
        self.Render(self, self:GetValue())
        if not silent and options.Callback then
            self.App:Call(options.Callback, self:GetValue(), value)
        end
    end
    local alphaFlag = options.AlphaFlag or (options.Flag and options.Flag .. ".alpha")
    local function alphaNormalize(value)
        if not Math.finite(value) then
            return nil
        end
        return math.clamp(value, 0, 1)
    end
    if alphaFlag then
        self.Maid:Give(self.App.FlagStore:Register(alphaFlag, self.Alpha, alphaNormalize, alphaApply))
    end
    function self:SetAlpha(value, silent)
        local valid = alphaNormalize(value)
        if valid == nil then
            return false
        end
        if alphaFlag then
            return self.App.FlagStore:Set(alphaFlag, valid, silent)
        end
        if valid ~= self.Alpha then
            alphaApply(valid, silent)
        end
        return true
    end
    function self:GetAlpha()
        return self.Alpha
    end
    function self:Open()
        if not self:CanInteract() then
            return
        end
        if self.App.Overlay.Active and self.App.Overlay.Active.Owner == self then
            self.App.Overlay:Close("Toggle")
            return
        end
        local h, s, v = self:GetValue():ToHSV()
        local draggingHue = false
        self.App.Overlay:Open(self, self.Button, Vector2.new(342, 398), function(ctx, panel)
            local square = Gui.new(ctx, "TextButton", {
                Position = UDim2.fromOffset(12, 12),
                Size = UDim2.new(1, -24, 0, 150),
                BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                BackgroundTransparency = 0,
            }, nil, panel)
            Gui.corner(ctx, square, 6)
            local saturation = Gui.new(ctx, "Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
            }, nil, square)
            Gui.corner(ctx, saturation, 6)
            Gui.new(ctx, "UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, nil, saturation)
            local valueLayer = Gui.new(
                ctx,
                "Frame",
                { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0 },
                nil,
                square
            )
            Gui.corner(ctx, valueLayer, 6)
            Gui.new(ctx, "UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, nil, valueLayer)
            local marker = Gui.new(
                ctx,
                "Frame",
                { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 },
                nil,
                square
            )
            Gui.corner(ctx, marker, 99)
            Gui.new(ctx, "UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, nil, marker)
            local hue = Gui.new(ctx, "TextButton", {
                Position = UDim2.fromOffset(12, 178),
                Size = UDim2.new(1, -24, 0, 18),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
            }, nil, panel)
            Gui.corner(ctx, hue, 5)
            local hueStops = {}
            for i = 0, 6 do
                table.insert(hueStops, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
            end
            Gui.new(ctx, "UIGradient", { Color = ColorSequence.new(hueStops) }, nil, hue)
            local hueMarker = Gui.new(ctx, "Frame", {
                Size = UDim2.new(0, 3, 1, 4),
                Position = UDim2.fromOffset(0, -2),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
            }, nil, hue)
            local alpha = Gui.new(
                ctx,
                "TextButton",
                { Position = UDim2.fromOffset(12, 210), Size = UDim2.new(1, -24, 0, 18) },
                nil,
                panel
            )
            for i = 0, 15 do
                Gui.new(ctx, "Frame", {
                    Position = UDim2.fromScale(i / 16, 0),
                    Size = UDim2.fromScale(1 / 16, 1),
                    BackgroundColor3 = Color3.fromRGB(
                        i % 2 == 0 and 80 or 145,
                        i % 2 == 0 and 80 or 145,
                        i % 2 == 0 and 80 or 145
                    ),
                    BackgroundTransparency = 0,
                }, nil, alpha)
            end
            local alphaColor = Gui.new(
                ctx,
                "Frame",
                { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 },
                nil,
                alpha
            )
            Gui.new(ctx, "UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, nil, alphaColor)
            local alphaMarker = Gui.new(ctx, "Frame", {
                Size = UDim2.new(0, 3, 1, 4),
                Position = UDim2.fromOffset(0, -2),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0,
            }, nil, alpha)
            local fields = {}
            local function row(label, y, count)
                Gui.label(
                    ctx,
                    panel,
                    label,
                    { Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(34, 28), TextSize = 10 },
                    "TextMuted"
                )
                local result = {}
                for i = 1, count do
                    local field = Gui.new(ctx, "TextBox", {
                        Position = UDim2.new((i - 1) * (1 / count), 46 - (i - 1) * 46 / count, 0, y),
                        Size = UDim2.new(1 / count, -(58 / count + 6), 0, 28),
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        BackgroundTransparency = 0,
                    }, { BackgroundColor3 = "Background", TextColor3 = "TextPrimary" }, panel)
                    Gui.corner(ctx, field, 5)
                    result[i] = field
                end
                return result
            end
            fields.RGB = row("RGB", 242, 3)
            fields.HSV = row("HSV", 278, 3)
            fields.Hex = row("HEX", 314, 2)
            local function refresh()
                local color = self:GetValue()
                if not draggingHue then
                    local newH, newS, newV = color:ToHSV()
                    if newS > 0 and newV > 0 then
                        h = newH
                    end
                    s, v = newS, newV
                end
                square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                marker.Position = UDim2.fromScale(s, 1 - v)
                hueMarker.Position = UDim2.new(h, -1, 0, -2)
                alphaMarker.Position = UDim2.new(self.Alpha, -1, 0, -2)
                alphaColor.BackgroundColor3 = color
                local rgb = { color.R * 255, color.G * 255, color.B * 255 }
                local hsv = { h * 360, s * 100, v * 100 }
                for i = 1, 3 do
                    if not fields.RGB[i]:IsFocused() then
                        fields.RGB[i].Text = tostring(math.floor(rgb[i] + 0.5))
                    end
                    if not fields.HSV[i]:IsFocused() then
                        fields.HSV[i].Text = tostring(math.floor(hsv[i] + 0.5))
                    end
                end
                if not fields.Hex[1]:IsFocused() then
                    fields.Hex[1].Text = "#" .. color:ToHex():upper()
                end
                if not fields.Hex[2]:IsFocused() then
                    fields.Hex[2].Text = string.format("%d%%", self.Alpha * 100 + 0.5)
                end
            end
            self.Refresh = refresh
            ctx.Maid:Give(function()
                self.App.Input:Cancel(ctx)
            end)
            ctx.Maid:Give(square.InputBegan:Connect(function(input)
                self.App.Input:Track(ctx, input, function(point)
                    s = math.clamp(
                        (point.X - square.AbsolutePosition.X) / math.max(1, square.AbsoluteSize.X),
                        0,
                        1
                    )
                    v = 1
                        - math.clamp(
                            (point.Y - square.AbsolutePosition.Y) / math.max(1, square.AbsoluteSize.Y),
                            0,
                            1
                        )
                    draggingHue = true
                    self:SetValue(Color3.fromHSV(h, s, v))
                    refresh()
                    draggingHue = false
                end)
            end))
            ctx.Maid:Give(hue.InputBegan:Connect(function(input)
                self.App.Input:Track(ctx, input, function(point)
                    h = math.clamp((point.X - hue.AbsolutePosition.X) / math.max(1, hue.AbsoluteSize.X), 0, 1)
                    draggingHue = true
                    self:SetValue(Color3.fromHSV(h, s, v))
                    refresh()
                    draggingHue = false
                end)
            end))
            ctx.Maid:Give(alpha.InputBegan:Connect(function(input)
                self.App.Input:Track(ctx, input, function(point)
                    self:SetAlpha(
                        math.clamp(
                            (point.X - alpha.AbsolutePosition.X) / math.max(1, alpha.AbsoluteSize.X),
                            0,
                            1
                        )
                    )
                end)
            end))
            for _, group in ipairs({ "RGB", "HSV" }) do
                for _, field in ipairs(fields[group]) do
                    ctx.Maid:Give(field.FocusLost:Connect(function()
                        local a, b, c =
                            tonumber(fields[group][1].Text),
                            tonumber(fields[group][2].Text),
                            tonumber(fields[group][3].Text)
                        if a and b and c then
                            if group == "RGB" then
                                self:SetValue(
                                    Color3.fromRGB(
                                        math.clamp(a, 0, 255),
                                        math.clamp(b, 0, 255),
                                        math.clamp(c, 0, 255)
                                    )
                                )
                            else
                                h, s, v =
                                    math.clamp(a, 0, 360) / 360,
                                    math.clamp(b, 0, 100) / 100,
                                    math.clamp(c, 0, 100) / 100
                                self:SetValue(Color3.fromHSV(h, s, v))
                            end
                        end
                        refresh()
                    end))
                end
            end
            ctx.Maid:Give(fields.Hex[1].FocusLost:Connect(function()
                local hex = string.gsub(fields.Hex[1].Text, "#", "")
                if #hex == 6 and string.match(hex, "^%x+$") then
                    self:SetValue(Color3.fromHex(hex))
                end
                refresh()
            end))
            ctx.Maid:Give(fields.Hex[2].FocusLost:Connect(function()
                local number = tonumber(string.gsub(fields.Hex[2].Text, "%%", ""))
                if number then
                    self:SetAlpha(number / 100)
                end
                refresh()
            end))
            Gui.label(
                ctx,
                panel,
                "RECENT",
                { Position = UDim2.fromOffset(12, 357), Size = UDim2.fromOffset(52, 24), TextSize = 9 },
                "TextMuted"
            )
            for index, color in ipairs(self.Recent) do
                local button = Gui.new(ctx, "TextButton", {
                    Position = UDim2.fromOffset(68 + (index - 1) * 29, 357),
                    Size = UDim2.fromOffset(22, 24),
                    BackgroundColor3 = color,
                    BackgroundTransparency = 0,
                }, nil, panel)
                Gui.corner(ctx, button, 5)
                ctx.Maid:Give(button.Activated:Connect(function()
                    self:SetValue(color)
                end))
            end
            refresh()
        end, {
            OnClose = function()
                self.Refresh = nil
                local color = self:GetValue()
                local existing = table.find(self.Recent, color)
                if existing then
                    table.remove(self.Recent, existing)
                end
                table.insert(self.Recent, 1, color)
                if #self.Recent > 8 then
                    table.remove(self.Recent)
                end
            end,
        })
    end
    self.Maid:Give(self.Button.Activated:Connect(function()
        self:Open()
    end))
    return self
end
return ColorPicker
