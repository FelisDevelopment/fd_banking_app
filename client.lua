local userAccounts = {}

CreateThread(function()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    while GetResourceState("fd_banking") ~= "started" do
        Wait(500)
    end

    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = "fd_banking",
        name = "Bankas",
        description = "El. Bankininkystė jūsų kišenėje",
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
    userAccounts = accounts

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

local function findAccount(account_id)
    for _, account in pairs(userAccounts) do
        if account.id == account_id then
            return account
        end
    end

    return nil
end

RegisterNetEvent('fd_advanced_banking:client:account:action', function(account_id, action, amount, reason)
    local title, description = 'Banking', nil
    local account = findAccount(account_id)

    if not account then return end
    if action == 'transferin' or action == 'deposit' then
        description = ('Account %s received $%s.'):format(account.iban, amount)
    end

    if action == 'transferout' or action == 'withdraw' then
        description = ('$%s was transfered from account %s.'):format(amount, account.iban)
    end

    if not title or not description then
        return
    end

    exports["lb-phone"]:SendNotification({
        app = "fd_banking",
        title = title,
        content = description,
    })
end)
