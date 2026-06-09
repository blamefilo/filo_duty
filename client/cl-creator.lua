local isCreating = false

RegisterNetEvent("filo_duty:client:openCreatorMenu", function()
    if isCreating then return end
    local dutyZones = lib.callback.await("filo_duty:server:getDutyZones", false)
    local options = {}
    for _, zone in ipairs(dutyZones) do
        table.insert(options, {
            title = zone.name,
            icon = 'fas fa-map-marker-alt',
            description = "Job: " .. zone.jobLabel .. " | Interaction Type: " .. zone.interactionType,
            arrow = true,
            onSelect = function()
                local childOptions = {
                    {
                        title = 'Delete Zone',
                        icon = 'fas fa-trash',
                        description = 'Delete this duty zone',
                        onSelect = function()
                            lib.callback.await("filo_duty:server:deleteDuty", false, zone.uuid)
                            TriggerEvent("filo_duty:client:openCreatorMenu")
                        end
                    },
                    {
                        title = 'Teleport to Zone',
                        icon = 'fas fa-location-dot',
                        description = 'Teleport to this duty zone',
                        onSelect = function()
                            RequestCollisionAtCoord(zone.coords.x, zone.coords.y, zone.coords.z)
                            SetEntityCoords(cache.ped, zone.coords.x, zone.coords.y, zone.coords.z)
                            FreezeEntityPosition(cache.ped, true)
                            while not HasCollisionLoadedAroundEntity(cache.ped) do
                                Wait(0)
                            end
                            FreezeEntityPosition(cache.ped, false)
                        end
                    }
                }
                lib.registerContext({
                    id = 'duty_zone_' .. zone.uuid,
                    title = zone.name,
                    options = childOptions
                })
                lib.showContext('duty_zone_' .. zone.uuid)
            end
        })
    end

    options[#options + 1] = {
        title = 'Create New Duty Zone',
        icon = 'fas fa-plus',
        description = 'Create a new duty zone',
        arrow = true,
        onSelect = function()
            TriggerEvent("filo_duty:client:createDuty")
        end
    }

    lib.registerContext({
        id = 'duty_creator',
        title = 'Duty Creator',
        options = options
    })
    lib.showContext('duty_creator')
end)

RegisterNetEvent("filo_duty:client:createDuty", function()
    if isCreating then return end
    isCreating = true

    local jobs = Framework.GetFrameworkJobs()
    local jobOptions = {}
    for jobName, jobData in pairs(jobs) do
        if jobName == 'unemployed' then
            goto continue
        end
        table.insert(jobOptions, {
            label = jobData.label,
            value = jobName
        })
        ::continue::
    end
    local input = lib.inputDialog('Create Duty', {
        {
            type = 'input',
            label = 'Name',
            description = 'Enter a name for this duty zone',
            required = true
        },
        {
            type = 'select',
            label = 'Job',
            options = jobOptions,
            required = true
        },
        {
            type = 'select',
            label = 'Interaction Type',
            options = {
                { label = 'Target', value = 'target' },
                { label = 'Marker', value = 'marker' }
            },
            required = true,
            default = 'target'
        }
    })
    if not input then
        isCreating = false
        return
    end
    local name = input[1]
    local job = input[2]
    local interactionType = input[3]

    local coords = nil

    if interactionType == 'target' then
        coords = StartTargetCreation()
    else
        coords = StartMarkerCreation()
    end

    if not coords then isCreating = false return end

    local result = lib.callback.await("filo_duty:server:createDuty", false, {
        coords = coords,
        job = job,
        jobLabel = jobs[job].label,
        interactionType = interactionType,
        name = name
    })
    if result then
        lib.notify({ title = "Duty Creator", description = "Duty created successfully", type = "success" })
    else
        lib.notify({ title = "Duty Creator", description = "Failed to create duty", type = "error" })
    end

    isCreating = false
end)

function StartTargetCreation()
    local coords = nil

    lib.requestModel(`prop_tennis_ball`)
    local pedPos = GetEntityCoords(cache.ped)
    local ball = CreateObject(`prop_tennis_ball`, pedPos, false, false, false)
    FreezeEntityPosition(ball, true)
    SetEntityCollision(ball, false, false)
    SetEntityAlpha(ball, 150)
    SetEntityDrawOutline(ball, true)
    SetEntityDrawOutlineColor(255, 0, 0, 255)

    while coords == nil do
        pedPos = GetEntityCoords(cache.ped)
        local hit, _, endCoords = lib.raycast.fromCamera()
        if hit and hit == 1 then
            SetEntityCoords(ball, endCoords)
            if IsControlJustReleased(2, 38) then
                coords = endCoords
            end
        end

        DrawLine(pedPos.x, pedPos.y, pedPos.z, endCoords.x, endCoords.y, endCoords.z, 255, 0, 0, 255)
        if IsControlJustReleased(2, 73) then break end
    end

    SetModelAsNoLongerNeeded(`prop_tennis_ball`)
    DeleteEntity(ball)

    if coords == nil then return end
    return coords
end

function StartMarkerCreation()
    local coords = nil
    local pedPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.5, 0.0)
    local markerData = Config.Marker
    markerData.coords = pedPos
    local marker = lib.marker.new(markerData)

    while coords == nil do
        marker:draw()
        pedPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.5, 0.0)
        marker.coords = pedPos
        if IsControlJustReleased(2, 38) then
            coords = pedPos
        end

        if IsControlJustReleased(2, 73) then break end
        Wait(0)
    end

    return coords
end