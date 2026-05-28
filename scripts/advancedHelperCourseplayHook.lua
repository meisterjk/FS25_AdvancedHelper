advancedHelperCourseplayHook = {}

advancedHelperCourseplayHook.COLOR_CP = {0.6, 0.4, 0.2, 0.95}

advancedHelperCourseplayHook.isInstalled = false
advancedHelperCourseplayHook.hookedVehicleTypes = {}
advancedHelperCourseplayHook.activeCPCount = 0

function advancedHelperCourseplayHook.isCPLoaded()
    return g_modIsLoaded ~= nil and g_modIsLoaded["FS25_Courseplay"]
end

function advancedHelperCourseplayHook.hasCPSpecialization(vehicle)
    if vehicle == nil then
        return false
    end
    if g_Courseplay == nil then
        return false
    end
    return vehicle.spec_cpAIWorker ~= nil
end

function advancedHelperCourseplayHook.canStartCPOnVehicle(vehicle)
    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        return false
    end
    if not advancedHelperCourseplayHook.isInstalled then
        return false
    end
    if not advancedHelperCourseplayHook.hasCPSpecialization(vehicle) then
        return false
    end
    if vehicle.getIsCpActive ~= nil and vehicle:getIsCpActive() then
        return false
    end
    if vehicle:getIsAIActive() then
        return false
    end
    if vehicle.hasCpCourse ~= nil and not vehicle:hasCpCourse() then
        return false
    end
    return true
end

-------------------------------------------------------------------------------
-- Install
-------------------------------------------------------------------------------

function advancedHelperCourseplayHook.install()
    if not advancedHelperCourseplayHook.isCPLoaded() then
        advancedHelperDebug.log("CPHOOK: Courseplay not loaded, skipping install")
        return
    end

    if g_vehicleTypeManager == nil then
        return
    end

    if CpAIWorker == nil then
        advancedHelperDebug.log("CPHOOK: CpAIWorker not available, trying event listeners only")
        advancedHelperCourseplayHook.installEventListenersOnly()
        return
    end

    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        advancedHelperCourseplayHook.installMinimal()
        return
    end

    advancedHelperCourseplayHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if SpecializationUtil.hasSpecialization(CpAIWorker, vehicleType.specializations) then
            advancedHelperCourseplayHook:installTypeHooks(vehicleType)
            advancedHelperCourseplayHook.hookedVehicleTypes[typeName] = true
        end
    end

    CpAIWorker.cpStartStopDriver = Utils.overwrittenFunction(
        CpAIWorker.cpStartStopDriver, advancedHelperCourseplayHook.cpStartStopDriverOverride)

    advancedHelperCourseplayHook.isInstalled = true
    advancedHelperCourseplayHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("CPHOOK: installed (infiltrate=true, types=%d)",
        advancedHelperCourseplayHook:countHookedTypes()))
end

function advancedHelperCourseplayHook.installMinimal()
    if g_vehicleTypeManager == nil then
        return
    end

    if CpAIWorker == nil then
        return
    end

    advancedHelperCourseplayHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if SpecializationUtil.hasSpecialization(CpAIWorker, vehicleType.specializations) then
            SpecializationUtil.registerEventListener(vehicleType, "onCpFinished", advancedHelperCourseplayHook)
            advancedHelperCourseplayHook.hookedVehicleTypes[typeName] = true
        end
    end

    advancedHelperCourseplayHook.isInstalled = true
    advancedHelperCourseplayHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("CPHOOK: installed minimal (infiltrate=false, types=%d) — only CP counter",
        advancedHelperCourseplayHook:countHookedTypes()))
end

function advancedHelperCourseplayHook.installEventListenersOnly()
    if advancedHelperCourseplayHook.eventListenersInstalled then
        return
    end
    if not advancedHelperCourseplayHook.isCPLoaded() then
        return
    end
    if g_vehicleTypeManager == nil then
        return
    end
    if CpAIWorker == nil then
        return
    end

    advancedHelperCourseplayHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if SpecializationUtil.hasSpecialization(CpAIWorker, vehicleType.specializations) then
            SpecializationUtil.registerEventListener(vehicleType, "onCpFinished", advancedHelperCourseplayHook)
            SpecializationUtil.registerEventListener(vehicleType, "onCpFuelEmpty", advancedHelperCourseplayHook)
            SpecializationUtil.registerEventListener(vehicleType, "onCpBroken", advancedHelperCourseplayHook)
            advancedHelperCourseplayHook.hookedVehicleTypes[typeName] = true
        end
    end

    advancedHelperCourseplayHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("CPHOOK: event listeners only (types=%d)",
        advancedHelperCourseplayHook:countHookedTypes()))
end

function advancedHelperCourseplayHook:installTypeHooks(vehicleType)
    if vehicleType == nil then
        return
    end

    SpecializationUtil.registerEventListener(vehicleType, "onCpFinished", advancedHelperCourseplayHook)
    SpecializationUtil.registerEventListener(vehicleType, "onCpFuelEmpty", advancedHelperCourseplayHook)
    SpecializationUtil.registerEventListener(vehicleType, "onCpBroken", advancedHelperCourseplayHook)
end

function advancedHelperCourseplayHook.uninstall()
    advancedHelperCourseplayHook.isInstalled = false
    advancedHelperCourseplayHook.eventListenersInstalled = false
    advancedHelperCourseplayHook.hookedVehicleTypes = {}
    advancedHelperCourseplayHook.activeCPCount = 0
    advancedHelperDebug.log("CPHOOK: uninstalled")
end

