advancedHelperCourseplayHook = {}

advancedHelperCourseplayHook.COLOR_CP = {0.6, 0.4, 0.2, 0.95}

advancedHelperCourseplayHook.isInstalled = false
advancedHelperCourseplayHook.hookedVehicleTypes = {}
advancedHelperCourseplayHook.activeCPCount = 0
advancedHelperCourseplayHook.CP_SPEC_NAME = "FS25_Courseplay.cpAIWorker"

function advancedHelperCourseplayHook.isCPLoaded()
    return g_modIsLoaded ~= nil and g_modIsLoaded["FS25_Courseplay"]
end

function advancedHelperCourseplayHook.hasCPSpecialization(vehicle)
    if vehicle == nil then
        return false
    end
    return vehicle.spec_cpAIWorker ~= nil
end

function advancedHelperCourseplayHook.vehicleTypeHasCP(vehicleType)
    if vehicleType == nil then
        return false
    end
    if vehicleType.specializationsByName[advancedHelperCourseplayHook.CP_SPEC_NAME] ~= nil then
        return true
    end
    if vehicleType.specializationsByName["cpAIWorker"] ~= nil then
        return true
    end
    for specName, _ in pairs(vehicleType.specializationsByName) do
        local len = string.len(specName)
        local suffix = ".cpAIWorker"
        local suffixLen = string.len(suffix)
        if len >= suffixLen and string.sub(specName, len - suffixLen + 1) == suffix then
            return true
        end
    end
    return false
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

function advancedHelperCourseplayHook.install()
    if advancedHelperCourseplayHook.isInstalled then
        return
    end

    if not advancedHelperCourseplayHook.isCPLoaded() then
        advancedHelperCourseplayHook.isInstalled = true
        return
    end

    if g_vehicleTypeManager == nil then
        return
    end

    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        advancedHelperCourseplayHook.installMinimal()
        return
    end

    advancedHelperCourseplayHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if advancedHelperCourseplayHook.vehicleTypeHasCP(vehicleType) then
            SpecializationUtil.registerEventListener(vehicleType, "onCpFinished", advancedHelperCourseplayHook)
            SpecializationUtil.registerEventListener(vehicleType, "onCpFuelEmpty", advancedHelperCourseplayHook)
            SpecializationUtil.registerEventListener(vehicleType, "onCpBroken", advancedHelperCourseplayHook)
            advancedHelperCourseplayHook.hookedVehicleTypes[typeName] = true
        end
    end

    advancedHelperCourseplayHook.isInstalled = true
    advancedHelperCourseplayHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("CPHOOK: installed observer mode (types=%d)",
        advancedHelperCourseplayHook:countHookedTypes()))
end

function advancedHelperCourseplayHook.installMinimal()
    if g_vehicleTypeManager == nil then
        return
    end

    advancedHelperCourseplayHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if advancedHelperCourseplayHook.vehicleTypeHasCP(vehicleType) then
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

    advancedHelperCourseplayHook.hookedVehicleTypes = {}

    for typeName, vehicleType in pairs(g_vehicleTypeManager.types) do
        if advancedHelperCourseplayHook.vehicleTypeHasCP(vehicleType) then
            SpecializationUtil.registerEventListener(vehicleType, "onCpFinished", advancedHelperCourseplayHook)
            SpecializationUtil.registerEventListener(vehicleType, "onCpFuelEmpty", advancedHelperCourseplayHook)
            SpecializationUtil.registerEventListener(vehicleType, "onCpBroken", advancedHelperCourseplayHook)
            advancedHelperCourseplayHook.hookedVehicleTypes[typeName] = true
        end
    end

    if advancedHelperCourseplayHook:countHookedTypes() == 0 then
        return
    end

    advancedHelperCourseplayHook.eventListenersInstalled = true
    advancedHelperDebug.log(string.format("CPHOOK: event listeners only (types=%d)",
        advancedHelperCourseplayHook:countHookedTypes()))
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

function advancedHelperCourseplayHook.startWorkerOnCP(workerId, vehicle)
    if g_server == nil then
        return
    end
    if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
        return
    end

    if vehicle == nil then
        return
    end

    if not advancedHelperCourseplayHook.hasCPSpecialization(vehicle) then
        return
    end

    if vehicle.getIsCpActive ~= nil and vehicle:getIsCpActive() then
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
        return
    end
    if worker.isAssigned then
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