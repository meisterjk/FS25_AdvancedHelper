advancedHelperHireEvent = {}
advancedHelperHireEvent_mt = Class(advancedHelperHireEvent, Event)
InitEventClass(advancedHelperHireEvent, "advancedHelperHireEvent")

function advancedHelperHireEvent.emptyNew()
    return Event.new(advancedHelperHireEvent_mt)
end

function advancedHelperHireEvent.new(applicantId, farmId)
    local self = advancedHelperHireEvent.emptyNew()
    self.applicantId = applicantId
    self.farmId = farmId
    return self
end

function advancedHelperHireEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.applicantId, 16)
    streamWriteUInt8(streamId, self.farmId)
end

function advancedHelperHireEvent:readStream(streamId, connection)
    self.applicantId = streamReadUIntN(streamId, 16)
    self.farmId = streamReadUInt8(streamId)
    self:run(connection)
end

function advancedHelperHireEvent:run(connection)
    if g_server ~= nil then
        advancedHelperManager:hireApplicant(self.applicantId, self.farmId)
    end
end

function advancedHelperHireEvent.sendEvent(applicantId, farmId)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(advancedHelperHireEvent.new(applicantId, farmId))
    end
end

advancedHelperFireEvent = {}
advancedHelperFireEvent_mt = Class(advancedHelperFireEvent, Event)
InitEventClass(advancedHelperFireEvent, "advancedHelperFireEvent")

function advancedHelperFireEvent.emptyNew()
    return Event.new(advancedHelperFireEvent_mt)
end

function advancedHelperFireEvent.new(workerId, farmId)
    local self = advancedHelperFireEvent.emptyNew()
    self.workerId = workerId
    self.farmId = farmId
    return self
end

function advancedHelperFireEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.workerId, 16)
    streamWriteUInt8(streamId, self.farmId)
end

function advancedHelperFireEvent:readStream(streamId, connection)
    self.workerId = streamReadUIntN(streamId, 16)
    self.farmId = streamReadUInt8(streamId)
    self:run(connection)
end

function advancedHelperFireEvent:run(connection)
    if g_server ~= nil then
        advancedHelperManager:fireWorker(self.workerId, self.farmId)
    end
end

function advancedHelperFireEvent.sendEvent(workerId, farmId)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(advancedHelperFireEvent.new(workerId, farmId))
    end
end

advancedHelperRefreshEvent = {}
advancedHelperRefreshEvent_mt = Class(advancedHelperRefreshEvent, Event)
InitEventClass(advancedHelperRefreshEvent, "advancedHelperRefreshEvent")

function advancedHelperRefreshEvent.emptyNew()
    return Event.new(advancedHelperRefreshEvent_mt)
end

function advancedHelperRefreshEvent.new(farmId)
    local self = advancedHelperRefreshEvent.emptyNew()
    self.farmId = farmId
    return self
end

function advancedHelperRefreshEvent:writeStream(streamId, connection)
    streamWriteUInt8(streamId, self.farmId)
end

function advancedHelperRefreshEvent:readStream(streamId, connection)
    self.farmId = streamReadUInt8(streamId)
    self:run(connection)
end

function advancedHelperRefreshEvent:run(connection)
    if g_server ~= nil then
        advancedHelperManager:generateApplicants()
        advancedHelperManager.lastRefreshDay = g_currentMission.environment.currentDay
        advancedHelperManager:saveState()
        advancedHelperSyncEvent.broadcast()
        local applicantCopies = {}
        for _, a in ipairs(advancedHelperManager.applicants) do
            table.insert(applicantCopies, advancedHelperAPI._copyWorker(a))
        end
        advancedHelperAPI._fire("applicantsRefreshed", applicantCopies)
    end
end

function advancedHelperRefreshEvent.sendEvent(farmId)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(advancedHelperRefreshEvent.new(farmId))
    end
end

advancedHelperStartAIEvent = {}
advancedHelperStartAIEvent_mt = Class(advancedHelperStartAIEvent, Event)
InitEventClass(advancedHelperStartAIEvent, "advancedHelperStartAIEvent")

function advancedHelperStartAIEvent.emptyNew()
    return Event.new(advancedHelperStartAIEvent_mt)
end

function advancedHelperStartAIEvent.new(vehicleId, workerId, farmId)
    local self = advancedHelperStartAIEvent.emptyNew()
    self.vehicleId = vehicleId
    self.workerId = workerId
    self.farmId = farmId
    return self
end

function advancedHelperStartAIEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.vehicleId)
    streamWriteUIntN(streamId, self.workerId, 16)
    streamWriteUInt8(streamId, self.farmId)
end

function advancedHelperStartAIEvent:readStream(streamId, connection)
    self.vehicleId = NetworkUtil.readNodeObjectId(streamId)
    self.workerId = streamReadUIntN(streamId, 16)
    self.farmId = streamReadUInt8(streamId)
    self:run(connection)
end

function advancedHelperStartAIEvent:run(connection)
    if g_server ~= nil then
        local vehicle = NetworkUtil.getObject(self.vehicleId)
        if vehicle ~= nil then
            local startableJob = vehicle:getStartableAIJob()
            if startableJob ~= nil then
                local worker = advancedHelperManager:getWorkerById(self.workerId)
                if worker ~= nil and not worker.isAssigned then
                    startableJob:applyCurrentState(vehicle, g_currentMission, self.farmId, true)
                    if worker.helperIndex ~= nil then
                        startableJob.helperIndex = worker.helperIndex
                    end
                    g_currentMission.aiSystem:startJob(startableJob, self.farmId)
                end
            end
        end
    end
