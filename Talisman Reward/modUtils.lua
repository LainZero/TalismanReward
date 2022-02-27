local jsonUtils = json

-- You'll probably not need this, as getConfigHandler already handles everything
local function loadConfig(defaultConfig, modName)
    local currentConfig = {}

    if jsonUtils ~= nil then
        local savedConfig = jsonUtils.load_file(modName .. "/config.json")

        if savedConfig ~= nil then currentConfig = savedConfig end

        for k, v in pairs(currentConfig) do defaultConfig[k] = v end
    end

    return defaultConfig
end

-- You can use this, but it's easier to use settings.saveConfig instead
-- "settings" is a table returned by calling getConfigHandler.
local function saveConfig(currentConfig, newConfig, modName)
    for k, v in pairs(newConfig) do currentConfig[k] = v end

    if jsonUtils ~= nil then
        jsonUtils.dump_file(modName .. "/config.json", currentConfig)
    end
end

-- Handles and persists your mod configuration for you, so users don't have to toggle stuff every restart.
local function getConfigHandler(defaultSettings, modName)
    local settings = {}

    settings.data = loadConfig(defaultSettings, modName)

    settings.isSavingAvailable = jsonUtils ~= nil

    function settings.saveConfig(newConfig)
        saveConfig(settings.data, newConfig, modName)
    end

    function settings.handleChange(changed, value, property)
        if changed then
            local newSetting = {};
            newSetting[property] = value;
            settings.saveConfig(newSetting)
        end
    end

    return settings
end

local modUtils = {}

modUtils.getConfigHandler = getConfigHandler;

return modUtils
