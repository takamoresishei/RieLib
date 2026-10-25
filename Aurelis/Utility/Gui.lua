--!nonstrict
local Gui = {}
function Gui.new(ctx, className, properties, tokens, parent)
    local object = Instance.new(className)
    if object:IsA("GuiObject") then
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
    end
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        object.Font = Enum.Font.Gotham
        object.TextSize = 13
        object.TextColor3 = ctx.Theme.Tokens.TextPrimary
        object.TextXAlignment = Enum.TextXAlignment.Left
        object.Text = ""
    end
    if object:IsA("GuiButton") then
        object.AutoButtonColor = false
        object.Selectable = true
    end
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    if tokens then
        ctx.Maid:Give(ctx.Theme:Bind(object, tokens))
    end
    object.Parent = parent
    -- All descendants are owned by their root; each theme binding is independently removed.
    ctx.Maid:Give(function()
        ctx.App.Motion:Cancel(object)
    end)
    return object
end
function Gui.corner(ctx, parent, radius)
    return Gui.new(ctx, "UICorner", radius and { CornerRadius = UDim.new(0, radius) } or {}, not radius and {
        CornerRadius = function(t)
            return UDim.new(0, t.Radius)
        end,
    } or nil, parent)
end
function Gui.stroke(ctx, parent, strong)
    return Gui.new(
        ctx,
        "UIStroke",
        { Thickness = 1, Transparency = 0.42 },
        { Color = strong and "BorderStrong" or "Border" },
        parent
    )
end
function Gui.padding(ctx, parent, amount)
    return Gui.new(ctx, "UIPadding", {
        PaddingLeft = UDim.new(0, amount),
        PaddingRight = UDim.new(0, amount),
        PaddingTop = UDim.new(0, amount),
        PaddingBottom = UDim.new(0, amount),
    }, nil, parent)
end
function Gui.list(ctx, parent, gap)
    return Gui.new(
        ctx,
        "UIListLayout",
        { Padding = UDim.new(0, gap or 8), SortOrder = Enum.SortOrder.LayoutOrder },
        nil,
        parent
    )
end
function Gui.label(ctx, parent, text, properties, token)
    local props = { Text = tostring(text or ""), Size = UDim2.new(1, 0, 0, 20) }
    for key, value in pairs(properties or {}) do
        props[key] = value
    end
    return Gui.new(ctx, "TextLabel", props, { TextColor3 = token or "TextPrimary" }, parent)
end
function Gui.button(ctx, parent, text, properties)
    local props =
        { Text = text or "", Size = UDim2.fromOffset(32, 32), TextXAlignment = Enum.TextXAlignment.Center }
    for key, value in pairs(properties or {}) do
        props[key] = value
    end
    local button = Gui.new(
        ctx,
        "TextButton",
        props,
        { TextColor3 = "TextSecondary", BackgroundColor3 = "SurfaceElevated" },
        parent
    )
    Gui.corner(ctx, button, 7)
    ctx.App.Input:Feedback(ctx, button)
    return button
end
return Gui
