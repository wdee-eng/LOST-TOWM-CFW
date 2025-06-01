    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    loadData()
    Wait(2000)
    DisplayRadar(true);
    first();
    loadmap('square');
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    current.hideHud = true
    Utils.SendNUiMessage('closeUI')
    DisplayRadar(false)
end)

AddEventHandler("onResourceStart", function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(500)
    loadData()
end)
