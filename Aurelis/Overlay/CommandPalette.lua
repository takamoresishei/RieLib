--!nonstrict
local Cleanup = require(script.Parent.Parent.Core.Cleanup)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Palette = {}
Palette.__index = Palette
function Palette.new(app)
    return setmetatable({ App = app }, Palette)
end
function Palette:Open(window, provider, title)
    local selected, results, render = 1, {}, nil
    local function activate()
        local entry = results[selected]
        if entry then
            self.App.Overlay:Close("Selected")
            self.App:Call(entry.Callback)
        end
    end
    self.App.Overlay:Open(window, nil, Vector2.new(510, 360), function(ctx, panel)
        local field = Gui.new(ctx, "TextBox", {
            Position = UDim2.fromOffset(18, 12),
            Size = UDim2.new(1, -36, 0, 38),
            ClearTextOnFocus = false,
            PlaceholderText = title or "Search commands…",
            TextSize = 15,
        }, { TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" }, panel)
        Gui.label(
            ctx,
            panel,
            "↑ ↓  navigate      ENTER  select      ESC  close",
            { Position = UDim2.new(0, 18, 1, -27), Size = UDim2.new(1, -36, 0, 20), TextSize = 9 },
            "TextMuted"
        )
        local list = Gui.new(ctx, "ScrollingFrame", {
            Position = UDim2.fromOffset(8, 60),
            Size = UDim2.new(1, -16, 1, -94),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
        }, { ScrollBarImageColor3 = "BorderStrong" }, panel)
        Gui.list(ctx, list, 3)
        local rows = nil
        render = function(requery)
            if rows then
                ctx.Maid:Remove(rows)
            end
            rows = Cleanup.new()
            ctx.Maid:Give(rows)
            local rowctx = { App = ctx.App, Theme = ctx.Theme, Maid = rows }
            if requery then
                results = provider(field.Text)
                selected = 1
            end
            selected = math.clamp(selected, 1, math.max(1, #results))
            if #results == 0 then
                rows:Give(
                    Gui.label(
                        rowctx,
                        list,
                        "No results found",
                        { Size = UDim2.new(1, 0, 0, 90), TextXAlignment = Enum.TextXAlignment.Center },
                        "TextMuted"
                    )
                )
            end
            for index, entry in ipairs(results) do
                if index > 100 then
                    break
                end
                local button = Gui.button(rowctx, list, "", {
                    Size = UDim2.new(1, -2, 0, entry.Path and 54 or 38),
                    LayoutOrder = index,
                    BackgroundTransparency = index == selected and 0.1 or 1,
                })
                rows:Give(button)
                Gui.label(rowctx, button, entry.Name, {
                    Position = UDim2.fromOffset(12, 8),
                    Size = UDim2.new(1, -24, 0, 22),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })
                if entry.Path then
                    Gui.label(rowctx, button, entry.Path, {
                        Position = UDim2.fromOffset(12, 29),
                        Size = UDim2.new(1, -24, 0, 18),
                        TextSize = 10,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                    }, "TextMuted")
                end
                rows:Give(button.Activated:Connect(function()
                    selected = index
                    activate()
                end))
            end
            local rowHeight = results[selected] and results[selected].Path and 57 or 41
            list.CanvasPosition =
                Vector2.new(0, math.max(0, (selected - 1) * rowHeight - list.AbsoluteSize.Y + rowHeight))
        end
        ctx.Maid:Give(field:GetPropertyChangedSignal("Text"):Connect(function()
            render(true)
        end))
        render(true)
        field:CaptureFocus()
    end, {
        Centered = true,
        OnInput = function(input)
            if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down then
                selected = math.clamp(
                    selected + (input.KeyCode == Enum.KeyCode.Down and 1 or -1),
                    1,
                    math.min(100, math.max(1, #results))
                )
                if render then
                    render(false)
                end
                return true
            elseif input.KeyCode == Enum.KeyCode.Return then
                activate()
                return true
            end
        end,
    })
end
return Palette
