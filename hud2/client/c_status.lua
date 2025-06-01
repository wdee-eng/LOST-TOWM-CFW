local QBCore = exports['qb-core']:GetCoreObject()
local isRunning = false
local isSprinting = false
local hungerInterval = 12000  -- Changed from 6 to 12 seconds
local thirstInterval = 10000  -- Changed from 5 to 10 seconds
local staminaInterval = 2000 -- Changed from 1 to 2 seconds

-- Initialize status values
local status = {
    hunger = 100,
    thirst = 100,
    stress = 0,
    stamina = 100,
    oxygen = 100
}

-- Cache for last sent values to prevent unnecessary updates
local lastSentValues = {
    hunger = 100,
    thirst = 100,
    stress = 0,
    stamina = 100,
    oxygen = 100
}

-- Function to update status on HUD
local function updateHUDStatus()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        -- Update status from metadata
        local shouldUpdate = false
        
        -- Only update if values have changed significantly (more than 1%)
        if math.abs((PlayerData.metadata.hunger or status.hunger) - status.hunger) > 1 then
            status.hunger = PlayerData.metadata.hunger or status.hunger
            shouldUpdate = true
        end
        if math.abs((PlayerData.metadata.thirst or status.thirst) - status.thirst) > 1 then
            status.thirst = PlayerData.metadata.thirst or status.thirst
            shouldUpdate = true
        end
        if math.abs((PlayerData.metadata.stress or status.stress) - status.stress) > 1 then
            status.stress = PlayerData.metadata.stress or status.stress
            shouldUpdate = true
        end
        if math.abs((PlayerData.metadata.stamina or status.stamina) - status.stamina) > 1 then
            status.stamina = PlayerData.metadata.stamina or status.stamina
            shouldUpdate = true
        end
        
        if shouldUpdate then
            for statName, value in pairs(status) do
                if math.abs(value - (lastSentValues[statName] or 0)) > 1 then
                    for i = 1, #Utils.rt_config.Hud do
                        if Utils.rt_config.Hud[i].name == statName then
                            Utils.rt_config.Hud[i].value = value
                            -- Add warning effects for low values
                            if value <= 15 and (statName == 'hunger' or statName == 'thirst') then
                                Utils.rt_config.Hud[i].startShaking = true
                                Utils.rt_config.Hud[i].startRed = true
                            else
                                Utils.rt_config.Hud[i].startShaking = false
                                Utils.rt_config.Hud[i].startRed = false
                            end
                            lastSentValues[statName] = value
                        end
                    end
                end
            end
        end
    end
end

-- Running and Stamina Management
CreateThread(function()
    local lastStaminaUpdate = 0
    local lastStressUpdate = 0
    
    while true do
        Wait(staminaInterval)
        local ped = PlayerPedId()
        local PlayerData = QBCore.Functions.GetPlayerData()
        
        if IsPedSprinting(ped) and not IsPedInAnyVehicle(ped, true) then
            isSprinting = true
            -- Decrease stamina while sprinting
            if PlayerData and PlayerData.metadata then
                local newStamina = math.max(0, (PlayerData.metadata.stamina or 100) - 2)
                -- Only update if stamina changed by more than 5%
                if math.abs(newStamina - lastStaminaUpdate) > 5 then
                    status.stamina = newStamina
                    lastStaminaUpdate = newStamina
                    -- Update server less frequently
                    TriggerServerEvent('Vf1Hud:server:UpdatePlayerState', {
                        type = 'stamina',
                        value = newStamina
                    })
                end
            end
            
            -- Apply effects when stamina is low
            if status.stamina < 20 then
                SetPedMoveRateOverride(ped, 0.8)
                -- Increase stress when exhausted, but less frequently
                if PlayerData and PlayerData.metadata then
                    local newStress = math.min(100, (PlayerData.metadata.stress or 0) + 0.5)
                    if math.abs(newStress - lastStressUpdate) > 5 then
                        status.stress = newStress
                        lastStressUpdate = newStress
                    end
                end
            end
        else
            isSprinting = false
            -- Regenerate stamina when not sprinting
            if PlayerData and PlayerData.metadata then
                local newStamina = math.min(100, (PlayerData.metadata.stamina or 100) + 1)
                -- Only update if stamina changed by more than 5%
                if math.abs(newStamina - lastStaminaUpdate) > 5 then
                    status.stamina = newStamina
                    lastStaminaUpdate = newStamina
                    -- Update server less frequently
                    TriggerServerEvent('Vf1Hud:server:UpdatePlayerState', {
                        type = 'stamina',
                        value = newStamina
                    })
                end
            end
            SetPedMoveRateOverride(ped, 1.0)
        end
        
        -- Only update HUD when needed
        if math.abs(status.stamina - lastStaminaUpdate) > 5 then
            updateHUDStatus()
        end
    end
end)

