advancedHelperAutoDriveHook = {}

advancedHelperAutoDriveHook.isInstalled = false
advancedHelperAutoDriveHook.hookedVehicleTypes = {}
advancedHelperAutoDriveHook.hookedCheckAddHelper = false
advancedHelperAutoDriveHook.activeADCount = 0

function advancedHelperAutoDriveHook.isADLoaded()
    return g_modIsLoaded ~= nil and g_modIsLoaded["FS25_AutoDrive"]
end

function advancedHelperAutoDriveHook.hasADSpecialization(vehicle)
    if vehicle == nil then
        return false
    end
    if AutoDrive == nil then
        return false
    end
    return vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil
end

function advancedHelperAutoDriveHook.install()
    if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
        advancedHelperAutoDriveHook.installMinimal()
        return
    end

    if not advancedHelperAutoDriveHook.isADLoaded() then
        advancedHelperDebug.log("ADHOOK: AutoDrive not loaded, skipping install")
        return
    end

    if AutoDrive == nil then
        advancedHelperDebug.log("ADHOOK: AutoDrive global not available, trying event listeners only")
        advancedHelperAutoDriveHook.installEventListenersOnly()
        return
    end

    if g_vehicleTypeManager == nil then
        return
    end

    advancedHelperAutoDriveHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if SpecializationUtil.hasSpecialization(AutoDrive, vehicleType.specializations) then
            advancedHelperAutoDriveHook:installTypeHooks(vehicleType)
            advancedHelperAutoDriveHook.hookedVehicleTypes[typeName] = true
        end
    end

    if AutoDrive.checkAddHelper ~= nil then
        AutoDrive.checkAddHelper = Utils.overwrittenFunction(
            AutoDrive.checkAddHelper, advancedHelperAutoDriveHook.checkAddHelperOverride)
        advancedHelperAutoDriveHook.hookedCheckAddHelper = true
    end

    advancedHelperAutoDriveHook.isInstalled = true
    advancedHelperDebug.log(string.format("ADHOOK: installed (infiltrate=true, types=%d, checkAddHelper=%s)",
        advancedHelperAutoDriveHook:countHookedTypes(), tostring(advancedHelperAutoDriveHook.hookedCheckAddHelper)))
end

function advancedHelperAutoDriveHook.installMinimal()
    if not advancedHelperAutoDriveHook.isADLoaded() then
        return
    end

    if AutoDrive == nil or g_vehicleTypeManager == nil then
        return
    end

    advancedHelperAutoDriveHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if SpecializationUtil.hasSpecialization(AutoDrive, vehicleType.specializations) then
            SpecializationUtil.registerEventListener(vehicleType, "onStartAutoDrive", advancedHelperAutoDriveHook)
            SpecializationUtil.registerEventListener(vehicleType, "onStopAutoDrive", advancedHelperAutoDriveHook)
            advancedHelperAutoDriveHook.hookedVehicleTypes[typeName] = true
        end
    end

    advancedHelperAutoDriveHook.isInstalled = true
    advancedHelperAutoDriveHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("ADHOOK: installed minimal (infiltrate=false, types=%d) — only AD counter",
        advancedHelperAutoDriveHook:countHookedTypes()))
end

function advancedHelperAutoDriveHook.installEventListenersOnly()
    if advancedHelperAutoDriveHook.eventListenersInstalled then
        return
    end
    if not advancedHelperAutoDriveHook.isADLoaded() then
        return
    end
    if g_vehicleTypeManager == nil then
        return
    end

    advancedHelperAutoDriveHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        local hasAD = false
        for _, spec in pairs(vehicleType.specializations) do
            if type(spec) == "table" and spec.ADSpecName ~= nil then
                hasAD = true
                break
            end
        end
        if hasAD then
            SpecializationUtil.registerEventListener(vehicleType, "onStartAutoDrive", advancedHelperAutoDriveHook)
            SpecializationUtil.registerEventListener(vehicleType, "onStopAutoDrive", advancedHelperAutoDriveHook)
            advancedHelperAutoDriveHook.hookedVehicleTypes[typeName] = true
        end
    end

    if advancedHelperAutoDriveHook:countHookedTypes() == 0 then
        return
    end

    advancedHelperAutoDriveHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("ADHOOK: event listeners only (types=%d)",
        advancedHelperAutoDriveHook:countHookedTypes()))
end

