advancedHelperPage = {
    SUB_CATEGORIES = { APPLICANTS = 1, EMPLOYEES = 2 },
    SUB_CATEGORY_TEXTS = { "advancedHelper_tabApplicants", "advancedHelper_tabOverview" }
}
advancedHelperPage.NUM_CATEGORIES = #advancedHelperPage.SUB_CATEGORY_TEXTS
advancedHelperPage._mt = Class(advancedHelperPage, TabbedMenuFrameElement)

function advancedHelperPage.new(i18n, custom_mt)
    local self = TabbedMenuFrameElement.new(nil, custom_mt or advancedHelperPage._mt)
    self.i18n = i18n
    self.subCategoryPages = {}
    self.subCategoryTabs = {}
    self.activeSubCategory = advancedHelperPage.SUB_CATEGORIES.APPLICANTS
    self.selectedApplicant = nil
    self.selectedWorker = nil
    self.applicantList = {}
    self.workerList = {}
    self.wasInitialized = false

    self.btnBack = {
        inputAction = InputAction.MENU_BACK
    }

    self.btnHire = {
        text = g_i18n:getText("advancedHelper_hire"),
        inputAction = InputAction.MENU_ACCEPT,
        callback = function()
            self:onHireClicked()
        end
    }

    self.btnFire = {
        text = g_i18n:getText("advancedHelper_fire"),
        inputAction = InputAction.MENU_ACCEPT,
        callback = function()
            self:onFireClicked()
        end
    }

    self.btnRefresh = {
        text = g_i18n:getText("advancedHelper_refresh"),
        inputAction = InputAction.MENU_EXTRA_1,
        callback = function()
            self:onRefreshClicked()
        end
    }

    self:setMenuButtonInfo({
        self.btnBack,
        self.btnHire,
        self.btnRefresh
    })

    return self
end

function advancedHelperPage:copyAttributes(src)
    advancedHelperPage:superClass().copyAttributes(self, src)
    self.i18n = src.i18n
end

function advancedHelperPage:onGuiSetupFinished()
    advancedHelperPage:superClass().onGuiSetupFinished(self)
    self.applicantsTable:setDataSource(self)
    self.applicantsTable:setDelegate(self)
    self.workersTable:setDataSource(self)
    self.workersTable:setDelegate(self)
end

function advancedHelperPage:initialize()
    if self.wasInitialized then
        return
    end

    self.selectorPrefab:unlinkElement()
    FocusManager:removeElement(self.selectorPrefab)

    for key = 1, advancedHelperPage.NUM_CATEGORIES do
        self.subCategoryPaging:addText(tostring(key))
        self.subCategoryTabs[key] = self.selectorPrefab:clone(self.subCategoryBox)
        FocusManager:loadElementFromCustomValues(self.subCategoryTabs[key])
        self.subCategoryTabs[key]:setText(g_i18n:getText(advancedHelperPage.SUB_CATEGORY_TEXTS[key]))
        self.subCategoryTabs[key]:getDescendantByName("background"):setSize(
            self.subCategoryTabs[key].size[1], self.subCategoryTabs[key].size[2])
        self.subCategoryTabs[key].onClickCallback = function()
            self:updateSubCategoryPages(key)
        end
    end

    self.subCategoryPages[advancedHelperPage.SUB_CATEGORIES.APPLICANTS] = self.applicantsContent
    self.subCategoryPages[advancedHelperPage.SUB_CATEGORIES.EMPLOYEES] = self.employeesContent

    self.subCategoryBox:invalidateLayout()

    self.wasInitialized = true
    self:updateSubCategoryPages(advancedHelperPage.SUB_CATEGORIES.APPLICANTS)
end

function advancedHelperPage:onFrameOpen()
    advancedHelperPage:superClass().onFrameOpen(self)
    if not self.wasInitialized then
        self:initialize()
    end
    self:updateContent()
end

function advancedHelperPage:onFrameClose()
    advancedHelperPage:superClass().onFrameClose(self)
end

function advancedHelperPage:updateSubCategoryPages(state)
    for i = 1, advancedHelperPage.NUM_CATEGORIES do
        self.subCategoryPages[i]:setVisible(false)
        self.subCategoryTabs[i]:setSelected(false)
    end
    self.subCategoryPages[state]:setVisible(true)
    self.subCategoryTabs[state]:setSelected(true)
    self.activeSubCategory = state

    if state == advancedHelperPage.SUB_CATEGORIES.APPLICANTS then
        self:setMenuButtonInfo({
            self.btnBack,
            self.btnHire,
            self.btnRefresh
        })
    else
        self:setMenuButtonInfo({
            self.btnBack,
            self.btnFire
        })
    end
    self:setMenuButtonInfoDirty()

    self:updateContent()
end

