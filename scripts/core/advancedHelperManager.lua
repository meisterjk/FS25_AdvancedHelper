advancedHelperManager = {}
advancedHelperManager.hiredWorkers = {}
advancedHelperManager.applicants = {}
advancedHelperManager.MAX_APPLICANTS = 5
advancedHelperManager.REFRESH_INTERVAL_DAYS = 3
advancedHelperManager.lastRefreshDay = 0
advancedHelperManager.isInitialized = false
advancedHelperManager.baseHelpersRemoved = false
advancedHelperManager.savedMaleStyles = {}
advancedHelperManager.savedFemaleStyles = {}

function advancedHelperManager:isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function advancedHelperManager:getSaveDir()
    if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.savegameDirectory ~= nil then
        return g_currentMission.missionInfo.savegameDirectory .. "/"
    end
    return getUserProfileAppPath() .. "modSettings/FS25_AdvancedHelper/"
end

function advancedHelperManager:loadFromSavegame()
    if #self.hiredWorkers > 0 or #self.applicants > 0 then
        self:refreshUI()
        if self:isServer() then
            advancedHelperSyncEvent.broadcast()
        end
        return
    end

    local savegameDir = g_currentMission.missionInfo.savegameDirectory
    if savegameDir == nil then
        if self:isServer() then
            self:generateApplicants()
            advancedHelperSyncEvent.broadcast()
        end
        return
    end
    local filePath = savegameDir .. "/advancedHelper.xml"
    if not fileExists(filePath) then
        if self:isServer() then
            self:generateApplicants()
            advancedHelperSyncEvent.broadcast()
        end
        return
    end
    local xmlFile = XMLFile.loadIfExists("advancedHelperSavegame", filePath, advancedHelperManager.xmlSchema)
    if xmlFile == nil then
        if self:isServer() then
            self:generateApplicants()
            advancedHelperSyncEvent.broadcast()
        end
        return
    end

    self.hiredWorkers = {}
    self.applicants = {}
    local maxId = 0
    local lastRefreshDay = xmlFile:getInt("advancedHelper#lastRefreshDay") or 0
    local numHired = xmlFile:getInt("advancedHelper#numHired") or 0
    local numApplicants = xmlFile:getInt("advancedHelper#numApplicants") or 0

    advancedHelperHud.loadFromXML(xmlFile, "advancedHelper")

    for i = 0, numHired - 1 do
        local w = advancedHelperWorker.loadFromXML(xmlFile, string.format("advancedHelper.hiredWorker(%d)", i))
        if w.isHired then
            table.insert(self.hiredWorkers, w)
            if w.id > maxId then
                maxId = w.id
            end
        end
    end

    for i = 0, numApplicants - 1 do
        local a = advancedHelperWorker.loadFromXML(xmlFile, string.format("advancedHelper.applicant(%d)", i))
        table.insert(self.applicants, a)
        if a.id > maxId then
            maxId = a.id
        end
    end

    xmlFile:delete()

    advancedHelperWorker._idCounter = maxId
    self.lastRefreshDay = lastRefreshDay

    if self:isServer() then
        self:removeBaseHelpers()
        self:reAddWorkerHelpers()
        if #self.applicants == 0 then
            self:generateApplicants()
        end
        advancedHelperSyncEvent.broadcast()
    end
    self:refreshUI()
end

function advancedHelperManager:init()
    if self.isInitialized then
        return
    end
    self.hiredWorkers = {}
    self.applicants = {}
    self.lastRefreshDay = 0
    self:saveBaseHelperStyles()

    if self:isServer() then
        self:removeBaseHelpers()
        if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.savegameDirectory ~= nil then
            self:loadFromSavegame()
        else
            self:generateApplicants()
        end
    else
        self:removeBaseHelpers()
    end

    self.isInitialized = true
    self.initialized = true
end

