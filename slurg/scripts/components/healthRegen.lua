local HealthRegen = Class(function(self, inst)
    self.inst = inst
	-- components
	self.health = self.inst.components.health
	self.hunger = self.inst.components.hunger
	-- update
	self.inst:StartUpdatingComponent(self)
end)

function HealthRegen:OnUpdate(dt)
	
	if(self.health.currenthealth>1) then
		if (self.hunger.current >= (self.hunger.max * REGEN_MIN_HUNGER)) then
			-- increase health
			self.health:DoDelta(REGEN_RATE_HEALTH * dt, true)
		end
	end
end

--The rate at which health is regenerated, per second.
REGEN_RATE_HEALTH = 0.2

--The percentage of hunger that is needed for regeneration.
REGEN_MIN_HUNGER = 90

return HealthRegen