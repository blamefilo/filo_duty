local togglingDuty = false
local zones = {}
local zone = {}
zone.__index = zone

function ToggleDuty(jobName, bool)
    if togglingDuty then return end
    togglingDuty = true
    TriggerServerEvent('filo_duty:server:toggleDuty', jobName, bool)
    togglingDuty = false
end

function zone:create(data)
    if zones[data.uuid] then
        DebugPrint('Zone already exists:', data.uuid)
        return
    end
    local self = setmetatable({}, zone)
    local interactionType = data.interactionType or 'marker'

    self.job = data.job
    self.jobLabel = data.jobLabel
    self.uuid = data.uuid

    if interactionType == 'marker' then
        local markerData = Config.Marker
        local drawingText = false
        markerData.coords = vec3(data.coords.x, data.coords.y, data.coords.z)
        self.marker = lib.marker.new(markerData)
        self.point = lib.points.new({
            coords = vec3(data.coords.x, data.coords.y, data.coords.z),
            distance = 10.0,
            nearby = function(point)
                self.marker:draw()
                if point.currentDistance < 1.0 then
                    local jobData = Framework.GetPlayerJobData()
                    local jobName = PlayerHasJob(self.job)

                    if not drawingText then
                        drawingText = true
                        local textLabel = jobData.onDuty and "Go Off Duty (" .. (self.jobLabel or self.job) .. ")" or "Go On Duty (" .. (self.jobLabel or self.job) .. ")"

                        if jobData.jobName ~= self.job and jobName then
                            textLabel = "Go On Duty (" .. (self.jobLabel or self.job) .. ")"
                        end

                        exports.filo_textui:DrawText({
                            { key = "E", label = textLabel }
                        })
                    end

                    if IsControlJustPressed(0, 38) then
                        if not jobName then
                            ToggleDuty(self.job, not jobData.onDuty)
                        else
                            ToggleDuty(self.job, true)
                        end
                    end
                else
                    if drawingText then
                        exports.filo_textui:HideText()
                        drawingText = false
                    end
                end
            end
        })
    elseif interactionType == 'target' then
        self.target = true
        exports.ox_target:addSphereZone({
            name = 'filo_duty_' .. data.uuid,
            coords = vec3(data.coords.x, data.coords.y, data.coords.z),
            radius = 0.25,
            debug = Config.Debug,
            drawSprite = false,
            options = {
                {
                    distance = 2.5,
                    icon = 'fa-solid fa-sign-in-alt',
                    label = 'Go On Duty (' .. (self.jobLabel or self.job) .. ')',
                    canInteract = function()
                        local jobData = Framework.GetPlayerJobData()
                        return (jobData.jobName == self.job and not jobData.onDuty) or (jobData.jobName ~= self.job and PlayerHasJob(self.job))
                    end,
                    onSelect = function()
                        ToggleDuty(self.job, true)
                    end
                },
                {
                    distance = 2.5,
                    icon = 'fa-solid fa-sign-out-alt',
                    label = 'Go Off Duty (' .. (self.jobLabel or self.job) .. ')',
                    canInteract = function()
                        local jobData = Framework.GetPlayerJobData()
                        return jobData.jobName == self.job and jobData.onDuty
                    end,
                    onSelect = function()
                        ToggleDuty(self.job, false)
                    end
                },
            }
        })
    end

    self.cleanup = function()
        if self.point then
            self.point:remove()
        end

        if self.target then
            exports.ox_target:removeZone('filo_duty_' .. self.uuid)
        end

        zones[self.uuid] = nil
    end

    return self
end

local function onPlayerLoaded()
    local playerJob = Framework.GetPlayerJobData()
    local dutyZones = lib.callback.await('filo_duty:server:getDutyZones', false)

    for uuid, zoneData in pairs(dutyZones) do
        local playerHasJob = PlayerHasJob(zoneData.job)
        if playerJob.jobName ~= zoneData.job and not playerHasJob then
            goto continue
        end

        if not zones[uuid] then
            zones[uuid] = zone:create(zoneData)
        end
        ::continue::
    end
end

local function cleanupAllZones()
    for _, zoneObj in pairs(zones) do
        zoneObj:cleanup()
    end
end

RegisterNetEvent('filo_duty:client:refreshDutyZones', function()
    cleanupAllZones()
    onPlayerLoaded()
end)

RegisterNetEvent('community_bridge:Client:OnPlayerLoaded', onPlayerLoaded)
RegisterNetEvent('community_bridge:Client:OnPlayerUnload', cleanupAllZones)
RegisterNetEvent('community_bridge:Client:OnPlayerJobUpdate', function(jobData)
    for _, zoneObj in pairs(zones) do
        local hasJob = PlayerHasJob(zoneObj.job)
        if zoneObj.job == jobData or hasJob then goto continue end

        zoneObj:cleanup()
        ::continue::
    end

    local dutyZones = lib.callback.await('filo_duty:server:getDutyZones', false)
    for uuid, zoneData in pairs(dutyZones) do
        local playerHasJob = PlayerHasJob(zoneData.job)
        if jobData ~= zoneData.job and not playerHasJob then
            goto continue
        end

        if not zones[uuid] then
            zones[uuid] = zone:create(zoneData)
        end
        ::continue::
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= cache.resource then return end
    if not Framework.GetIsPlayerLoaded() then return end

    onPlayerLoaded()
end)