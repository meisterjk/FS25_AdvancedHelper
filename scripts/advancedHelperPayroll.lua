advancedHelperPayroll = {}
advancedHelperPayroll.lastPaidPeriod = -1

function advancedHelperPayroll.onDayChanged()
    if g_server == nil then
        return
    end
    if g_currentMission == nil or g_currentMission.environment == nil then
        return
    end
    local period = g_currentMission.environment.currentPeriod
    if period == advancedHelperPayroll.lastPaidPeriod then
        return
    end
    advancedHelperPayroll.lastPaidPeriod = period
    advancedHelperPayroll.paySalaries()
end

function advancedHelperPayroll.paySalaries()
    if #advancedHelperManager.hiredWorkers == 0 then
        return
    end

    local farmWorkerMap = {}
    for _, worker in ipairs(advancedHelperManager.hiredWorkers) do
        if farmWorkerMap[worker.farmId] == nil then
            farmWorkerMap[worker.farmId] = {}
        end
        table.insert(farmWorkerMap[worker.farmId], worker)
    end

    for farmId, workers in pairs(farmWorkerMap) do
        local farm = g_farmManager:getFarmById(farmId)
        if farm ~= nil then
            local totalCosts = 0
            for _, worker in ipairs(workers) do
                totalCosts = totalCosts + worker.monthlySalary
            end

            advancedHelperDebug.log(string.format("PAYROLL: Farm %d, %d Arbeiter, Total %d, Balance %d",
                farmId, #workers, totalCosts, farm:getBalance()))

            if farm:getBalance() < totalCosts then
                local shortfall = totalCosts - farm:getBalance()
                local formatted = g_i18n:formatMoney(shortfall)
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("advancedHelper_cannotAfford"), formatted))
            else
                for _, worker in ipairs(workers) do
                    g_currentMission:addMoney(-worker.monthlySalary, farmId, MoneyType.WORKER_SALARY, true, true)
                    local formatted = g_i18n:formatMoney(worker.monthlySalary)
                    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, worker:getFullName() .. ": " .. formatted .. " " .. g_i18n:getText("advancedHelper_perMonth"))
                    advancedHelperDebug.log(string.format("  %s: -%d", worker:getFullName(), worker.monthlySalary))
                end
            end
        end
    end
end
