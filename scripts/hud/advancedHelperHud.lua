advancedHelperHud = {}

advancedHelperHud.POS_X = 810
advancedHelperHud.POS_Y = 60
advancedHelperHud.WIDTH = 360
advancedHelperHud.LINE_HEIGHT_PX = 20
advancedHelperHud.HEADER_HEIGHT_PX = 20
advancedHelperHud.FOOTER_HEIGHT_PX = 16
advancedHelperHud.MARGIN_PX = 6
advancedHelperHud.BUTTON_SIZE_PX = 13
advancedHelperHud.CLOSE_SIZE_PX = 12
advancedHelperHud.ICON_SIZE_PX = 14
advancedHelperHud.ATTR_ICON_SIZE_PX = 12
advancedHelperHud.FONT_SIZE_TITLE = 0.014
advancedHelperHud.FONT_SIZE_DEFAULT = 0.011
advancedHelperHud.FONT_SIZE_SMALL = 0.009
advancedHelperHud.ATTR_TEXT_SIZE = 0.010

advancedHelperHud.BG_COLOR = {0.0, 0.0, 0.0, 0.75}
advancedHelperHud.HEADER_COLOR = {0.18, 0.35, 0.003, 1.0}
advancedHelperHud.ROW_EVEN = {0.05, 0.05, 0.05, 0.5}
advancedHelperHud.ROW_ODD = {0.0, 0.0, 0.0, 0.35}
advancedHelperHud.COLOR_PLAY = {0.18, 0.35, 0.003, 1.0}
advancedHelperHud.COLOR_STOP = {0.85, 0.15, 0.15, 0.95}
advancedHelperHud.COLOR_CLOSE = {1.0, 1.0, 1.0, 0.9}
advancedHelperHud.COLOR_DISABLED = {0.3, 0.3, 0.3, 0.5}
advancedHelperHud.COLOR_HOVER = {0.4, 0.7, 1.0, 0.95}
advancedHelperHud.STATUS_ACTIVE = {0.95, 0.75, 0.0, 0.9}
advancedHelperHud.STATUS_FREE = {0.4, 0.8, 0.4, 0.9}

advancedHelperHud.FALLBACK_UVS = {0, 0, 1, 0, 1, 1, 0, 1}

advancedHelperHud.isVisible = false
advancedHelperHud.isInitialized = false
advancedHelperHud.spriteRegistered = false
advancedHelperHud.x = nil
advancedHelperHud.y = nil
advancedHelperHud.buttonRows = {}
advancedHelperHud.hudWidth = nil
advancedHelperHud.hudHeight = nil
advancedHelperHud.hudPosX = nil
advancedHelperHud.hudPosY = nil
advancedHelperHud.bgOverlay = nil
advancedHelperHud.headerOverlay = nil
advancedHelperHud.rowOverlays = {}
advancedHelperHud.footerOverlay = nil
advancedHelperHud.maxRowOverlays = 20
advancedHelperHud.playOverlays = {}
advancedHelperHud.stopOverlays = {}
advancedHelperHud.closeOverlay = nil
advancedHelperHud.iconFuelOverlays = {}
advancedHelperHud.iconSpeedOverlays = {}
advancedHelperHud.iconRepairOverlays = {}
advancedHelperHud._drawLogged = false
advancedHelperHud._mouseLogged = false
advancedHelperHud.mouseX = nil
advancedHelperHud.mouseY = nil

advancedHelperHud.isDragging = false
advancedHelperHud.dragOffsetX = 0
advancedHelperHud.dragOffsetY = 0
advancedHelperHud.savedHudX = nil
advancedHelperHud.savedHudY = nil

