local QBCore = exports['qb-core']:GetCoreObject()
local firstAlarm = false
local smashing = false
local targBusy = false
local vitrine = {}

local function sort(tbl, val)
    table.sort(tbl, function(a, b)
        return a[val] < b[val]
    end)
end

RegisterNetEvent('qb-jewellery:client:setBusy', function(id, bool)
    vitrine[id].isBusy = bool
end)

RegisterNetEvent('qb-jewellery:client:setOpened', function(id, bool)
    vitrine[id].isOpened = bool
end)


local function loadParticle()
    if not HasNamedPtfxAssetLoaded('scr_jewelheist') then
        RequestNamedPtfxAsset('scr_jewelheist')
    end
    while not HasNamedPtfxAssetLoaded('scr_jewelheist') do
        Wait(0)
    end
    SetPtfxAssetNextCall('scr_jewelheist')
end

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(3)
    end
end

local function validWeapon()
    local ped = PlayerPedId()
    local pedWeapon = GetSelectedPedWeapon(ped)

    for k, _ in pairs(Config.WhitelistedWeapons) do
        if pedWeapon == k then
            return true
        end
    end
    return false
end

local function smashVitrine(k)
    TriggerServerEvent('qb-jewellery:server:setBusy', k, true)
    if not firstAlarm then
        TriggerServerEvent('police:server:policeAlert', 'Suspicious Activity')
        firstAlarm = true
    end
    -- if not QBCore.Functions.GetOnDuty('police') >= Config.RequiredCops then 
        -- QBCore.Functions.Notify(Lang:t('error.minimum_police', {value = Config.RequiredCops}), 'error')
        --TriggerServerEvent('qb-jewellery:server:setBusy', k, false)
        -- targBusy = false
        -- return
    -- end
    smashing = true
    local animDict,animName  = 'missheist_jewel', 'smash_case'
    local ped = PlayerPedId()
    local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.6, 0)
    local pedWeapon = GetSelectedPedWeapon(ped)
    local random = math.random(1, 100)

    if random <= 80 and not QBCore.Functions.IsWearingGloves() then
        TriggerServerEvent('evidence:server:CreateFingerDrop', plyCoords)
    elseif random <= 5 and QBCore.Functions.IsWearingGloves() then
        TriggerServerEvent('evidence:server:CreateFingerDrop', plyCoords)
        QBCore.Functions.Notify(Lang:t('error.fingerprints'), 'error')
    end

    CreateThread(function()
        while smashing do
            loadAnimDict(animDict)
            TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 2, 0, 0, 0, 0)
            Wait(500)
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'breaking_vitrine_glass', 0.25)
            loadParticle()
            StartParticleFxLoopedAtCoord('scr_jewel_cab_smash', plyCoords.x, plyCoords.y, plyCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            Wait(2500)
        end
    end)

    QBCore.Functions.Progressbar('smash_vitrine', Lang:t('info.progressbar'), Config.WhitelistedWeapons[pedWeapon]['timeOut'], false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('qb-jewellery:server:setBusy', k, false)
        TriggerServerEvent('qb-jewellery:server:vitrineReward', k)
        TriggerServerEvent('qb-jewellery:server:setTimeout')
        TriggerServerEvent('police:server:policeAlert', 'Robbery in progress')
        smashing = false
        TaskPlayAnim(ped, animDict, 'exit', 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        targBusy = false
    end, function()
        smashing = false
        targBusy = false
        TriggerServerEvent('qb-jewellery:server:setBusy', k, false)
    end)
end

-- Threads

CreateThread(function()
    local Dealer = AddBlipForCoord(Config.JewelleryLocation['coords']['x'], Config.JewelleryLocation['coords']['y'], Config.JewelleryLocation['coords']['z'])
    SetBlipSprite(Dealer, 617)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale(Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Vangelico Jewelry')
    EndTextCommandSetBlipName(Dealer)
end)


CreateThread(function()
    QBCore.Functions.TriggerCallback('qb-jewelery:server:getLoc', function(data)
        sort(data, 'id')
        for k, v in ipairs (data) do 
            table.insert(vitrine, {coords = v.coords, isOpened = v.isOpened, isBusy = v.isBusy, id = v.id})
        end
    end)
    repeat Wait(1) until #vitrine >= 1 -- there to give time for vitrine to populate from callback

    if Config.UseTarget then
        for k, v in pairs(vitrine) do
            exports['qb-target']:AddBoxZone('jewelstore' .. k, v.coords, 1, 1, {
                name = 'jewelstore' .. k,
                heading = 40,
                minZ = v.coords.z - 1,
                maxZ = v.coords.z + 1,
                debugPoly = false
            }, {
                options = {
                    {
                        type = 'client',
                        icon = 'fa fa-hand',
                        label = Lang:t('general.target_label'),
                        action = function()
                            targBusy = true
                            if validWeapon() then
                                smashVitrine(k)
                            else
                                targBusy = false
                                QBCore.Functions.Notify(Lang:t('error.wrong_weapon'), 'error')
                            end
                        end,
                        canInteract = function()
                            print(k)
                            if v.isOpened or v.isBusy or targBusy then
                                return false
                            end
                            return true
                        end,
                    }
                },
                distance = 1.5
            })
        end
    else
        for k, v in pairs(vitrine) do
            local boxZone = BoxZone:Create(v.coords, 0.5, 1, {
                name = 'jewelstore' .. k,
                heading = v.coords.w,
                minZ = v.coords.z - 1,
                maxZ = v.coords.z + 1,
                debugPoly = true
            })
            boxZone:onPlayerInOut(function(isPointInside)
              --  if not exports['qb-policejob']:GetCops(0) then return end
                if v.isBusy or v.isOpened then return end
                if isPointInside then
                    exports['qb-core']:DrawText(Lang:t('general.drawtextui_grab'), 'left')
                    while not smashing do
                        if IsControlJustPressed(0, 38) then
                            if not vitrine[k].isBusy and not vitrine[k].isOpened then
                                exports['qb-core']:KeyPressed()
                                if validWeapon() then
                                    smashVitrine(k)
                                else
                                    QBCore.Functions.Notify(Lang:t('error.wrong_weapon'), 'error')
                                end
                            else
                                exports['qb-core']:DrawText(Lang:t('general.drawtextui_broken'), 'left') 
                            end
                        end
                        Wait(1)
                    end
                else
                    exports['qb-core']:HideText()
                end
            end)
        end
    end
end)