function advancedHelperManager:saveBaseHelperStyles()
    self.savedMaleStyles = {}
    self.savedFemaleStyles = {}
    for name, helper in pairs(g_helperManager.helpers) do
        if helper.playerStyle ~= nil then
            local styleCopy = PlayerStyle.new()
            styleCopy:copyFrom(helper.playerStyle)
            if helper.playerStyle.xmlFilename ~= nil and string.find(helper.playerStyle.xmlFilename, "playerF") then
                table.insert(self.savedFemaleStyles, styleCopy)
            else
                table.insert(self.savedMaleStyles, styleCopy)
            end
        end
    end
end

function advancedHelperManager:removeBaseHelpers()
    if self.baseHelpersRemoved then
        return
    end

    g_helperManager.availableHelpers = {}
    local namesToRemove = {}
    for name, helper in pairs(g_helperManager.helpers) do
        table.insert(namesToRemove, name)
    end
    for _, name in ipairs(namesToRemove) do
        g_helperManager.helpers[name] = nil
        if g_helperManager.nameToIndex then
            g_helperManager.nameToIndex[name] = nil
        end
    end
    if g_helperManager.indexToHelper then
        for idx in pairs(g_helperManager.indexToHelper) do
            g_helperManager.indexToHelper[idx] = nil
        end
    end
    g_helperManager.numHelpers = 0

    self.baseHelpersRemoved = true
end

function advancedHelperManager:formatHelperName(worker)
    local function replaceUmlauts(s)
        s = s:gsub("ä", "ae")
        s = s:gsub("ö", "oe")
        s = s:gsub("ü", "ue")
        s = s:gsub("Ä", "Ae")
        s = s:gsub("Ö", "Oe")
        s = s:gsub("Ü", "Ue")
        s = s:gsub("ß", "ss")
        return s
    end

    local name = replaceUmlauts(worker.firstName) .. "_" .. replaceUmlauts(worker.lastName)
    name = string.upper(name)

    local baseName = name
    local counter = 2
    while g_helperManager.helpers[name] ~= nil do
        name = baseName .. "_" .. counter
        counter = counter + 1
    end

    return name
end