function advancedHelperHud:init()
    if advancedHelperHud.isInitialized then
        return
    end

    local texture = g_baseUIFilename
    if texture == nil then
        texture = 'dataS/menu/base/graph_pixel.png'
    end

    local uvs = g_colorBgUVs
    if uvs == nil then
        uvs = advancedHelperHud.FALLBACK_UVS
    end

    if advancedHelperHud.savedHudX ~= nil and advancedHelperHud.savedHudY ~= nil then
        advancedHelperHud.x = advancedHelperHud.savedHudX
        advancedHelperHud.y = advancedHelperHud.savedHudY
    else
        advancedHelperHud.x, advancedHelperHud.y = getNormalizedScreenValues(advancedHelperHud.POS_X, advancedHelperHud.POS_Y)
    end

    local useSprites = g_overlayManager ~= nil and advancedHelperHud.spriteRegistered

    if useSprites then
        advancedHelperHud.bgOverlay = g_overlayManager:createOverlay("advancedHelperIcon.panel", 0, 0, 0, 0)
    else
        advancedHelperHud.bgOverlay = Overlay.new(texture, 0, 0, 0, 0)
        advancedHelperHud.bgOverlay:setUVs(uvs)
    end
    advancedHelperHud.bgOverlay:setColor(unpack(advancedHelperHud.BG_COLOR))

    if useSprites then
        advancedHelperHud.headerOverlay = g_overlayManager:createOverlay("advancedHelperIcon.titleBar", 0, 0, 0, 0)
    else
        advancedHelperHud.headerOverlay = Overlay.new(texture, 0, 0, 0, 0)
        advancedHelperHud.headerOverlay:setUVs(uvs)
    end
    advancedHelperHud.headerOverlay:setColor(unpack(advancedHelperHud.HEADER_COLOR))

    if useSprites then
        advancedHelperHud.footerOverlay = g_overlayManager:createOverlay("advancedHelperIcon.bottomBar", 0, 0, 0, 0)
    else
        advancedHelperHud.footerOverlay = Overlay.new(texture, 0, 0, 0, 0)
        advancedHelperHud.footerOverlay:setUVs(uvs)
    end
    advancedHelperHud.footerOverlay:setColor(unpack(advancedHelperHud.BG_COLOR))

    for i = 1, advancedHelperHud.maxRowOverlays do
        local ov = Overlay.new(texture, 0, 0, 0, 0)
        ov:setUVs(uvs)
        ov:setColor(unpack(advancedHelperHud.ROW_ODD))
        advancedHelperHud.rowOverlays[i] = ov
    end

    local btnW, btnH = getNormalizedScreenValues(advancedHelperHud.BUTTON_SIZE_PX, advancedHelperHud.BUTTON_SIZE_PX)
    local closeW, closeH = getNormalizedScreenValues(advancedHelperHud.CLOSE_SIZE_PX, advancedHelperHud.CLOSE_SIZE_PX)

    for i = 1, advancedHelperHud.maxRowOverlays do
        local playOv
        if useSprites then
            playOv = g_overlayManager:createOverlay("advancedHelperIcon.play", 0, 0, btnW, btnH)
        else
            playOv = Overlay.new(texture, 0, 0, btnW, btnH)
            playOv:setUVs(uvs)
        end
        playOv:setColor(unpack(advancedHelperHud.COLOR_PLAY))
        advancedHelperHud.playOverlays[i] = playOv

        local stopOv
        if useSprites then
            stopOv = g_overlayManager:createOverlay("advancedHelperIcon.stop", 0, 0, btnW, btnH)
        else
            stopOv = Overlay.new(texture, 0, 0, btnW, btnH)
            stopOv:setUVs(uvs)
        end
        stopOv:setColor(unpack(advancedHelperHud.COLOR_STOP))
        advancedHelperHud.stopOverlays[i] = stopOv
    end

    if useSprites then
        advancedHelperHud.closeOverlay = g_overlayManager:createOverlay("advancedHelperIcon.close", 0, 0, closeW, closeH)
    else
        advancedHelperHud.closeOverlay = Overlay.new(texture, 0, 0, closeW, closeH)
        advancedHelperHud.closeOverlay:setUVs(uvs)
    end
    advancedHelperHud.closeOverlay:setColor(unpack(advancedHelperHud.COLOR_CLOSE))

    local attrIconW, attrIconH = getNormalizedScreenValues(advancedHelperHud.ATTR_ICON_SIZE_PX, advancedHelperHud.ATTR_ICON_SIZE_PX)

    for i = 1, advancedHelperHud.maxRowOverlays do
        if g_overlayManager ~= nil then
            local fuelOv = g_overlayManager:createOverlay("gui.icon_fuel", 0, 0, attrIconW, attrIconH)
            fuelOv:setColor(1, 0.85, 0.2, 0.9)
            advancedHelperHud.iconFuelOverlays[i] = fuelOv

            local speedOv = g_overlayManager:createOverlay("gui.icon_tempomat", 0, 0, attrIconW, attrIconH)
            speedOv:setColor(0.3, 0.75, 1.0, 0.9)
            advancedHelperHud.iconSpeedOverlays[i] = speedOv

            local repairOv = g_overlayManager:createOverlay("gui.icon_repair", 0, 0, attrIconW, attrIconH)
            repairOv:setColor(0.9, 0.5, 0.1, 0.9)
            advancedHelperHud.iconRepairOverlays[i] = repairOv
        else
            advancedHelperHud.iconFuelOverlays[i] = nil
            advancedHelperHud.iconSpeedOverlays[i] = nil
            advancedHelperHud.iconRepairOverlays[i] = nil
        end
    end

    advancedHelperHud.isInitialized = true
    advancedHelperDebug.log(string.format("HUD init OK: x=%.4f y=%.4f sprites=%s",
        advancedHelperHud.x, advancedHelperHud.y, useSprites and "advancedHelperIcon" or "fallback"))
