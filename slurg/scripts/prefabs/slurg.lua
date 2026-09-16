local MakePlayerCharacter = require "prefabs/player_common"
local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}

-- console cmds d's nuts
--     c_give ("spoiled_food", 30)

-- char stats
TUNING.SLURG_HEALTH = 50
TUNING.SLURG_HUNGER = 100
TUNING.SLURG_SANITY = 150

-- leveling: eating spoiled food raises inst.level from 0 up to SLURG_MAX_LEVEL
TUNING.SLURG_MAX_LEVEL = 5000
-- Movement. Slurg's speed is a multiplier on Wilson's run, and it is built out
-- of a signed bonus either side of x1.00:
--
--     b = bonus(fullness)
--     multiplier = 1 + b * (b > 0 and levelmult or penaltymult)
--
-- bonus(fullness) runs -SWING when empty, 0 at SPEED_HUNGER_MID, and +SWING at
-- SPEED_HUNGER_MAX and above.
--
-- Level then scales the bonus, and the two signs are scaled by DIFFERENT
-- factors. Both run from 1x at level 0:
--
--   positive bonus  ->  x1 climbing to SPEED_LEVEL_MULT    (3x, a reward)
--   negative bonus  ->  x1 fading to SPEED_PENALTY_MULT    (0x, forgiveness)
--
-- So levelling widens the upside and closes the downside at the same time. At
-- level 0 he runs x0.75 empty to x1.25 full; at the cap he runs x1.00 empty to
-- x1.75 full, with the whole first half of the belly flat at x1.00 because the
-- penalty has been levelled away entirely.
--
-- The factors are applied to the BONUS, never to the whole multiplier, so the
-- top end is 1 + 0.25*3 = x1.75 and not 1.25*3 = x3.75.
--
-- x1.00 means as fast as Wilson, TUNING.WILSON_RUN_SPEED = 6, which is the
-- yardstick every character is measured against -- Klei annotate their own that
-- way (tuning.lua:4636 BEAVER_RUN_SPEED = 6.6, --x1.1 speed).
TUNING.SLURG_SPEED_SWING = 0.25       -- +/- this either side of x1.00, pre-level
TUNING.SLURG_SPEED_LEVEL_MULT = 3.0   -- positive bonus is multiplied UP to this
TUNING.SLURG_SPEED_PENALTY_MULT = 0.0 -- negative bonus is faded DOWN to this
TUNING.SLURG_SPEED_HUNGER_MID = 0.50  -- fullness where the multiplier is x1.00
TUNING.SLURG_SPEED_HUNGER_MAX = 0.75  -- at or above this the bonus is maxed
-- Physical size, a function of level alone. Purely cosmetic as far as speed is
-- concerned: the engine multiplies motor velocity by the Transform scale, so
-- updaterunspeed divides it straight back out. Klei do the same wherever a
-- mob's scale differs from the base it is tuned against, and in every case the
-- division lands the FELT speed exactly on the named constant:
--
--   warglet.lua:245,275   scale 1.5, runspeed HOUND_SPEED * (1/1.5) -> 10.0
--   rocky.lua:89          ROCKY_WALK_SPEED / scale, held flat as it grows
--   shadowchesspieces:247 SHADOW_KNIGHT.SPEED[level] / scale
--   SGshadow_bishop:84    2 / scale
--
-- Writing "HOUND_SPEED * (1/scale)" is a strange way to say "two thirds of a
-- hound" and an obvious way to say "cancel the scale so it moves like one".
-- Mobs with a fixed scale (babybeefalo, bunnyman, beequeen, bernie_big) set
-- flat speeds with no division, but that proves nothing either way: with scale
-- constant, any correction is already baked into the number.
TUNING.SLURG_SCALE_MIN = 1.5    -- size at level 0
TUNING.SLURG_SCALE_MAX = 3.0    -- size at SLURG_MAX_LEVEL
-- max hunger scales from SLURG_HUNGER at level 0 to this at SLURG_MAX_LEVEL
TUNING.SLURG_HUNGER_MAX = 1000
-- mushrooms restore this share of his stomach on top of their own hunger
TUNING.SLURG_MUSHROOM_HUNGER_PCT = 0.02

