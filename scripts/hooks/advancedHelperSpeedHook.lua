advancedHelperSpeedHook = {}
advancedHelperSpeedHook.vehiclesToStop = {}

function advancedHelperSpeedHook.install()
    VehicleMotor.setSpeedLimit = Utils.overwrittenFunction(VehicleMotor.setSpeedLimit, advancedHelperSpeedHook.motorSetSpeedLimit)
end

function advancedHelperSpeedHook.motorSetSpeedLimit(self, superFunc, limit)
    local vehicle = self.vehicle
    local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    if worker ~= nil and limit ~= math.huge and limit > 0 then
        local speedMult = worker:getSpeedMultiplier()
        if speedMult < 1.0 then
            local newLimit = limit * speedMult
            advancedHelperDebug.log(string.format(
                "SPEED: %s motor %.1f->%.1fkm/h (-%.0f%%) [driving=%d]",
                vehicle:getName(), limit, newLimit, (1 - speedMult) * 100, worker.driving
            ))
            limit = newLimit
        end
    end
    superFunc(self, limit)
end

function advancedHelperSpeedHook.onAIJobStarted(job, startFarmId)
    if g_server == nil then
        return
    end

    local vehicle = advancedHelperHelperSafeguard.getVehicleFromJob(job)
    if vehicle == nil then
        advancedHelperDebug.log("AI_JOB_STARTED: no vehicle from job")
        return
    end

    local source = ""
    if job.name ~= nil and string.find(job.name, "CP") then
        source = "CP"
    end
    if source == "" and vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and vehicle.ad.stateModule:isActive() then
        source = "AD"
    end

    local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    if worker ~= nil and worker.isAssigned and worker.assignedVehicle == vehicle then
        advancedHelperDebug.log(string.format("AI_JOB_STARTED: %s already assigned to %s by aiJobStart — hotspot only",
            worker:getFullName(), vehicle:getName()))
        advancedHelperHotspot:createHotspot(vehicle, worker, source)
        return
    end

    if worker == nil then
        worker = advancedHelperManager:getWorkerByHelperIndex(job.helperIndex)
    end

    if worker == nil then
        local farmId = startFarmId or (vehicle:getOwnerFarmId())
        local freeWorkers = advancedHelperManager:getFreeWorkersForFarm(farmId)
        if #freeWorkers == 0 then
            if #advancedHelperManager.hiredWorkers > 0 then
                advancedHelperDebug.log(string.format("AI_JOB_STARTED: no worker and no free workers for helperIndex=%d vehicle=%s — stopping job",
                    job.helperIndex or -1, vehicle:getName()))
                table.insert(advancedHelperSpeedHook.vehiclesToStop, vehicle)
                if g_currentMission ~= nil then
                    g_currentMission:addIngameNotification(
                        FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                        g_i18n:getText("advancedHelper_allWorkersBusy"))
                end
            end
            return
        end
        worker = freeWorkers[1]
        job.helperIndex = worker.helperIndex
        advancedHelperDebug.log(string.format("AI_JOB_STARTED: substituted free worker %s (helperIndex=%d) for vehicle %s",
            worker:getFullName(), worker.helperIndex, vehicle:getName()))
    end

    if worker.isAssigned then
        if worker.assignedVehicle == vehicle then
            advancedHelperHotspot:createHotspot(vehicle, worker, source)
            return
        end
        local farmId = startFarmId or (vehicle:getOwnerFarmId())
        local freeWorkers = advancedHelperManager:getFreeWorkersForFarm(farmId)
        if #freeWorkers > 0 then
            worker = freeWorkers[1]
            job.helperIndex = worker.helperIndex
            advancedHelperDebug.log(string.format("AI_JOB_STARTED: worker was assigned to other vehicle, substituted free worker %s (helperIndex=%d) for vehicle %s",
                worker:getFullName(), worker.helperIndex, vehicle:getName()))
        else
            advancedHelperDebug.log(string.format("AI_JOB_STARTED: worker %s already assigned to %s and no free workers — stopping job for %s (source=%s)",
                worker:getFullName(),
                worker.assignedVehicle and worker.assignedVehicle:getName() or "?",
                vehicle:getName(), source))
            table.insert(advancedHelperSpeedHook.vehiclesToStop, vehicle)
            if g_currentMission ~= nil then
                g_currentMission:addIngameNotification(
                    FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                    g_i18n:getText("advancedHelper_allWorkersBusy"))
            end
            return
        end
    end

    advancedHelperManager:assignWorkerToVehicle(worker.id, vehicle)
    worker.assignSource = source
    advancedHelperDebug.log(string.format("AI JOB ASSIGN: %s -> %s (source=%s)", worker:getFullName(), vehicle:getName(), source))
    advancedHelperSyncEvent.broadcast()
    advancedHelperAPI._fire("workerAssigned", advancedHelperAPI._copyWorker(worker), vehicle:getName())
    advancedHelperHotspot:createHotspot(vehicle, worker, source)
end

function advancedHelperSpeedHook.processDeferredStops()
    if #advancedHelperSpeedHook.vehiclesToStop == 0 then
        return
    end
    local vehicles = advancedHelperSpeedHook.vehiclesToStop
    advancedHelperSpeedHook.vehiclesToStop = {}
    for _, vehicle in ipairs(vehicles) do
        advancedHelperDebug.log(string.format("AI_JOB_STARTED: deferred stop for %s", vehicle:getName()))
        vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
    end
end

function advancedHelperSpeedHook.onAIJobStopped(job, aiMessage)
    if g_server == nil then
        return
    end

    local vehicle = advancedHelperHelperSafeguard.getVehicleFromJob(job)
    if vehicle == nil then
        return
    end

    if vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and vehicle.ad.stateModule:isActive() then
        advancedHelperDebug.log(string.format("AI_JOB_STOPPED: AD active on %s, keeping worker assigned", vehicle:getName()))
        return
    end

    advancedHelperManager:unassignWorkerByVehicle(vehicle)
    advancedHelperHotspot:removeHotspot(vehicle)
    advancedHelperSyncEvent.broadcast()
end