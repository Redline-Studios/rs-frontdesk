local QBCore = exports['qb-core']:GetCoreObject()
local serverCooldown = {}

-- Coldown for each job --
RegisterServerEvent('rs-frontdesk:server:AlertCooldown', function(job, bool)
    if serverCooldown[job] == nil then serverCooldown[job] = false end
    if bool then
        serverCooldown[job] = true

        SetTimeout((Config.Cooldown * 60000), function()
            serverCooldown[job] = false
        end)
    end
end)

QBCore.Functions.CreateCallback('rs-frontdesk:server:CooldownCheck',function(source, cb, job)
    local src = source
    local callback = false

    if not serverCooldown[job] then callback = true end
    cb(callback)
end)