function advancedHelperAutoDriveHook:installTypeHooks(vehicleType)
    if vehicleType == nil then
        return
    end

    if vehicleType.startAutoDrive ~= nil then
        vehicleType.startAutoDrive = Utils.overwrittenFunction(
            vehicleType.startAutoDrive, advancedHelperAutoDriveHook.startAutoDriveOverride)
    end

    SpecializationUtil.registerEventListener(vehicleType, "onStartAutoDrive", advancedHelperAutoDriveHook)
    SpecializationUtil.registerEventListener(vehicleType, "onStopAutoDrive", advancedHelperAutoDriveHook)
end

function advancedHelperAutoDriveHook.uninstall()
    advancedHelperAutoDriveHook.isInstalled = false
    advancedHelperAutoDriveHook.eventListenersInstalled = false
    advancedHelperAutoDriveHook.hookedVehicleTypes = {}
    advancedHelperAutoDriveHook.hookedCheckAddHelper = false
    advancedHelperAutoDriveHook.activeADCount = 0
    advancedHelperDebug.log("ADHOOK: uninstalled")
end

function advancedHelperAutoDriveHook:countHookedTypes()
    local count = 0
    for _ in pairs(advancedHelperAutoDriveHook.hookedVehicleTypes) do
        count = count + 1
    end
    return count
end

