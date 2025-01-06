local userAccounts = {}

RegisterNetEvent('fd_banking:client:fetchAccounts', function(accounts)
    userAccounts = accounts

    SendData({
        action = 'bank:setAccounts',
        data = {
            accounts = accounts
        }
    })
end)

RegisterNetEvent("fd_banking:client:fetchAccount", function(account)
    SendData({
        action = 'bank:setAccount',
        data = {
            account = account
        }
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

    TriggerEvent("fd_banking:client:notification", description, "info")
end)