end

function advancedHelperHud.getCurrentVehicle()
    if g_localPlayer ~= nil and g_localPlayer.getCurrentVehicle ~= nil then
        return g_localPlayer:getCurrentVehicle()
    end
    return nil
end

function advancedHelperHud:toggle()
    advancedHelperHud.isVisible = not advancedHelperHud.isVisible
    if not advancedHelperHud.isVisible then
        advancedHelperHud.wasVisibleBeforeExit = false
        advancedHelperHud.cursorVisible = false
        g_inputBinding:setShowMouseCursor(false)
    end
    advancedHelperDebug.log(string.format("HUD toggle: visible=%s cursor=%s", tostring(advancedHelperHud.isVisible), tostring(advancedHelperHud.cursorVisible)))
end

function advancedHelperHud:show()
    advancedHelperHud.isVisible = true
end

function advancedHelperHud:hide()
    advancedHelperHud.isVisible = false
    advancedHelperHud.wasVisibleBeforeExit = false
    advancedHelperHud.cursorVisible = false
    g_inputBinding:setShowMouseCursor(false)
end

function advancedHelperHud:toggleCursor()
    if not advancedHelperHud.isVisible or advancedHelper.localPlayerVehicle == nil then
        advancedHelperHud.cursorVisible = false
        g_inputBinding:setShowMouseCursor(false)
        return
    end
    advancedHelperHud.cursorVisible = not advancedHelperHud.cursorVisible
    g_inputBinding:setShowMouseCursor(advancedHelperHud.cursorVisible)
    advancedHelperDebug.log(string.format("HUD cursor toggle: cursor=%s", tostring(advancedHelperHud.cursorVisible)))
end

function advancedHelperHud:clampPosition()
    if advancedHelperHud.x == nil or advancedHelperHud.y == nil then
        return
    end
    local w = advancedHelperHud.hudWidth or 0
    local h = advancedHelperHud.hudHeight or 0
    if w > 0 and h > 0 then
        advancedHelperHud.x = math.clamp(advancedHelperHud.x, 0, 1 - w)
        advancedHelperHud.y = math.clamp(advancedHelperHud.y, 0, 1 - h)
    end
