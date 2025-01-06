if not GetResourceState("yseries"):find('start') then return end
lib.checkDependency('yseries', '0.99.5', true)

local function AddApp()
    local dataLoaded = exports.yseries:GetDataLoaded()
    while not dataLoaded do
        Wait(1000)
        dataLoaded = exports.yseries:GetDataLoaded()
    end

    local added, errorMessage = exports.yseries:AddCustomApp({
        key = "fd_banking",
        name = "Banking",
        defaultApp = true,
        icon = {
            yos = ("https://cfx-nui-%s/web/dist/bank_app.png"):format(GetCurrentResourceName()),
            humanoid = ("https://cfx-nui-%s/web/dist/bank_app.png"):format(GetCurrentResourceName()),
        },
        ui = ("https://cfx-nui-%s/web/dist/index.html"):format(GetCurrentResourceName()),
    })

    if not added then
        lib.print.debug('Could not add app:', errorMessage)
        return
    end

    lib.print.debug('Banking app added.')
end

CreateThread(function()
    while GetResourceState("yseries") ~= "started" do
        Wait(500)
    end

    while GetResourceState("fd_banking") ~= "started" do
        Wait(500)
    end

    AddApp()
end)


AddEventHandler("fd_banking:client:notification", function(text, type)
    TriggerServerEvent("fd_banking:server:notification", text, type)
end)

function SendData(data)
    exports.yseries:SendAppMessage('fd_banking', data)
end
