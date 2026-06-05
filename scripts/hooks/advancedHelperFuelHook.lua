advancedHelperFuelHook = {}

function advancedHelperFuelHook.install()
    Motorized.updateConsumers = Utils.overwrittenFunction(Motorized.updateConsumers, advancedHelperFuelHook.updateConsumers)
end

function advancedHelperFuelHook.updateConsumers(self, superFunc, dt, accInput)
    local worker = advancedHelperManager:getWorkerForVehicle(self)
    local fuelMult = 1.0

    if worker ~= nil then
        fuelMult = worker:getFuelMultiplier()
    end

    if fuelMult ~= 1.0 and self.spec_motorized ~= nil then
        local savedUsages = {}
        for _, consumer in pairs(self.spec_motorized.consumers) do
            if consumer.permanentConsumption and consumer.usage > 0 then
                savedUsages[consumer] = consumer.usage
                consumer.usage = consumer.usage * fuelMult
            end
        end

        superFunc(self, dt, accInput)

        for consumer, originalUsage in pairs(savedUsages) do
            consumer.usage = originalUsage
        end
    else
        superFunc(self, dt, accInput)
    end
end