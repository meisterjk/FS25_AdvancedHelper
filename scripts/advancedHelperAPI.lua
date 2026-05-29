advancedHelperAPI = {
    _version = "0.4.0",
    _listeners = {},
}

-------------------------------------------------------------------------------
-- Internal: create a safe, flat copy of a worker object for external use.
-- No internal references (no vehicle objects, no metatable).
-------------------------------------------------------------------------------
function advancedHelperAPI._copyWorker(worker)
    if worker == nil then
        return nil
    end
    return {
        id = worker.id,
        firstName = worker.firstName or "",
        lastName = worker.lastName or "",
        gender = worker.gender or "M",
        efficiency = worker.efficiency or 5,
        driving = worker.driving or 5,
        skill = worker.skill or 5,
        monthlySalary = worker.monthlySalary or advancedHelperWorker.BASE_SALARY,
        hireDay = worker.hireDay or 0,
        farmId = worker.farmId or FarmManager.SINGLEPLAYER_FARM_ID,
        isHired = worker.isHired or false,
        isAssigned = worker.isAssigned or false,
        assignSource = worker.assignSource or "",
        helperIndex = worker.helperIndex,
        assignedVehicleName = (worker.assignedVehicle ~= nil and worker.assignedVehicle.getName ~= nil)
            and worker.assignedVehicle:getName() or nil,
    }
end

-------------------------------------------------------------------------------
-- Internal: fire a registered callback event.
-------------------------------------------------------------------------------
function advancedHelperAPI._fire(eventName, ...)
    local cbs = advancedHelperAPI._listeners[eventName]
    if cbs == nil then
        return
    end
    for _, cb in ipairs(cbs) do
        local ok, err = pcall(cb, ...)
        if not ok then
            advancedHelperDebug.log(string.format("API CALLBACK ERROR [%s]: %s", eventName, tostring(err)))
        end
    end
end

-------------------------------------------------------------------------------
-- Metadata
-------------------------------------------------------------------------------

--- Check if FS25_AdvancedHelper mod is loaded and ready.
-- @return bool
function advancedHelperAPI.isLoaded()
    return advancedHelperManager ~= nil and advancedHelperManager.initialized == true
end

--- Get mod version string.
-- @return string e.g. "1.0.0.0"
function advancedHelperAPI.getVersion()
    return advancedHelperAPI._version
end

--- Check if the mod is active in the current mission.
-- Requires g_currentMission and initialized manager.
-- @return bool
function advancedHelperAPI.isActive()
    return g_currentMission ~= nil and advancedHelperAPI.isLoaded()
end

-------------------------------------------------------------------------------
-- Query: read-only access to worker data (returns flat copies)
-------------------------------------------------------------------------------

--- Get all hired workers, optionally filtered by farmId.
-- @param farmId int? (optional) filter by farm
-- @return table array of worker data tables
function advancedHelperAPI.getHiredWorkers(farmId)
    if not advancedHelperAPI.isActive() then
        return {}
    end
    local result = {}
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if farmId == nil or w.farmId == farmId then
            table.insert(result, advancedHelperAPI._copyWorker(w))
        end
    end
    return result
end

--- Get free (unassigned) workers, optionally filtered by farmId.
-- @param farmId int? (optional) filter by farm
-- @return table array of worker data tables
function advancedHelperAPI.getFreeWorkers(farmId)
    if not advancedHelperAPI.isActive() then
        return {}
    end
    local result = {}
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if (farmId == nil or w.farmId == farmId) and not w.isAssigned then
            table.insert(result, advancedHelperAPI._copyWorker(w))
        end
    end
    return result
end

--- Get assigned workers, optionally filtered by farmId.
-- @param farmId int? (optional) filter by farm
-- @return table array of worker data tables
function advancedHelperAPI.getAssignedWorkers(farmId)
    if not advancedHelperAPI.isActive() then
        return {}
    end
    local result = {}
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if (farmId == nil or w.farmId == farmId) and w.isAssigned then
            table.insert(result, advancedHelperAPI._copyWorker(w))
        end
    end
    return result
end

