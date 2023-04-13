CreateThread(function ()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    while GetResourceState("fd_banking") ~= "started" do
        Wait(500)
    end

    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = "fd_banking",
        name = "Bank",
        description = "Banking in your phone",
        developer = "Felis Development",
        defaultApp = true,
        size = 59812,
        icon = "nui://" .. GetCurrentResourceName() .. "/web/dist/bank_app.png",
        ui = GetCurrentResourceName() .. "/web/dist/index.html",
    })

    if not added then
        print("Could not add app:", errorMessage)
    end
end)

RegisterNetEvent('fd_banking:client:fetchAccounts', function(accounts)
    exports["lb-phone"]:SendCustomAppMessage("fd_banking", {
        action = 'bank:setAccounts',
        data = {
            accounts = accounts
        }
    })
end)

RegisterNetEvent("fd_banking:client:fetchAccount", function(account)
    exports["lb-phone"]:SendCustomAppMessage("fd_banking", {
        action = 'bank:setAccount',
        data = {
            account = account
        }
    })
end)

RegisterNetEvent("lb-phone:settingsUpdated", function(settings)
    SendNUIMessage({
        type = "settingsUpdated",
        settings = settings
    })
end)
