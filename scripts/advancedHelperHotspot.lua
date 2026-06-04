advancedHelperHotspot = {}
advancedHelperHotspot.hotspots = {}

function advancedHelperHotspot.install()
    Vehicle.delete = Utils.overwrittenFunction(Vehicle.delete, advancedHelperHotspot.onVehicleDelete)
end

function advancedHelperHotspot.uninstall()
    Vehicle.delete = Utils.overwrittenFunction(Vehicle.delete, nil)
end

function advancedHelperHotspot.formatDisplayName(worker, source)
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

    local name = replaceUmlauts(worker.firstName) .. " " .. replaceUmlauts(worker.lastName)
    if source == "CP" then
        name = name .. " (CP)"
    elseif source == "AD" then
        name = name .. " (AD)"
    end
    return name
end

function advancedHelperHotspot:createHotspot(vehicle, worker, source)
    if vehicle == nil or worker == nil then
        return
    end

    local vehicleId = NetworkUtil.getObjectId(vehicle)
    if self.hotspots[vehicleId] ~= nil then
        self:updateHotspot(vehicle, worker, source)
        return
    end

    if vehicle.ad ~= nil and vehicle.ad.mapHotspot ~= nil then
        self:renameADHotspot(vehicle, worker, source)
        return
    end

    local hotspot = AIHotspot.new()
    if hotspot == nil then
        advancedHelperDebug.log("HOTSPOT: failed to create AIHotspot")
        return
    end

    local displayName = self.formatDisplayName(worker, source)
    hotspot:setAIHelperName(displayName)
    hotspot:setVehicle(vehicle)
    hotspot:setOwnerFarmId(vehicle:getOwnerFarmId())

    local _, textOffsetY = getNormalizedScreenValues(0, -5)
    hotspot.textOffsetY = textOffsetY

    g_currentMission.hud:addMapHotspot(hotspot)

    self.hotspots[vehicleId] = hotspot
    advancedHelperDebug.log(string.format("HOTSPOT: created for %s -> %s (source=%s)", worker:getFullName(), vehicle:getName(), source or ""))
end

function advancedHelperHotspot:updateHotspot(vehicle, worker, source)
    if vehicle == nil or worker == nil then
        return
    end

    local vehicleId = NetworkUtil.getObjectId(vehicle)

    if vehicle.ad ~= nil and vehicle.ad.mapHotspot ~= nil then
        self:renameADHotspot(vehicle, worker, source)
        if self.hotspots[vehicleId] ~= nil then
            self:removeHotspotByVehicleId(vehicleId)
        end
        return
    end

    local hotspot = self.hotspots[vehicleId]
    if hotspot ~= nil then
        local displayName = self.formatDisplayName(worker, source)
        hotspot:setAIHelperName(displayName)
        advancedHelperDebug.log(string.format("HOTSPOT: updated for %s -> %s (source=%s)", worker:getFullName(), vehicle:getName(), source or ""))
    else
        self:createHotspot(vehicle, worker, source)
    end
end

function advancedHelperHotspot:removeHotspot(vehicle)
    if vehicle == nil then
        return
    end
    local vehicleId = NetworkUtil.getObjectId(vehicle)
    self:removeHotspotByVehicleId(vehicleId)

    if vehicle.ad ~= nil and vehicle.ad.mapHotspot ~= nil then
        self:restoreADHotspot(vehicle)
    end
end

function advancedHelperHotspot:removeHotspotByVehicleId(vehicleId)
    local hotspot = self.hotspots[vehicleId]
    if hotspot ~= nil then
        g_currentMission.hud:removeMapHotspot(hotspot)
        hotspot:setVehicle(nil)
        hotspot:delete()
        self.hotspots[vehicleId] = nil
        advancedHelperDebug.log(string.format("HOTSPOT: removed vehicleId=%d", vehicleId))
    end
end

function advancedHelperHotspot:renameADHotspot(vehicle, worker, source)
    if vehicle == nil or vehicle.ad == nil or vehicle.ad.mapHotspot == nil then
        return
    end
    local displayName = self.formatDisplayName(worker, source)
    vehicle.ad.mapHotspot:setAIHelperName(displayName)
    advancedHelperDebug.log(string.format("HOTSPOT: renamed AD hotspot for %s -> %s (source=%s)", worker:getFullName(), vehicle:getName(), source or ""))
end

function advancedHelperHotspot:restoreADHotspot(vehicle)
    if vehicle == nil or vehicle.ad == nil or vehicle.ad.mapHotspot == nil then
        return
    end
    local adName = "AD"
    if vehicle.ad.stateModule ~= nil and vehicle.ad.stateModule.getName ~= nil then
        adName = vehicle.ad.stateModule:getName()
    end
    vehicle.ad.mapHotspot:setAIHelperName("AD: " .. adName)
    advancedHelperDebug.log(string.format("HOTSPOT: restored AD hotspot name for %s", vehicle:getName()))
end

function advancedHelperHotspot:removeAll()
    for vehicleId, hotspot in pairs(self.hotspots) do
        g_currentMission.hud:removeMapHotspot(hotspot)
        hotspot:setVehicle(nil)
        hotspot:delete()
    end
    self.hotspots = {}
end

function advancedHelperHotspot:onVehicleDelete(superFunc, ...)
    advancedHelperHotspot:onVehicleDeleteCleanup(self)
    return superFunc(self, ...)
end

function advancedHelperHotspot:onVehicleDeleteCleanup(vehicle)
    if vehicle == nil then
        return
    end
    pcall(function()
        local vehicleId = NetworkUtil.getObjectId(vehicle)
        advancedHelperHotspot:removeHotspotByVehicleId(vehicleId)
    end)
end