--- Get current applicants, optionally filtered by farmId.
-- @param farmId int? (optional) filter by farm
-- @return table array of applicant data tables
function advancedHelperAPI.getApplicants(farmId)
    if not advancedHelperAPI.isActive() then
        return {}
    end
    local result = {}
    for _, a in ipairs(advancedHelperManager.applicants) do
        if farmId == nil or a.farmId == farmId then
            table.insert(result, advancedHelperAPI._copyWorker(a))
        end
    end
    return result
end

--- Get a single worker by ID.
-- @param workerId int
-- @return table/nil worker data table (copy) or nil if not found
function advancedHelperAPI.getWorkerById(workerId)
    if not advancedHelperAPI.isActive() or workerId == nil then
        return nil
    end
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if w.id == workerId then
            return advancedHelperAPI._copyWorker(w)
        end
    end
    return nil
end

--- Get a worker by helper index (links Giants helper system to FS25_AdvancedHelper).
-- @param helperIndex int
-- @return table/nil worker data table (copy) or nil if not found
function advancedHelperAPI.getWorkerByHelperIndex(helperIndex)
    if not advancedHelperAPI.isActive() or helperIndex == nil then
        return nil
    end
    local w = advancedHelperManager:getWorkerByHelperIndex(helperIndex)
    return advancedHelperAPI._copyWorker(w)
end

--- Get the worker assigned to a specific vehicle.
-- @param vehicle table the vehicle object
-- @return table/nil worker data table (copy) or nil if not found
function advancedHelperAPI.getWorkerForVehicle(vehicle)
    if not advancedHelperAPI.isActive() or vehicle == nil then
        return nil
    end
    local w = advancedHelperManager:getWorkerForVehicle(vehicle)
    return advancedHelperAPI._copyWorker(w)
end

--- Get the total number of hired workers, optionally filtered by farmId.
-- @param farmId int? (optional) filter by farm
-- @return int
function advancedHelperAPI.getWorkerCount(farmId)
    if not advancedHelperAPI.isActive() then
        return 0
    end
    if farmId ~= nil then
        return advancedHelperManager:getWorkerCountForFarm(farmId)
    end
    return #advancedHelperManager.hiredWorkers
end

-------------------------------------------------------------------------------
-- Actions: start/stop workers via events (MP-safe)
-------------------------------------------------------------------------------

--- Start a specific worker on a vehicle (assign + start AI job).
-- Sends advancedHelperStartAIEvent — works in SP and MP.
-- @param workerId int the worker's id
-- @param vehicle table the vehicle object
-- @param farmId int the farm requesting the action
-- @return bool true if event was sent
function advancedHelperAPI.startWorker(workerId, vehicle, farmId)
    if not advancedHelperAPI.isActive() then
        return false
    end
    if workerId == nil or vehicle == nil or farmId == nil then
        return false
    end
    local worker = nil
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil or worker.isAssigned then
        return false
    end
    advancedHelperStartAIEvent.sendEvent(vehicle, workerId, farmId)
    return true
end

--- Start the first free worker on a vehicle.
-- @param vehicle table the vehicle object
-- @param farmId int the farm requesting the action
-- @return int/nil worker id if a free worker was found and event sent, nil otherwise
function advancedHelperAPI.startFreeWorker(vehicle, farmId)
    if not advancedHelperAPI.isActive() then
        return nil
    end
    if vehicle == nil or farmId == nil then
        return nil
    end
    local freeWorkers = advancedHelperManager:getFreeWorkersForFarm(farmId)
    if #freeWorkers == 0 then
        return nil
    end
    advancedHelperStartAIEvent.sendEvent(vehicle, freeWorkers[1].id, farmId)
    return freeWorkers[1].id
end

--- Stop the worker currently assigned to a vehicle.
-- @param vehicle table the vehicle object
-- @return bool true if a worker was assigned and stop was initiated
function advancedHelperAPI.stopWorkerByVehicle(vehicle)
    if not advancedHelperAPI.isActive() or vehicle == nil then
        return false
    end
    local worker = advancedHelperManager:getWorkerForVehicle(vehicle)
    if worker == nil then
        return false
    end
    if g_server ~= nil then
        vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
    else
        g_client:getServerConnection():sendEvent(
            AIJobStopRequestEvent.new(vehicle, AIMessageSuccessStoppedByUser.new()))
    end
    return true