-- passive health regen, see components/healthregen.lua
TUNING.SLURG_REGEN_TICK = 1            -- seconds between regen ticks
TUNING.SLURG_REGEN_HUNGER_MIN = 0.50   -- no regen below this fullness
TUNING.SLURG_REGEN_HUNGER_PEAK = 0.90  -- fastest regen at or above this fullness
-- Seconds per hitpoint is BASE divided by two independent divisors:
--
--     sec/hp = BASE / (hungerdiv * leveldiv)
--
-- The four corners:
--
--                    50% full     90% full and up
--     level 0        240s (/1)       40s (/6)
--     level 5000      30s (/8)        5s (/48)
--
-- The two axes are interpolated DIFFERENTLY, on purpose.
--
-- Fullness is linear in SECONDS: a straight line from 240s down to 240/6 =
-- 40s across HUNGER_MIN..HUNGER_PEAK. Every hunger point in that band is
-- worth the same fixed number of seconds, 5s each at level 0.
--
-- Level is exponential, LEVEL_DIV^t rather than 1 + 7t. Applying a divisor
-- linearly makes the time a reciprocal of a straight line, and a reciprocal
-- collapses early: at 1 + 7t the first 1250 levels alone were worth 73% of the
-- whole 240s -> 30s gain and the last 1250 were worth 4%. At 8^t every equal
-- slice of levelling is worth the same PROPORTIONAL gain instead, x1.682 per
-- 1250 levels, which is a straight halving of the time every 1667 levels.
--
-- Fullness does not need that treatment because it is already expressed in
-- seconds rather than as a divisor, so it was never front-loaded.
TUNING.SLURG_REGEN_BASE = 240          -- sec/hp with both divisors at 1
TUNING.SLURG_REGEN_HUNGER_DIV = 6      -- fullness divides the time by up to this
TUNING.SLURG_REGEN_LEVEL_DIV = 8       -- level divides the time by up to this

-- char starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.SLURG = {
	--"spoiled_food",
}
-- fills starting inventory
local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.SLURG
end
local prefabs = FlattenTree(start_inv, true)

-- functions reason for unknown reasons
local function onbecamehuman(inst)
	-- Set speed when not a ghost (optional)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "slurg_speed_mod", 1)
end
local function onbecameghost(inst)
	-- Remove speed modifier when becoming a ghost
	inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "slurg_speed_mod")
end

-- Sets locomotor.runspeed from how full Slurg is and how far he has levelled.
-- See the movement block at the top of this file for the shape of the curve and
-- for why the Transform scale is divided back out at the end.
local function updaterunspeed(inst)
	local hunger = inst.components.hunger
	if hunger == nil or inst.components.locomotor == nil then
		return
	end

	local pct = hunger:GetPercent()
	local swing = TUNING.SLURG_SPEED_SWING
	local mid = TUNING.SLURG_SPEED_HUNGER_MID
	local max = TUNING.SLURG_SPEED_HUNGER_MAX

	-- signed distance from x1.00, before level is taken into account
	local bonus
	if pct >= max then
		bonus = swing
	elseif pct >= mid then
		bonus = swing * ((pct - mid) / (max - mid))
	else
		bonus = -swing * (1 - math.clamp(pct / mid, 0, 1))
	end

	-- Levels scale the bonus, with a different factor for each sign: the reward
	-- for being full grows, and the penalty for being empty shrinks away.
	if bonus > 0 then
		bonus = bonus * (inst.speedlevelmult or 1)
	elseif bonus < 0 then
		bonus = bonus * (inst.speedpenaltymult or 1)
	end

	-- The engine multiplies motor velocity by the Transform scale, so divide the
	-- scale back out to land on the multiplier we actually want to feel.
	local target = TUNING.WILSON_RUN_SPEED * (1 + bonus)
	inst.components.locomotor.runspeed =
		target / (inst.bodyscale or TUNING.SLURG_SCALE_MIN)
