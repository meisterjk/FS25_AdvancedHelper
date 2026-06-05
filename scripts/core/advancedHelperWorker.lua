advancedHelperWorker = {}
advancedHelperWorker_mt = Class(advancedHelperWorker)

advancedHelperWorker.NAMES_MALE = {"Hans","Peter","Klaus","Werner","Günther","Dieter","Helmut","Jürgen","Manfred","Rolf"}
advancedHelperWorker.NAMES_FEMALE = {"Anna","Maria","Helga","Ingrid","Brigitte","Ursula","Karin","Renate","Monika","Petra"}
advancedHelperWorker.NAMES_LAST_DE = {"Müller","Schmidt","Schneider","Fischer","Weber","Meyer","Wagner","Becker","Schulz","Hoffmann","Koch","Richter","Klein","Wolf","Schröder"}

advancedHelperWorker.ATTR_MIN = 1
advancedHelperWorker.ATTR_MAX = 10

advancedHelperWorker.BASE_SALARY = 1500

function advancedHelperWorker.new(custom_mt)
    local self = {}
    setmetatable(self, custom_mt or advancedHelperWorker_mt)

    self.id = advancedHelperWorker._nextId()
    self.firstName = ""
    self.lastName = ""
    self.gender = "M"
    self.efficiency = 5
    self.driving = 5
    self.skill = 5
    self.monthlySalary = advancedHelperWorker.BASE_SALARY
    self.isHired = false
    self.hireDay = 0
    self.helperIndex = nil
    self.helperName = nil
    self.farmId = FarmManager.SINGLEPLAYER_FARM_ID
    self.isAssigned = false
    self.assignedVehicle = nil
    self.assignSource = ""

    return self
end

function advancedHelperWorker._nextId()
    if advancedHelperWorker._idCounter == nil then
        advancedHelperWorker._idCounter = 0
    end
    advancedHelperWorker._idCounter = advancedHelperWorker._idCounter + 1
    return advancedHelperWorker._idCounter
end

