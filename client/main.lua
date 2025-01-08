local ESX = exports['es_extended']:getSharedObject()
local missionInProgress = false
local spawnedVehicle = nil
local deliveryBlip = nil
local deliveryMarkerActive = false
local startNPC = nil
local endNPC = nil
local freeCam = nil
local isFreeCamActive = false
local missionCooldown = false

local function loadAnimation(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
end

local function createNPC(npcConfig)
    RequestModel(npcConfig.model)
    while not HasModelLoaded(npcConfig.model) do
        Wait(100)
    end

    local ped = CreatePed(4, npcConfig.model, npcConfig.coords.x, npcConfig.coords.y, npcConfig.coords.z - 1.0, npcConfig.heading, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    return ped
end

local function activateFreeCam(vehicle)
    if not DoesEntityExist(vehicle) then return end

    local vehicleCoords = GetEntityCoords(vehicle)
    local camOffset = vector3(0.0, -5.0, 2.5)
    local camCoords = vehicleCoords + camOffset

    freeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(freeCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtEntity(freeCam, vehicle, 0.0, 0.0, 0.0, true)
    SetCamActive(freeCam, true)
    RenderScriptCams(true, true, 1000, true, false)

    isFreeCamActive = true
end

local function deactivateFreeCam()
    if isFreeCamActive and DoesCamExist(freeCam) then
        RenderScriptCams(false, true, 1000, true, false)
        DestroyCam(freeCam, false)
        freeCam = nil
        isFreeCamActive = false
    end
end

CreateThread(function()
    startNPC = createNPC(Config.StartNPC)
    endNPC = createNPC(Config.EndNPC)

    exports.ox_target:addBoxZone({
        coords = Config.StartNPC.coords + vector3(0.0, 0.0, 1.0),
        size = vec3(1.5, 1.5, 2.0),
        rotation = Config.StartNPC.heading,
        debugPoly = false,
        options = {
            {
                name = 'start_go_fast',
                event = 'goFast:startMission',
                icon = 'fa-solid fa-key',
                label = 'Commencer un Go Fast',
                canInteract = function(entity, distance, zone)
                    return not missionInProgress and not missionCooldown
                end
            }
        }
    })
end)

RegisterNetEvent('goFast:startMission', function()
    missionInProgress = true

    loadAnimation(Config.StartNPC.animationDict)
    TaskPlayAnim(PlayerPedId(), Config.StartNPC.animationDict, Config.StartNPC.animationName, 8.0, -8.0, 2000, 0, 0, false, false, false)
    TaskPlayAnim(startNPC, Config.StartNPC.animationDict, Config.StartNPC.animationName, 8.0, -8.0, 2000, 0, 0, false, false, false)

    local randomIndex = math.random(1, #Config.VehicleSpawn.models)
    local selectedModel = Config.VehicleSpawn.models[randomIndex]

    RequestModel(selectedModel)
    while not HasModelLoaded(selectedModel) do
        Wait(100)
    end

    spawnedVehicle = CreateVehicle(selectedModel, Config.VehicleSpawn.coords.x, Config.VehicleSpawn.coords.y, Config.VehicleSpawn.coords.z, Config.VehicleSpawn.heading, true, false)
    SetVehicleNumberPlateText(spawnedVehicle, "GOFAST")
    SetEntityInvincible(spawnedVehicle, false)
    ESX.ShowNotification("~g~Le véhicule a été livré. Regardez-le.")

    activateFreeCam(spawnedVehicle)

    Citizen.CreateThread(function()
        Wait(3000)
        deactivateFreeCam()
        ESX.ShowNotification("~g~Dirigez-vous vers le véhicule pour commencer la mission.")
    end)

    deliveryBlip = AddBlipForCoord(Config.EndNPC.coords)
    SetBlipSprite(deliveryBlip, 225)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)

    deliveryMarkerActive = true
end)

CreateThread(function()
    while true do
        Wait(0)
        if missionInProgress and deliveryMarkerActive then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - Config.EndNPC.coords)

            if distance < 25.0 then
                DrawMarker(1, Config.EndNPC.coords.x, Config.EndNPC.coords.y, Config.EndNPC.coords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    5.0, 5.0, 1.5,
                    0, 255, 0, 150,
                    false, true, 2, nil, nil, false)

                if distance < 5.0 and IsControlJustPressed(1, 38) then
                    TriggerEvent('goFast:finishMission')
                    deliveryMarkerActive = false
                end
            end
        end
    end
end)

RegisterNetEvent('goFast:finishMission', function()
    local playerVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if playerVehicle == spawnedVehicle then
        TaskLeaveVehicle(PlayerPedId(), spawnedVehicle, 0)
        Wait(1000)

        local teleportCoords = Config.EndNPC.coords + vector3(0.0, -0.9, 0.0)

        SetEntityCoords(PlayerPedId(), teleportCoords.x, teleportCoords.y, teleportCoords.z)
        SetEntityHeading(PlayerPedId(), Config.EndNPC.heading + 180.0)

        loadAnimation(Config.EndNPC.animationDict)
        TaskPlayAnim(PlayerPedId(), Config.EndNPC.animationDict, Config.EndNPC.animationName, 8.0, -8.0, 2000, 0, 0, false, false, false)
        TaskPlayAnim(endNPC, Config.EndNPC.animationDict, Config.EndNPC.animationName, 8.0, -8.0, 2000, 0, 0, false, false, false)

        local reward = math.random(Config.Reward.min, Config.Reward.max)
        TriggerServerEvent('goFast:giveReward', reward)
        ESX.ShowNotification("~g~Mission terminée. Vous avez reçu votre récompense.")

        Citizen.CreateThread(function()
            local alpha = 255
            while alpha > 0 do
                Wait(100)
                alpha = alpha - 25
                SetEntityAlpha(spawnedVehicle, alpha, false)
            end
            DeleteVehicle(spawnedVehicle)
            spawnedVehicle = nil
        end)

        if deliveryBlip then
            RemoveBlip(deliveryBlip)
            deliveryBlip = nil
        end

        missionInProgress = false

        missionCooldown = true
        Citizen.CreateThread(function()
            Wait(120000)
            missionCooldown = false
            ESX.ShowNotification("~g~Vous pouvez maintenant démarrer une nouvelle mission.")
        end)
    else
        ESX.ShowNotification("~r~Vous n'êtes pas dans le bon véhicule.")
    end
end)
