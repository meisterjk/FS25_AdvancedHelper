advancedHelperSpeedHook = {}
advancedHelperSpeedHook.originalSpeedLimits = {}
advancedHelperSpeedHook.vehiclesToStop = {}

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
        advancedHelperDebug.log(string.format("AI_JOB_STARTED: %s already assigned to %s by aiJobStart — speed+hotspot only",
            worker:getFullName(), vehicle:getName()))
        advancedHelperSpeedHook.applySpeedModification(vehicle, worker)
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
            advancedHelperSpeedHook.applySpeedModification(vehicle, worker)
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

    advancedHelperSpeedHook.applySpeedModification(vehicle, worker)
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

function advancedHelperSpeedHook.applySpeedModification(vehicle, worker)
    local speedMult = worker:getSpeedMultiplier()
    if speedMult >= 1.0 then
        return
    end

    local seen = {}
    local allObjects = {}

    local function addObject(obj)
        if obj ~= nil and seen[obj] == nil then
            seen[obj] = true
            table.insert(allObjects, obj)
        end
    end

    addObject(vehicle)

    if vehicle.getAttachedImplements ~= nil then
        for _, impl in ipairs(vehicle:getAttachedImplements()) do
            addObject(impl.object)
        end
    end

    local root = vehicle.rootVehicle
    if root ~= nil and root ~= vehicle then
        addObject(root)
        if root.getAttachedImplements ~= nil then
            for _, impl in ipairs(root:getAttachedImplements()) do
                addObject(impl.object)
            end
        end
    end

    local modified = false

    for _, obj in ipairs(allObjects) do
        if obj.speedLimit ~= nil then
            if obj.speedLimit ~= math.huge then
                if advancedHelperSpeedHook.originalSpeedLimits[obj] == nil then
                    advancedHelperSpeedHook.originalSpeedLimits[obj] = obj.speedLimit
                end
                local newLimit = obj.speedLimit * speedMult
                advancedHelperDebug.log(string.format(
                    "SPEED SET: %s speedLimit=%.1f->%.1fkm/h (-%.1f%%) [driving=%d]",
                    obj:getName(), obj.speedLimit, newLimit, (1 - speedMult) * 100, worker.driving
                ))
                obj.speedLimit = newLimit
                modified = true
            else
                advancedHelperDebug.log(string.format(
                    "SPEED SKIP: %s speedLimit=inf (no working limit) [driving=%d]",
                    obj:getName(), worker.driving
                ))
            end
        end
    end

    if not modified then
        advancedHelperDebug.log(string.format(
            "SPEED: no modifiable speedLimit for %s (driving=%d mult=%.2f objects=%d)",
            vehicle:getName(), worker.driving, speedMult, #allObjects
        ))
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
    advancedHelperSpeedHook.restoreSpeedModification(vehicle)
    advancedHelperHotspot:removeHotspot(vehicle)
    advancedHelperSyncEvent.broadcast()
end

function advancedHelperSpeedHook.restoreSpeedModification(vehicle)
    if vehicle == nil then
        return
    end

    local restored = 0
    local seen = {}

    local function restoreObj(obj)
        if obj ~= nil and seen[obj] == nil then
            seen[obj] = true
            local original = advancedHelperSpeedHook.originalSpeedLimits[obj]
            if original ~= nil then
                advancedHelperDebug.log(string.format(
                    "SPEED RESTORE: %s -> %.1fkm/h",
                    obj:getName(), original
                ))
                obj.speedLimit = original
                advancedHelperSpeedHook.originalSpeedLimits[obj] = nil
                restored = restored + 1
            end
        end
    end

    restoreObj(vehicle)

    if vehicle.getAttachedImplements ~= nil then
        for _, impl in ipairs(vehicle:getAttachedImplements()) do
            restoreObj(impl.object)
        end
    end

    local root = vehicle.rootVehicle
    if root ~= nil and root ~= vehicle then
        restoreObj(root)
        if root.getAttachedImplements ~= nil then
            for _, impl in ipairs(root:getAttachedImplements()) do
                restoreObj(impl.object)
            end
        end
    end

    if restored > 0 then
        advancedHelperDebug.log(string.format("SPEED RESTORED %d limits for %s", restored, vehicle:getName()))
    end
end

function advancedHelperSpeedHook.restoreAll()
    for obj, original in pairs(advancedHelperSpeedHook.originalSpeedLimits) do
        if obj ~= nil then
            advancedHelperDebug.log(string.format("SPEED SAVE-RESTORE: %s -> %.1fkm/h", obj:getName(), original))
            obj.speedLimit = original
        end
    end
    advancedHelperSpeedHook.originalSpeedLimits = {}
end