end

function advancedHelperHud:isMouseOverHud(posX, posY)
    if advancedHelperHud.hudPosX == nil then
        return false
    end
    return posX >= advancedHelperHud.hudPosX and posX <= advancedHelperHud.hudPosX + advancedHelperHud.hudWidth
        and posY >= advancedHelperHud.hudPosY and posY <= advancedHelperHud.hudPosY + advancedHelperHud.hudHeight
end

function advancedHelperHud:isMouseOverHeader(posX, posY)
    if advancedHelperHud.hudPosX == nil then
        return false
    end
    local _, hH = getNormalizedScreenValues(1, advancedHelperHud.HEADER_HEIGHT_PX)
    local headerY = advancedHelperHud.hudPosY + advancedHelperHud.hudHeight - hH
    return posX >= advancedHelperHud.hudPosX and posX <= advancedHelperHud.hudPosX + advancedHelperHud.hudWidth
        and posY >= headerY and posY <= advancedHelperHud.hudPosY + advancedHelperHud.hudHeight
end

function advancedHelperHud:draw()
    if not advancedHelperHud.isVisible then
        return
    end
    if g_currentMission == nil then
        return
    end

    advancedHelperHud:init()
    if not advancedHelperHud.isInitialized then
        return
    end

    local vehicle = advancedHelperHud.getCurrentVehicle()

    local playerFarmId = g_currentMission:getFarmId()
    local farmWorkers = advancedHelperManager:getWorkersForFarm(playerFarmId)
    local numWorkers = #farmWorkers
    local totalCosts = advancedHelperManager:getTotalMonthlyCosts(playerFarmId)

    local w, _ = getNormalizedScreenValues(advancedHelperHud.WIDTH, 1)
    local m, _ = getNormalizedScreenValues(advancedHelperHud.MARGIN_PX, 1)
    local _, hH = getNormalizedScreenValues(1, advancedHelperHud.HEADER_HEIGHT_PX)
    local _, fH = getNormalizedScreenValues(1, advancedHelperHud.FOOTER_HEIGHT_PX)
    local _, lH = getNormalizedScreenValues(1, advancedHelperHud.LINE_HEIGHT_PX)
    local btnSzW, btnSzH = getNormalizedScreenValues(advancedHelperHud.BUTTON_SIZE_PX, advancedHelperHud.BUTTON_SIZE_PX)
    local closeSzW, closeSzH = getNormalizedScreenValues(advancedHelperHud.CLOSE_SIZE_PX, advancedHelperHud.CLOSE_SIZE_PX)
    local attrIconW, attrIconH = getNormalizedScreenValues(advancedHelperHud.ATTR_ICON_SIZE_PX, advancedHelperHud.ATTR_ICON_SIZE_PX)

    local uiScale = g_gameSettings:getValue("uiScale") or 1.0
    local fTitle = getCorrectTextSize(advancedHelperHud.FONT_SIZE_TITLE * uiScale)
    local fDefault = getCorrectTextSize(advancedHelperHud.FONT_SIZE_DEFAULT * uiScale)
    local fSmall = getCorrectTextSize(advancedHelperHud.FONT_SIZE_SMALL * uiScale)
    local fAttr = getCorrectTextSize(advancedHelperHud.ATTR_TEXT_SIZE * uiScale)

    local totalH = hH + fH + lH * math.max(numWorkers, 1)
    local x = advancedHelperHud.x
    local y = advancedHelperHud.y

    advancedHelperHud.hudPosX = x
    advancedHelperHud.hudPosY = y
    advancedHelperHud.hudWidth = w
    advancedHelperHud.hudHeight = totalH
    advancedHelperHud.buttonRows = {}

    advancedHelperHud.bgOverlay:setPosition(x, y)
    advancedHelperHud.bgOverlay:setDimension(w, totalH)
    advancedHelperHud.bgOverlay:render()

    advancedHelperHud.headerOverlay:setPosition(x, y + totalH - hH)
    advancedHelperHud.headerOverlay:setDimension(w, hH)
    advancedHelperHud.headerOverlay:render()

    setTextColor(1, 1, 1, 0.95)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x + m, y + totalH - hH + hH * 0.2, fTitle, g_i18n:getText("advancedHelper_title"))

    local closeBtnX = x + w - m - closeSzW
    local closeBtnY = y + totalH - hH + (hH - closeSzH) * 0.5
    advancedHelperHud.closeOverlay:setPosition(closeBtnX, closeBtnY)
    advancedHelperHud.closeOverlay:setDimension(closeSzW, closeSzH)
    local closeHovered = advancedHelperHud.mouseX ~= nil
        and closeBtnX <= advancedHelperHud.mouseX and advancedHelperHud.mouseX <= closeBtnX + closeSzW
        and closeBtnY <= advancedHelperHud.mouseY and advancedHelperHud.mouseY <= closeBtnY + closeSzH
    if closeHovered then
        advancedHelperHud.closeOverlay:setColor(unpack(advancedHelperHud.COLOR_HOVER))
    else
        advancedHelperHud.closeOverlay:setColor(unpack(advancedHelperHud.COLOR_CLOSE))
    end
    advancedHelperHud.closeOverlay:render()
    table.insert(advancedHelperHud.buttonRows, {
        type = "close", x = closeBtnX, y = closeBtnY,
        w = closeSzW, h = closeSzH
    })

    local fuelStartPct = 0.26
    local speedStartPct = 0.40
    local repairStartPct = 0.54
    local statusStartPct = 0.70

    for i = #farmWorkers, 1, -1 do
        local worker = farmWorkers[i]
        local rowY = y + totalH - hH - lH * i
        local rowColor = (i % 2 == 0) and advancedHelperHud.ROW_EVEN or advancedHelperHud.ROW_ODD

        if i <= advancedHelperHud.maxRowOverlays then
            local rowOv = advancedHelperHud.rowOverlays[i]
            rowOv:setPosition(x, rowY)
            rowOv:setDimension(w, lH)
            rowOv:setColor(unpack(rowColor))
            rowOv:render()
        end

        local textY = rowY + lH * 0.15

        setTextColor(1, 1, 1, 0.9)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(x + m, textY, fDefault, worker:getFullName())

        local fuelX = x + w * fuelStartPct
        local speedX = x + w * speedStartPct
        local repairX = x + w * repairStartPct

        if i <= advancedHelperHud.maxRowOverlays then
            if advancedHelperHud.iconFuelOverlays[i] ~= nil then
                advancedHelperHud.iconFuelOverlays[i]:setPosition(fuelX, textY)
                advancedHelperHud.iconFuelOverlays[i]:render()
            end
            if advancedHelperHud.iconSpeedOverlays[i] ~= nil then
                advancedHelperHud.iconSpeedOverlays[i]:setPosition(speedX, textY)
                advancedHelperHud.iconSpeedOverlays[i]:render()
            end
            if advancedHelperHud.iconRepairOverlays[i] ~= nil then
                advancedHelperHud.iconRepairOverlays[i]:setPosition(repairX, textY)
                advancedHelperHud.iconRepairOverlays[i]:render()
            end
        end

        local valOffsetX = attrIconW + m * 0.3
        setTextColor(1, 1, 1, 0.85)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(fuelX + valOffsetX, textY, fAttr, tostring(worker.efficiency))
        renderText(speedX + valOffsetX, textY, fAttr, tostring(worker.driving))
        renderText(repairX + valOffsetX, textY, fAttr, tostring(worker.skill))

        local statusX = x + w * statusStartPct
        if worker.isAssigned and worker.assignedVehicle ~= nil then
            setTextColor(unpack(advancedHelperHud.STATUS_ACTIVE))
            local vehName = worker.assignedVehicle:getName()
            if worker.assignSource ~= nil and worker.assignSource ~= "" then
                vehName = vehName .. " (" .. worker.assignSource .. ")"
            end
            local maxChars = 17
            if vehName:len() > maxChars then
                vehName = vehName:sub(1, maxChars - 1) .. "~"
            end
            renderText(statusX, textY, fAttr, vehName)
        else
            setTextColor(unpack(advancedHelperHud.STATUS_FREE))
            renderText(statusX, textY, fAttr, g_i18n:getText("advancedHelper_hudFree"))
        end

        local btnX = x + w - m - btnSzW
        local btnY = rowY + (lH - btnSzH) * 0.5

        if i <= advancedHelperHud.maxRowOverlays then
            local btnHovered = advancedHelperHud.mouseX ~= nil
                and btnX <= advancedHelperHud.mouseX and advancedHelperHud.mouseX <= btnX + btnSzW
                and btnY <= advancedHelperHud.mouseY and advancedHelperHud.mouseY <= btnY + btnSzH
            if worker.isAssigned then
                local stopOv = advancedHelperHud.stopOverlays[i]
                stopOv:setPosition(btnX, btnY)
                stopOv:setDimension(btnSzW, btnSzH)
                if btnHovered then
                    stopOv:setColor(unpack(advancedHelperHud.COLOR_HOVER))
                else
                    stopOv:setColor(unpack(advancedHelperHud.COLOR_STOP))
                end
                stopOv:render()
            else
                local canStart = vehicle ~= nil and vehicle:getCanStartAIVehicle()
                local playOv = advancedHelperHud.playOverlays[i]
                playOv:setPosition(btnX, btnY)
                playOv:setDimension(btnSzW, btnSzH)
                if btnHovered then
                    playOv:setColor(unpack(advancedHelperHud.COLOR_HOVER))
                elseif canStart then
                    playOv:setColor(unpack(advancedHelperHud.COLOR_PLAY))
                else
                    playOv:setColor(unpack(advancedHelperHud.COLOR_DISABLED))
                end
                playOv:render()
            end
        end

        if worker.isAssigned then
            table.insert(advancedHelperHud.buttonRows, {
                type = "stop", workerId = worker.id,
                x = btnX, y = btnY, w = btnSzW, h = btnSzH
            })
        else
            local canStart = vehicle ~= nil and vehicle:getCanStartAIVehicle()
            table.insert(advancedHelperHud.buttonRows, {
                type = "start", workerId = worker.id, vehicle = vehicle,
                x = btnX, y = btnY, w = btnSzW, h = btnSzH,
                enabled = canStart or false
            })
        end
    end

    if numWorkers == 0 then
        local emptyY = y + totalH - hH - lH * 0.5
        setTextColor(0.6, 0.6, 0.6, 0.8)
        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(x + w * 0.5, emptyY, fDefault, g_i18n:getText("advancedHelper_noEmployees"))
    end

    advancedHelperHud.footerOverlay:setPosition(x, y)
    advancedHelperHud.footerOverlay:setDimension(w, fH)
    advancedHelperHud.footerOverlay:render()

    setTextColor(0.65, 0.65, 0.65, 0.8)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(x + m, y + fH * 0.15, fSmall,
        string.format("%s: %s%s | %d %s",
            g_i18n:getText("advancedHelper_totalCosts"),
            g_i18n:formatMoney(totalCosts),
            g_i18n:getText("advancedHelper_perMonth"),
            numWorkers, g_i18n:getText("advancedHelper_hudWorkers")))

    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
