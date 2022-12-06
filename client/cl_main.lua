local QBCore = exports['qb-core']:GetCoreObject()
local CurrentCops = 0
local closestDesk = nil
local CurrentCops = 0
local doctorCount = 0
local PlayerData = QBCore.Functions.GetPlayerData()
local PlayerJob = QBCore.Functions.GetPlayerData().job

-- Front Desk Target Zones
local function FrontDeskZones()
	for k, v in pairs(Config.Locations) do
        exports['qb-target']:AddBoxZone(v.Zone.name, v.Zone.coords, v.Zone.length, v.Zone.width, {
            name = v.Zone.name,
            debugPoly = Config.Debug,
            heading = v.Zone.heading,
            minZ = v.Zone.minZ,
            maxZ = v.Zone.maxZ,
        }, {
            options = {
                {
                    type = "client",
                    action = function()
                        TriggerEvent("rs-frontdesk:client:OpenFrontDesk", closestDesk)
                    end,
                    icon = "fas fa-desktop",
                    label = "Front Desk",
                },
            },
            distance = 2.0
        })
    end
end

-- Gets closest front desk to pass the correct data
CreateThread(function()
    while true do
        Wait(100)
        for k in pairs(Config.Locations) do
            local Pos = GetEntityCoords(PlayerPedId())
            local Distance = #(Pos - vector3(Config.Locations[k].Zone.coords.x,Config.Locations[k].Zone.coords.y,Config.Locations[k].Zone.coords.z))
            if Distance < 5 then
                closestDesk = k

                if Config.Debug then
                    print(closestDesk)
                end
            else
                Wait(100)
            end
        end
    end
end)

