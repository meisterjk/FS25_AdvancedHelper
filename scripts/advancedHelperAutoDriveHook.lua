advancedHelperAutoDriveHook = {}

advancedHelperAutoDriveHook.isInstalled = false
advancedHelperAutoDriveHook.hookedVehicleTypes = {}
advancedHelperAutoDriveHook.activeADCount = 0
advancedHelperAutoDriveHook.vehiclesToStop = {}
advancedHelperAutoDriveHook.AD_SPEC_NAME = "FS25_AutoDrive.AutoDrive"

function advancedHelperAutoDriveHook.isADLoaded()
    return g_modIsLoaded ~= nil and g_modIsLoaded["FS25_AutoDrive"]
end

function advancedHelperAutoDriveHook.hasADSpecialization(vehicle)
    if vehicle == nil then
        return false
    end
    return vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil
end

function advancedHelperAutoDriveHook.vehicleTypeHasAD(vehicleType)
    if vehicleType == nil then
        return false
    end
    if vehicleType.specializationsByName[advancedHelperAutoDriveHook.AD_SPEC_NAME] ~= nil then
        return true
    end
    if vehicleType.specializationsByName["AutoDrive"] ~= nil then
        return true
    end
    for _, spec in pairs(vehicleType.specializations) do
        if type(spec) == "table" and spec.ADSpecName ~= nil then
            return true
        end
    end
    return false
end

function advancedHelperAutoDriveHook.install()
    if advancedHelperAutoDriveHook.isInstalled then
        return
    end

    if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
        advancedHelperAutoDriveHook.installMinimal()
        return
    end

    if not advancedHelperAutoDriveHook.isADLoaded() then
        advancedHelperAutoDriveHook.isInstalled = true
        return
    end

    if g_vehicleTypeManager == nil then
        return
    end

    advancedHelperAutoDriveHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if advancedHelperAutoDriveHook.vehicleTypeHasAD(vehicleType) then
            SpecializationUtil.registerEventListener(vehicleType, "onStartAutoDrive", advancedHelperAutoDriveHook)
            SpecializationUtil.registerEventListener(vehicleType, "onStopAutoDrive", advancedHelperAutoDriveHook)
            advancedHelperAutoDriveHook.hookedVehicleTypes[typeName] = true
        end
    end

    advancedHelperAutoDriveHook.isInstalled = true
    advancedHelperAutoDriveHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("ADHOOK: installed observer mode (types=%d)",
        advancedHelperAutoDriveHook:countHookedTypes()))
end

function advancedHelperAutoDriveHook.installMinimal()
    if not advancedHelperAutoDriveHook.isADLoaded() then
        return
    end

    if g_vehicleTypeManager == nil then
        return
    end

    advancedHelperAutoDriveHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if advancedHelperAutoDriveHook.vehicleTypeHasAD(vehicleType) then
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
        if advancedHelperAutoDriveHook.vehicleTypeHasAD(vehicleType) then
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

function advancedHelperAutoDriveHook.uninstall()
    advancedHelperAutoDriveHook.isInstalled = false
    advancedHelperAutoDriveHook.eventListenersInstalled = false
    advancedHelperAutoDriveHook.hookedVehicleTypes = {}
    advancedHelperAutoDriveHook.activeADCount = 0
    advancedHelperAutoDriveHook.vehiclesToStop = {}
    advancedHelperDebug.log("ADHOOK: uninstalled")
end

function advancedHelperAutoDriveHook:countHookedTypes()
    local count = 0
    for _ in pairs(advancedHelperAutoDriveHook.hookedVehicleTypes) do
        count = count + 1
    end
    return count
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
            for _, w in ipairs(advancedHelperManager.hiredWorkers) do
                if w.assignedVehicle == vehicle and w.id ~= worker.id then
                    advancedHelperDebug.log(string.format("ADHOOK: releasing previous worker %s from %s",
                        w:getFullName(), vehicle:getName()))
                    w.isAssigned = false
                    w.assignedVehicle = nil
                    w.assignSource = ""
                end
            end
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
        advancedHelperHotspot:createHotspot(vehicle, worker, "AD")
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
        advancedHelperAutoDriveHook.activeADCount = math.max(0, advancedHelperAutoDriveHook.activeADCount - 1)
        table.insert(advancedHelperAutoDriveHook.vehiclesToStop, vehicle)
        advancedHelperDebug.log(string.format("ADHOOK: BLOCKED onStartAutoDrive — no free worker for vehicle=%s, deferred stop",
            vehicle:getName()))
        if g_currentMission ~= nil then
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
                g_i18n:getText("advancedHelper_allWorkersBusy"))
        end
        advancedHelperSyncEvent.broadcast()
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
    advancedHelperHotspot:removeHotspot(vehicle)
    advancedHelperSyncEvent.broadcast()
end

function advancedHelperAutoDriveHook.processDeferredStops()
    if #advancedHelperAutoDriveHook.vehiclesToStop == 0 then
        return
    end
    local vehicles = advancedHelperAutoDriveHook.vehiclesToStop
    advancedHelperAutoDriveHook.vehiclesToStop = {}
    for _, vehicle in ipairs(vehicles) do
        if vehicle.ad ~= nil and vehicle.ad.stateModule ~= nil and vehicle.ad.stateModule:isActive() then
            vehicle.ad.isStoppingWithError = true
            vehicle:stopAutoDrive()
            advancedHelperDebug.log(string.format("ADHOOK: deferred stop executed for %s", vehicle:getName()))
        end
    end
end