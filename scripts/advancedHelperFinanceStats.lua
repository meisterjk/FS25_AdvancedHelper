advancedHelperFinanceStats = {}

table.insert(FinanceStats.statNames, "statisticWorkerSalary")
FinanceStats.statNameToIndex["statisticWorkerSalary"] = #FinanceStats.statNames

function advancedHelperFinanceStats.new(self, superFunc, customMt)
    local returnValue = superFunc(self, customMt)
    FinanceStats.statNamesI18n["statisticWorkerSalary"] = g_i18n:getText("statisticWorkerSalary")
    return returnValue
end

FinanceStats.new = Utils.overwrittenFunction(FinanceStats.new, advancedHelperFinanceStats.new)