end

-- Recalculate everything that scales with Slurg's level: size, the speed bonus
-- multiplier, damage, max health and max hunger. Health and hunger are put back
-- to the percentage they were at, so raising the maxes never silently heals or
-- feeds him. The speed itself is worked out per hunger tick in updaterunspeed;
-- this only hands it the two level-derived numbers it needs.
local function applyupgrades(inst)
	local healthbonus = .05
	local damagebonus = .0003
	local hungerbonus = (TUNING.SLURG_HUNGER_MAX - TUNING.SLURG_HUNGER) / TUNING.SLURG_MAX_LEVEL
	local levelpct = inst.level / TUNING.SLURG_MAX_LEVEL

	-- Size is set from level alone, here and nowhere else. updaterunspeed reads
	-- it back to cancel the engine's scale multiply, so growing does not change
	-- how fast he feels.
	inst.bodyscale = TUNING.SLURG_SCALE_MIN
		+ ((TUNING.SLURG_SCALE_MAX - TUNING.SLURG_SCALE_MIN) * levelpct)
	inst:ApplyScale("sizecorrection", inst.bodyscale)

	-- The two level factors updaterunspeed applies to the speed bonus. Both start
	-- at 1x: the first climbs, the second fades to nothing.
	inst.speedlevelmult = 1
		+ ((TUNING.SLURG_SPEED_LEVEL_MULT - 1) * levelpct)
	inst.speedpenaltymult = 1
		+ ((TUNING.SLURG_SPEED_PENALTY_MULT - 1) * levelpct)

	local newhealth = math.floor(TUNING.SLURG_HEALTH + (inst.level * healthbonus))
	local newdamage = (1.0 + (damagebonus * inst.level))
	local newhunger = TUNING.SLURG_HUNGER + (inst.level * hungerbonus)

	local health_percent = inst.components.health:GetPercent()
	local hunger_percent = inst.components.hunger:GetPercent()

	inst.components.combat.damagemultiplier = newdamage
	inst.components.health.maxhealth = newhealth
	inst.components.hunger:SetMax(newhunger)
	inst.components.health:SetPercent(health_percent)
	inst.components.hunger:SetPercent(hunger_percent)

	updaterunspeed(inst)
end

local function onsave(inst, data)
	data.level = inst.level
	-- Save fullness as percentages, not raw values. The health and hunger
	-- components save raw amounts and their own OnLoad runs before ours, while
	-- the maxes are still the level 0 ones, so those raw values come back
	-- clamped. The percentages are the only faithful record of how full he was.
	data.healthpercent = inst.components.health:GetPercent()
	data.hungerpercent = inst.components.hunger:GetPercent()
end

-- When loading or spawning the character
local function onload(inst, data)
	if data ~= nil and data.level ~= nil then
		inst.level = data.level
		-- Raise the maxes to match the restored level before putting his health
		-- and hunger back, otherwise the percentages apply to the level 0 maxes.
		applyupgrades(inst)

		-- data.currenthealth was the old name for the health percentage. Keep
		-- reading it so saves made before this change still restore properly.
		local healthpercent = data.healthpercent or data.currenthealth
		if healthpercent ~= nil then
			inst.components.health:SetPercent(healthpercent)
		end
		if data.hungerpercent ~= nil then
			inst.components.hunger:SetPercent(data.hungerpercent)
		end
	end
	inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
	inst:ListenForEvent("ms_becameghost", onbecameghost)
	if inst:HasTag("playerghost") then
		onbecameghost(inst)
	else
		onbecamehuman(inst)
	end
end

