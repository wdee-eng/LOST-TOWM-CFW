local seatbeltOn = false
local seatbeltState = false
local harnessOn = false
local newvehicleBodyHealth = 0
local currentvehicleBodyHealth = 0
local frameBodyChange = 0
local lastFrameVehiclespeed = 0
local lastFrameVehiclespeed2 = 0
local thisFrameVehicleSpeed = 0
local tick = 0
local damagedone = false
local modifierDensity = true

-- Main thread for seatbelt functionality
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped)

        if inVehicle then
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= nil and vehicle ~= false and vehicle ~= 0 then
                local vehicleClass = GetVehicleClass(vehicle)
                -- Exclude bikes, bicycles, etc.
                if vehicleClass ~= 8 and vehicleClass ~= 13 and vehicleClass ~= 14 then
                    -- Speed calculations
                    local speed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                    if not seatbeltOn and not harnessOn then
                        -- Eject player if crash detected
                        if speed > 40.0 then
                            thisFrameVehicleSpeed = GetEntitySpeed(vehicle) * 3.6
                            currentvehicleBodyHealth = GetVehicleBodyHealth(vehicle)
                            if currentvehicleBodyHealth ~= newvehicleBodyHealth then
                                if not damagedone then
                                    frameBodyChange = newvehicleBodyHealth - currentvehicleBodyHealth
                                    if frameBodyChange > 18.0 then
                                        if not seatbeltOn then
                                            EjectFromVehicle(vehicle, speed)
                                        end
                                    end
                                    damagedone = true
                                    SetTimeout(1000, function()
                                        damagedone = false
                                    end)
                                end
                            end
                            newvehicleBodyHealth = currentvehicleBodyHealth
                        end
                    end
                end
            end
        end
    end
end)

-- Function to handle ejection from vehicle
function EjectFromVehicle(vehicle, speed)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    SetEntityCoords(ped, pos.x, pos.y, pos.z - 0.5, true, true, true)
    SetEntityVelocity(ped, lastFrameVehiclespeed2.x, lastFrameVehiclespeed2.y, lastFrameVehiclespeed2.z)
    SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
    
    -- Damage player based on speed
    local damage = math.min(speed * 1.5, 100)
    SetEntityHealth(ped, GetEntityHealth(ped) - damage)
    
    -- Notify player
    TriggerEvent('Rc2-Hud:client:ShowNotification', 'You were ejected from the vehicle!')
end

-- Toggle seatbelt
RegisterCommand('toggleseatbelt', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped) then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehicleClass = GetVehicleClass(vehicle)
        
        if vehicleClass ~= 8 and vehicleClass ~= 13 and vehicleClass ~= 14 then
            seatbeltOn = not seatbeltOn
            TriggerEvent('Rc2-Hud:client:ToggleSeatbelt', seatbeltOn)
            
            if seatbeltOn then
                TriggerEvent('Rc2-Hud:client:ShowNotification', 'Seatbelt: ON')
                PlaySoundFrontend(-1, "Faster_Click", "RESPAWN_ONLINE_SOUNDSET", 1)
            else
                TriggerEvent('Rc2-Hud:client:ShowNotification', 'Seatbelt: OFF')
                PlaySoundFrontend(-1, "Faster_Click", "RESPAWN_ONLINE_SOUNDSET", 1)
            end
        end
    end
end)

-- Register key mapping for seatbelt
RegisterKeyMapping('toggleseatbelt', 'Toggle Seatbelt', 'keyboard', 'B')

-- Export seatbelt state
exports('getSeatbeltState', function()
    return seatbeltOn
end)
