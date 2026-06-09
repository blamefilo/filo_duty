function PlayerHasJob(source, job)
    if GetResourceState("qbx_core") == "started" then
        local groups = exports.qbx_core:GetGroups(source)
        for jobName, grade in pairs(groups) do
            if jobName == job then
                return jobName, grade
            end
        end
    end
    return false
end