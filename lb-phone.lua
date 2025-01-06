local SendNUIMessage = SendNUIMessage
if not GetResourceState("lb-phone"):find('start') then return end


CreateThread(function()
    while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    while GetResourceState("fd_banking") ~= "started" do
        Wait(500)
    end

    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = "fd_banking",
        name = "Bank",
        description = "Banking right in your pocket.",
        developer = "Felis Development",
        defaultApp = true,
        size = 59812,
        fixBlur = true,
        icon = "nui://" .. GetCurrentResourceName() .. "/web/dist/bank_app.png",
        ui = GetCurrentResourceName() .. "/web/dist/index.html",
    })

    if not added then
        print("Could not add app:", errorMessage)
    end
end)

if IsDuplicityVersion() then
else
    AddEventHandler("fd_banking:client:notification", function(text, type)
        exports["lb-phone"]:SendNotification({
            app = "fd_banking",
            title = "Banking",
            content = text,
        })
    end)

    function SendData(data)
        exports["lb-phone"]:SendCustomAppMessage("fd_banking", data)
    end
end
