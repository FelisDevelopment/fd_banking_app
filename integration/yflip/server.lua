if not GetResourceState("yflip"):find('start') then return end

RegisterNetEvent('fd_banking:server:notification', function(text, type)
    local src = source

    exports.yseries:SendNotification({
        app = "fd_banking",
        title = "Banking",
        text = text,
        icon = ("https://cfx-nui-%s/web/dist/bank_app.png"):format(GetCurrentResourceName())
    }, 'source', src)
end)
