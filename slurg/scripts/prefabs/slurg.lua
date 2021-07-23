local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
-- c_give ("spoiled_food", 30)
-- Your character's stats

TUNING.SLURG_HEALTH = 50
TUNING.SLURG_HUNGER = 150
TUNING.SLURG_SANITY = 150

-- Custom starting inventory
TUNING.GAMEMODE_STARTING_ITEMS.DEFAULT.SLURG = {
	--"spoiled_food",
}

local start_inv = {}
for k, v in pairs(TUNING.GAMEMODE_STARTING_ITEMS) do
    start_inv[string.lower(k)] = v.SLURG
end
local prefabs = FlattenTree(start_inv, true)


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
local function onload(inst,data)
	if data and data.level then
        inst.level = data.level
		inst.components.health:SetPercent(data.currenthealth)
		inst:ApplyScale("sizecorrection", (1.5 + (inst.level * 0.0015)))
		local runspeed_bonus = .001
		local healthbonus = .25
		local damagebonus = .0015
		local hungerbonus = .35
		local newspeed = ((TUNING.WILSON_RUN_SPEED + (TUNING.WILSON_RUN_SPEED * runspeed_bonus * inst.level))/(1.5 + (inst.level * 0.0015)))
		local newhealth = math.floor(TUNING.SLURG_HEALTH + (inst.level * healthbonus))
		local newdamage = (1.0 + (damagebonus * inst.level))
		local health_percent = inst.components.health:GetPercent()
		local newhunger = TUNING.SLURG_HUNGER + (inst.level * hungerbonus)
		inst.components.health.maxhealth = newhealth
		inst.components.hunger:SetMax(newhunger)
		inst.components.locomotor.runspeed = newspeed
		inst.components.combat.damagemultiplier = newdamage
		inst.components.health:SetPercent(health_percent)
        --applyupgrades(inst)
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
		local runspeed_bonus = .001
		local healthbonus = .25
		local damagebonus = .0015
		local hungerbonus = .35
		inst:ApplyScale("sizecorrection", (1.5 + (inst.level * 0.0015)))
		local newspeed = ((TUNING.WILSON_RUN_SPEED + (TUNING.WILSON_RUN_SPEED * runspeed_bonus * inst.level))/(1.5 + (inst.level * 0.0015)))
		local newhealth = math.floor(TUNING.SLURG_HEALTH + (inst.level * healthbonus))
		local newdamage = (1.0 + (damagebonus * inst.level))
		local health_percent = inst.components.health:GetPercent()
		local newhunger = TUNING.SLURG_HUNGER + (inst.level * hungerbonus)
		inst.components.health.maxhealth = newhealth
		inst.components.hunger:SetMax(newhunger)
		inst.components.locomotor.runspeed = newspeed
		inst.components.combat.damagemultiplier = newdamage
		inst.components.health:SetPercent(health_percent)
end

		
	

local function oneat(inst, food)
	if food and food.components.edible and food:HasTag("spoiled_food") then
		if inst.level < 1000 then
			inst.level = inst.level + 1
		end	
    applyupgrades(inst) 
	inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
	end
end


-- This initializes for both the server and client. Tags can be added here.
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
	
	--applyupgrades(inst)
	-- choose which sounds this character will play
	inst.soundsname = "webber"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	
	inst.OnSave = onsave 
    inst.OnLoad = onload

	-- Stats	

	inst.components.health:SetMaxHealth(TUNING.SLURG_HEALTH)
	inst.components.hunger:SetMax(TUNING.SLURG_HUNGER)
	inst.components.sanity:SetMax(TUNING.SLURG_SANITY)
	applyupgrades(inst)
	
	-- Damage multiplier (optional)
    inst.components.combat.damagemultiplier = 1
	
	-- Hunger rate (optional)
	inst.components.hunger.hungerrate = 1.25 * TUNING.WILSON_HUNGER_RATE
	


	
end

return MakePlayerCharacter("slurg", prefabs, assets, common_postinit, master_postinit, prefabs)
