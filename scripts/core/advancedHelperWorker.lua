advancedHelperWorker = {}
advancedHelperWorker_mt = Class(advancedHelperWorker)

advancedHelperWorker.NAMES_MALE_DE = {
    "Hans","Peter","Klaus","Werner","Günther","Dieter","Helmut","Jürgen","Manfred","Rolf",
    "Thomas","Stefan","Andreas","Michael","Markus","Jörg","Uwe","Rüdiger","Frank","Volker",
    "Heinz","Gerd","Wolfgang","Karl","Ernst","Otto","Friedrich","Heinrich","Wilhelm","Ludwig",
    "Eberhard","Siegfried","Bernhard","Gerhard","Dietrich","Reinhard","Walther","Gottfried","Hartmut","Norbert",
    "Bernd","Rainer","Karlheinz","Hansjörg","Dietmar","Alois","Benedikt","Georg","Konrad","Matthias"
}
advancedHelperWorker.NAMES_FEMALE_DE = {
    "Anna","Maria","Helga","Ingrid","Brigitte","Ursula","Karin","Renate","Monika","Petra",
    "Sabine","Claudia","Susanne","Barbara","Christa","Elke","Gisela","Hildegard","Margarethe","Rosa",
    "Gertrud","Irmgard","Liselotte","Waltraud","Edeltraut","Annemarie","Elfriede","Ingeborg","Lieselotte","Bärbel",
    "Heidrun","Marlene","Ulla","Sigi","Hannelore","Gudrun","Traudl","Irmela","Doris","Eva",
    "Katharina","Mechthild","Adelheid","Hildegard","Josepha","Franziska","Antonia","Ludmilla","Brunhilde","Wilhelmine"
}
advancedHelperWorker.NAMES_LAST_DE = {
    "Müller","Schmidt","Schneider","Fischer","Weber","Meyer","Wagner","Becker","Schulz","Hoffmann",
    "Koch","Richter","Klein","Wolf","Schröder","Neumann","Schwarz","Zimmermann","Braun","Hartmann",
    "Lange","Werner","Kratz","Lorenz","Funk","Walter","Graf","Frank","Schubert","Bauer",
    "Krause","Schäfer","Bergmann","Simon","Keller","Herrmann","König","Walter","Lehmann","Maier",
    "Huber","Pfeiffer","Lang","Stein","Weiß","Schafer","Dietrich","Herrman","Berger","Fuchs"
}

advancedHelperWorker.NAMES_MALE_EN = {
    "James","Robert","John","Michael","David","William","Richard","Joseph","Thomas","Charles",
    "Christopher","Daniel","Matthew","Anthony","Mark","Donald","Steven","Paul","Andrew","Joshua",
    "Kenneth","Kevin","Brian","George","Timothy","Ronald","Edward","Jason","Jeffrey","Ryan",
    "Jacob","Gary","Nicholas","Eric","Jonathan","Stephen","Larry","Justin","Scott","Benjamin",
    "Brandon","Samuel","Raymond","Gregory","Frank","Alexander","Patrick","Jack","Dennis","Henry"
}
advancedHelperWorker.NAMES_FEMALE_EN = {
    "Mary","Patricia","Jennifer","Linda","Barbara","Elizabeth","Susan","Jessica","Sarah","Karen",
    "Lisa","Nancy","Betty","Margaret","Sandra","Ashley","Dorothy","Kimberly","Emily","Donna",
    "Michelle","Carol","Amanda","Melissa","Deborah","Stephanie","Rebecca","Sharon","Laura","Cynthia",
    "Kathleen","Amy","Angela","Shirley","Anna","Brenda","Pamela","Emma","Nicole","Helen",
    "Samantha","Katherine","Christine","Debra","Rachel","Carolyn","Janet","Catherine","Maria","Heather"
}
advancedHelperWorker.NAMES_LAST_EN = {
    "Smith","Johnson","Williams","Brown","Jones","Davies","Evans","Wilson","Thomas","Roberts",
    "Thompson","Walker","White","Wright","Robinson","Hall","Green","Harris","Cooper","King",
    "Lee","Martin","Clarke","James","Morgan","Hughes","Edwards","Hill","Moore","Clark",
    "Harrison","Scott","Young","Morris","Ward","Watson","Brooks","Wood","Bennett","Gray",
    "Price","Griffiths","Carter","Mitchell","Turner","Phillips","Campbell","Parker","Evans","Baker"
}

