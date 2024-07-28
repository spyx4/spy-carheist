-- server.lua
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('spy-carheist:reward')
AddEventHandler('spy-carheist:reward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local reward = math.random(500, 1000) -- Random reward between 500 and 1000

    Player.Functions.AddMoney('cash', reward)
    TriggerClientEvent('QBCore:Notify', src, "You received $" .. reward .. " for delivering the car!", 'success')
end)
