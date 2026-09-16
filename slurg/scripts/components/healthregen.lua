--------------------------------------------------------------------------
-- Slurg's passive health regen.
--
-- How fast Slurg heals depends on how full he is, and on how far he has
-- levelled.
--
-- Two divisors, applied to SLURG_REGEN_BASE seconds per hitpoint:
--
--     effective seconds per hp = period(hunger) / coefficient(level)
--                              = BASE / (hungerdiv * leveldiv)
--
-- Hunger sets the first, and it is LINEAR IN SECONDS: no regen at all below
-- SLURG_REGEN_HUNGER_MIN, then a straight line from BASE down to
-- BASE / SLURG_REGEN_HUNGER_DIV at SLURG_REGEN_HUNGER_PEAK, flat above it.
-- Every hunger point in the band is therefore worth the same fixed number of
-- seconds -- 5s each at level 0, where the belly holds 100.
--
-- Level sets the second, and it is EXPONENTIAL: SLURG_REGEN_LEVEL_DIV raised
-- to the normalised level. That is deliberate and the two are not the same
-- shape on purpose. A divisor applied linearly makes the resulting time a
-- reciprocal of a straight line, which dumps most of the gain into the first
-- few levels; raising it to a power instead gives every equal slice of
-- levelling the same proportional pay-off. See the SLURG_REGEN_* block in
-- prefabs/slurg.lua.
--
-- Best case is 5 seconds per hitpoint, worst is 240.
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
	-- linear in SECONDS, not in the divisor, so every hunger point is worth
	-- the same fixed number of seconds
	return Lerp(TUNING.SLURG_REGEN_BASE,
		TUNING.SLURG_REGEN_BASE / TUNING.SLURG_REGEN_HUNGER_DIV, t)
end

-- How much faster Slurg's current level makes him heal, 1x up to LEVEL_DIV.
function HealthRegen:GetCoefficient()
	local t = math.min((self.inst.level or 0) / TUNING.SLURG_MAX_LEVEL, 1)
	return TUNING.SLURG_REGEN_LEVEL_DIV ^ t
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
