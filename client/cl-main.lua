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
    self.job = data.job
    self.jobLabel = data.jobLabel
    self.uuid = data.uuid

    local interactionType = data.interactionType or 'marker'
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
                    local hasJob = PlayerHasJob(self.job)

                    if not drawingText then
                        drawingText = true
                        local textLabel = jobData.onDuty and "Go Off Duty (" .. (self.jobLabel or self.job) .. ")" or "Go On Duty (" .. (self.jobLabel or self.job) .. ")"

                        if jobData.jobName ~= self.job and hasJob then
                            textLabel = "Go On Duty (" .. (self.jobLabel or self.job) .. ")"
                        end

                        exports.filo_textui:DrawText({
                            { key = "E", label = textLabel }
                        })
                    end

                    if IsControlJustPressed(0, 38) then
                        if self.job == jobData.jobName then
                            ToggleDuty(self.job, not jobData.onDuty)
                        elseif self.job ~= jobData.jobName and hasJob then
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

    function self:cleanup()
        if self.marker then
            self.marker:destroy()
            self.marker = nil
        end

        if self.point then
            self.point:destroy()
            self.point = nil
        end

        if self.target then
            exports.ox_target:removeZone('filo_duty_' .. self.uuid)
            self.target = nil
        end

        zones[data.uuid] = nil
    end

    zones[data.uuid] = self
end

local function onPlayerLoaded()
    local playerJob = Framework.GetPlayerJobData()
    local dutyZones = lib.callback.await('filo_duty:server:getDutyZones', false)

    for uuid, zoneData in pairs(dutyZones) do
        local playerHasJob = PlayerHasJob(zoneData.job)
        if playerJob.jobName ~= zoneData.job and not playerHasJob then
            goto continue
        end

        if zones[uuid] then
            zones[uuid]:cleanup()
        end

        zone:create(zoneData)
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
    Wait(100)
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
            zone:create(zoneData)
        end
        ::continue::
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= cache.resource then return end
    if not Framework.GetIsPlayerLoaded() then return end

    onPlayerLoaded()
end)