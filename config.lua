Config = Config or {}

-- Set to true or false or GetConvar('UseTarget', 'false') == 'true' to use global option or script specific
-- These have to be a string thanks to how Convars are returned.
Config.UseTarget = true

Config.Timeout = (1000 * 60) * 15 -- last number originally 15 is amount of minutes 
Config.RequiredCops = 0
Config.JewelleryLocation = {
    ['coords'] = vector3(-630.5, -237.13, 38.08),
}

Config.WhitelistedWeapons = {
    [`weapon_assaultrifle`] = {
        ['timeOut'] = 10000
    },
    [`weapon_carbinerifle`] = {
        ['timeOut'] = 10000
    },
    [`weapon_pumpshotgun`] = {
        ['timeOut'] = 10000
    },
    [`weapon_sawnoffshotgun`] = {
        ['timeOut'] = 10000
    },
    [`weapon_compactrifle`] = {
        ['timeOut'] = 10000
    },
    [`weapon_microsmg`] = {
        ['timeOut'] = 10000
    },
    [`weapon_autoshotgun`] = {
        ['timeOut'] = 10000
    },
    [`weapon_pistol`] = {
        ['timeOut'] = 10000
    },
    [`weapon_pistol_mk2`] = {
        ['timeOut'] = 10000
    },
    [`weapon_combatpistol`] = {
        ['timeOut'] = 10000
    },
    [`weapon_appistol`] = {
        ['timeOut'] = 10000
    },
    [`weapon_pistol50`] = {
        ['timeOut'] = 10000
    },
}