advancedHelperWorker.NAMES_MALE_US = {
    "James","Robert","John","Michael","David","William","Richard","Joseph","Thomas","Charles",
    "Christopher","Daniel","Matthew","Anthony","Mark","Steven","Paul","Andrew","Joshua","Kenneth",
    "Brian","Kevin","Jason","Timothy","Jeffrey","Ryan","Gary","Nicholas","Eric","Jacob",
    "Frank","Scott","Justin","Brandon","Benjamin","Samuel","Raymond","Gregory","Alexander","Patrick",
    "Jack","Dennis","Henry","Peter","Larry","Albert","Jonathan","Philip","Douglas","Eugene"
}
advancedHelperWorker.NAMES_FEMALE_US = {
    "Mary","Patricia","Jennifer","Linda","Barbara","Elizabeth","Susan","Jessica","Sarah","Karen",
    "Lisa","Nancy","Betty","Margaret","Sandra","Ashley","Dorothy","Kimberly","Emily","Donna",
    "Michelle","Carol","Amanda","Melissa","Deborah","Stephanie","Rebecca","Sharon","Laura","Cynthia",
    "Kathleen","Amy","Angela","Shirley","Anna","Brenda","Pamela","Emma","Nicole","Helen",
    "Samantha","Katherine","Christine","Debra","Rachel","Carolyn","Janet","Catherine","Maria","Heather"
}
advancedHelperWorker.NAMES_LAST_US = {
    "Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez",
    "Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson","Martin",
    "Lee","Perez","Thompson","White","Harris","Sanchez","Clark","Ramirez","Lewis","Robinson",
    "Walker","Young","Allen","King","Wright","Scott","Torres","Nguyen","Hill","Flores",
    "Green","Adams","Nelson","Baker","Hall","Rivera","Campbell","Mitchell","Carter","Roberts"
}

advancedHelperWorker.LANGUAGE_POOLS = {
    de = { male = "NAMES_MALE_DE", female = "NAMES_FEMALE_DE", last = "NAMES_LAST_DE" },
    en = { male = "NAMES_MALE_EN", female = "NAMES_FEMALE_EN", last = "NAMES_LAST_EN" },
    us = { male = "NAMES_MALE_US", female = "NAMES_FEMALE_US", last = "NAMES_LAST_US" },
}

advancedHelperWorker.LANGUAGE_SUFFIX_MAP = {
    _de = "de",
    _en = "en",
    _us = "us",
    _gb = "en",
    _fr = "en",
    _it = "en",
    _es = "en",
    _pl = "en",
    _ru = "en",
    _cz = "en",
    _jp = "en",
    _kr = "en",
    _br = "en",
    _pt = "en",
    _hu = "en",
    _tr = "en",
    _nl = "en",
    _dk = "en",
    _se = "en",
    _no = "en",
    _fi = "en",
    _at = "de",
    _ch = "de",
}

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

function advancedHelperWorker.getCurrentLanguageCode()
    if g_languageSuffix ~= nil then
        local code = advancedHelperWorker.LANGUAGE_SUFFIX_MAP[g_languageSuffix]
        if code ~= nil then
            return code
        end
        local stripped = g_languageSuffix:gsub("^_", "")
        if advancedHelperWorker.LANGUAGE_POOLS[stripped] ~= nil then
            return stripped
        end
    end
    return "en"
end

function advancedHelperWorker.getNamePool(langCode)
    local pool = advancedHelperWorker.LANGUAGE_POOLS[langCode]
    if pool == nil then
        pool = advancedHelperWorker.LANGUAGE_POOLS["en"]
    end
    return pool
end

function advancedHelperWorker.generateRandom(excludeNames)
    local langCode = advancedHelperWorker.getCurrentLanguageCode()
    local pool = advancedHelperWorker.getNamePool(langCode)

    local maleNames = advancedHelperWorker[pool.male]
    local femaleNames = advancedHelperWorker[pool.female]
    local lastNames = advancedHelperWorker[pool.last]

    local maxAttempts = 50
    for _ = 1, maxAttempts do
        local w = advancedHelperWorker.new()
        local isMale = math.random() > 0.5
        w.gender = isMale and "M" or "F"

        if isMale then
            w.firstName = maleNames[math.random(#maleNames)]
        else
            w.firstName = femaleNames[math.random(#femaleNames)]
        end
        w.lastName = lastNames[math.random(#lastNames)]

        w.efficiency = math.random(advancedHelperWorker.ATTR_MIN, advancedHelperWorker.ATTR_MAX)
        w.driving = math.random(advancedHelperWorker.ATTR_MIN, advancedHelperWorker.ATTR_MAX)
        w.skill = math.random(advancedHelperWorker.ATTR_MIN, advancedHelperWorker.ATTR_MAX)
        w.monthlySalary = advancedHelperWorker.calculateSalary(w.efficiency, w.driving, w.skill)

        if excludeNames == nil or excludeNames[w:getFullName()] == nil then
            return w
        end
    end

    local w = advancedHelperWorker.new()
    w.gender = "M"
    w.firstName = maleNames[math.random(#maleNames)]
    w.lastName = lastNames[math.random(#lastNames)]
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