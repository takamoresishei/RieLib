--!nonstrict
local Base = require(script.Parent.Base)
local Gui = require(script.Parent.Parent.Utility.Gui)
local Label = {}
function Label.new(owner, options)
    local self = Base.new(owner, options, "Label", 30)
    local text = Gui.label(self, self.Control, "", {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, options.Status and "Success" or "TextSecondary")
    self:Value(options.Value or options.Content or "", function(value)
        if type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then
            return nil
        end
        return tostring(value)
    end, function(_, value)
        text.Text = value
    end)
    return self
end
return Label