-- Front Desk Menu
RegisterNetEvent('rs-frontdesk:client:OpenFrontDesk',function(job)
    if PlayerJob.name == job then
        local FrontDeskMenu = {
            {
                header =  Config.Locations[job].Zone.name,
                isMenuHeader = true,
            },
            {
                header = 'Toggle Duty',
                icon = 'fas fa-power-off',
                params = {
                    event = 'rs-frontdesk:client:ToggleDuty',
                    args = job
                }
            },
            {
                header = 'Assistance Menu',
                icon = 'fas fa-hand-holding-heart',
                params = {
                    event = 'rs-frontdesk:client:OpenAssistanceMenu',
                    args = job
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
                header =  Config.Locations[job].Zone.name,
                isMenuHeader = true,
            },
            {
                header = 'Assistance Menu',
                icon = 'fas fa-hand-holding-heart',
                params = {
                    event = 'rs-frontdesk:client:OpenAssistanceMenu',
                    args = job
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

-- Toggle Duty Event
RegisterNetEvent('rs-frontdesk:client:ToggleDuty',function(job)
    if job == 'police' then
        TriggerEvent('qb-policejob:ToggleDuty')
    elseif job == 'ambulance' then
        TriggerEvent('EMSToggle:Duty')
    else
        TriggerServerEvent("QBCore:ToggleDuty")
    end
end)

-- Assistance Menu
RegisterNetEvent('rs-frontdesk:client:OpenAssistanceMenu',function(job)
    local AssistanceMenu = {}
    AssistanceMenu[#AssistanceMenu + 1] = {
        header = 'Assistance Menu',
        txt = 'Select an option below',
        icon = 'fas fa-code',
        isMenuHeader = true,
    }

    for r, s in pairs(Config.Locations[job].Menu) do
        AssistanceMenu[#AssistanceMenu + 1] = {
            header = s.Header,
            txt = s.Txt,
            icon = s.Icon,
            params = {
                event = s.Event,
                args = {
                    type = s.Args,
                    job = job
                }
            }
        }
    end

    AssistanceMenu[#AssistanceMenu + 1] = {
        header = 'Return',
        icon = 'fas fa-arrow-left-long',
        params = {
            event = 'rs-frontdesk:client:OpenFrontDesk'
        }
    }

    exports['qb-menu']:openMenu(AssistanceMenu)
end)

-- Request Assistance Event
RegisterNetEvent('rs-frontdesk:client:RequestAssistance',function(data)
    QBCore.Functions.TriggerCallback('rs-frontdesk:server:CooldownCheck', function(alert)
        if alert then
            if Config.Dispatch == "default" then
                if data.job == 'police' then
                    if CurrentCops >= Config.Locations[data.job].Required then
                        QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                        if data.type == "assistance" then
                            TriggerServerEvent('police:server:policeAlert', 'Assitance Required')
                        elseif data.type == "weaponlicense" then
                            TriggerServerEvent('police:server:policeAlert', 'Weapon License Request')
                        elseif data.type == "interview" then
                            TriggerServerEvent('police:server:policeAlert', 'Interview Request')
                        elseif data.type == "supervisor" then
                            TriggerServerEvent('police:server:policeAlert', 'Supervisor Request')
                        end
                        TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                    else
                        QBCore.Functions.Notify('Not enough officers on duty!', 'error', 3000)
                    end
                elseif data.job == 'ambulance' then
                    if doctorCount >= Config.Locations[data.job].Required then
                        QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                        if data.type == "assistance" then
                            TriggerServerEvent('hospital:server:ambulanceAlert', 'Assitance Required')
                        elseif data.type == "interview" then
                            TriggerServerEvent('hospital:server:ambulanceAlert', 'Interview Request')
                        elseif data.type == "supervisor" then
                            TriggerServerEvent('hospital:server:ambulanceAlert', 'Supervisor Request')
                        end
                        TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                    else
                        QBCore.Functions.Notify('Not enough doctors on duty!', 'error', 3000)
                    end
                end
            elseif Config.Dispatch == "ps-dispatch" then
                local PlayerData = QBCore.Functions.GetPlayerData()
                local coords = GetEntityCoords(PlayerPedId())
                if data.job == 'police' then
                    if CurrentCops >= Config.Locations[data.job].Required then
                        QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                        if data.type == "assistance" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['police'].Zone.coords, job = { 'police' }, message = "Assitance Required", dispatchCode = "10-60", firstStreet = coords, name =  PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Assistance Required", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        elseif data.type == "weaponlicense" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['police'].Zone.coords, job = { 'police' }, message = "Weapon License Request", dispatchCode = "10-60", firstStreet = coords, name = PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Weapon License Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        elseif data.type == "interview" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['police'].Zone.coords, job = { 'police' }, message = "Interview Request", dispatchCode = "10-60", firstStreet = coords, name = PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Interview Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        elseif data.type == "supervisor" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['police'].Zone.coords, job = { 'police' }, message = "Supervisor Request", dispatchCode = "10-60", firstStreet = coords, name = PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Supervisor Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        end
                        TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                    else
                        QBCore.Functions.Notify('Not enough officers on duty!', 'error', 3000)
                    end
                elseif data.job == 'ambulance' then
                    if doctorCount >= Config.Locations[data.job].Required then
                        QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                        if data.type == "assistance" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['ambulance'].Zone.coords, job = { 'ambulance' }, message = "Assitance Required", dispatchCode = "10-60", firstStreet = coords, name =  PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Assistance Required", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        elseif data.type == "interview" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['ambulance'].Zone.coords, job = { 'ambulance' }, message = "Interview Request", dispatchCode = "10-60", firstStreet = coords, name = PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Interview Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        elseif data.type == "supervisor" then
                            exports["ps-dispatch"]:CustomAlert({ coords = Config.Locations['ambulance'].Zone.coords, job = { 'ambulance' }, message = "Supervisor Request", dispatchCode = "10-60", firstStreet = coords, name = PlayerData.charinfo.firstname:sub(1,1):upper()..PlayerData.charinfo.firstname:sub(2).. " ".. PlayerData.charinfo.lastname:sub(1,1):upper()..PlayerData.charinfo.lastname:sub(2), description = "Supervisor Request", radius = 0, sprite = 205, color = 2, scale = 1.0, length = 3, })
                        end
                        TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                    else
                        QBCore.Functions.Notify('Not enough doctors on duty!', 'error', 3000)
                    end
                end

            elseif Config.Dispatch == "cd_dispatch" then
                if data.job == 'police' then
                    if CurrentCops >= Config.Locations[data.job].Required then
                        QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                        if data.type == "assistance" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Assitance Required', message = 'Assitance Required at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Assitance Required', time = (5 * 60 * 1000), sound = 1, }, })
                        elseif data.type == "weaponlicense" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Weapon License Request', message = 'Weapon License Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Weapon License Request', time = (5 * 60 * 1000), sound = 1, }, })
                        elseif data.type == "interview" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Interview Request', message = 'Interview Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Interview Request', time = (5 * 60 * 1000), sound = 1, }, })
                        elseif data.type == "supervisor" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'police' }, coords = data.coords, title = '10-60 - Supervisor Request', message = 'Supervisor Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Supervisor Request', time = (5 * 60 * 1000), sound = 1, }, })
                        end
                        TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                    else
                        QBCore.Functions.Notify('Not enough officers on duty!', 'error', 3000)
                    end

                elseif data.job == 'ambulance' then
                    if doctorCount >= Config.Locations[data.job].Required then
                        QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                        if data.type == "assistance" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'ambulance' }, coords = data.coords, title = '10-60 - Assitance Required', message = 'Assitance Required at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Assitance Required', time = (5 * 60 * 1000), sound = 1, }, })
                        elseif data.type == "weaponlicense" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'ambulance' }, coords = data.coords, title = '10-60 - Weapon License Request', message = 'Weapon License Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Weapon License Request', time = (5 * 60 * 1000), sound = 1, }, })
                        elseif data.type == "interview" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'ambulance' }, coords = data.coords, title = '10-60 - Interview Request', message = 'Interview Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Interview Request', time = (5 * 60 * 1000), sound = 1, }, })
                        elseif data.type == "supervisor" then
                            local data = exports['cd_dispatch']:GetPlayerInfo()
                            TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'ambulance' }, coords = data.coords, title = '10-60 - Supervisor Request', message = 'Supervisor Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Supervisor Request', time = (5 * 60 * 1000), sound = 1, }, })
                        end
                        TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                    else
                        QBCore.Functions.Notify('Not enough doctors on duty!', 'error', 3000)
                    end
                end
                
                -- ADD MORE JOBS BELOW 
                -- DON'T FORGET TO ADD THEM TO YOUR CONFIG AS WELL

                -- elseif data.job == 'mechanic' then
                --     if doctorCount >= Config.Locations[data.job].Required then
                --         QBCore.Functions.Notify('You will be assisted shortly!', 'success')
                --         if data.type == "assistance" then
                --             local data = exports['cd_dispatch']:GetPlayerInfo()
                --             TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'mechanic' }, coords = data.coords, title = 'Assitance Required', message = 'Assitance Required at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Assitance Required', time = (5 * 60 * 1000), sound = 1, }, })
                --         elseif data.type == "weaponlicense" then
                --             local data = exports['cd_dispatch']:GetPlayerInfo()
                --             TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'mechanic' }, coords = data.coords, title = 'Upgrade' Request', message = 'Sucker at the front desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = 'Someone wanna go fast', time = (5 * 60 * 1000), sound = 1, }, })
                --         elseif data.type == "interview" then
                --             local data = exports['cd_dispatch']:GetPlayerInfo()
                --             TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'mechanic' }, coords = data.coords, title = '10-60 - Interview Request', message = 'Interview Request at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = '911 - Interview Request', time = (5 * 60 * 1000), sound = 1, }, })
                --         elseif data.type == "supervisor" then
                --             local data = exports['cd_dispatch']:GetPlayerInfo()
                --             TriggerServerEvent('cd_dispatch:AddNotification', { job_table = { 'mechanic' }, coords = data.coords, title = 'Karen Alert', message = 'Karen at the Front Desk', flash = 0, unique_id = tostring(math.random(0000000, 9999999)), blip = { sprite = 205, scale = 1.2, colour = 3, flashes = false, text = 'Supervisor Request', time = (5 * 60 * 1000), sound = 1, }, })
                --         end
                --         TriggerServerEvent('rs-frontdesk:server:AlertCooldown', data.job, true)
                --     else
                --         QBCore.Functions.Notify('Not enough doctors on duty!', 'error', 3000)
                --     end
                -- end
            end
        else
            QBCore.Functions.Notify('Alert was recently sent, please wait!', 'error', 7500)
        end
    end, data.job)
end)

RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)

RegisterNetEvent('hospital:client:SetDoctorCount', function(amount)
    doctorCount = amount
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	PlayerData = QBCore.Functions.GetPlayerData()
    PlayerJob = QBCore.Functions.GetPlayerData().job
	FrontDeskZones()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
	PlayerData = QBCore.Functions.GetPlayerData()
	PlayerJob = QBCore.Functions.GetPlayerData().job
        FrontDeskZones()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(Config.Locations) do
            exports['qb-target']:RemoveZone(v.Zone.name)
        end
    end
end)
