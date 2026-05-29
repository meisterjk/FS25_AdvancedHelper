advancedHelper = {}
advancedHelper.modDirectory = g_currentModDirectory
advancedHelper.modName = g_currentModName

source(advancedHelper.modDirectory .. "scripts/advancedHelperConfig.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperDebug.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperWorker.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperManager.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperPayroll.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperFuelHook.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperSpeedHook.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperDamageHook.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperHelperSafeguard.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperAutoDriveHook.lua")
source(advancedHelper.modDirectory .. "scripts/advancedHelperCourseplayHook.lua")
source(advancedHelper.modDirectory .. "scripts/hud/advancedHelperHud.lua")
source(advancedHelper.modDirectory .. "scripts/gui/advancedHelperInGameMenuIntegration.lua")
source(advancedHelper.modDirectory .. "scripts/gui/advancedHelperPage.lua")

function advancedHelper:loadMap()
    g_overlayManager:addTextureConfigFile(
        Utils.getFilename("textures/iconSprite.xml", advancedHelper.modDirectory),
        "advancedHelperIcon")
    advancedHelperHud.spriteRegistered = true

    advancedHelperManager:init()

    advancedHelperFuelHook.install()
    advancedHelperDamageHook.install()
    advancedHelperHelperSafeguard.install()

    advancedHelperAutoDriveHook.install()
    advancedHelperCourseplayHook.install()

    advancedHelperGui.loadMap()

    g_messageCenter:subscribe(MessageType.DAY_CHANGED, advancedHelper.onDayChanged, advancedHelper)
    g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, advancedHelper.onMissionStarted, advancedHelper)
    g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, advancedHelperSpeedHook.onAIJobStarted)
    g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, advancedHelperSpeedHook.onAIJobStopped)

    advancedHelper:installPlayerInputHook()

    ItemSystem.save = Utils.prependedFunction(ItemSystem.save, advancedHelper.onSaveGame)

    FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(
        FSBaseMission.onConnectionFinishedLoading, advancedHelper.onClientJoined)

    g_currentMission.advancedHelper = advancedHelper
end

function advancedHelper:deleteMap()
    g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, advancedHelper)
    g_messageCenter:unsubscribe(MessageType.CURRENT_MISSION_START, advancedHelper)
    g_messageCenter:unsubscribe(MessageType.AI_JOB_STARTED, advancedHelperSpeedHook.onAIJobStarted)
    g_messageCenter:unsubscribe(MessageType.AI_JOB_STOPPED, advancedHelperSpeedHook.onAIJobStopped)
    advancedHelperAutoDriveHook.uninstall()
    advancedHelperCourseplayHook.uninstall()
    advancedHelper:uninstallPlayerInputHook()
end

function advancedHelper:update(dt)
    if not advancedHelperAutoDriveHook.eventListenersInstalled and advancedHelperAutoDriveHook.isADLoaded() then
        advancedHelperAutoDriveHook.installEventListenersOnly()
    end
    if not advancedHelperCourseplayHook.eventListenersInstalled and advancedHelperCourseplayHook.isCPLoaded() then
        advancedHelperCourseplayHook.installEventListenersOnly()
    end

    if g_server ~= nil and g_currentMission ~= nil then
        local target = #advancedHelperManager.hiredWorkers
        if not advancedHelperConfig.INFILTRATE_AUTODRIVE then
            local adExtra = advancedHelperAutoDriveHook.activeADCount or 0
            target = target + adExtra
        end
        if not advancedHelperConfig.INFILTRATE_COURSEPLAY then
            local cpExtra = advancedHelperCourseplayHook.activeCPCount or 0
            target = target + cpExtra
        end
        if g_currentMission.maxNumHirables ~= target then
            g_currentMission.maxNumHirables = target
        end
    end

    advancedHelperPayroll.update(dt)
    advancedHelper.cancelOrphanedAIJobs()
end

function advancedHelper.onToggleHud()
    advancedHelperHud:toggle()
end

function advancedHelper.onToggleCursor()
    advancedHelperHud:toggleCursor()
end

