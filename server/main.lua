local ESX = exports['es_extended']:getSharedObject()
local activeMissions = {}

RegisterNetEvent('goFast:playerJoined', function()
    local src = source
    if activeMissions[src] then
        TriggerClientEvent('goFast:syncMission', src, activeMissions[src])
    end
end)

RegisterNetEvent('goFast:startMission', function()
    local src = source
    if not activeMissions[src] then
        activeMissions[src] = {
            started = true,
            vehicleSpawned = false
        }
        TriggerClientEvent('goFast:missionStarted', src)
    else
        TriggerClientEvent('esx:showNotification', src, "~r~Vous avez déjà une mission active.")
    end
end)

RegisterNetEvent('goFast:finishMission', function()
    local src = source
    if activeMissions[src] then
        activeMissions[src] = nil
        TriggerClientEvent('goFast:missionFinished', src)
    else
        TriggerClientEvent('esx:showNotification', src, "~r~Aucune mission active trouvée.")
    end
end)

RegisterNetEvent('goFast:giveReward', function(reward)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer then
        xPlayer.addAccountMoney('black_money', reward)
        TriggerClientEvent('esx:showNotification', src, 'Vous avez reçu ~g~$' .. reward .. '~s~.')
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if activeMissions[src] then
        activeMissions[src] = nil
    end
end)