end

function advancedHelperStartAIEvent.sendEvent(vehicle, workerId, farmId)
    if g_client ~= nil and vehicle ~= nil then
        local vehicleId = NetworkUtil.getObjectId(vehicle)
        g_client:getServerConnection():sendEvent(advancedHelperStartAIEvent.new(vehicleId, workerId, farmId))
    end
end

advancedHelperSyncEvent = {}
advancedHelperSyncEvent_mt = Class(advancedHelperSyncEvent, Event)
InitEventClass(advancedHelperSyncEvent, "advancedHelperSyncEvent")

function advancedHelperSyncEvent.emptyNew()
    return Event.new(advancedHelperSyncEvent_mt)
end

function advancedHelperSyncEvent.new(data)
    local self = advancedHelperSyncEvent.emptyNew()
    self.data = data
    return self
end

function advancedHelperSyncEvent:writeStream(streamId, connection)
    local d = self.data
    streamWriteUIntN(streamId, d.lastRefreshDay, 16)
    streamWriteUIntN(streamId, #d.hiredWorkers, 8)
    streamWriteUIntN(streamId, #d.applicants, 4)

    for _, w in ipairs(d.hiredWorkers) do
        streamWriteUIntN(streamId, w.id, 16)
        streamWriteString(streamId, w.firstName)
        streamWriteString(streamId, w.lastName)
        streamWriteUInt8(streamId, w.gender == "F" and 1 or 0)
        streamWriteUInt8(streamId, w.efficiency)
        streamWriteUInt8(streamId, w.driving)
        streamWriteUInt8(streamId, w.skill)
        streamWriteInt32(streamId, w.monthlySalary)
        streamWriteUIntN(streamId, w.hireDay, 16)
        streamWriteUInt8(streamId, w.farmId)
        streamWriteBool(streamId, w.isAssigned)
        streamWriteString(streamId, w.assignSource or "")
        if w.isAssigned and w.assignedVehicleId ~= nil then
            streamWriteBool(streamId, true)
            NetworkUtil.writeNodeObjectId(streamId, w.assignedVehicleId)
        else
            streamWriteBool(streamId, false)
        end
    end

    for _, a in ipairs(d.applicants) do
        streamWriteUIntN(streamId, a.id, 16)
        streamWriteString(streamId, a.firstName)
        streamWriteString(streamId, a.lastName)
        streamWriteUInt8(streamId, a.gender == "F" and 1 or 0)
        streamWriteUInt8(streamId, a.efficiency)
        streamWriteUInt8(streamId, a.driving)
        streamWriteUInt8(streamId, a.skill)
        streamWriteInt32(streamId, a.monthlySalary)
    end
end

function advancedHelperSyncEvent:readStream(streamId, connection)
    local d = {}
    d.lastRefreshDay = streamReadUIntN(streamId, 16)
    local numHired = streamReadUIntN(streamId, 8)
    local numApplicants = streamReadUIntN(streamId, 4)

    d.hiredWorkers = {}
    for i = 1, numHired do
        local w = {}
        w.id = streamReadUIntN(streamId, 16)
        w.firstName = streamReadString(streamId)
        w.lastName = streamReadString(streamId)
        w.gender = streamReadUInt8(streamId) == 1 and "F" or "M"
        w.efficiency = streamReadUInt8(streamId)
        w.driving = streamReadUInt8(streamId)
        w.skill = streamReadUInt8(streamId)
        w.monthlySalary = streamReadInt32(streamId)
        w.hireDay = streamReadUIntN(streamId, 16)
        w.farmId = streamReadUInt8(streamId)
        w.isAssigned = streamReadBool(streamId)
        w.assignSource = streamReadString(streamId) or ""
        if w.isAssigned and streamReadBool(streamId) then
            w.assignedVehicleId = NetworkUtil.readNodeObjectId(streamId)
        end
        w.isHired = true
        w.helperIndex = nil
        w.helperName = nil
        w.assignedVehicle = nil
        d.hiredWorkers[i] = w
    end

    d.applicants = {}
    for i = 1, numApplicants do
        local a = {}
        a.id = streamReadUIntN(streamId, 16)
        a.firstName = streamReadString(streamId)
        a.lastName = streamReadString(streamId)
        a.gender = streamReadUInt8(streamId) == 1 and "F" or "M"
        a.efficiency = streamReadUInt8(streamId)
        a.driving = streamReadUInt8(streamId)
        a.skill = streamReadUInt8(streamId)
        a.monthlySalary = streamReadInt32(streamId)
        a.isHired = false
        a.hireDay = 0
        a.farmId = FarmManager.SINGLEPLAYER_FARM_ID
        a.isAssigned = false
        a.assignedVehicle = nil
        a.helperIndex = nil
        a.helperName = nil
        d.applicants[i] = a
    end

    self.data = d
    self:run(connection)
end

function advancedHelperSyncEvent:run(connection)
    advancedHelperManager:applySyncState(self.data)
end

function advancedHelperSyncEvent.broadcast()
    if g_server == nil then
        return
    end
    local data = advancedHelperManager:buildSyncData()
    g_server:broadcastEvent(advancedHelperSyncEvent.new(data))
end

function advancedHelperSyncEvent.sendToClient(connection)
    if g_server == nil then
        return
    end
    local data = advancedHelperManager:buildSyncData()
    connection:sendEvent(advancedHelperSyncEvent.new(data))
end