function advancedHelper:draw()
    if not advancedHelper._drawLogged then
        advancedHelperDebug.log("advancedHelper:draw() is being called")
        advancedHelper._drawLogged = true
    end
    new2DLayer()
    advancedHelperHud:draw()
    if advancedHelperHud.cursorVisible and g_inputBinding ~= nil then
        g_inputBinding:setShowMouseCursor(true)
    end
end

function advancedHelper:mouseEvent(posX, posY, isDown, isUp, button)
    if advancedHelperHud:mouseEvent(posX, posY, isDown, isUp, button) then
        return
    end
end

function advancedHelper.onDayChanged()
    advancedHelperManager:updateDay()
end

function advancedHelper.onMissionStarted()
    advancedHelperManager:loadFromSavegame()
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        advancedHelperPayroll.lastPaidPeriod = g_currentMission.environment.currentPeriod
    end
end

function advancedHelper.onSaveGame()
    if g_server ~= nil then
        advancedHelperSpeedHook.restoreAll()
        advancedHelperManager:saveState()
    end
end

function advancedHelper.onClientJoined(mission, connection, x, y, z, viewDistanceCoeff)
    if connection ~= nil then
        advancedHelperSyncEvent.sendToClient(connection)
        advancedHelperDebug.log("SYNC: sent initial state to joining client")
    end
end

function advancedHelper.cancelOrphanedAIJobs()
    if g_currentMission == nil or g_currentMission.aiSystem == nil then
        return
    end
    if #advancedHelperManager.hiredWorkers > 0 then
        return
    end
    if not g_server then
        return
    end

    local aiSystem = g_currentMission.aiSystem
    if aiSystem.activeJobVehicles == nil or #aiSystem.activeJobVehicles == 0 then
        return
    end

    local vehiclesToStop = {}
    for _, vehicle in ipairs(aiSystem.activeJobVehicles) do
        if vehicle ~= nil and vehicle.stopCurrentAIJob ~= nil then
            table.insert(vehiclesToStop, vehicle)
        end
    end

    for _, vehicle in ipairs(vehiclesToStop) do
        pcall(function()
            vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
        end)
    end
end

function advancedHelper:installPlayerInputHook()
    if self.playerInputHooked then
        return
    end
    if PlayerInputComponent == nil then
        return
    end
    local function registerAdvancedHelperActions(self, superFunc, ...)
        superFunc(self, ...)
        if InputAction.ADVANCEDHELPER_TOGGLE_HUD ~= nil then
            local _, eventId = g_inputBinding:registerActionEvent(
                InputAction.ADVANCEDHELPER_TOGGLE_HUD, advancedHelper, advancedHelper.onToggleHud,
                false, true, false, true)
            if eventId ~= nil then
                g_inputBinding:setActionEventText(eventId, g_i18n:getText("input_ADVANCEDHELPER_TOGGLE_HUD"))
                g_inputBinding:setActionEventTextVisibility(eventId, true)
                g_inputBinding:setActionEventActive(eventId, true)
            end
        end
        if InputAction.ADVANCEDHELPER_TOGGLE_CURSOR ~= nil then
            local _, eventId = g_inputBinding:registerActionEvent(
                InputAction.ADVANCEDHELPER_TOGGLE_CURSOR, advancedHelper, advancedHelper.onToggleCursor,
                false, true, false, true)
            if eventId ~= nil then
                g_inputBinding:setActionEventText(eventId, g_i18n:getText("input_ADVANCEDHELPER_TOGGLE_CURSOR"))
                g_inputBinding:setActionEventTextVisibility(eventId, true)
                g_inputBinding:setActionEventActive(eventId, true)
            end
        end
    end
    PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.overwrittenFunction(
        PlayerInputComponent.registerGlobalPlayerActionEvents, registerAdvancedHelperActions)
    self.playerInputHooked = true
    advancedHelperDebug.log("PlayerInputComponent hook installed")
end

function advancedHelper:uninstallPlayerInputHook()
    if not self.playerInputHooked then
        return
    end
    pcall(function()
        g_inputBinding:removeActionEventsByTarget(advancedHelper)
    end)
    self.playerInputHooked = false
end

addModEventListener(advancedHelper)