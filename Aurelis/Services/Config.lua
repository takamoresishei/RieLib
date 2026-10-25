--!nonstrict
local HttpService = game:GetService("HttpService")
local Config = {}
Config.__index = Config
local function nameCheck(name)
    assert(
        type(name) == "string" and #name > 0 and #name <= 64 and string.match(name, "^[%w _%-]+$"),
        "Invalid configuration name"
    )
end
local function encode(value)
    if typeof(value) == "Color3" then
        return { __aurelis = "Color3", R = value.R, G = value.G, B = value.B }
    end
    if typeof(value) == "EnumItem" then
        return { __aurelis = "KeyCode", Name = value.Name }
    end
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = encode(item)
    end
    return result
end
local function decode(value, depth)
    depth = depth or 0
    assert(depth < 16, "Configuration nesting limit exceeded")
    if type(value) ~= "table" then
        return value
    end
    if value.__aurelis == "Color3" then
        for _, key in ipairs({ "R", "G", "B" }) do
            assert(type(value[key]) == "number" and value[key] >= 0 and value[key] <= 1, "Invalid color")
        end
        return Color3.new(value.R, value.G, value.B)
    elseif value.__aurelis == "KeyCode" then
        assert(type(value.Name) == "string", "Invalid key code")
        return Enum.KeyCode[value.Name]
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = decode(item, depth + 1)
    end
    return result
end
function Config.MemoryAdapter()
    local storage = {}
    return {
        Read = function(name)
            assert(storage[name], "Configuration does not exist")
            return storage[name]
        end,
        Write = function(name, data)
            storage[name] = data
        end,
        Delete = function(name)
            assert(storage[name], "Configuration does not exist")
            storage[name] = nil
        end,
        List = function()
            local names = {}
            for name in pairs(storage) do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end,
    }
end
-- Inject filesystem capabilities explicitly; Studio can instead inject a server-backed adapter.
function Config.FileAdapter(fs, folder)
    folder = folder or "AurelisConfigs"
    assert(string.match(folder, "^[%w_%-]+$"), "Use a single sandbox folder")
    for _, method in ipairs({ "readfile", "writefile", "delfile", "listfiles", "isfolder", "makefolder" }) do
        assert(type(fs[method]) == "function", "Missing filesystem capability: " .. method)
    end
    if not fs.isfolder(folder) then
        fs.makefolder(folder)
    end
    local function file(name)
        nameCheck(name)
        return folder .. "/" .. name .. ".json"
    end
    return {
        Read = function(name)
            return fs.readfile(file(name))
        end,
        Write = function(name, data)
            fs.writefile(file(name), data)
        end,
        Delete = function(name)
            fs.delfile(file(name))
        end,
        List = function()
            local result = {}
            for _, path in ipairs(fs.listfiles(folder)) do
                local name = string.match(path, "([^/\\]+)%.json$")
                if name and pcall(nameCheck, name) then
                    table.insert(result, name)
                end
            end
            table.sort(result)
            return result
        end,
    }
end
function Config.new(flags, adapter)
    return setmetatable(
        { Flags = flags, Adapter = adapter or Config.MemoryAdapter(), SchemaVersion = 1 },
        Config
    )
end
function Config:UseAdapter(adapter)
    for _, method in ipairs({ "Read", "Write", "Delete", "List" }) do
        assert(type(adapter[method]) == "function", "Invalid adapter")
    end
    self.Adapter = adapter
end
function Config:Export()
    return HttpService:JSONEncode({
        SchemaVersion = self.SchemaVersion,
        Flags = encode(self.Flags:Snapshot()),
    })
end
function Config:EncodeValue(value)
    return HttpService:JSONEncode(encode(value))
end
function Config:Import(data, silent)
    local ok, result = pcall(function()
        assert(type(data) == "string" and #data <= 1048576, "Configuration size limit exceeded")
        local document = HttpService:JSONDecode(data)
        assert(type(document) == "table", "Invalid configuration")
        local version = document.SchemaVersion or 0
        assert(
            type(version) == "number" and version >= 0 and version <= self.SchemaVersion,
            "Unsupported configuration version"
        )
        assert(type(document.Flags) == "table", "Missing Flags object")
        local report, pending = { Applied = {}, Skipped = {} }, {}
        for key, value in pairs(document.Flags) do
            local entry = self.Flags._entries[key]
            local valid, normalized = pcall(function()
                return entry and entry.Normalize(decode(value))
            end)
            if entry and valid and normalized ~= nil then
                pending[key] = normalized
            else
                table.insert(report.Skipped, key)
            end
        end
        local keys = {}
        for key in pairs(pending) do
            table.insert(keys, key)
        end
        table.sort(keys, function(a, b)
            local ap, bp = self.Flags._entries[a].Priority, self.Flags._entries[b].Priority
            return ap == bp and a < b or ap < bp
        end)
        for _, key in ipairs(keys) do
            self.Flags:Set(key, pending[key], silent)
            table.insert(report.Applied, key)
        end
        table.sort(report.Applied)
        table.sort(report.Skipped)
        return report
    end)
    return ok, result
end
function Config:Save(name)
    return pcall(function()
        nameCheck(name)
        self.Adapter.Write(name, self:Export())
        return name
    end)
end
function Config:Load(name, silent)
    local ok, data = pcall(function()
        nameCheck(name)
        return self.Adapter.Read(name)
    end)
    if not ok then
        return false, data
    end
    return self:Import(data, silent)
end
function Config:Delete(name)
    return pcall(function()
        nameCheck(name)
        self.Adapter.Delete(name)
        return name
    end)
end
function Config:List()
    return self.Adapter.List()
end
function Config:Rename(old, new)
    return pcall(function()
        nameCheck(old)
        nameCheck(new)
        if old == new then
            return new
        end
        assert(not table.find(self.Adapter.List(), new), "Destination already exists")
        local data = self.Adapter.Read(old)
        self.Adapter.Write(new, data)
        local ok, err = pcall(self.Adapter.Delete, old)
        if not ok then
            pcall(self.Adapter.Delete, new)
            error(err)
        end
        return new
    end)
end
return Config
