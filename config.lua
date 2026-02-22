local config = {
    simhid_g1000_identifier = {path = "COM3"},
    simhid_g1000_display = 2,
    simhid_g1000_display3 = 3,
    x56_stick_identifier = {name = "Saitek Pro Flight X-56 Rhino Stick"},
    x56_throttle_identifier = {name = "Saitek Pro Flight X-56 Rhino Throttle"},
}

if override_config ~= nil then
    for key, value in pairs(override_config) do
        config[key] = value
    end
end
if config.simhid_g1000_display_scale == nil then
    config.simhid_g1000_display_scale = 1
end

package.path = package.path ..
               ";" .. mapper.script_dir .. "\\simhid_g1000\\?.lua" ..
               ";" .. mapper.script_dir .. "\\simhid_g1000\\msfs\\?.lua" ..
               ";" .. mapper.script_dir .. "\\x56\\?.lua"

local context = {
    simhid_g1000 = require("simhid_g1000"),
    hotas = require("x56"),
}

mapper.add_primary_mappings(context.simhid_g1000.init(config))
mapper.add_primary_mappings(context.hotas.init(config))

local synonym_map_msfs = {}
synonym_map_msfs["Airbus A320neo FlyByWire"] = "Airbus A320 Neo FlyByWire"
synonym_map_msfs["Airbus A320 NX ANA All Nippon Airways JA219A SoccerYCA "] = "Airbus A320 Neo FlyByWire"
synonym_map_msfs["Airbus A320 Neo Bhutan Airlines (A32NX Converted)"] = "Airbus A320 Neo FlyByWire"

local function normalize_msfs_aircraft_name(name)
    local synonym = synonym_map_msfs[name]
    if synonym then
        return synonym
    else
        if string.find(name, "FenixA320") == 1 then
            return "FenixA320"
        end
        if string.find(name, "Fenix A320") == 1 then
            return "FenixA320"
        end
        if string.find(name, "PMDG 737") == 1 then
            return "PMDG 737"
        end
        if string.find(name, "Blackbird Simulations DHC-") == 1 then
            return "Blackbird Simulations DHC-2"
        end
        if string.find(name, "Microsoft Vision Jet") == 1 then
            return "Vision Jet"
        end
        if string.find(name, "PC%-24") then
             return "pc24"
        end
        if string.find(name, "C408 SkyCourier") then
             return "C408 SkyCourier"
        end
        if string.find(name, "King Air C90") then
             return "King Air C90 GTX"
        end
        if string.find(name, "G1000") then
             return "Cessna Skyhawk G1000"
        end
        if string.find(name, "SR22T") then
             return "SR22T"
        end

        return name
    end
end

local active_sim = ""
local active_aircraft = ""

local function change_aircraft(sim_type, aircraft, is_reload)
    if not is_reload then
        mapper.reset_viewports()
    end
    mapper.set_secondary_mappings({})

    active_sim = sim_type
    active_aircraft = aircraft

    if sim_type == "msfs" or sim_type == "fs2024" then
        aircraft = normalize_msfs_aircraft_name(aircraft)
        mapper.print("DEBUG: Normalized Aircraft Name: '" .. tostring(aircraft) .. "'") 
    end

    local controller = context.simhid_g1000.change(sim_type, aircraft)
    context.hotas.change(sim_type, aircraft, controller)
    if controller.need_to_start_viewports then
        mapper.start_viewports()
    end
end

mapper.add_primary_mappings({
    {event=mapper.events.change_aircraft, action=function (event, value)
        change_aircraft(value.sim_type, value.aircraft, false)
    end},
})

-- Hot-reload configuration
local function reload_config()
    mapper.print("Reloading FSMapper configs...")
    
    if context.simhid_g1000 and type(context.simhid_g1000.cleanup) == "function" then
        context.simhid_g1000.cleanup()
    end

    -- Clear all loaded modules from cache except essential ones so they re-evaluate
    local core_modules = {
        ["config"] = true,
        ["os"] = true,
        ["io"] = true,
        ["string"] = true,
        ["math"] = true,
        ["table"] = true,
        ["coroutine"] = true,
        ["package"] = true,
        ["_G"] = true,
    }
    for k, v in pairs(package.loaded) do
        if not core_modules[k] and string.find(k, "lib/") == nil then
            package.loaded[k] = nil
            mapper.print("DEBUG: Cleared module: " .. k)
        elseif string.find(k, "msfs/") ~= nil or string.find(k, "dcs/") ~= nil then
            package.loaded[k] = nil
            mapper.print("DEBUG: Cleared sub-module: " .. k)
        end
    end
    
    -- Reload and reinitialize modules after a small delay to release OS handles
    mapper.delay(500, function()
        context.simhid_g1000 = require("simhid_g1000/simhid_g1000")
        context.hotas = require("x56/x56")
        
        mapper.add_primary_mappings(context.simhid_g1000.init(config))
        mapper.add_primary_mappings(context.hotas.init(config))
        
        -- Reapply current aircraft configuration without resetting viewports
        local sim = active_sim
        local ac = active_aircraft
        if sim == "" and config.initial_sim ~= nil then sim = config.initial_sim end
        if ac == "" and config.initial_aircraft ~= nil then ac = config.initial_aircraft end

        change_aircraft(sim, ac, true)
        mapper.print("Reload complete.")
    end)
end

-- Expose the reload function so it can be called from the console or other scripts
mapper.reload_config = reload_config

if config.initial_sim ~= nil and config.initial_aircraft ~= nil then
    mapper.print('Emulating: [' .. config.initial_sim .. '] ' .. config.initial_aircraft)
    change_aircraft(config.initial_sim, config.initial_aircraft, false)
else
    change_aircraft("", "", false)
end