function advancedHelperPage:updateContent()
    if self.totalCostsValue == nil or self.helpersCountText == nil then
        return
    end
    if not self.wasInitialized then
        return
    end

    local playerFarmId = g_currentMission:getFarmId()
    local farmWorkers = advancedHelperManager:getWorkersForFarm(playerFarmId)
    local totalCosts = advancedHelperManager:getTotalMonthlyCosts(playerFarmId)
    self.totalCostsValue:setText(g_i18n:formatMoney(totalCosts) .. " " .. g_i18n:getText("advancedHelper_perMonth"))
    local helpersAvailable = #g_helperManager.availableHelpers
    self.helpersCountText:setText(string.format(g_i18n:getText("advancedHelper_helpersAvailable"), helpersAvailable))

    if self.activeSubCategory == advancedHelperPage.SUB_CATEGORIES.APPLICANTS then
        self.applicantList = advancedHelperManager.applicants

        if self.applicantsTable == nil then
            return
        end

        if next(self.applicantList) == nil then
            self.applicantsTableContainer:setVisible(false)
            self.noApplicantsContainer:setVisible(true)
            self.btnHire.disabled = true
            self:setMenuButtonInfoDirty()
            return
        end

        self.applicantsTableContainer:setVisible(true)
        self.noApplicantsContainer:setVisible(false)
        self.btnHire.disabled = false
        self:setMenuButtonInfoDirty()
        self.applicantsTable:reloadData()
    else
        self.workerList = farmWorkers

        if self.workersTable == nil then
            return
        end

        if next(self.workerList) == nil then
            self.employeesTableContainer:setVisible(false)
            self.noEmployeesContainer:setVisible(true)
            self.btnFire.disabled = true
            self:setMenuButtonInfoDirty()
            return
        end

        self.employeesTableContainer:setVisible(true)
        self.noEmployeesContainer:setVisible(false)
        self.btnFire.disabled = false
        self:setMenuButtonInfoDirty()
        self.workersTable:reloadData()
    end
end

function advancedHelperPage:onHireClicked()
    if self.selectedApplicant == nil then
        return
    end

    local applicantId = self.selectedApplicant.id

    YesNoDialog.show(
        function(clickOk)
            if clickOk then
                local playerFarmId = g_currentMission:getFarmId()
                advancedHelperHireEvent.sendEvent(applicantId, playerFarmId)
                self.selectedApplicant = nil
                self:updateContent()
            end
        end,
        nil,
        g_i18n:getText("advancedHelper_hireConfirm")
    )
end

function advancedHelperPage:onFireClicked()
    if self.selectedWorker == nil then
        return
    end

    local workerId = self.selectedWorker.id

    YesNoDialog.show(
        function(clickOk)
            if clickOk then
                local playerFarmId = g_currentMission:getFarmId()
                advancedHelperFireEvent.sendEvent(workerId, playerFarmId)
                self.selectedWorker = nil
                self:updateContent()
            end
        end,
        nil,
        g_i18n:getText("advancedHelper_fireConfirm")
    )
end

function advancedHelperPage:onRefreshClicked()
    advancedHelperRefreshEvent.sendEvent()
    self:updateContent()
end

function advancedHelperPage:getNumberOfSections(list)
    return 1
end

function advancedHelperPage:getNumberOfItemsInSection(list, section)
    if list == self.applicantsTable then
        return #self.applicantList
    else
        return #self.workerList
    end
end

function advancedHelperPage:getTitleForSectionHeader(list, section)
    return ""
end

function advancedHelperPage:populateCellForItemInSection(list, section, index, cell)
    if list == self.applicantsTable then
        local applicant = self.applicantList[index]
        if applicant == nil then
            return
        end

        cell:getAttribute("name"):setText(applicant:getFullName())
        cell:getAttribute("efficiency"):setText(string.format("%d/10", applicant.efficiency))
        cell:getAttribute("driving"):setText(string.format("%d/10", applicant.driving))
        cell:getAttribute("skill"):setText(string.format("%d/10", applicant.skill))
        cell:getAttribute("salary"):setText(g_i18n:formatMoney(applicant.monthlySalary) .. " " .. g_i18n:getText("advancedHelper_perMonth"))
    else
        local worker = self.workerList[index]
        if worker == nil then
            return
        end

        cell:getAttribute("name"):setText(worker:getFullName())
        cell:getAttribute("efficiency"):setText(string.format("%d/10", worker.efficiency))
        cell:getAttribute("driving"):setText(string.format("%d/10", worker.driving))
        cell:getAttribute("skill"):setText(string.format("%d/10", worker.skill))
        cell:getAttribute("salary"):setText(g_i18n:formatMoney(worker.monthlySalary) .. " " .. g_i18n:getText("advancedHelper_perMonth"))
    end
end

function advancedHelperPage:onListSelectionChanged(list, section, index)
    if list == self.applicantsTable then
        if index >= 1 and index <= #self.applicantList then
            self.selectedApplicant = self.applicantList[index]
        else
            self.selectedApplicant = nil
        end
    else
        if index >= 1 and index <= #self.workerList then
            self.selectedWorker = self.workerList[index]
        else
            self.selectedWorker = nil
        end
    end
end