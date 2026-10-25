--!nonstrict
local Page = require(script.Parent.Page)
local Tab = {}
function Tab.new(window, options)
    return Page.new(window, options, nil)
end
return Tab