-- Mushrooms feed Slurg far better than they feed anyone else, so they need to
-- be identified exactly. The mushroom tag alone is not enough: mushrooms.lua
-- only tags the raw caps in capcommonfn, not the cooked ones. Match the known
-- prefabs as well, and keep the tag check so mushrooms added by other mods are
-- still covered.
local mushroom_prefabs = {
	red_cap = true,   red_cap_cooked = true,
	green_cap = true, green_cap_cooked = true,
	blue_cap = true,  blue_cap_cooked = true,
	moon_cap = true,  moon_cap_cooked = true,
}

local function IsMushroom(food)
	return food:HasTag("mushroom") or mushroom_prefabs[food.prefab] == true
end

-- Slurg's own food values, keyed by food prefab name. Omit a stat to leave it at 0.
--
-- health and sanity are flat amounts. hunger is flat PLUS hungerpct of Slurg's
-- current max hunger, so garbage keeps up as his belly grows with level:
--
--     hunger restored = hunger + (hungerpct * max hunger)
--
-- Plain rot at hunger 1 / hungerpct 0.01 gives 2 at level 0 (max 100) and 11
-- at the level cap (max 1000).
--
-- levels is how much eating one raises inst.level. Leave it out and the food
-- still gets Slurg's values but does not grow him, which is how wetgoop and
-- gears behave. This table is the single source of truth for what counts as
-- Slurg food; nothing keys off tags any more.
local food_stat_dict = {
	spoiled_food = { health = 3, sanity = 1, hunger = 1, hungerpct = 0.01, levels = 1 },
	spoiled_fish = { health = 3, sanity = 1, hunger = 1, hungerpct = 0.01, levels = 1 },
	spoiled_fish_small = { health = 3, sanity = 1, hunger = 1, hungerpct = 0.01, levels = 1 },
	rottenegg = { health = 25, sanity = 10, hunger = 5, hungerpct = 0.05, levels = 10 },
	poop = { health = 4, sanity = 5, hunger = 10, hungerpct = 0.03, levels = 2 },
	guano = { health = 5, sanity = 5, hunger = 10, hungerpct = 0.04, levels = 2 },
	compost = { health = 15, sanity = 15, hunger = 15, hungerpct = 0.06, levels = 5 },
	glommerfuel = { health = 50, sanity = 50, hunger = 20, hungerpct = 0.10, levels = 25 },
	wetgoop = { health = 5, sanity = 5, hunger = 5, hungerpct = 0.03, levels = 3 },
	gears = { health = 20, sanity = 20, hunger = 25 },
}

-- Eating Slurg food raises his level by that food's levels value.
local function oneat(inst, food)
	if food == nil or food.components.edible == nil then
		return
	end

	local food_stats = food_stat_dict[food.prefab]
	if food_stats == nil or food_stats.levels == nil then
		return
	end

	if inst.level < TUNING.SLURG_MAX_LEVEL then
		inst.level = math.min(inst.level + food_stats.levels, TUNING.SLURG_MAX_LEVEL)
		inst.SoundEmitter:PlaySound("dontstarve/characters/slurg/slurg_LU")
	end
	applyupgrades(inst)
end

-- Read the max through the replica when the component is absent, which is the
-- case on clients, where the display hook still needs the right number.
local function GetMaxHunger(eater)
	if eater == nil then
		return nil
	end
	return (eater.components.hunger ~= nil and eater.components.hunger.max)
		or (eater.replica ~= nil and eater.replica.hunger ~= nil and eater.replica.hunger:Max())
		or nil
end