end

function advancedHelperHud:mouseEvent(posX, posY, isDown, isUp, button)
    advancedHelperHud.mouseX = posX
    advancedHelperHud.mouseY = posY
    if not advancedHelperHud.isVisible then
        return false
    end

    if advancedHelperHud.isDragging then
        if button == 1 and isUp then
            advancedHelperHud.isDragging = false
            advancedHelperDebug.log(string.format("HUD drag end: x=%.4f y=%.4f", advancedHelperHud.x, advancedHelperHud.y))
            return true
        end
        advancedHelperHud.x = posX - advancedHelperHud.dragOffsetX
        advancedHelperHud.y = posY - advancedHelperHud.dragOffsetY
        advancedHelperHud:clampPosition()
        return true
    end

    if button == 1 and isDown then
        for _, btn in ipairs(advancedHelperHud.buttonRows) do
            if posX >= btn.x and posX <= btn.x + btn.w
                and posY >= btn.y and posY <= btn.y + btn.h then
                advancedHelperDebug.log(string.format("HUD click: type=%s workerId=%s",
                    btn.type, tostring(btn.workerId)))

                if btn.type == "close" then
                    advancedHelperHud:hide()
                    return true
                elseif btn.type == "start" then
                    if btn.enabled and btn.vehicle ~= nil then
                        advancedHelperHud:startWorker(btn.workerId, btn.vehicle)
                    end
                    return true
                elseif btn.type == "stop" then
                    advancedHelperHud:stopWorker(btn.workerId)
                    return true
                end
            end
        end

        if advancedHelperHud:isMouseOverHeader(posX, posY) then
            advancedHelperHud.isDragging = true
            advancedHelperHud.dragOffsetX = posX - advancedHelperHud.x
            advancedHelperHud.dragOffsetY = posY - advancedHelperHud.y
            advancedHelperDebug.log("HUD drag start")
            return true
        end
    end

    if advancedHelperHud:isMouseOverHud(posX, posY) then
        return true
    end

    return false
