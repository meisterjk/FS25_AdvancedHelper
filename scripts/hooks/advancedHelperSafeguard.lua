advancedHelperHelperSafeguard = {}

function advancedHelperHelperSafeguard.install()
    HelperManager.getRandomHelper = Utils.overwrittenFunction(HelperManager.getRandomHelper, advancedHelperHelperSafeguard.getRandomHelper)
    HelperManager.getRandomHelperStyle = Utils.overwrittenFunction(HelperManager.getRandomHelperStyle, advancedHelperHelperSafeguard.getRandomHelperStyle)
    AIJobVehicle.getCanStartAIVehicle = Utils.overwrittenFunction(AIJobVehicle.getCanStartAIVehicle, advancedHelperHelperSafeguard.getCanStartAIVehicle)
    AIJobVehicle.getShowAIToggleActionEvent = Utils.overwrittenFunction(AIJobVehicle.getShowAIToggleActionEvent, advancedHelperHelperSafeguard.getShowAIToggleActionEvent)
    AISystem.getAILimitedReached = Utils.overwrittenFunction(AISystem.getAILimitedReached, advancedHelperHelperSafeguard.getAILimitedReached)
    AIJob.start = Utils.overwrittenFunction(AIJob.start, advancedHelperHelperSafeguard.aiJobStart)
    AIJob.getPricePerMs = Utils.overwrittenFunction(AIJob.getPricePerMs, advancedHelperHelperSafeguard.getPricePerMs)
    AIJobFieldWork.getPricePerMs = Utils.overwrittenFunction(AIJobFieldWork.getPricePerMs, advancedHelperHelperSafeguard.getPricePerMs)
    AIJobConveyor.getPricePerMs = Utils.overwrittenFunction(AIJobConveyor.getPricePerMs, advancedHelperHelperSafeguard.getPricePerMs)

    local jobClasses = { AIJobFieldWork, AIJobGoTo, AIJobDeliver, AIJobLoadAndDeliver, AIJobConveyor }
    for _, jobClass in ipairs(jobClasses) do
        if jobClass ~= nil and jobClass.getIsStartable ~= nil then
            jobClass.getIsStartable = Utils.overwrittenFunction(jobClass.getIsStartable, advancedHelperHelperSafeguard.getIsStartable)
        end
    end
end

function advancedHelperHelperSafeguard.getRandomHelper(self, superFunc)
    if #self.availableHelpers == 0 then
        return nil
    end
    local result = superFunc(self)
    if result ~= nil and #advancedHelperManager.hiredWorkers > 0 then
        local worker = advancedHelperManager:getWorkerByHelperIndex(result.index)
        if worker ~= nil and worker.isAssigned then
            for _, h in ipairs(self.availableHelpers) do
                local w = advancedHelperManager:getWorkerByHelperIndex(h.index)
                if w ~= nil and not w.isAssigned then
                    advancedHelperDebug.log(string.format("getRandomHelper: substituted free worker %s for assigned %s",
                        w:getFullName(), worker:getFullName()))
                    return h
                end
            end
        end
    end
    return result
end

function advancedHelperHelperSafeguard.getRandomHelperStyle(self, superFunc)
    if self.numHelpers == 0 or next(self.indexToHelper) == nil then
        local fallbackStyle = PlayerStyle.new()
        fallbackStyle.xmlFilename = "dataS/character/playerM/playerM.xml"
        fallbackStyle:loadConfigurationXML(fallbackStyle.xmlFilename)
        return fallbackStyle
    end
    return superFunc(self)
end

function advancedHelperHelperSafeguard.hasFreeWorkersForVehicle(vehicle)
    if #advancedHelperManager.hiredWorkers == 0 then
        return false
    end
    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil then
        return false
    end
    return #advancedHelperManager:getFreeWorkersForFarm(farmId) > 0
end

function advancedHelperHelperSafeguard.getIsStartable(self, superFunc, connection)
    if #advancedHelperManager.hiredWorkers > 0 then
        local vehicle = advancedHelperHelperSafeguard.getVehicleFromJob(self)
        if vehicle ~= nil then
            local farmId = vehicle:getOwnerFarmId()
            if farmId ~= nil then
                local freeWorkers = advancedHelperManager:getFreeWorkersForFarm(farmId)
                if #freeWorkers == 0 then
                    advancedHelperDebug.log(string.format("getIsStartable: BLOCKED (no free workers for farm %d) vehicle=%s",
                        farmId, vehicle:getName()))
                    return false, AIJobFieldWork.START_ERROR_LIMIT_REACHED
                end
            end
        end
    end
    return superFunc(self, connection)
end

function advancedHelperHelperSafeguard.getCanStartAIVehicle(self, superFunc, ...)
    return superFunc(self, ...)
end

function advancedHelperHelperSafeguard.getShowAIToggleActionEvent(self, superFunc, ...)
    return superFunc(self, ...)
end

function advancedHelperHelperSafeguard.getAILimitedReached(self, superFunc)
    if #advancedHelperManager.hiredWorkers > 0 then
        return false
    end
    return superFunc(self)
