Utils = {}

Utils.getMinimapPosition = function()
    local safezone = GetSafeZoneSize()
    local safezone_x = 1.0 / 20.0
    local safezone_y = 1.0 / 20.0
    local aspect_ratio = GetAspectRatio(false)
    -- local res_x, res_y = GetActiveScreenResolution()
    -- print(GetActiveScreenResolution(), 'GetActiveScreenResolution()', res_x, res_y, aspect_ratio)
    local res_x, res_y = 1920, 1080
    local xscale = 1.0 / res_x
    local yscale = 1.0 / res_y
    local scaleData = {}
    local pixelData = {}

    scaleData.width = xscale * (res_x / (4 * aspect_ratio))
    scaleData.height = yscale * (res_y / 5.674)
    scaleData.left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)))
    scaleData.bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)))
    scaleData.right_x = scaleData.left_x + scaleData.width
    scaleData.top_y = scaleData.bottom_y - scaleData.height
    scaleData.x = scaleData.left_x
    scaleData.y = scaleData.top_y
    scaleData.xunit = xscale
    scaleData.yunit = yscale

    pixelData.width = res_x * scaleData.width
    pixelData.height = res_y * scaleData.height
    pixelData.left_x = res_x * scaleData.left_x
    pixelData.bottom_y = res_y * scaleData.bottom_y
    pixelData.right_x = res_x * scaleData.right_x
    pixelData.top_y = not IsRadarHidden() and res_y * scaleData.top_y or 1070
    pixelData.x = res_x * scaleData.x
    pixelData.y = res_y * scaleData.y
    pixelData.xunit = res_x * scaleData.xunit
    pixelData.yunit = res_y * scaleData.yunit

    return { scale = scaleData, pixel = pixelData }
end

Utils.SendNUiMessage = function(action, data, st, st2, position)
    if st then
        SendNUIMessage(json.encode({
            type = action,
            data = data and data or nil,
            st = st,
            st2 = st2,
            position = position
        }))
        return
    end
    SendNUIMessage(json.encode({
        type = action,
        data = data and data or nil,
    }))
end

Utils.getVoiceState = function()
    if GetResourceState('pma-voice') == 'started' then
        return { talking = NetworkIsPlayerTalking(PlayerId()), range = LocalPlayer.state['proximity']?.distance or 0 }
    end

    return { talking = NetworkIsPlayerTalking(PlayerId()), range = 1.5 }
end

Utils.getStatus = function(statIndex)
    local pPed = PlayerPedId()
    local pId = PlayerId()
    local PlayerData = QBCore.Functions.GetPlayerData()

    if statIndex == 'health' then
        return GetEntityHealth(pPed) > 0 and (GetEntityHealth(pPed) - 100) or 0
    elseif statIndex == 'armor' then
        return GetPedArmour(pPed)
    elseif statIndex == 'stamina' then
        local staminaValue = PlayerData.metadata.stamina or 100
        return 100 - GetPlayerSprintStaminaRemaining(pId), IsPedSprinting(pPed) and staminaValue > 0
    elseif statIndex == 'oxygen' then
        if IsPedSwimmingUnderWater(pPed) then
            return GetPlayerUnderwaterTimeRemaining(pId) * 10
        end
    else
        return PlayerData.metadata[statIndex]
    end
end

Utils.getFuel = function(vehicle)
    if GetResourceState('LegacyFuel') == 'started' then
        return exports.LegacyFuel:GetFuel(vehicle)
    end
    if GetResourceState('Rc2-Fuel') == 'started' then
        return exports['Rc2-Fuel']:GetFuel(vehicle)
    end
    if GetResourceState('ox_fuel') == 'started' then
        return Entity(vehicle).state.fuel
    end
end

Utils.registerKeyMap = function(data, cb, cb2)
    RegisterCommand('+rt_' .. data.command, function()
        local response = true
        if not (data.useWhileFrontendMenu and data.useWhileFrontendMenu or false) and IsPauseMenuActive() then response = false end
        if not (data.useWhileNuiFocus and data.useWhileNuiFocus or false) and IsNuiFocused() then response = false end
        if cb and type(cb) == 'function' then cb(response) end
    end)
    RegisterCommand('-rt_' .. data.command, function()
        if cb2 and type(cb2) == 'function' then cb2() end
    end)
    if data.key:match('mouse') or data.key:match('iom') then
        RegisterKeyMapping('+rt_' .. data.command, data.description, 'mouse_button', data.key:lower())
    else
        RegisterKeyMapping('+rt_' .. data.command, data.description, 'keyboard', data.key:lower())
    end

    Wait(500)
    TriggerEvent('chat:removeSuggestion', ('/+rt_%s'):format(data.command))
    TriggerEvent('chat:removeSuggestion', ('/-rt_%s'):format(data.command))
end

Utils.rt_config = Load('config')
