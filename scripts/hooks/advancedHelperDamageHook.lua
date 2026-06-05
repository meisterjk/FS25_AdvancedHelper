advancedHelperDamageHook = {}

function advancedHelperDamageHook.install()
    Wearable.updateDamageAmount = Utils.overwrittenFunction(Wearable.updateDamageAmount, advancedHelperDamageHook.updateDamageAmount)
    Wearable.getWearMultiplier = Utils.overwrittenFunction(Wearable.getWearMultiplier, advancedHelperDamageHook.getWearMultiplier)
end

function advancedHelperDamageHook.updateDamageAmount(self, superFunc, dt)
    local changeAmount = superFunc(self, dt)

    local worker = advancedHelperManager:getWorkerForVehicle(self)
    if worker == nil then
        return changeAmount or 0
    end

    local wearMult = worker:getWearMultiplier()
    if wearMult ~= 1.0 then
        changeAmount = (changeAmount or 0) * wearMult
    end

    return changeAmount or 0
end

function advancedHelperDamageHook.getWearMultiplier(self, superFunc)
    local multiplier = superFunc(self)

    local worker = advancedHelperManager:getWorkerForVehicle(self)
    if worker == nil then
        return multiplier
    end

    return multiplier * worker:getWearMultiplier()
end