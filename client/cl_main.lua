local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)


CreateThread(function() 
	for k, v in pairs(Config.Locations["police"]) do
        exports['qb-target']:AddBoxZone(v.name, v.coords, v.length, v.width, {
            name = v.name,
            debugPoly = Config.Debug,
            heading = v.heading,
            minZ = v.minZ,
            maxZ = v.maxZ,
        }, {
        options = {
            {
                type = "client",
                event = "rs-frontdesk:client:OpenFrontDesk",
                icon = "fas fa-desktop",
                label = "Front Desk",
            },
        },
        distance = 2.5
    })
    end
end)

local function IsValidJob()
    local retval = false
    for k, v in pairs(Config.Jobs) do
        if PlayerData.job.name == v then
            retval = true
        end
    end
    return retval
end

local function DutyCheck()
    local retval = false
    if PlayerData.job.onduty then
        retval = true
    end
    return retval
end

RegisterNetEvent('rs-frontdesk:client:OpenFrontDesk',function()
    if IsValidJob() then
    local FrontDeskMenu = {
        {
            header =  'Police Department Front Desk',
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = 'Toggle Duty',
            icon = 'fas fa-power-off',
            params = {
                event = 'rs-frontdesk:client:ToggleDuty'
            }
        },  
        {
            header = 'Assistance Menu',
            icon = 'fas fa-hand-holding-heart',
            params = {
                event = 'rs-frontdesk:client:OpenAssistanceMenu'
            }
        },
        {
            header = 'Exit Menu',
            icon = 'fas fa-x',
        },
    }
        exports['qb-menu']:openMenu(FrontDeskMenu)
else
    local FrontDeskMenu = {
        {
            header =  'Police Department Front Desk',
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = 'Toggle Duty',
            icon = 'fas fa-power-off',
            disabled = true,
            params = {
                event = 'rs-frontdesk:client:OpenDutyMenu'
            }
        },  
        {
            header = 'Assistance Menu',
            icon = 'fas fa-hand-holding-heart',
            params = {
                event = 'rs-frontdesk:client:OpenAssistanceMenu'
            }
        },
        {
            header = 'Exit Menu',
            icon = 'fas fa-x',
        },
    }
    exports['qb-menu']:openMenu(FrontDeskMenu)
end
end)

RegisterNetEvent('rs-frontdesk:client:ToggleDuty',function()
    TriggerServerEvent('QBCore:ToggleDuty')
end)


RegisterNetEvent('rs-frontdesk:client:OpenAssistanceMenu',function()
    local AssistanceMenu = {
        {
            header = 'Assistance Menu',
            txt = 'Select an option below',
            icon = 'fas fa-code',
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = 'Assistance',
            icon = 'fas fa-hand',
            params = {
                event = 'rs-frontdesk:client:RequestAssistance',
                args = 'assistance',
            }
        },  
        {
            header = 'Weapon License',
            icon = 'fas fa-gun',
            params = {
                event = 'rs-frontdesk:client:RequestAssistance',
                args = 'weaponlicense',
            }
        },
        {
            header = 'Interview',
            icon = 'fas fa-people-arrows-left-right',
            params = {
                event = 'rs-frontdesk:client:RequestAssistance',
                args = 'interview',
            }
        },
        {
            header = 'Supervisor',
            icon = 'fas fa-crown',
            params = {
                event = 'rs-frontdesk:client:RequestAssistance',
                args = 'supervisor',
            }
        },
        {
            header = 'Return',
            icon = 'fas fa-arrow-left-long',
            params = {
                event = 'rs-frontdesk:client:OpenFrontDesk'
            }
        },
    }
    exports['qb-menu']:openMenu(AssistanceMenu)
end)


RegisterNetEvent('rs-frontdesk:client:RequestAssistance',function(type)
    QBCore.Functions.Notify('An Officer should be with you shortly', 'success')
    Wait(1000)
    if Config.Dispatch == "default" then
        if type == "assistance" then
            TriggerServerEvent('police:server:policeAlert', 'Assitance Required')
        elseif type == "weaponlicense" then
            TriggerServerEvent('police:server:policeAlert', 'Weapon License Request')
        elseif type == "interview" then
            TriggerServerEvent('police:server:policeAlert', 'Interview Request')
        elseif type == "supervisor" then
            TriggerServerEvent('police:server:policeAlert', 'Supervisor Request')
        end
    elseif Config.Dispatch == "ps-dispatch" then
        if type == "assistance" then 
            exports["ps-dispatch"]:CustomAlert({ coords = vector3(0.0, 0.0, 0.0), message = "Assitance Required", dispatchCode = "10-60", description = "Assistance Required", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
        elseif type == "weaponlicense" then
            exports["ps-dispatch"]:CustomAlert({ coords = vector3(0.0, 0.0, 0.0), message = "Weapon License Request", dispatchCode = "10-60", description = "Weapon License Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
        elseif type == "interview" then
            exports["ps-dispatch"]:CustomAlert({ coords = vector3(0.0, 0.0, 0.0), message = "Interview Request", dispatchCode = "10-60", description = "Interview Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
        elseif type == "supervisor" then
            exports["ps-dispatch"]:CustomAlert({ coords = vector3(0.0, 0.0, 0.0), message = "Supervisor Request", dispatchCode = "10-60", description = "Supervisor Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
        end
    elseif Config.Dispatch == "cd_dispatch" then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        if type == "assistance" then
        TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Assitance Required', message = 'Assitance Required at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Assitance Required', time = (5 * 60 * 1000), sound = 1, }, })
        elseif type == "weaponlicense" then
        TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Weapon License Request', message = 'Weapon License Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Weapon License Request', time = (5 * 60 * 1000), sound = 1, }, })
        elseif type == "interview" then
        TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Interview Request', message = 'Interview Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Interview Request', time = (5 * 60 * 1000), sound = 1, }, })
        elseif type == "supervisor" then
        TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Supervisor Request', message = 'Supervisor Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Supervisor Request', time = (5 * 60 * 1000), sound = 1, }, })
        end
    end
end)


AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(Config.Locations["police"]) do
            exports['qb-target']:RemoveZone(v.name)
        end
    end
end)