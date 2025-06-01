local radio, vehicleNitro = false, 0
mathfloor, mathrandom, mathceil, mathround = math.floor, math.random, math.ceil, math.round
current = {
    initialized = false,
    inVehicle = false,
    hideHud = false,
    settings = {
        modules = {},
        colors = {}
    }
}

AddEventHandler("pma-voice:radioActive", function(value)
    radio = value
end)

function loadData()
    current.hideHud = false
    initialize()
    DisplayRadar(true);
    first();
    loadmap('square');
    Wait(2000)
    DisplayRadar(true);
    first();
    loadmap('square');
end

initialize = function()
    Citizen.CreateThread(function()
        SetTextChatEnabled(false)
        SetNuiFocus(false)
        while true do
            if not IsPauseMenuActive() and not current.hideHud then
                local pPed = PlayerPedId()
                local pWeapon = GetSelectedPedWeapon(PlayerPedId())
                local ped = GetPlayerPed(PlayerId())
                local x, y, z = table.unpack(GetEntityCoords(ped, true))
                local street = GetStreetNameAtCoord(x, y, z)
                local zone = tostring(GetNameOfZone(x, y, z))
                local location = Utils.rt_config.zoneNames[tostring(zone)]
                local street1 = Utils.rt_config.streetNames[GetStreetNameFromHashKey(street)]

                -- print(location, location2)
                for i = 1, #Utils.rt_config.Hud do
                    local tempStatus = Utils.rt_config.Hud[i]
                    if tempStatus.name == 'mic' or tempStatus.name == 'radio' then
                        local voiceState = Utils.getVoiceState()
                        if voiceState.talking then
                            Utils.rt_config.Hud[i].isTalking = 'normal'
                            Utils.rt_config.Hud[i].name = radio and 'radio' or 'mic'
                            if LocalPlayer.state['proximity'] then
                                -- Utils.rt_config.Hud[i].value = LocalPlayer.state['proximity'].distance == 1.5 and 30 or LocalPlayer.state['proximity'].distance == 3.0 and 65 or LocalPlayer.state['proximity'].distance == 6.0 and 100
                                Utils.rt_config.Hud[i].value = LocalPlayer.state['proximity'].distance == 1.5 and 30 or
                                    LocalPlayer.state['proximity'].distance == 3.0 and 65 or
                                    LocalPlayer.state['proximity'].distance >= 6.0 and 100
                            else
                                Utils.rt_config.Hud[i].value = 0
                            end
                        else
                            Utils.rt_config.Hud[i].isTalking = 'none'
                            Utils.rt_config.Hud[i].name = radio and 'radio' or 'mic'
                            if LocalPlayer.state['proximity'] and LocalPlayer.state['proximity'].distance then
                                Utils.rt_config.Hud[i].value = LocalPlayer.state['proximity'].distance == 1.5 and 30 or LocalPlayer.state['proximity'].distance == 3.0 and 65 or LocalPlayer.state['proximity'].distance >= 6.0 and 100
                            else
                                Utils.rt_config.Hud[i].value = 0
                            end
                        end
                    else
                        -- print(tempStatus.useValue, 'tempStatus.useValue', Utils.rt_config.Hud[i].name)
                        if tempStatus.useValue then
                            Utils.rt_config.Hud[i].value = tempStatus.value
                        else
                            local statusValue, stamina = Utils.getStatus(tempStatus.name)
                            if type(statusValue) == "number" then
                                if tempStatus.name == 'health' or tempStatus.name == 'hunger' or tempStatus.name == 'thirst' then
                                    if math.floor(statusValue) > 0 and math.floor(statusValue) <= 15 then
                                        Utils.rt_config.Hud[i].startShaking = true
                                        Utils.rt_config.Hud[i].startRed = true
                                    else
                                        Utils.rt_config.Hud[i].startShaking = false
                                        Utils.rt_config.Hud[i].startRed = false
                                    end
                                end

                                if tempStatus.name == 'stamina' and stamina then
                                    Utils.rt_config.Hud[i].startPurple = true
                                elseif not stamina then
                                    Utils.rt_config.Hud[i].startPurple = false
                                end

                                Utils.rt_config.Hud[i].startPurple = Utils.rt_config.Hud[i].startPurple or false
                                Utils.rt_config.Hud[i].value = math.floor(statusValue)
                            else
                                Utils.rt_config.Hud[i].value = 100
                            end
                        end
                    end
                end

                -- if pWeapon and pWeapon ~= `weapon_unarmed` and wd.weapons[pWeapon] then
                --     local _, tempCurrentAmmo = GetAmmoInClip(pPed, pWeapon)
                --     SendReactMessage('setWeapon', {
                --         current = tempCurrentAmmo,
                --         total = (GetAmmoInPedWeapon(pPed, pWeapon) - tempCurrentAmmo),
                --         name = wd.weapons[pWeapon]:upper() or 'WEAPON_ASSAULTRIFLE'
                --     })
                -- else
                --     SendReactMessage('setWeapon', {})
                -- end

                -- print(json.encode(Utils.rt_config.Hud))
                -- print(IsRadarHidden(), not IsRadarHidden(), 'IsRadarHidden()')
                Utils.SendNUiMessage('changeStatus', Utils.rt_config.Hud, street1 or '', location or '',
                    Utils.getMinimapPosition().pixel.top_y)
            else
                Utils.SendNUiMessage('closeUI')
            end
            Wait(Utils.rt_config.updateInterval)
        end
    end)
end

RegisterNetEvent('Rc2-Hud:client:hudCloseUI', function()
    current.hideHud = true
    Utils.SendNUiMessage('closeUI')
    DisplayRadar(false)
end)

RegisterNetEvent('Rc2-Hud:client:hudShowUI', function()
    current.hideHud = false
    DisplayRadar(true)
end)

RegisterNetEvent('Rc2-Hud:client:addNewElement', function(data)
    local exists = false
    for key, value in pairs(Utils.rt_config.Hud) do
        if value.name == data.name then
            Utils.rt_config.Hud[key] = {
                name = data.name,
                value = data.value,
                startShaking = data.startShaking,
                startGolden = data.startGolden,
                startRed = data.startRed,
                startPurple = data.startPurple,
                useValue = data.useValue or false,
                isVisible = true,
            }
            exists = true
            break
        end
    end

    if not exists then
        table.insert(Utils.rt_config.Hud, data)
    end
end)

RegisterNetEvent('Rc2-Hud:client:removeNewElement', function(id)
    for key, value in pairs(Utils.rt_config.Hud) do
        if value.name == id then
            value.isVisible = false
            Wait(1000)
            table.remove(Utils.rt_config.Hud, key)
            return
        end
    end
end)

RegisterCommand('HudCloseUI', function(source, args)
    current.hideHud = true
    Utils.SendNUiMessage('closeUI')
    DisplayRadar(false)
end)

RegisterCommand('RadarCloseUI', function(source, args)
    DisplayRadar(false)
end)

RegisterCommand('HudShowUI', function(source, args)
    current.hideHud = false
    DisplayRadar(true)
end)

-- RegisterCommand('loc', function(source, args)
--     local ped = GetPlayerPed(PlayerId())
--     local x, y, z = table.unpack(GetEntityCoords(ped, true))
--     local street = GetStreetNameAtCoord(x, y, z)
--     local zone = tostring(GetNameOfZone(x, y, z))
--     local location = Utils.rt_config.zoneNames[tostring(zone)]
--     local street1 = Utils.rt_config.streetNames[GetStreetNameFromHashKey(street)]

--     print(street1, location, GetStreetNameFromHashKey(street))
-- end)
