--------------------------------------------------------------------------
-- Slurg's passive health regen.
--
-- How fast Slurg heals depends on how full he is, and on how far he has
-- levelled.
--
-- Seconds per hitpoint is a straight bilinear blend of four tuned corners,
-- so BOTH axes are linear in seconds:
--
--                      50% full      90% full and up
--     level 0            240s              40s
--     level 5000          30s               5s
--
-- Linear in fullness at any level, and linear in level at any fullness. Every
-- equal step of either input is worth the same fixed number of seconds -- at
-- level 0 that is 5s per hunger point, and at 50% fullness it is 52.5s per
-- 1250 levels. Nothing is front-loaded and nothing is raised to a power.
--
-- No regen at all below SLURG_REGEN_HUNGER_MIN. Above SLURG_REGEN_HUNGER_PEAK
-- the fullness half stops improving and holds at its best.
--
-- Note this does NOT factor into a period times a coefficient, so there is a
-- single lookup rather than the two it used to have.
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

-- Seconds per hitpoint right now, or nil when regen is switched off.
function HealthRegen:GetSecondsPerHitpoint(hungerpct)
	if hungerpct < TUNING.SLURG_REGEN_HUNGER_MIN then
		return nil
	end

	local span = TUNING.SLURG_REGEN_HUNGER_PEAK - TUNING.SLURG_REGEN_HUNGER_MIN
	local ht = math.min((hungerpct - TUNING.SLURG_REGEN_HUNGER_MIN) / span, 1)
	local lt = math.min((self.inst.level or 0) / TUNING.SLURG_MAX_LEVEL, 1)

	-- interpolate along fullness at each end of the level range, then between
	-- those two results along level
	local atlv0 = Lerp(TUNING.SLURG_REGEN_SEC_LV0_HALF,
		TUNING.SLURG_REGEN_SEC_LV0_FULL, ht)
	local atcap = Lerp(TUNING.SLURG_REGEN_SEC_CAP_HALF,
		TUNING.SLURG_REGEN_SEC_CAP_FULL, ht)
	return Lerp(atlv0, atcap, lt)
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

	local secperhp = self:GetSecondsPerHitpoint(hunger:GetPercent())
	if secperhp == nil then
		return
	end

	self.progress = self.progress + (dt / secperhp)

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