function advancedHelperManager:generatePlayerStyle(worker)
    local styleList
    if worker.gender == "F" and #self.savedFemaleStyles > 0 then
        styleList = self.savedFemaleStyles
    elseif worker.gender ~= "F" and #self.savedMaleStyles > 0 then
        styleList = self.savedMaleStyles
    elseif #self.savedMaleStyles > 0 then
        styleList = self.savedMaleStyles
    elseif #self.savedFemaleStyles > 0 then
        styleList = self.savedFemaleStyles
    else
        local fallbackStyle = PlayerStyle.new()
        fallbackStyle.xmlFilename = worker:getPlayerStyleXmlFilename()
        fallbackStyle:loadConfigurationXML(fallbackStyle.xmlFilename)
        fallbackStyle.hairColor = {0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6}
        return fallbackStyle
    end

    local sourceStyle = styleList[math.random(#styleList)]
    local playerStyle = PlayerStyle.new()
    playerStyle:copyFrom(sourceStyle)

    if playerStyle.xmlFilename == nil or playerStyle.xmlFilename == "" then
        playerStyle.xmlFilename = worker:getPlayerStyleXmlFilename()
    end

    if not playerStyle.isConfigurationLoaded then
        playerStyle:loadConfigurationXML(playerStyle.xmlFilename)
    end

    playerStyle:copySelectionFrom(sourceStyle)
    playerStyle.hairColor = {0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6}

    return playerStyle
end

function advancedHelperManager:reAddWorkerHelpers()
    for _, worker in ipairs(self.hiredWorkers) do
        local helperName = self:formatHelperName(worker)
        local color = {0.2, 0.6, 0.9}
        local playerStyle = self:generatePlayerStyle(worker)

        local helper = g_helperManager:addHelper(helperName, worker:getFullName(), color, playerStyle, nil, false)
        if helper then
            worker.helperIndex = helper.index
            worker.helperName = helperName
        end
    end
    g_helperManager.numHelpers = #self.hiredWorkers
end

function advancedHelperManager:getWorkersForFarm(farmId)
    local result = {}
    for _, w in ipairs(self.hiredWorkers) do
        if w.farmId == farmId then
            table.insert(result, w)
        end
    end
    return result
end

function advancedHelperManager:getWorkerCountForFarm(farmId)
    local count = 0
    for _, w in ipairs(self.hiredWorkers) do
        if w.farmId == farmId then
            count = count + 1
        end
    end
    return count
end

function advancedHelperManager:getTotalMonthlyCosts(farmId)
    local total = 0
    for _, w in ipairs(self.hiredWorkers) do
        if farmId == nil or w.farmId == farmId then
            total = total + w.monthlySalary
        end
    end
    return total
end

function advancedHelperManager:getUsedNames()
    local names = {}
    for _, w in ipairs(self.hiredWorkers) do
        names[w:getFullName()] = true
    end
    for _, a in ipairs(self.applicants) do
        names[a:getFullName()] = true
    end
    return names
end

function advancedHelperManager:generateApplicants()
    self.applicants = {}
    local usedNames = self:getUsedNames()
    local count = math.random(3, advancedHelperManager.MAX_APPLICANTS)
    for _ = 1, count do
        local worker = advancedHelperWorker.generateRandom(usedNames)
        table.insert(self.applicants, worker)
        usedNames[worker:getFullName()] = true
    end
end

function advancedHelperManager:refreshUI()
    if advancedHelperGui.workersPage then
        advancedHelperGui.workersPage:updateContent()
    end
end

function advancedHelperManager:hireApplicant(applicantId, farmId)
    if not self:isServer() then
        return false
    end

    local applicant = nil
    local appIndex = nil
    for i, a in ipairs(self.applicants) do
        if a.id == applicantId then
            applicant = a
            appIndex = i
            break
        end
    end
    if applicant == nil then
        return false
    end

    applicant.isHired = true
    applicant.hireDay = g_currentMission.environment.currentDay
    applicant.farmId = farmId or g_currentMission:getFarmId()

    local helperName = self:formatHelperName(applicant)
    local color = {0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6, 0.2 + math.random() * 0.6}
    local playerStyle = self:generatePlayerStyle(applicant)

    local helper = g_helperManager:addHelper(helperName, applicant:getFullName(), color, playerStyle, nil, false)
    if helper then
        applicant.helperIndex = helper.index
        applicant.helperName = helperName
        g_helperManager.numHelpers = #self.hiredWorkers + 1

        table.insert(self.hiredWorkers, applicant)
        table.remove(self.applicants, appIndex)
        g_currentMission:addMoney(-applicant.monthlySalary, applicant.farmId, MoneyType.WORKER_SALARY, true, true)
        self:saveState()
        advancedHelperSyncEvent.broadcast()
        advancedHelperAPI._fire("workerHired", advancedHelperAPI._copyWorker(applicant))
        advancedHelperDebug.log(string.format("HIRE: %s (Eff=%d Fahr=%d Koennen=%d) Farm=%d Gehalt=%d/Monat",
            applicant:getFullName(), applicant.efficiency, applicant.driving, applicant.skill,
            applicant.farmId, applicant.monthlySalary))
        return true
    end

    return false
end

function advancedHelperManager:fireWorker(workerId, farmId)
    if not self:isServer() then
        return false
    end

    local worker = nil
    local wIndex = nil
    for i, w in ipairs(self.hiredWorkers) do
        if w.id == workerId then
            worker = w
            wIndex = i
            break
        end
    end
    if worker == nil then
        return false
    end

    if farmId ~= nil and worker.farmId ~= farmId then
        return false
    end

    if worker.isAssigned and worker.assignedVehicle ~= nil then
        pcall(function()
            worker.assignedVehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
        end)
        worker.isAssigned = false
        worker.assignedVehicle = nil
        worker.assignSource = ""
    end

    local helperName = worker.helperName
    if helperName ~= nil then
        local upperName = helperName:upper()

        for i, h in ipairs(g_helperManager.availableHelpers) do
            if h.name == upperName then
                table.remove(g_helperManager.availableHelpers, i)
                break
            end
        end

        g_helperManager.helpers[upperName] = nil
        if g_helperManager.nameToIndex then
            g_helperManager.nameToIndex[upperName] = nil
        end
        if g_helperManager.indexToHelper and worker.helperIndex then
            g_helperManager.indexToHelper[worker.helperIndex] = nil
        end
    end

    table.remove(self.hiredWorkers, wIndex)
    g_helperManager.numHelpers = #self.hiredWorkers

    self:saveState()
    advancedHelperSyncEvent.broadcast()
    advancedHelperAPI._fire("workerFired", advancedHelperAPI._copyWorker(worker))
    advancedHelperDebug.log(string.format("FIRE: %s Farm=%d", worker:getFullName(), worker.farmId))
    return true
end

function advancedHelperManager:getWorkerByHelperIndex(helperIndex)
    if helperIndex == nil then
        return nil
    end
    for _, w in ipairs(self.hiredWorkers) do
        if w.helperIndex == helperIndex then
            return w
        end
    end
    return nil
end

function advancedHelperManager:getWorkerForVehicle(vehicle)
    if vehicle == nil then
        return nil
    end
    for _, w in ipairs(self.hiredWorkers) do
        if w.assignedVehicle == vehicle then
            return w
        end
    end
    local spec = vehicle.spec_aiJobVehicle
    if spec ~= nil and spec.currentHelper ~= nil then
        return self:getWorkerByHelperIndex(spec.currentHelper.index)
    end
    if vehicle.getCurrentHelper ~= nil then
        local helper = vehicle:getCurrentHelper()
        if helper ~= nil then
            return self:getWorkerByHelperIndex(helper.index)
        end
    end
    return nil
end

function advancedHelperManager:getFreeWorkersForFarm(farmId)
    local result = {}
    for _, w in ipairs(self.hiredWorkers) do
        if w.farmId == farmId and not w.isAssigned then
            table.insert(result, w)
        end
    end
    return result
end

function advancedHelperManager:assignWorkerToVehicle(workerId, vehicle)
    local worker = nil
    for _, w in ipairs(self.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil then
        return false
    end
    if worker.isAssigned then
        return false
    end
    if vehicle == nil then
        return false
    end
    for _, w in ipairs(self.hiredWorkers) do
        if w.assignedVehicle == vehicle and w.id ~= worker.id then
            advancedHelperDebug.log(string.format("ASSIGN: releasing previous worker %s from %s",
                w:getFullName(), vehicle:getName()))
            w.isAssigned = false
            w.assignedVehicle = nil
            w.assignSource = ""
        end
    end
    worker.isAssigned = true
    worker.assignedVehicle = vehicle
    advancedHelperDebug.log(string.format("ASSIGN: %s -> %s", worker:getFullName(), vehicle:getName()))
    if self:isServer() then
        advancedHelperSyncEvent.broadcast()
        advancedHelperAPI._fire("workerAssigned", advancedHelperAPI._copyWorker(worker), vehicle:getName())
    end
    return true
end

function advancedHelperManager:unassignWorker(workerId)
    local worker = nil
    for _, w in ipairs(self.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil then
        return false
    end
    local vehName = worker.assignedVehicle and worker.assignedVehicle:getName() or "none"
    advancedHelperDebug.log(string.format("UNASSIGN: %s (was: %s)", worker:getFullName(), vehName))
    worker.isAssigned = false
    worker.assignedVehicle = nil
    worker.assignSource = ""
    if self:isServer() then
        advancedHelperSyncEvent.broadcast()
        advancedHelperAPI._fire("workerUnassigned", advancedHelperAPI._copyWorker(worker), vehName)
    end
    return true
end

function advancedHelperManager:unassignWorkerByVehicle(vehicle)
    if vehicle == nil then
        return false
    end
    local found = false
    local vehName = vehicle:getName()
    for _, w in ipairs(self.hiredWorkers) do
        if w.assignedVehicle == vehicle then
            w.isAssigned = false
            w.assignedVehicle = nil
            w.assignSource = ""
            advancedHelperDebug.log(string.format("UNASSIGN: %s (vehicle %s stopped)", w:getFullName(), vehName))
            if self:isServer() then
                advancedHelperAPI._fire("workerUnassigned", advancedHelperAPI._copyWorker(w), vehName)
            end
            found = true
        end
    end
    if found and self:isServer() then
        advancedHelperSyncEvent.broadcast()
    end
    return found
end

function advancedHelperManager:updateDay()
    if not self:isServer() then
        return
    end
    local currentDay = g_currentMission.environment.currentDay
    local daysSinceRefresh = currentDay - self.lastRefreshDay
    if daysSinceRefresh >= advancedHelperManager.REFRESH_INTERVAL_DAYS or self.lastRefreshDay == 0 then
        self:generateApplicants()
        self.lastRefreshDay = currentDay
        self:saveState()
        advancedHelperSyncEvent.broadcast()
    end
end

function advancedHelperManager:saveState()
    if not self:isServer() then
        return
    end
    local saveDir = self:getSaveDir()
    createFolder(saveDir)
    local filePath = saveDir .. "advancedHelper.xml"
    local xmlFile = XMLFile.create("advancedHelperState", filePath, "advancedHelper", advancedHelperManager.xmlSchema)
    if xmlFile == nil then
        return
    end

    xmlFile:setInt("advancedHelper#lastRefreshDay", self.lastRefreshDay)
    xmlFile:setInt("advancedHelper#numHired", #self.hiredWorkers)
    xmlFile:setInt("advancedHelper#numApplicants", #self.applicants)

    advancedHelperHud.saveToXML(xmlFile, "advancedHelper")

    for i, w in ipairs(self.hiredWorkers) do
        w:saveToXML(xmlFile, string.format("advancedHelper.hiredWorker(%d)", i - 1))
    end

    for i, a in ipairs(self.applicants) do
        a:saveToXML(xmlFile, string.format("advancedHelper.applicant(%d)", i - 1))
    end

    xmlFile:save()
    xmlFile:delete()
end

function advancedHelperManager:buildSyncData()
    local data = {}
    data.lastRefreshDay = self.lastRefreshDay
    data.hiredWorkers = {}
    data.applicants = {}

    for _, w in ipairs(self.hiredWorkers) do
        local wd = {
            id = w.id,
            firstName = w.firstName,
            lastName = w.lastName,
            gender = w.gender,
            efficiency = w.efficiency,
            driving = w.driving,
            skill = w.skill,
            monthlySalary = w.monthlySalary,
            hireDay = w.hireDay,
            farmId = w.farmId,
            isAssigned = w.isAssigned,
            assignSource = w.assignSource or "",
            assignedVehicleId = nil
        }
        if w.isAssigned and w.assignedVehicle ~= nil then
            wd.assignedVehicleId = NetworkUtil.getObjectId(w.assignedVehicle)
        end
        table.insert(data.hiredWorkers, wd)
    end

    for _, a in ipairs(self.applicants) do
        table.insert(data.applicants, {
            id = a.id,
            firstName = a.firstName,
            lastName = a.lastName,
            gender = a.gender,
            efficiency = a.efficiency,
            driving = a.driving,
            skill = a.skill,
            monthlySalary = a.monthlySalary
        })
    end

    return data
end

function advancedHelperManager:applySyncState(data)
    if data == nil then
        return
    end

    self.hiredWorkers = {}
    self.applicants = {}
    self.lastRefreshDay = data.lastRefreshDay or 0

    local maxId = 0

    for _, wd in ipairs(data.hiredWorkers or {}) do
        local w = advancedHelperWorker.new()
        w.id = wd.id
        w.firstName = wd.firstName or ""
        w.lastName = wd.lastName or ""
        w.gender = wd.gender or "M"
        w.efficiency = wd.efficiency or 5
        w.driving = wd.driving or 5
        w.skill = wd.skill or 5
        w.monthlySalary = wd.monthlySalary or advancedHelperWorker.BASE_SALARY
        w.isHired = true
        w.hireDay = wd.hireDay or 0
        w.farmId = wd.farmId or FarmManager.SINGLEPLAYER_FARM_ID
        w.isAssigned = wd.isAssigned or false
        w.assignSource = wd.assignSource or ""
        w.assignedVehicle = nil
        w.helperIndex = nil
        w.helperName = nil

        if w.isAssigned and wd.assignedVehicleId ~= nil then
            local vehicle = NetworkUtil.getObject(wd.assignedVehicleId)
            if vehicle ~= nil then
                w.assignedVehicle = vehicle
            else
                w.isAssigned = false
            end
        end

        if w.id > maxId then
            maxId = w.id
        end

        table.insert(self.hiredWorkers, w)
    end

    for _, ad in ipairs(data.applicants or {}) do
        local a = advancedHelperWorker.new()
        a.id = ad.id
        a.firstName = ad.firstName or ""
        a.lastName = ad.lastName or ""
        a.gender = ad.gender or "M"
        a.efficiency = ad.efficiency or 5
        a.driving = ad.driving or 5
        a.skill = ad.skill or 5
        a.monthlySalary = ad.monthlySalary or advancedHelperWorker.BASE_SALARY
        a.isHired = false
        a.hireDay = 0
        a.farmId = FarmManager.SINGLEPLAYER_FARM_ID
        a.isAssigned = false
        a.assignedVehicle = nil
        a.helperIndex = nil
        a.helperName = nil

        if a.id > maxId then
            maxId = a.id
        end

        table.insert(self.applicants, a)
    end

    advancedHelperWorker._idCounter = maxId
    self:refreshUI()
    advancedHelperDebug.log(string.format("SYNC: %d workers, %d applicants, lastRefreshDay=%d",
        #self.hiredWorkers, #self.applicants, self.lastRefreshDay))
    local syncData = {
        hiredWorkers = {},
        applicants = {},
        lastRefreshDay = self.lastRefreshDay,
    }
    for _, w in ipairs(self.hiredWorkers) do
        table.insert(syncData.hiredWorkers, advancedHelperAPI._copyWorker(w))
    end
    for _, a in ipairs(self.applicants) do
        table.insert(syncData.applicants, advancedHelperAPI._copyWorker(a))
    end
    advancedHelperAPI._fire("syncReceived", syncData)
end

advancedHelperManager.xmlSchema = XMLSchema.new("advancedHelper")
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper#lastRefreshDay", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper#numHired", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper#numApplicants", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.FLOAT, "advancedHelper#hudX", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.FLOAT, "advancedHelper#hudY", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#id", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.hiredWorker(?)#firstName", "")
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.hiredWorker(?)#lastName", "")
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.hiredWorker(?)#gender", "M")
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#efficiency", 5)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#driving", 5)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#skill", 5)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#monthlySalary", 1500)
advancedHelperManager.xmlSchema:register(XMLValueType.BOOL, "advancedHelper.hiredWorker(?)#isHired", false)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#hireDay", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#helperIndex", -1)
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.hiredWorker(?)#helperName", "")
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.hiredWorker(?)#farmId", FarmManager.SINGLEPLAYER_FARM_ID)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.applicant(?)#id", 0)
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.applicant(?)#firstName", "")
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.applicant(?)#lastName", "")
advancedHelperManager.xmlSchema:register(XMLValueType.STRING, "advancedHelper.applicant(?)#gender", "M")
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.applicant(?)#efficiency", 5)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.applicant(?)#driving", 5)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.applicant(?)#skill", 5)
advancedHelperManager.xmlSchema:register(XMLValueType.INT, "advancedHelper.applicant(?)#monthlySalary", 1500)