function advancedHelperCourseplayHook:countHookedTypes()
    local count = 0
    for _ in pairs(advancedHelperCourseplayHook.hookedVehicleTypes) do
        count = count + 1
    end
    return count
end

-------------------------------------------------------------------------------
-- Hook: cpStartStopDriver — block CP start when no free workers
-------------------------------------------------------------------------------

function advancedHelperCourseplayHook.cpStartStopDriverOverride(self, superFunc, isStartedByHud)
    if isStartedByHud and not self:getIsAIActive() then
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
            advancedHelperDebug.log(string.format("CPHOOK: BLOCKED cpStartStopDriver for %s (no free workers for farm %d)",
                self:getName(), farmId or -1))
            return
        end

        advancedHelperDebug.log(string.format("CPHOOK: cpStartStopDriver allowed for %s (free workers=%d)",
            self:getName(), #freeWorkers))
    end

    superFunc(self, isStartedByHud)
end

-------------------------------------------------------------------------------
-- Vehicle Events: onCpFinished / onCpFuelEmpty / onCpBroken
-------------------------------------------------------------------------------

function advancedHelperCourseplayHook:onCpFinished()
    if g_server == nil then
        return
    end
    local vehicle = self

    advancedHelperCourseplayHook.activeCPCount = math.max(0, advancedHelperCourseplayHook.activeCPCount - 1)

    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        advancedHelperDebug.log(string.format("CPHOOK: onCpFinished minimal — count=%d vehicle=%s",
            advancedHelperCourseplayHook.activeCPCount, vehicle:getName()))
        return
    end

    local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    if worker ~= nil then
        local vehName = vehicle:getName()
        worker.isAssigned = false
        worker.assignedVehicle = nil
        worker.assignSource = ""
        advancedHelperSpeedHook.restoreSpeedModification(vehicle)
        if g_server ~= nil then
            advancedHelperSyncEvent.broadcast()
            advancedHelperAPI._fire("workerUnassigned", advancedHelperAPI._copyWorker(worker), vehName)
        end
        advancedHelperDebug.log(string.format("CPHOOK: onCpFinished — unassigned %s from %s",
            worker:getFullName(), vehName))
    else
        advancedHelperDebug.log(string.format("CPHOOK: onCpFinished — no worker found for %s", vehicle:getName()))
    end
end

function advancedHelperCourseplayHook:onCpFuelEmpty()
    if g_server == nil then
        return
    end
    local vehicle = self

    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        return
    end

    local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    if worker ~= nil then
        local vehName = vehicle:getName()
        worker.isAssigned = false
        worker.assignedVehicle = nil
        worker.assignSource = ""
        advancedHelperSpeedHook.restoreSpeedModification(vehicle)
        if g_server ~= nil then
            advancedHelperSyncEvent.broadcast()
            advancedHelperAPI._fire("workerUnassigned", advancedHelperAPI._copyWorker(worker), vehName)
        end
        advancedHelperDebug.log(string.format("CPHOOK: onCpFuelEmpty — unassigned %s from %s",
            worker:getFullName(), vehName))
    end
end

function advancedHelperCourseplayHook:onCpBroken()
    if g_server == nil then
        return
    end
    local vehicle = self

    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        return
    end

    local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    if worker ~= nil then
        local vehName = vehicle:getName()
        worker.isAssigned = false
        worker.assignedVehicle = nil
        worker.assignSource = ""
        advancedHelperSpeedHook.restoreSpeedModification(vehicle)
        if g_server ~= nil then
            advancedHelperSyncEvent.broadcast()
            advancedHelperAPI._fire("workerUnassigned", advancedHelperAPI._copyWorker(worker), vehName)
        end
        advancedHelperDebug.log(string.format("CPHOOK: onCpBroken — unassigned %s from %s",
            worker:getFullName(), vehName))
    end
end

-------------------------------------------------------------------------------
-- Start a worker with Courseplay
-------------------------------------------------------------------------------

function advancedHelperCourseplayHook.startWorkerOnCP(workerId, vehicle)
    if g_server == nil then
        advancedHelperDebug.log("CPHOOK: startWorkerOnCP blocked — client-only call")
        return
    end
    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        advancedHelperDebug.log("CPHOOK: startWorkerOnCP blocked — INFILTRATE_COURSEPLAY=false")
        return
    end

    if vehicle == nil then
        advancedHelperDebug.log("CPHOOK: startWorkerOnCP — no vehicle")
        return
    end

    if not advancedHelperCourseplayHook.hasCPSpecialization(vehicle) then
        advancedHelperDebug.log(string.format("CPHOOK: startWorkerOnCP — vehicle %s has no CP specialization",
            vehicle:getName()))
        return
    end

    if vehicle.getIsCpActive ~= nil and vehicle:getIsCpActive() then
        advancedHelperDebug.log(string.format("CPHOOK: startWorkerOnCP — CP already active on %s", vehicle:getName()))
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
        advancedHelperDebug.log(string.format("CPHOOK: startWorkerOnCP — worker not found id=%d", workerId))
        return
    end
    if worker.isAssigned then
        advancedHelperDebug.log(string.format("CPHOOK: startWorkerOnCP — %s already assigned", worker:getFullName()))
        return
    end

    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil then
        farmId = g_currentMission:getFarmId()
    end

    advancedHelperManager:assignWorkerToVehicle(workerId, vehicle)
    advancedHelperSpeedHook.applySpeedModification(vehicle, worker)

    advancedHelperDebug.log(string.format("CPHOOK: startWorkerOnCP — starting CP for %s on %s",
        worker:getFullName(), vehicle:getName()))

    vehicle:cpStartStopDriver(true)
end