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
-- Effective in-game speed. These are real speeds as felt in game, NOT the
-- value that goes into locomotor.runspeed; see updatesize for why they differ.
-- For reference, TUNING.WILSON_RUN_SPEED is 6.
--
-- Speed ramps from EMPTY up to the level's top speed across the same fullness
-- band as size, so the range widens with level. Taking 4.0 as Slurg's nominal
-- speed, that is x0.75 empty rising to x1.25 full at level 0, and x0.75 rising
-- to x2.00 full at the cap. An empty belly is the same floor at every level.
TUNING.SLURG_SPEED_EMPTY = 3.0  -- effective speed when empty, at every level
TUNING.SLURG_SPEED_MIN = 5.0    -- effective speed when full, at level 0
TUNING.SLURG_SPEED_MAX = 8.0    -- effective speed when full, at SLURG_MAX_LEVEL
-- Physical size. Level sets the CAP; how much of that cap Slurg actually
-- reaches is decided by how full he is. Size also multiplies movement speed,
-- so a hungry Slurg is both small and slow.
TUNING.SLURG_SCALE_MIN = 1.5    -- size cap at level 0
TUNING.SLURG_SCALE_MAX = 3.0    -- size cap at SLURG_MAX_LEVEL
TUNING.SLURG_SCALE_NORMAL = 1.0 -- size when empty, same as everyone else
TUNING.SLURG_SIZE_HUNGER_MIN = 0.01 -- below this he is normal sized
TUNING.SLURG_SIZE_HUNGER_MAX = 0.90 -- at or above this he is at his cap
-- max hunger scales from SLURG_HUNGER at level 0 to this at SLURG_MAX_LEVEL
TUNING.SLURG_HUNGER_MAX = 1000

-- passive health regen, see components/healthregen.lua
TUNING.SLURG_REGEN_TICK = 1            -- seconds between regen ticks
TUNING.SLURG_REGEN_HUNGER_MIN = 0.50   -- no regen below this fullness
TUNING.SLURG_REGEN_HUNGER_PEAK = 0.90  -- fastest regen at or above this fullness
TUNING.SLURG_REGEN_PERIOD_FLOOR = 60   -- seconds per hp at HUNGER_MIN
TUNING.SLURG_REGEN_PERIOD_PEAK = 10    -- seconds per hp at HUNGER_PEAK
TUNING.SLURG_REGEN_COEFF_MIN = 0.5     -- regen speed multiplier at level 0
TUNING.SLURG_REGEN_COEFF_MAX = 1.0     -- regen speed multiplier at SLURG_MAX_LEVEL

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

-- Slurg swells as he fills up. An empty Slurg is normal sized like anyone
-- else; he reaches the size cap his level allows at SLURG_SIZE_HUNGER_MAX
-- fullness, interpolated so every hunger point in between counts.
--
-- Because in-game speed is runspeed multiplied by Transform scale, this
-- throttles his speed at the same time: a starving Slurg is slow whatever
-- his level, and only a full one gets the speed his level has earned.
local function updatesize(inst)
	local hunger = inst.components.hunger
	if hunger == nil then
		return
	end

	local cap = inst.scalecap or TUNING.SLURG_SCALE_MIN
	local topspeed = inst.topspeed or TUNING.SLURG_SPEED_MIN
	local span = TUNING.SLURG_SIZE_HUNGER_MAX - TUNING.SLURG_SIZE_HUNGER_MIN
	local t = math.clamp((hunger:GetPercent() - TUNING.SLURG_SIZE_HUNGER_MIN) / span, 0, 1)

	local scale = TUNING.SLURG_SCALE_NORMAL + ((cap - TUNING.SLURG_SCALE_NORMAL) * t)
	inst:ApplyScale("sizecorrection", scale)

	-- Speed has its own curve rather than riding on size, so the two can be
	-- tuned apart. The engine multiplies runspeed by the Transform scale
	-- (locomotor.lua:730), so divide the scale back out to land on the
	-- effective speed we actually want.
	if inst.components.locomotor ~= nil then
		local effective = TUNING.SLURG_SPEED_EMPTY + ((topspeed - TUNING.SLURG_SPEED_EMPTY) * t)
		inst.components.locomotor.runspeed = effective / scale
	end
end