end

--- Stop a worker by ID. Finds the assigned vehicle and stops the AI job.
-- @param workerId int
-- @return bool true if worker was assigned and stop initiated
function advancedHelperAPI.stopWorker(workerId)
    if not advancedHelperAPI.isActive() or workerId == nil then
        return false
    end
    local worker = nil
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil or not worker.isAssigned or worker.assignedVehicle == nil then
        return false
    end
    local vehicle = worker.assignedVehicle
    if g_server ~= nil then
        vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
    else
        g_client:getServerConnection():sendEvent(
            AIJobStopRequestEvent.new(vehicle, AIMessageSuccessStoppedByUser.new()))
    end
    return true
end

--- Hire an applicant.
-- @param applicantId int the applicant's id
-- @param farmId int the farm hiring
-- @return bool true if event was sent
function advancedHelperAPI.hireApplicant(applicantId, farmId)
    if not advancedHelperAPI.isActive() then
        return false
    end
    if applicantId == nil or farmId == nil then
        return false
    end
    advancedHelperHireEvent.sendEvent(applicantId, farmId)
    return true
end

--- Fire a worker.
-- @param workerId int the worker's id
-- @param farmId int the farm firing
-- @return bool true if event was sent
function advancedHelperAPI.fireWorker(workerId, farmId)
    if not advancedHelperAPI.isActive() then
        return false
    end
    if workerId == nil or farmId == nil then
        return false
    end
    advancedHelperFireEvent.sendEvent(workerId, farmId)
    return true
end

--- Generate new applicants (refresh).
-- @return bool true if event was sent
function advancedHelperAPI.refreshApplicants()
    if not advancedHelperAPI.isActive() then
        return false
    end
    advancedHelperRefreshEvent.sendEvent()
    return true
end

--- Start a specific worker on a vehicle with Courseplay.
-- Assigns worker to vehicle, applies speed modification, then starts CP driver.
-- @param workerId int the worker's id
-- @param vehicle table the vehicle object (must have CP specialization)
-- @param farmId int the farm requesting the action
-- @return bool true if worker was assigned and CP start was called
function advancedHelperAPI.startWorkerOnCP(workerId, vehicle, farmId)
    if not advancedHelperAPI.isActive() then
        return false
    end
    if workerId == nil or vehicle == nil or farmId == nil then
        return false
    end
    if not advancedHelperCourseplayHook.canStartCPOnVehicle(vehicle) then
        return false
    end
    local worker = nil
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil or worker.isAssigned then
        return false
    end
    advancedHelperCourseplayHook.startWorkerOnCP(workerId, vehicle)
    return true
end

-------------------------------------------------------------------------------
-- Callbacks: subscribe/unsubscribe to worker state events
-------------------------------------------------------------------------------

--- Subscribe to a worker event.
-- Available events:
--   "workerHired"          - fired after a worker is hired.          Args: (workerData)
--   "workerFired"          - fired after a worker is fired.          Args: (workerData)
--   "workerAssigned"       - fired after a worker is assigned.       Args: (workerData, vehicleName)
--   "workerUnassigned"     - fired after a worker is unassigned.     Args: (workerData, vehicleName)
--   "applicantsRefreshed"  - fired after applicants are regenerated.  Args: (applicantsList)
--   "syncReceived"         - fired after MP sync state is applied.    Args: (fullState)
--
-- @param eventName string one of the event names above
-- @param callback function the callback to register
function advancedHelperAPI.subscribe(eventName, callback)
    if eventName == nil or callback == nil then
        return
    end
    if advancedHelperAPI._listeners[eventName] == nil then
        advancedHelperAPI._listeners[eventName] = {}
    end
    table.insert(advancedHelperAPI._listeners[eventName], callback)
end

--- Unsubscribe a previously registered callback.
-- @param eventName string
-- @param callback function the exact function reference to remove
function advancedHelperAPI.unsubscribe(eventName, callback)
    if eventName == nil or callback == nil then
        return
    end
    local cbs = advancedHelperAPI._listeners[eventName]
    if cbs == nil then
        return
    end
    table.removeElement(cbs, callback)
end