-- Works out what a food is worth to Slurg. Every edible is passed through here,
-- because the last two rules apply to all food, not only the food we name.
--
--   1. a named entry in food_stat_dict replaces the values outright
--   2. hunger penalties are cleared, and any health penalty is added onto the
--      food's sanity, which is the only meter eating can still cost him
--
-- basehealth, basehunger and basesanity are optional. Display mods run client
-- side, where food has no edible component at all, so they pass the vanilla
-- numbers in from their own cache instead.
local function calculateFoodValues(food, eater, basehealth, basehunger, basesanity)
	local edible = food.components.edible
	if edible == nil and basehealth == nil then
		return false, 0, 0, 0
	end

	-- Start from the food's own values so rule 2 has something to act on.
	local healthval = basehealth or (edible ~= nil and edible.healthvalue) or 0
	local hungerval = basehunger or (edible ~= nil and edible.hungervalue) or 0
	local sanityval = basesanity or (edible ~= nil and edible.sanityvalue) or 0

	local food_stats = food_stat_dict[food.prefab]
	if food_stats ~= nil then
		healthval = food_stats["health"] or 0
		hungerval = food_stats["hunger"] or 0
		sanityval = food_stats["sanity"] or 0

		-- scale the hunger value with how big the eater's belly has grown
		local hungerpct = food_stats["hungerpct"]
		if hungerpct ~= nil then
			local maxhunger = GetMaxHunger(eater)
			if maxhunger ~= nil then
				hungerval = hungerval + (hungerpct * maxhunger)
			end
		end
	end

	-- Slurg never loses health or hunger to food. A health penalty is added to
	-- the food's sanity value instead, so harmful food costs him his mind rather
	-- than his body.
	--
	-- Sanity is deliberately NOT cleared. The shift is additive, so a food that
	-- already drained sanity drains that much more of it, and one that restored
	-- sanity restores less. Clearing it first would throw away the food's own
	-- cost and leave only the health damage.
	hungerval = math.max(hungerval, 0)

	-- Mushrooms restore a share of his stomach on top of their own hunger. Added
	-- after the floor above, so a mushroom with negative hunger still gets the
	-- full share rather than having it cancelled out.
	if IsMushroom(food) then
		local maxhunger = GetMaxHunger(eater)
		if maxhunger ~= nil then
			hungerval = hungerval + (TUNING.SLURG_MUSHROOM_HUNGER_PCT * maxhunger)
		end
	end

	if healthval < 0 then
		sanityval = sanityval + healthval
		healthval = 0
	end

	-- Monster food and raw meat are the two things this cannot touch.
	-- Eater:DoFoodEffects is false for both, because Slurg has strongstomach and
	-- eatsrawmeat, so eater.lua:243 and :266 drop their negative health and
	-- sanity outright and anything moved into sanity here is never applied.
	-- Clear it, otherwise the food tooltip promises a cost he never pays.
	if sanityval < 0 and (food:HasTag("monstermeat") or food:HasTag("rawmeat")) then
		sanityval = 0
	end

	return true, healthval, hungerval, sanityval
end

local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "slurg.tex" )

	-- Food display mods read the edible component directly, which still holds
	-- the vanilla numbers, so they show values Slurg will never actually get.
	-- Show Me looks for this on the viewing player and uses our numbers instead
	-- when it returns a non-nil sanity value. Defined in common_postinit so it
	-- exists on clients too, and only ever on Slurg, so other players keep
	-- seeing the normal values.
	inst.FoodValuesChanger = function(player, food, basehealth, basehunger, basesanity)
		if food == nil then
			return
		end
		local changed, healthval, hungerval, sanityval =
			calculateFoodValues(food, player, basehealth, basehunger, basesanity)
		if changed then
			return healthval, hungerval, sanityval
		end
	end
	inst:ListenForEvent("equip", function()	
	inst.AnimState:ClearOverrideSymbol("swap_hat")	
	inst.AnimState:Show("hair")		
	inst.AnimState:ClearOverrideSymbol("swap_body")	end)
end

