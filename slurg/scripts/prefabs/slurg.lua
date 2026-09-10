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
-- run speed scales linearly from MIN at level 0 to MAX at SLURG_MAX_LEVEL.
-- for reference, TUNING.WILSON_RUN_SPEED is 6.
TUNING.SLURG_SPEED_MIN = 4.0
TUNING.SLURG_SPEED_MAX = 6.0
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

local function onsave(inst, data)
    data.level = inst.level
	data.currenthealth = inst.components.health:GetPercent()
end

-- When loading or spawning the character
local function onload(inst, data)
	if data and data.level then
        inst.level = data.level
		inst.components.health:SetPercent(data.currenthealth)
		local healthbonus = .05
		local damagebonus = .0003
		local hungerbonus = (TUNING.SLURG_HUNGER_MAX - TUNING.SLURG_HUNGER) / TUNING.SLURG_MAX_LEVEL
		inst:ApplyScale("sizecorrection", (1.5 + (inst.level * 0.0003)))
		local levelpct = inst.level / TUNING.SLURG_MAX_LEVEL
		local newspeed = TUNING.SLURG_SPEED_MIN + ((TUNING.SLURG_SPEED_MAX - TUNING.SLURG_SPEED_MIN) * levelpct)
		local newhealth = math.floor(TUNING.SLURG_HEALTH + (inst.level * healthbonus))
		local newdamage = (1.0 + (damagebonus * inst.level))
		local newhunger = TUNING.SLURG_HUNGER + (inst.level * hungerbonus)
		local health_percent = inst.components.health:GetPercent()
		local hunger_percent = inst.components.hunger:GetPercent()
		inst.components.locomotor.runspeed = newspeed
		inst.components.combat.damagemultiplier = newdamage
		inst.components.health.maxhealth = newhealth
		inst.components.hunger:SetMax(newhunger)
		inst.components.health:SetPercent(health_percent)
		inst.components.hunger:SetPercent(hunger_percent)
	end
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)
    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end

--hunger, health, sanity
local function applyupgrades(inst)
		local healthbonus = .05
		local damagebonus = .0003
		local hungerbonus = (TUNING.SLURG_HUNGER_MAX - TUNING.SLURG_HUNGER) / TUNING.SLURG_MAX_LEVEL
		inst:ApplyScale("sizecorrection", (1.5 + (inst.level * 0.0003)))
		local levelpct = inst.level / TUNING.SLURG_MAX_LEVEL
		local newspeed = TUNING.SLURG_SPEED_MIN + ((TUNING.SLURG_SPEED_MAX - TUNING.SLURG_SPEED_MIN) * levelpct)
		local newhealth = math.floor(TUNING.SLURG_HEALTH + (inst.level * healthbonus))
		local newdamage = (1.0 + (damagebonus * inst.level))
		local newhunger = TUNING.SLURG_HUNGER + (inst.level * hungerbonus)
		local health_percent = inst.components.health:GetPercent()
		local hunger_percent = inst.components.hunger:GetPercent()
		inst.components.locomotor.runspeed = newspeed
		inst.components.combat.damagemultiplier = newdamage
		inst.components.health.maxhealth = newhealth
		inst.components.hunger:SetMax(newhunger)
		inst.components.health:SetPercent(health_percent)
		inst.components.hunger:SetPercent(hunger_percent)
end

local function oneat(inst, food)
	if food and food.components.edible and food:HasTag("spoiled_food") then
		if inst.level < TUNING.SLURG_MAX_LEVEL then
			inst.level = inst.level + 1
			inst.SoundEmitter:PlaySound("dontstarve/characters/slurg/slurg_LU")
		end	
		applyupgrades(inst) 
	end
end

-- food_values is a dictionary with food prefab names as keys and stat-dictionaries as values.
-- The stat-dictionaries have stat-names as keys and the effect on each stat as values.
-- If you want a stat not to be affected, you can just omit it from the stat-dictionary.
local food_stat_dict = {
	spoiled_food = { health = 3, sanity = 1, hunger = 1 },
	wetgoop = { health = 5, sanity = 5, hunger = 5 },
	gears = {health = 20, sanity = 20, hunger = 25},
}

-- This is the ONLY function you should be making changes to.
local function calculateFoodValues(food)
	-- We want the caller of this function to be told whether our code made changes to the food.
	-- Therefore, we also send back a bool, called changesweremade, which we set to true if we change anything.
	-- In this case it's very simple. If we find the food in our food_stats, we will make changes to it.
	local changesweremade = false
	-- Local variables to hold our food values.
	local healthval, hungerval, sanityval = 0, 0, 0
	
	---------- ONLY EDIT BELOW THIS LINE ----------
	-- HERE you make your changes to the values, if you want to affect this particular food.
	
	-- For this example, we will make use of our food_stat_dict to determine whether to change the food,
	-- and what to change its values to.
	
	-- We look up the food values in our dictionary, using the prefab-variable (prefab identifier)
	-- of the item we are eating.
	local food_stats = food_stat_dict[food.prefab]
	
	-- If we found an entry in our food_stat_dict dictionary for the food...
	if food_stats ~= nil then
		-- We indicate that we made changes to the food.
		changesweremade = true
		
		-- Then set our values to whatever is set for them in the dictionary,
		-- and default to 0 if no value is given for the stat.
		healthval = food_stats["health"] or 0
		hungerval = food_stats["hunger"] or 0
		sanityval = food_stats["sanity"] or 0
	end
	---------- ONLY EDIT ABOVE THIS LINE ----------
	
	-- Return the results.
	return changesweremade, healthval, hungerval, sanityval
end

local common_postinit = function(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon( "slurg.tex" )
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
        inst.components.eater:SetOnEatFn(oneat)
    end
	-- applyupgrades(inst)
	-- choose which sounds this character will play
	inst.soundsname = "slurg"
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    inst.talker_path_override = "dontstarve_DLC001/characters/"
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
            changesweremade, healthval, hungerval, sanityval = calculateFoodValues(food)
            
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
    -- display values for food for mods like 'ShowMe'
    -- inst.FoodValuesChanger = function(player, food)
    --     local changesweremade, healthval, hungerval, sanityval = calculateFoodValues(food)
    --     if changesweremade then
    --         return healthval, hungerval, sanityval
    --     end
    --     local e = food.components.edible
    --     return e.healthvalue, e.hungervalue, e.sanityvalue
    -- end
end

return MakePlayerCharacter("slurg", prefabs, assets, common_postinit, master_postinit, prefabs)