function advancedHelperAutoDriveHook.startAutoDriveOverride(self, superFunc)
    local farmId = self:getOwnerFarmId()
    if farmId == nil then
        farmId = g_currentMission:getFarmId()
    end

    local freeWorkers = advancedHelperManager:getFreeWorkersForFarm(farmId)
    if #freeWorkers == 0 then
        if g_currentMission ~= nil then
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                g_i18n:getText("advancedHelper_allWorkersBusy"))
        end
        advancedHelperDebug.log(string.format("ADHOOK: BLOCKED startAutoDrive for %s (no free workers for farm %d)",
            self:getName(), farmId or -1))
        return
    end

    superFunc(self)

    advancedHelperDebug.log(string.format("ADHOOK: startAutoDrive allowed for %s (free workers=%d)",
        self:getName(), #freeWorkers))
end

function advancedHelperAutoDriveHook:onStartAutoDrive()
    if g_server == nil then
        return
    end
    local vehicle = self

    advancedHelperAutoDriveHook.activeADCount = advancedHelperAutoDriveHook.activeADCount + 1

    if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
        advancedHelperDebug.log(string.format("ADHOOK: onStartAutoDrive minimal — count=%d vehicle=%s",
            advancedHelperAutoDriveHook.activeADCount, vehicle:getName()))
        return
    end

    local helperIndex = 0
    if vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
        helperIndex = vehicle.ad.stateModule:getCurrentHelperIndex()
    end
    if helperIndex <= 0 and vehicle.ad ~= nil and vehicle.ad.currentHelper ~= nil then
        helperIndex = vehicle.ad.currentHelper.index or 0
    end

    local worker = nil
    if helperIndex > 0 then
        worker = advancedHelperManager:getWorkerByHelperIndex(helperIndex)
    end
    if worker == nil then
        worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    end

    if worker ~= nil then
        if not worker.isAssigned then
            worker.isAssigned = true
            worker.assignedVehicle = vehicle
            worker.assignSource = "AD"
            advancedHelperDebug.log(string.format("ADHOOK: ASSIGN %s -> %s (helperIndex=%d, source=AD)",
                worker:getFullName(), vehicle:getName(), helperIndex))
        else
            advancedHelperDebug.log(string.format("ADHOOK: ASSIGN %s already assigned to %s (helperIndex=%d)",
                worker:getFullName(),
                worker.assignedVehicle and worker.assignedVehicle:getName() or "?",
                helperIndex))
        end

        advancedHelperSpeedHook.applySpeedModification(vehicle, worker)
        advancedHelperSyncEvent.broadcast()

        if advancedHelperConfig.DEBUG then
            local speedMult = worker:getSpeedMultiplier()
            local speedPct = speedMult >= 1.0 and 0 or (1 - speedMult) * 100
            advancedHelperDebug.log(string.format(
                "ADHOOK: AD START %s on %s | Eff=%d->Sprit %+.1f%% | Fahr=%d->Tempo -%.1f%% | Koennen=%d->Verschleiss %+.1f%%",
                worker:getFullName(), vehicle:getName(),
                worker.efficiency, (worker:getFuelMultiplier() - 1) * 100,
                worker.driving, speedPct,
                worker.skill, (worker:getWearMultiplier() - 1) * 100
            ))
        end
    else
        advancedHelperDebug.log(string.format("ADHOOK: onStartAutoDrive — no worker found for helperIndex=%d vehicle=%s",
            helperIndex, vehicle:getName()))
    end
end

function advancedHelperAutoDriveHook:onStopAutoDrive()
    if g_server == nil then
        return
    end
    local vehicle = self

    advancedHelperAutoDriveHook.activeADCount = math.max(0, advancedHelperAutoDriveHook.activeADCount - 1)

    if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
        advancedHelperDebug.log(string.format("ADHOOK: onStopAutoDrive minimal — count=%d vehicle=%s",
            advancedHelperAutoDriveHook.activeADCount, vehicle:getName()))
        return
    end

    local helperIndex = 0
    if vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil then
        helperIndex = vehicle.ad.stateModule:getCurrentHelperIndex()
    end
    if helperIndex <= 0 and vehicle.ad ~= nil and vehicle.ad.currentHelper ~= nil then
        helperIndex = vehicle.ad.currentHelper.index or 0
    end

    local worker = nil
    if helperIndex > 0 then
        worker = advancedHelperManager:getWorkerByHelperIndex(helperIndex)
    end
    if worker == nil then
        worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    end

    if worker ~= nil then
        advancedHelperDebug.log(string.format("ADHOOK: UNASSIGN %s from %s (wasAssigned=%s)",
            worker:getFullName(), vehicle:getName(), tostring(worker.isAssigned)))
        worker.isAssigned = false
        worker.assignedVehicle = nil
        worker.assignSource = ""
    end

    advancedHelperSpeedHook.restoreSpeedModification(vehicle)
    advancedHelperSyncEvent.broadcast()
end

function advancedHelperAutoDriveHook.checkAddHelperOverride(vehicle, superFunc, helperIndex, numHelpersToAdd)
    advancedHelperDebug.log(string.format("ADHOOK: checkAddHelper BLOCKED (vehicle=%s helperIndex=%s numToAdd=%s)",
        vehicle and vehicle:getName() or "nil",
        tostring(helperIndex), tostring(numHelpersToAdd)))
    return nil
end

function advancedHelperAutoDriveHook.startWorkerOnAD(workerId, vehicle)
    if g_server == nil then
        advancedHelperDebug.log("ADHOOK: startWorkerOnAD blocked — client-only call")
        return
    end
    if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
        advancedHelperDebug.log("ADHOOK: startWorkerOnAD blocked — INFILTRATE_AUTODRIVE=false")
        return
    end

    if vehicle == nil then
        advancedHelperDebug.log("ADHOOK: startWorkerOnAD — no vehicle")
        return
    end

    if not advancedHelperAutoDriveHook.hasADSpecialization(vehicle) then
        advancedHelperDebug.log(string.format("ADHOOK: startWorkerOnAD — vehicle %s has no AD specialization",
            vehicle:getName()))
        return
    end

    if vehicle.ad.stateModule:isActive() then
        advancedHelperDebug.log(string.format("ADHOOK: startWorkerOnAD — AD already active on %s", vehicle:getName()))
        return
    end

    local worker = nil
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil then
        advancedHelperDebug.log(string.format("ADHOOK: startWorkerOnAD — worker not found id=%d", workerId))
        return
    end
    if worker.isAssigned then
        advancedHelperDebug.log(string.format("ADHOOK: startWorkerOnAD — %s already assigned", worker:getFullName()))
        return
    end

    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil then
        farmId = g_currentMission:getFarmId()
    end

    if farmId and farmId > 0 then
        vehicle.ad.stateModule:setActualFarmId(farmId)
    end
    vehicle.ad.stateModule:setLoopsDone(0)

    advancedHelperDebug.log(string.format("ADHOOK: startWorkerOnAD — starting AD for %s on %s",
        worker:getFullName(), vehicle:getName()))

    vehicle.ad.stateModule:getCurrentMode():start(AutoDrive.USER_PLAYER or 1)
end

function advancedHelperAutoDriveHook.canStartADOnVehicle(vehicle)
    if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
        return false
    end
    if not advancedHelperAutoDriveHook.isInstalled and not advancedHelperAutoDriveHook.eventListenersInstalled then
        return false
    end
    if not advancedHelperAutoDriveHook.hasADSpecialization(vehicle) then
        return false
    end
    if vehicle.ad.stateModule:isActive() then
        return false
    end
    if ADGraphManager ~= nil then
        if ADGraphManager:getWayPointById(1) == nil then
            return false
        end
    end
    if vehicle.ad.stateModule:getFirstMarker() == nil then
        return false
    end
    return true
end