-- This initializes for the server only. Components are added here.
local master_postinit = function(inst)
	-- Set starting inventory
    inst.starting_inventory = start_inv[TheNet:GetServerGameMode()] or start_inv.default
	-- one time sets the raw level for Slurg to 0
	inst.level = 0
	if inst.components.eater ~= nil then
        inst.components.eater.ignoresspoilage = true
		inst.components.eater.strongstomach = true
		inst.components.eater:SetCanEatHorrible()
		inst.components.eater:SetCanEatGears()
		inst.components.eater:SetCanEatRaw()
		-- raw meat costs him no sanity, the same call Webber uses
		inst.components.eater:SetCanEatRawMeat(true)
		-- Droppings, made edible for Slurg alone in modmain.lua.
		-- caneat is what lets him eat it at all. preferseating is separate and
		-- also required: without it the stategraph refuses the food and pushes
		-- wonteatfood instead (SGwilson.lua:1172). The vanilla SetCanEat*
		-- helpers add to both lists for exactly this reason.
		table.insert(inst.components.eater.caneat, FOODTYPE.SLURGROT)
		table.insert(inst.components.eater.preferseating, FOODTYPE.SLURGROT)
		inst:AddTag(FOODTYPE.SLURGROT .. "_eater")
        inst.components.eater:SetOnEatFn(oneat)
    end
	-- applyupgrades(inst)
	-- choose which sounds this character will play
	inst.soundsname = "slurg"
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    inst.talker_path_override = "dontstarve_DLC001/characters/"
	-- Hunger ticks once a second (hunger.lua UPDATE_PERIOD) and pushes this on
	-- every change, so it doubles as the speed update without its own task.
	inst:ListenForEvent("hungerdelta", function() updaterunspeed(inst) end)
	inst.OnSave = onsave 
    inst.OnLoad = onload
	-- Stats
	inst.components.health:SetMaxHealth(TUNING.SLURG_HEALTH)
	inst.components.hunger:SetMax(TUNING.SLURG_HUNGER)
	inst.components.sanity:SetMax(TUNING.SLURG_SANITY)
	applyupgrades(inst)
	-- passive health regen, scaled by fullness and level
	inst:AddComponent("healthregen")
	-- char damage multiplier (optional)
    inst.components.combat.damagemultiplier = 1
	-- char hunger rate (optional)
	inst.components.hunger.hungerrate = 1.35 * TUNING.WILSON_HUNGER_RATE
    -- overwrite eat function with custom eat function
    local old_Eat = inst.components.eater.Eat
    inst.components.eater.Eat = function(self, food)
        -- Make a local variable holding the edible component of the food (optimization).
        local edible_comp = food.components.edible
        -- Make a local variable saying whether we made changes to the food.
        local changesweremade = false
        
        -- If the food has an edible component...
        if edible_comp then
            -- Local variables to hold the new food values.
            local healthval, hungerval, sanityval
            
            -- Calculate the food values, and let us know if changes were made to them.
            changesweremade, healthval, hungerval, sanityval = calculateFoodValues(food, self.inst)
            
            if changesweremade then
                -- We first save the original food values, since we want to reset them after changing them temporarily for our character.
                edible_comp.originalhealthvalue = edible_comp.healthvalue
                edible_comp.originalhungervalue = edible_comp.hungervalue
                edible_comp.originalsanityvalue = edible_comp.sanityvalue
                
                -- We change the food to have our new stat values, and default to 0 if the stat was omitted from the dictionary entry.
                edible_comp.healthvalue = healthval
                edible_comp.hungervalue = hungerval
                edible_comp.sanityvalue = sanityval
            end
        end
        
        -- Call the original Eat function, while the food has our new values, and save the result in a variable.
        local returnvalue = old_Eat(self, food)
        
        -- If we made changes to the food, and the food is still valid (meaning it has not been destroyed
        -- because it was the last in the stack), and the edible component is still accessible...
        if food:IsValid() and changesweremade then
            -- We reset the food values after eating it.
            edible_comp.healthvalue = edible_comp.originalhealthvalue
            edible_comp.hungervalue = edible_comp.originalhungervalue
            edible_comp.sanityvalue = edible_comp.originalsanityvalue
            
            -- Remove the temporary values from the food to save memory.
            edible_comp.originalhealthvalue = nil
            edible_comp.originalhungervalue = nil
            edible_comp.originalsanityvalue = nil
        end
        
        -- Then we return the value returned by the original Eat function.
        return returnvalue
    end
end

return MakePlayerCharacter("slurg", prefabs, assets, common_postinit, master_postinit)
