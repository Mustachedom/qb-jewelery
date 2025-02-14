local QBCore = exports['qb-core']:GetCoreObject()
local timeOut = false
local flags = {}

local VitrineRewards = {
    { item = 'rolex',         amount = { min = 1, max = 4},  probability = 0.4 },
    { item = 'diamond_ring',  amount = { min = 1, max = 4 }, probability = 0.3 },
    { item = 'goldchain',     amount = { min = 1, max = 4 }, probability = 0.2 },
    { item = 'tenkgoldchain', amount = { min = 1, max = 4 }, probability = 0.1 },
}

local vitrineLocations  = {
    {coords = vector4(-626.91, -235.39, 38.06, 34.63),    isOpened = false,    isBusy = false, id = 1},
    {coords = vector4(-625.82, -234.7, 38.05, 34.63),     isOpened = false,    isBusy = false, id = 2},
    {coords = vector4(-626.93, -233.05, 38.06, 210.85),   isOpened = false,    isBusy = false, id = 3},
    {coords = vector4(-628.0, -233.86, 38.05, 210.85),    isOpened = false,    isBusy = false, id = 4},
    {coords = vector4(-625.7, -237.84, 38.06, 215.51),    isOpened = false,    isBusy = false, id = 5},
    {coords = vector4(-626.66, -238.57, 38.06, 208.53),   isOpened = false,    isBusy = false, id = 6},
    {coords = vector4(-624.61, -230.86, 38.06, 303.37),   isOpened = false,    isBusy = false, id = 7},
    {coords = vector4(-623.13, -232.86, 38.06, 309.02),   isOpened = false,    isBusy = false, id = 8},
    {coords = vector4(-620.23, -234.33, 38.06, 217.5),    isOpened = false,    isBusy = false, id = 9},
    {coords = vector4(-619.16, -233.63, 38.06, 217.42),   isOpened = false,    isBusy = false, id = 10},
    {coords = vector4(-620.17, -233.39, 38.06, 36.03),    isOpened = false,    isBusy = false, id = 11},
    {coords = vector4(-617.63, -230.55, 38.06, 307.75),   isOpened = false,    isBusy = false, id = 12},
    {coords = vector4(-618.37, -229.41, 38.06, 303.97),   isOpened = false,    isBusy = false, id = 13},
    {coords = vector4(-621.04, -228.62, 38.06, 125.78),   isOpened = false,    isBusy = false, id = 14},
    {coords = vector4(-619.68, -227.6, 38.06, 313.51),    isOpened = false,    isBusy = false, id = 15},
    {coords = vector4(-620.45, -226.51, 38.06, 298.4),    isOpened = false,    isBusy = false, id = 16},
    {coords = vector4(-619.73, -230.35, 38.06, 127.88),   isOpened = false,    isBusy = false, id = 17},
    {coords = vector4(-623.93, -227.1, 38.06, 33.19),     isOpened = false,    isBusy = false, id = 18},
    {coords = vector4(-624.97, -227.85, 38.06, 35.51),    isOpened = false,    isBusy = false, id = 19},
    {coords = vector4(-623.96, -228.16, 38.06, 212.71),   isOpened = false,    isBusy = false, id = 20},
}

QBCore.Functions.CreateCallback('qb-jewelery:server:getLoc', function(_, cb)
    cb(vitrineLocations)
end)


-- Functions

local function exploitBan(id, reason)
    MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(id),
            QBCore.Functions.GetIdentifier(id, 'license'),
            QBCore.Functions.GetIdentifier(id, 'discord'),
            QBCore.Functions.GetIdentifier(id, 'ip'),
            reason,
            2147483647,
            'qb-jewelery'
        })
    TriggerEvent('qb-log:server:CreateLog', 'jewelery', 'Player Banned', 'red',
        string.format('%s was banned by %s for %s', GetPlayerName(id), 'qb-jewelery', reason), true)
    DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

local function getRewardBasedOnProbability(source, table)
    local src = source
    local random, probability = math.random(), 0

    for k, v in pairs(table) do
        probability = probability + v.probability
        if random <= probability then
            local data = VitrineRewards[k]
            local info = {item = data.item, amount = math.random(data.amount.min, data.amount.max)}
            if exports['qb-inventory']:AddItem(src, info.item, info.amount, false, false, 'qb-jewellery:server:vitrineReward') then
                TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[info.item], 'add', info.amount)
            else
                TriggerClientEvent('QBCore:Notify', src, Lang:t('error.to_much'), 'error')
            end
        end
    end
end

-- Events
local function setOpen(id, bool)
    vitrineLocations[id].isBusy = bool
    TriggerClientEvent('qb-jewellery:client:setOpened', -1, id, bool)
    CreateThread(function()
        Wait(Config.Timeout)
        vitrineLocations[id].isBusy = false
        TriggerClientEvent('qb-jewellery:client:setBusy', -1, id, false)
    end)
    return true
end

local function checkDist(source, num)
    local src = source
    local plrPed = GetPlayerPed(src)
    local plrCoords = GetEntityCoords(plrPed)
    local vitrineCoords = vitrineLocations[num].coords
    if #(plrCoords - vector3(vitrineCoords.x, vitrineCoords.y, vitrineCoords.z)) <= 5.0 then
        return true
    else
        return false
    end
end

local function handleCheat(Player)
    local license = Player.PlayerData.license
    if flags[license] then
        flags[license] = flags[license] + 1 or 1
    else
        flags[license] = 1
    end
    if flags[license] >= 3 then
        exploitBan('Getting flagged many times from exploiting the \"qb-jewellery:server:vitrineReward\" event')
    else
        DropPlayer(Player.PlayerData.source, 'Exploiting')
    end
end

-- events
RegisterNetEvent('qb-jewellery:server:setBusy', function(id, bool)
    vitrineLocations[id].isBusy = bool
    TriggerClientEvent('qb-jewellery:client:setBusy', -1, id, bool)
end)

RegisterNetEvent('qb-jewellery:server:vitrineReward', function(vitrineIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if vitrineLocations[vitrineIndex] == nil or vitrineLocations[vitrineIndex].isOpened ~= false then
        exploitBan(src, 'Trying to trigger an exploitable event \"qb-jewellery:server:vitrineReward\"')
        return
    end

    --if QBCore.Functions.GetOnDuty('police') >= Config.RequiredCops then return end
    if not checkDist(src, vitrineIndex) then
        handleCheat(Player)
    else
        setOpen(vitrineIndex, true)
        getRewardBasedOnProbability(src, VitrineRewards)
    end
end)

RegisterNetEvent('qb-jewellery:server:setTimeout', function()
    if not timeOut then
        timeOut = true
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', true)
        Citizen.CreateThread(function()
            Citizen.Wait(Config.Timeout)
            TriggerEvent('qb-scoreboard:server:SetActivityBusy', 'jewellery', false)
            timeOut = false
        end)
    end
end)
