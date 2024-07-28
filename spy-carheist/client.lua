local QBCore = exports['qb-core']:GetCoreObject()
local missionVehicle = nil
local missionBlip = nil
local deliveryBlip = nil
local bossBlip = nil
local missionStarted = false
local enemies = {}

-- Define NPC and mission details
local npcCoords = vector3(-59.4, 1946.59, 189.32) -- Replace with actual coordinates
local vehicleCoordsList = {
    vector3(-1287.28, -812.9, 17.42), -- Replace with actual coordinates
    vector3(-1195.3, -1496.13, 4.38), -- Add more coordinates as needed
    vector3(-583.29, -1793.77, 22.84),
}

-- List of potential vehicle models
local vehicleModels = {'seminole2', 'washington', 'dynasty'} -- Replace with desired vehicle models

-- List of potential delivery coordinates
local deliveryLocations = {
    vector3(1258.02, -337.34, 69.08),
    vector3(2579.57, 439.7, 108.46),
    vector3(1531.61, 1703.64, 109.76),
    -- Add more locations as needed
}

-- Enemy spawn details
local enemyModel = 'g_m_m_chicold_01' -- Replace with desired enemy ped model

-- Create NPC on client load
Citizen.CreateThread(function()
    RequestModel('a_m_m_business_01') -- Replace with desired ped model
    while not HasModelLoaded('a_m_m_business_01') do
        Wait(1)
    end

    local bossPed = CreatePed(4, 'a_m_m_business_01', npcCoords.x, npcCoords.y, npcCoords.z, 3374176, false, true)
    SetEntityInvincible(bossPed, true)
    FreezeEntityPosition(bossPed, true)
    SetBlockingOfNonTemporaryEvents(bossPed, true)

    -- Add blip for the boss
    bossBlip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)
    SetBlipSprite(bossBlip, 280)
    SetBlipDisplay(bossBlip, 4)
    SetBlipScale(bossBlip, 1.0)
    SetBlipColour(bossBlip, 1)
    SetBlipAsShortRange(bossBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Boss")
    EndTextCommandSetBlipName(bossBlip)

    exports['qb-target']:AddTargetEntity(bossPed, {
        options = {
            {
                event = "spy-carheist:startMission",
                icon = "fas fa-car",
                label = "Talk to Boss",
            },
        },
        distance = 2.5,
    })
end)

-- Start the mission
RegisterNetEvent('spy-carheist:startMission')
AddEventHandler('spy-carheist:startMission', function()
    if not missionStarted then
        missionStarted = true
        QBCore.Functions.Notify("Go steal the car marked on your GPS!", "success")

        -- Select a random vehicle location
        local vehicleCoords = vehicleCoordsList[math.random(#vehicleCoordsList)]
        -- Select a random vehicle model
        local vehicleModel = vehicleModels[math.random(#vehicleModels)]

        RequestModel(vehicleModel)
        while not HasModelLoaded(vehicleModel) do
            Wait(1)
        end

        missionVehicle = CreateVehicle(vehicleModel, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, 0.0, true, false)
        SetVehicleDoorsLocked(missionVehicle, 2)
        missionBlip = AddBlipForCoord(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z)
        SetBlipSprite(missionBlip, 225)
        SetBlipColour(missionBlip, 1)
        SetBlipRoute(missionBlip, true)

        -- Listen for player death
        Citizen.CreateThread(function()
            while missionStarted do
                Citizen.Wait(100)
                if IsEntityDead(PlayerPedId()) then
                    QBCore.Functions.Notify("You have been killed. Mission failed!", "error")
                    EndMission()
                end
            end
        end)

        -- Check for player reaching the vehicle coordinates
        Citizen.CreateThread(function()
            while missionStarted do
                Citizen.Wait(1000)
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - vehicleCoords)
                if distance < 50.0 then
                    SpawnEnemies(vehicleCoords)
                    break
                end
            end
        end)
    else
        QBCore.Functions.Notify("You are already on a mission!", "error")
    end
end)

-- Check for car delivery
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if missionStarted and missionVehicle then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if IsPedInVehicle(playerPed, missionVehicle, false) then
                if missionBlip then
                    RemoveBlip(missionBlip)
                end
                if not deliveryBlip then
                    -- Select a random delivery location
                    local deliveryCoords = deliveryLocations[math.random(#deliveryLocations)]
                    deliveryBlip = AddBlipForCoord(deliveryCoords.x, deliveryCoords.y, deliveryCoords.z)
                    SetBlipSprite(deliveryBlip, 225)
                    SetBlipColour(deliveryBlip, 2)
                    SetBlipRoute(deliveryBlip, true)
                    QBCore.Functions.Notify("Deliver the car to the marked location!", "success")
                end
            end

            if deliveryBlip then
                local deliveryCoords = GetBlipCoords(deliveryBlip)
                local distance = #(playerCoords - deliveryCoords)
                if distance < 10.0 and IsPedInVehicle(playerPed, missionVehicle, false) then
                    QBCore.Functions.Notify("Car delivered!", "success")
                    TriggerServerEvent('spy-carheist:reward')
                    EndMission()
                end
            end
        end
    end
end)

-- Function to spawn enemies
function SpawnEnemies(vehicleCoords)
    -- Set up relationship group for enemies
    AddRelationshipGroup("ENEMIES")
    SetRelationshipBetweenGroups(5, GetHashKey("ENEMIES"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("ENEMIES"))
    SetRelationshipBetweenGroups(0, GetHashKey("ENEMIES"), GetHashKey("ENEMIES"))

    -- Spawn enemies near the vehicle location
    local enemyCoordsList = {
        vector3(vehicleCoords.x + 2.0, vehicleCoords.y, vehicleCoords.z),
        vector3(vehicleCoords.x - 2.0, vehicleCoords.y, vehicleCoords.z),
        vector3(vehicleCoords.x, vehicleCoords.y + 2.0, vehicleCoords.z),
    }

    for _, coords in pairs(enemyCoordsList) do
        RequestModel(enemyModel)
        while not HasModelLoaded(enemyModel) do
            Wait(1)
        end

        local enemy = CreatePed(4, enemyModel, coords.x, coords.y, coords.z, 3374176, false, true)
        GiveWeaponToPed(enemy, GetHashKey("WEAPON_PISTOL"), 250, false, true)
        SetPedAccuracy(enemy, 50)
        SetPedArmour(enemy, 50)
        SetPedAsEnemy(enemy, true)
        SetPedRelationshipGroupHash(enemy, GetHashKey("ENEMIES"))
        TaskCombatPed(enemy, PlayerPedId(), 0, 16)
        table.insert(enemies, enemy)
    end
end

-- Function to end the mission
function EndMission()
    DeleteVehicle(missionVehicle)
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
    end
    missionStarted = false
    missionVehicle = nil
    deliveryBlip = nil

    -- Delete enemies
    for _, enemy in pairs(enemies) do
        if DoesEntityExist(enemy) then
            DeleteEntity(enemy)
        end
    end
    enemies = {}
end