end

function advancedHelperHud:startWorker(workerId, vehicle)
    local worker = nil
    for _, w in ipairs(advancedHelperManager.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    if worker == nil then
        advancedHelperDebug.log(string.format("HUD START ABORT: worker not found id=%d", workerId))
        return
    end
    if worker.isAssigned then
        advancedHelperDebug.log(string.format("HUD START ABORT: %s already assigned", worker:getFullName()))
        return
    end
    if vehicle == nil then
        advancedHelperDebug.log(string.format("HUD START ABORT: vehicle is nil for %s", worker:getFullName()))
        return
    end

    local farmId = g_currentMission:getFarmId()
    advancedHelperStartAIEvent.sendEvent(vehicle, workerId, farmId)
    advancedHelperDebug.log(string.format("HUD START: sent advancedHelperStartAIEvent for %s on %s",
        worker:getFullName(), vehicle:getName()))
end

function advancedHelperHud:stopWorker(workerId)
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
    if worker.assignedVehicle ~= nil then
        if worker.assignSource == "AD" then
            worker.assignedVehicle:stopAutoDrive()
        else
            worker.assignedVehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
        end
        advancedHelperDebug.log(string.format("HUD STOP: %s (source=%s)", worker:getFullName(), worker.assignSource))
    end
end

function advancedHelperHud.saveToXML(xmlFile, baseKey)
    if advancedHelperHud.x ~= nil then
        xmlFile:setFloat(baseKey .. "#hudX", advancedHelperHud.x)
    end
    if advancedHelperHud.y ~= nil then
        xmlFile:setFloat(baseKey .. "#hudY", advancedHelperHud.y)
    end
end

function advancedHelperHud.loadFromXML(xmlFile, baseKey)
    local hudX = xmlFile:getFloat(baseKey .. "#hudX")
    local hudY = xmlFile:getFloat(baseKey .. "#hudY")
    if hudX ~= nil then
        advancedHelperHud.savedHudX = hudX
    end
    if hudY ~= nil then
        advancedHelperHud.savedHudY = hudY
    end
    advancedHelperDebug.log(string.format("HUD load: savedHudX=%s savedHudY=%s",
        tostring(advancedHelperHud.savedHudX), tostring(advancedHelperHud.savedHudY)))
end
