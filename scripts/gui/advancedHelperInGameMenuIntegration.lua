advancedHelperGui = {}
advancedHelperGui.modDirectory = g_currentModDirectory
advancedHelperGui.menuRegistered = false
advancedHelperGui.workersPage = nil

function advancedHelperGui.loadMap()
    g_gui:loadProfiles(advancedHelperGui.modDirectory .. "config/gui/guiProfiles.xml")

    advancedHelperGui.workersPage = advancedHelperPage.new(g_i18n)
    g_gui:loadGui(advancedHelperGui.modDirectory .. "config/gui/advancedHelperPage.xml", "advancedHelperPage", advancedHelperGui.workersPage, true)

    advancedHelperGui.addIngameMenuPage(advancedHelperGui.workersPage, "advancedHelperPage",
        { 0, 0, 1024, 1024 }, advancedHelperGui.makeIsEnabledPredicate(), "pageSettings")
end

function advancedHelperGui.makeIsEnabledPredicate()
    return function() return true end
end

function advancedHelperGui.addIngameMenuPage(frame, pageName, uvs, predicateFunc, insertAfter)
    local targetPosition = 0

    for k, v in pairs({ pageName }) do
        g_inGameMenu.controlIDs[v] = nil
    end

    for i = 1, #g_inGameMenu.pagingElement.elements do
        local child = g_inGameMenu.pagingElement.elements[i]
        if child == g_inGameMenu[insertAfter] then
            targetPosition = i + 1
            break
        end
    end

    g_inGameMenu[pageName] = frame
    g_inGameMenu.pagingElement:addElement(g_inGameMenu[pageName])

    g_inGameMenu:exposeControlsAsFields(pageName)

    for i = 1, #g_inGameMenu.pagingElement.elements do
        local child = g_inGameMenu.pagingElement.elements[i]
        if child == g_inGameMenu[pageName] then
            table.remove(g_inGameMenu.pagingElement.elements, i)
            table.insert(g_inGameMenu.pagingElement.elements, targetPosition, child)
            break
        end
    end

    for i = 1, #g_inGameMenu.pagingElement.pages do
        local child = g_inGameMenu.pagingElement.pages[i]
        if child.element == g_inGameMenu[pageName] then
            table.remove(g_inGameMenu.pagingElement.pages, i)
            table.insert(g_inGameMenu.pagingElement.pages, targetPosition, child)
            break
        end
    end

    g_inGameMenu.pagingElement:updateAbsolutePosition()
    g_inGameMenu.pagingElement:updatePageMapping()

    g_inGameMenu:registerPage(g_inGameMenu[pageName], nil, predicateFunc)

    local iconFileName = Utils.getFilename('icon_advancedHelper.dds', advancedHelperGui.modDirectory)
    g_inGameMenu:addPageTab(g_inGameMenu[pageName], iconFileName, GuiUtils.getUVs(uvs))

    for i = 1, #g_inGameMenu.pageFrames do
        local child = g_inGameMenu.pageFrames[i]
        if child == g_inGameMenu[pageName] then
            table.remove(g_inGameMenu.pageFrames, i)
            table.insert(g_inGameMenu.pageFrames, targetPosition, child)
            break
        end
    end

    g_inGameMenu:rebuildTabList()
end