-- Recalculate everything that scales with Slurg's level: size cap, speed,
-- damage, max health and max hunger. Health and hunger are put back to the
-- percentage they were at, so raising the maxes never silently heals or feeds
-- him.
local function applyupgrades(inst)
	local healthbonus = .05
	local damagebonus = .0003
	local hungerbonus = (TUNING.SLURG_HUNGER_MAX - TUNING.SLURG_HUNGER) / TUNING.SLURG_MAX_LEVEL
	local levelpct = inst.level / TUNING.SLURG_MAX_LEVEL
	-- Level only sets the cap. updatesize decides how much of it he is at.
	inst.scalecap = TUNING.SLURG_SCALE_MIN + ((TUNING.SLURG_SCALE_MAX - TUNING.SLURG_SCALE_MIN) * levelpct)

	-- Top speed for this level, reached at full. updatesize ramps up to it.
	inst.topspeed = TUNING.SLURG_SPEED_MIN + ((TUNING.SLURG_SPEED_MAX - TUNING.SLURG_SPEED_MIN) * levelpct)
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

	updatesize(inst)
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
	-- half of the values this mod used to give (20 / 20 / 25)
	gears = { health = 10, sanity = 10, hunger = 12.5 },
}

-- Food Slurg digests poorly. Unlike food_stat_dict these do not replace the
-- food's values, they scale the food's own values by the given fraction, so
-- they keep working if Klei retunes a food and they cover foods added by other
-- mods. Matched by tag, first match wins.
--
-- Values are not rounded: half of 18.75 hunger stays 9.375.
--
-- Note that negative values still get dropped entirely for monster food,
-- because eater.lua:243 and :266 skip negative health and sanity when
-- strongstomach is set. So halving monster meat only really halves its hunger.
local food_multipliers = {
	{ tag = "rawmeat", multiplier = 0.5 },
	{ tag = "monstermeat", multiplier = 0.5 },
}

local function GetFoodMultiplier(food)
	for _, v in ipairs(food_multipliers) do
		if food:HasTag(v.tag) then
			return v.multiplier
		end
	end
	return nil
end

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

-- Works out what a food is worth to Slurg. Every edible is passed through here,
-- because the last two rules apply to all food, not only the food we name.
--
--   1. a named entry in food_stat_dict replaces the values outright
--   2. otherwise a category multiplier scales the food's own values
--   3. hunger penalties are cleared, and any health penalty is added onto the
--      food's sanity, which is the only meter eating can still cost him
-- basehealth, basehunger and basesanity are optional. Display mods run client
-- side, where food has no edible component at all, so they pass the vanilla
-- numbers in from their own cache instead.
local function calculateFoodValues(food, eater, basehealth, basehunger, basesanity)
	local edible = food.components.edible
	if edible == nil and basehealth == nil then
		return false, 0, 0, 0
	end

	-- Start from the food's own values so rules 3 and 4 have something to act on.
	local healthval = basehealth or (edible ~= nil and edible.healthvalue) or 0
	local hungerval = basehunger or (edible ~= nil and edible.hungervalue) or 0
	local sanityval = basesanity or (edible ~= nil and edible.sanityvalue) or 0

	local food_stats = food_stat_dict[food.prefab]
	if food_stats ~= nil then
		healthval = food_stats["health"] or 0
		hungerval = food_stats["hunger"] or 0
		sanityval = food_stats["sanity"] or 0

		-- scale the hunger value with how big the eater's belly has grown. Read
		-- the max through the replica so this is also correct on clients, where
		-- the hunger component itself does not exist but the display hook still
		-- needs the right number.
		local hungerpct = food_stats["hungerpct"]
		if hungerpct ~= nil and eater ~= nil then
			local maxhunger = (eater.components.hunger ~= nil and eater.components.hunger.max)
				or (eater.replica ~= nil and eater.replica.hunger ~= nil and eater.replica.hunger:Max())
			if maxhunger ~= nil then
				hungerval = hungerval + (hungerpct * maxhunger)
			end
		end
	else
		local multiplier = GetFoodMultiplier(food)
		if multiplier ~= nil then
			healthval = healthval * multiplier
			hungerval = hungerval * multiplier
			sanityval = sanityval * multiplier
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

	if healthval < 0 then
		sanityval = sanityval + healthval
		healthval = 0
	end

	-- Monster food is the one thing this cannot touch. eater.lua:243 and :266
	-- drop negative health and sanity outright when strongstomach is set, which
	-- Slurg has, so anything moved into sanity here would never be applied.
	-- Clear it, otherwise the food tooltip promises a cost he never pays.
	if sanityval < 0 and food:HasTag("monstermeat") then
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
	-- every change, so it doubles as the size update without its own task.
	inst:ListenForEvent("hungerdelta", function() updatesize(inst) end)
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