function advancedHelperWorker.generateRandom()
    local w = advancedHelperWorker.new()
    local isMale = math.random() > 0.5
    w.gender = isMale and "M" or "F"
    if isMale then
        w.firstName = advancedHelperWorker.NAMES_MALE[math.random(#advancedHelperWorker.NAMES_MALE)]
    else
        w.firstName = advancedHelperWorker.NAMES_FEMALE[math.random(#advancedHelperWorker.NAMES_FEMALE)]
    end
    w.lastName = advancedHelperWorker.NAMES_LAST_DE[math.random(#advancedHelperWorker.NAMES_LAST_DE)]
    w.efficiency = math.random(advancedHelperWorker.ATTR_MIN, advancedHelperWorker.ATTR_MAX)
    w.driving = math.random(advancedHelperWorker.ATTR_MIN, advancedHelperWorker.ATTR_MAX)
    w.skill = math.random(advancedHelperWorker.ATTR_MIN, advancedHelperWorker.ATTR_MAX)
    w.monthlySalary = advancedHelperWorker.calculateSalary(w.efficiency, w.driving, w.skill)
    return w
end

function advancedHelperWorker.calculateSalary(efficiency, driving, skill)
    local attrSum = efficiency + driving + skill
    local minSum = advancedHelperWorker.ATTR_MIN * 3
    local maxSum = advancedHelperWorker.ATTR_MAX * 3
    local qualityRatio = (attrSum - minSum) / (maxSum - minSum)
    local difficultyMult = advancedHelperWorker.getDifficultySalaryMultiplier()
    local salary = advancedHelperWorker.BASE_SALARY * (0.5 + qualityRatio * 1.5) * difficultyMult
    return MathUtil.round(salary)
end

function advancedHelperWorker.getDifficultySalaryMultiplier()
    if g_currentMission == nil or g_currentMission.missionInfo == nil then
        return 1.0
    end
    local econDiff = g_currentMission.missionInfo.economicDifficulty or 2
    if econDiff == 1 then
        return 0.7
    elseif econDiff == 2 then
        return 1.0
    else
        return 1.5
    end
end

function advancedHelperWorker:getFuelMultiplier()
    local maxPct = advancedHelperConfig.FUEL_MAX_PERCENT / 100
    local deviation = 5 - self.efficiency
    if deviation >= 0 then
        return 1.0 + (deviation / 4) * maxPct
    else
        return 1.0 + (deviation / 5) * maxPct
    end
end

function advancedHelperWorker:getSpeedMultiplier()
    local maxPct = advancedHelperConfig.SPEED_MAX_PERCENT / 100
    local factor = (10 - self.driving) / 9
    return 1.0 - factor * maxPct
end

function advancedHelperWorker:getWearMultiplier()
    local maxPct = advancedHelperConfig.WEAR_MAX_PERCENT / 100
    local deviation = 5 - self.skill
    if deviation >= 0 then
        return 1.0 + (deviation / 4) * maxPct
    else
        return 1.0 + (deviation / 5) * maxPct
    end
end

function advancedHelperWorker:getFullName()
    return self.firstName .. " " .. self.lastName
end

function advancedHelperWorker:getPlayerStyleXmlFilename()
    if self.gender == "F" then
        return "dataS/character/playerF/playerF.xml"
    end
    return "dataS/character/playerM/playerM.xml"
end

function advancedHelperWorker:saveToXML(xmlFile, key)
    xmlFile:setInt(key .. "#id", self.id)
    xmlFile:setString(key .. "#firstName", self.firstName)
    xmlFile:setString(key .. "#lastName", self.lastName)
    xmlFile:setString(key .. "#gender", self.gender)
    xmlFile:setInt(key .. "#efficiency", self.efficiency)
    xmlFile:setInt(key .. "#driving", self.driving)
    xmlFile:setInt(key .. "#skill", self.skill)
    xmlFile:setInt(key .. "#monthlySalary", self.monthlySalary)
    xmlFile:setBool(key .. "#isHired", self.isHired)
    xmlFile:setInt(key .. "#hireDay", self.hireDay)
    if self.helperIndex ~= nil then
        xmlFile:setInt(key .. "#helperIndex", self.helperIndex)
    end
    if self.helperName ~= nil then
        xmlFile:setString(key .. "#helperName", self.helperName)
    end
    xmlFile:setInt(key .. "#farmId", self.farmId)
end

function advancedHelperWorker.loadFromXML(xmlFile, key)
    local w = advancedHelperWorker.new()
    w.id = xmlFile:getInt(key .. "#id") or w.id
    w.firstName = xmlFile:getString(key .. "#firstName") or ""
    w.lastName = xmlFile:getString(key .. "#lastName") or ""
    w.gender = xmlFile:getString(key .. "#gender") or "M"
    w.efficiency = xmlFile:getInt(key .. "#efficiency") or 5
    w.driving = xmlFile:getInt(key .. "#driving") or 5
    w.skill = xmlFile:getInt(key .. "#skill") or 5
    w.monthlySalary = xmlFile:getInt(key .. "#monthlySalary") or advancedHelperWorker.BASE_SALARY
    w.isHired = xmlFile:getBool(key .. "#isHired") or false
    w.hireDay = xmlFile:getInt(key .. "#hireDay") or 0
    if xmlFile:hasProperty(key .. "#helperIndex") then
        w.helperIndex = xmlFile:getInt(key .. "#helperIndex")
    end
    if xmlFile:hasProperty(key .. "#helperName") then
        w.helperName = xmlFile:getString(key .. "#helperName")
    end
    w.farmId = xmlFile:getInt(key .. "#farmId") or FarmManager.SINGLEPLAYER_FARM_ID
    if w.firstName == "" then
        w.gender = "M"
    end
    return w
end