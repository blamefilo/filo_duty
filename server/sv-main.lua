lib.addCommand(Config.Command, {
    help = 'Open duty creator menu',
    restricted = Config.CommandPermissions
}, function(source, args, raw)
    TriggerClientEvent("filo_duty:client:openCreatorMenu", source)
end)

lib.callback.register("filo_duty:server:createDuty", function(source, data)
    local uuid = lib.string.random('aaa111AAA111')
    data.uuid = uuid
    Storage:add(data)

    TriggerClientEvent("filo_duty:client:refreshDutyZones", -1)
    return true
end)

lib.callback.register("filo_duty:server:deleteDuty", function(source, uuid)
    Storage:remove(uuid)
    TriggerClientEvent("filo_duty:client:refreshDutyZones", -1)
    return true
end)

lib.callback.register("filo_duty:server:getDutyZones", function(source, jobName)
    return Storage:get()
end)

RegisterNetEvent("filo_duty:server:toggleDuty", function(jobName, bool)
    local src = source
    local playerJob = Framework.GetPlayerJobData(src)

    if jobName == playerJob.jobName then
        Framework.SetPlayerDuty(src, bool)
        Notify.SendNotification(src, "Duty", bool and "You are now on duty." or "You are now off duty.", "success")
    else
        local jobName, jobGrade = PlayerHasJob(src, jobName)
        if jobName then
            Framework.SetPlayerJob(src, jobName, jobGrade)
            Framework.SetPlayerDuty(src, bool)
            Notify.SendNotification(src, "Duty",
                bool and "You are now on duty with " .. jobName .. "." or "You are now off duty.", "success")
        end
    end
end)

CreateThread(function()
    while not Storage do Wait(100) end
    Storage:initialize()
end)
