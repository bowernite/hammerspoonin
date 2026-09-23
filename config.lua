local defaults = {
    startColimaOnBoot = true,
    skipUpgradeCasks = {},
    extraNagNeedles = {},
    extraSuppressRules = {}
}

local function loadLocalOverrides()
    local path = hs.configdir .. "/local.lua"
    if not hs.fs.attributes(path) then
        return {}
    end

    local chunk, loadErr = loadfile(path)
    if not chunk then
        hs.printf("local.lua failed to load: %s", loadErr)
        return {}
    end

    local ok, result = pcall(chunk)
    if not ok then
        hs.printf("local.lua failed to run: %s", result)
        return {}
    end

    if type(result) ~= "table" then
        hs.printf("local.lua must return a table")
        return {}
    end

    return result
end

local function applyOverrides(overrides)
    local config = {}
    for key, value in pairs(defaults) do
        config[key] = value
    end

    for key, value in pairs(overrides) do
        if defaults[key] == nil then
            hs.printf("local.lua has unknown key: %s", key)
        else
            config[key] = value
        end
    end

    return config
end

return applyOverrides(loadLocalOverrides())