-- Hunger and Thirst Management
CreateThread(function()
    while true do
        Wait(hungerInterval)
        local PlayerData = QBCore.Functions.GetPlayerData()
        
        if PlayerData and PlayerData.metadata then
            -- Decrease hunger over time
            status.hunger = math.max(0, (PlayerData.metadata.hunger or status.hunger) - 0.3)
            if status.hunger <= 0 then
                -- Apply damage when starving
                local ped = PlayerPedId()
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, health - 1)
            end
            
            Wait(thirstInterval)
            -- Decrease thirst over time
            status.thirst = math.max(0, (PlayerData.metadata.thirst or status.thirst) - 0.4)
            if status.thirst <= 0 then
                -- Apply damage when dehydrated
                local ped = PlayerPedId()
                local health = GetEntityHealth(ped)
                SetEntityHealth(ped, health - 1)
            end
            
            -- Update metadata
            TriggerServerEvent('Vf1Hud:server:UpdateMetadata', 'hunger', status.hunger)
            TriggerServerEvent('Vf1Hud:server:UpdateMetadata', 'thirst', status.thirst)
            
            updateHUDStatus()
        end
        Wait(1000) -- Add a small wait if player data isn't ready
    end
end)

-- Stress Management
CreateThread(function()
    while true do
        Wait(10000) -- Check every 10 seconds
        local ped = PlayerPedId()
        local PlayerData = QBCore.Functions.GetPlayerData()
        
        -- Increase stress in various situations
        if IsPedInMeleeCombat(ped) then
            if PlayerData and PlayerData.metadata then
                status.stress = math.min(100, (PlayerData.metadata.stress or 0) + 2)
            end
        elseif IsPedShooting(ped) then
            if PlayerData and PlayerData.metadata then
                status.stress = math.min(100, (PlayerData.metadata.stress or 0) + 1)
            end
        elseif not isSprinting and not IsPedInAnyVehicle(ped, true) then
            -- Decrease stress when calm
            if PlayerData and PlayerData.metadata then
                status.stress = math.max(0, (PlayerData.metadata.stress or 0) - 0.5)
            end
        end
        
        -- Apply stress effects
        if status.stress > 80 then
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
        end
        
        -- Update stress in metadata
        TriggerServerEvent('Vf1Hud:server:UpdatePlayerState', {
            type = 'stress',
            value = status.stress
        })
        
        updateHUDStatus()
    end
end)

-- Events for consuming items
RegisterNetEvent('Vf1Hud:client:EatFood', function(amount)
    status.hunger = math.min(100, status.hunger + amount)
    updateHUDStatus()
end)

RegisterNetEvent('Vf1Hud:client:Drink', function(amount)
    status.thirst = math.min(100, status.thirst + amount)
    updateHUDStatus()
end)

-- Event for stress relief
RegisterNetEvent('Vf1Hud:client:RelieveStress', function(amount)
    status.stress = math.max(0, status.stress - amount)
    updateHUDStatus()
end)

-- Export functions for other resources to use
exports('getStatus', function(statusType)
    return status[statusType]
end)

-- Initialize player data when ready
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata then
        status.hunger = PlayerData.metadata.hunger or 100
        status.thirst = PlayerData.metadata.thirst or 100
        status.stress = PlayerData.metadata.stress or 0
        status.stamina = PlayerData.metadata.stamina or 100
    end
    updateHUDStatus()
end)

-- Sync status with server periodically
CreateThread(function()
    while true do
        Wait(5000) -- Sync every 5 seconds
        TriggerServerEvent('Vf1Hud:server:SyncData')
    end
end)
