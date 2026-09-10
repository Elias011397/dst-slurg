--------------------------------------------------------------------------
-- Slurg's passive health regen.
--
-- How fast Slurg heals depends on how full he is, and on how far he has
-- levelled.
--
-- Hunger sets the base seconds-per-hitpoint. It is interpolated linearly
-- so that every hunger point matters, not just the round numbers:
--
--     below 50%      no regen at all
--     at    50%      SLURG_REGEN_PERIOD_FLOOR seconds per hp  (slowest)
--     at    90%      SLURG_REGEN_PERIOD_PEAK  seconds per hp  (fastest)
--     above 90%      stays at the peak; 90% is as good as it gets
--
-- Level then scales the whole thing by a coefficient running from
-- SLURG_REGEN_COEFF_MIN at level 0 to SLURG_REGEN_COEFF_MAX at
-- SLURG_MAX_LEVEL, so a fresh Slurg regens at half speed no matter how
-- stuffed he is, and grows into the perk.
--
--     effective seconds per hp = period(hunger) / coefficient(level)
--
-- Because the rate slides around continuously, we tick on a fixed interval
-- and bank fractional progress, spending it only in whole hitpoints. That
-- keeps the health bar on integers while still letting a 1.25 second
-- difference between two hunger points add up over time.
--------------------------------------------------------------------------

local function Lerp(a, b, t)
	return a + ((b - a) * t)
end

local HealthRegen = Class(function(self, inst)
	self.inst = inst
	-- banked fraction of a hitpoint, carried between ticks
	self.progress = 0
	self.task = inst:DoPeriodicTask(TUNING.SLURG_REGEN_TICK, function()
		self:OnTick(TUNING.SLURG_REGEN_TICK)
	end)
end)

-- Seconds per hitpoint at this fullness, or nil when regen is switched off.
function HealthRegen:GetPeriod(hungerpct)
	if hungerpct < TUNING.SLURG_REGEN_HUNGER_MIN then
		return nil
	end
	local span = TUNING.SLURG_REGEN_HUNGER_PEAK - TUNING.SLURG_REGEN_HUNGER_MIN
	local t = math.min((hungerpct - TUNING.SLURG_REGEN_HUNGER_MIN) / span, 1)
	return Lerp(TUNING.SLURG_REGEN_PERIOD_FLOOR, TUNING.SLURG_REGEN_PERIOD_PEAK, t)
end

-- Regen speed multiplier for Slurg's current level.
function HealthRegen:GetCoefficient()
	local t = math.min((self.inst.level or 0) / TUNING.SLURG_MAX_LEVEL, 1)
	return Lerp(TUNING.SLURG_REGEN_COEFF_MIN, TUNING.SLURG_REGEN_COEFF_MAX, t)
end

function HealthRegen:OnTick(dt)
	local health = self.inst.components.health
	local hunger = self.inst.components.hunger
	if health == nil or hunger == nil
		or health:IsDead()
		or not health:IsHurt()
		or self.inst:HasTag("playerghost") then
		return
	end

	local period = self:GetPeriod(hunger:GetPercent())
	if period == nil then
		return
	end

	self.progress = self.progress + ((dt * self:GetCoefficient()) / period)

	local gained = math.floor(self.progress)
	if gained > 0 then
		self.progress = self.progress - gained
		health:DoDelta(gained, true, "healthregen")
	end
end

function HealthRegen:OnRemoveFromEntity()
	if self.task ~= nil then
		self.task:Cancel()
		self.task = nil
	end
end

return HealthRegen