end

function advancedHelperHelperSafeguard.getVehicleFromJob(job)
    if job.vehicleParameter ~= nil and job.vehicleParameter.getVehicle ~= nil then
        return job.vehicleParameter:getVehicle()
    end
    return nil
end

function advancedHelperHelperSafeguard.aiJobStart(self, superFunc, farmId)
    if g_server == nil then
        return superFunc(self, farmId)
    end

    if #advancedHelperManager.hiredWorkers == 0 then
        return
    end
    local freeWorkers = advancedHelperManager:getFreeWorkersForFarm(farmId)
    if #freeWorkers == 0 then
        local vehicle = advancedHelperHelperSafeguard.getVehicleFromJob(self)
        if vehicle ~= nil then
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                g_i18n:getText("advancedHelper_allWorkersBusy"))
        end
        advancedHelperDebug.log(string.format("aiJobStart: BLOCKED — no free workers for farm %d", farmId or -1))
        return
    end

    local result = superFunc(self, farmId)

    local vehicle = advancedHelperHelperSafeguard.getVehicleFromJob(self)
    if vehicle ~= nil then
        local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
        if worker == nil then
            worker = advancedHelperManager:getWorkerByHelperIndex(self.helperIndex)
        end
        if worker == nil then
            worker = freeWorkers[1]
            if worker ~= nil then
                self.helperIndex = worker.helperIndex
                advancedHelperDebug.log(string.format("aiJobStart: substituted free worker %s (helperIndex=%d)",
                    worker:getFullName(), worker.helperIndex))
            end
        end
        if worker ~= nil then
            local source = ""
            if self.name ~= nil and string.find(self.name, "CP") then
                source = "CP"
            end
            if source == "" and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and vehicle.ad.stateModule:isActive() then
                source = "AD"
            end
            if worker.isAssigned then
                local subWorker = nil
                for _, fw in ipairs(freeWorkers) do
                    if not fw.isAssigned then
                        subWorker = fw
                        break
                    end
                end
                if subWorker ~= nil then
                    advancedHelperDebug.log(string.format("aiJobStart: substituted free worker %s for already-assigned %s",
                        subWorker:getFullName(), worker:getFullName()))
                    worker = subWorker
                    self.helperIndex = worker.helperIndex
                end
            end
            if worker.helperIndex ~= nil then
                self.helperIndex = worker.helperIndex
            end
            if not worker.isAssigned then
                for _, w in ipairs(advancedHelperManager.hiredWorkers) do
                    if w.assignedVehicle == vehicle and w.id ~= worker.id then
                        advancedHelperDebug.log(string.format("aiJobStart: releasing previous worker %s from %s",
                            w:getFullName(), vehicle:getName()))
                        w.isAssigned = false
                        w.assignedVehicle = nil
                        w.assignSource = ""
                    end
                end
                worker.isAssigned = true
                worker.assignedVehicle = vehicle
                worker.assignSource = source
                advancedHelperDebug.log(string.format("AI ASSIGN: %s -> %s (auto-assigned, source=%s)", worker:getFullName(), vehicle:getName(), source))
                advancedHelperSyncEvent.broadcast()
                advancedHelperAPI._fire("workerAssigned", advancedHelperAPI._copyWorker(worker), vehicle:getName())
            else
                advancedHelperDebug.log(string.format("AI ASSIGN: %s helperIndex=%d on %s (already assigned)",
                    worker:getFullName(), worker.helperIndex, vehicle:getName()))
            end
            advancedHelperHotspot:createHotspot(vehicle, worker, source)
        end
    end

    if advancedHelperConfig.DEBUG then
        vehicle = vehicle or advancedHelperHelperSafeguard.getVehicleFromJob(self)
        local worker = advancedHelperManager:getWorkerByHelperIndex(self.helperIndex)
        if worker ~= nil then
            local speedMult = worker:getSpeedMultiplier()
            local speedPct = speedMult >= 1.0 and 0 or (1 - speedMult) * 100
            advancedHelperDebug.log(string.format(
                "AI START: %s auf %s | Eff=%d->Sprit %+.1f%% | Fahr=%d->Arbeitstempo -%.1f%% | Koennen=%d->Verschleiss %+.1f%%",
                worker:getFullName(),
                vehicle and vehicle:getName() or "?",
                worker.efficiency, (worker:getFuelMultiplier() - 1) * 100,
                worker.driving, speedPct,
                worker.skill, (worker:getWearMultiplier() - 1) * 100
            ))
        else
            advancedHelperDebug.log(string.format("AI START: no worker found for helperIndex=%d vehicle=%s",
                self.helperIndex or -1,
                vehicle and vehicle:getName() or "?"))
        end
    end

    return result
end

function advancedHelperHelperSafeguard.getPricePerMs(self, superFunc)
    if #advancedHelperManager.hiredWorkers > 0 then
        local farmId = self.startedFarmId
        if farmId ~= nil then
            if advancedHelperManager:getWorkerCountForFarm(farmId) > 0 then
                return 0
            end
        else
            return 0
        end
    end
    return superFunc(self)
end