PrefabFiles = {
	"slurg",
	"slurg_none",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/slurg.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/slurg.xml" ),
    Asset( "IMAGE", "images/selectscreen_portraits/slurg.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/slurg.xml" ),
    Asset( "IMAGE", "images/selectscreen_portraits/slurg_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/slurg_silho.xml" ),
    Asset( "IMAGE", "bigportraits/slurg.tex" ),
    Asset( "ATLAS", "bigportraits/slurg.xml" ),
	Asset( "IMAGE", "images/map_icons/slurg.tex" ),
	Asset( "ATLAS", "images/map_icons/slurg.xml" ),
	Asset( "IMAGE", "images/avatars/avatar_slurg.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_slurg.xml" ),
	Asset( "IMAGE", "images/avatars/avatar_ghost_slurg.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_slurg.xml" ),
	Asset( "IMAGE", "images/avatars/self_inspect_slurg.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_slurg.xml" ),
	Asset( "IMAGE", "images/names_slurg.tex" ),
    Asset( "ATLAS", "images/names_slurg.xml" ),
	Asset( "IMAGE", "images/names_gold_slurg.tex" ),
    Asset( "ATLAS", "images/names_gold_slurg.xml" ),
	Asset("SOUNDPACKAGE","sound/slurg.fev"),
	Asset("SOUND","sound/slurg.fsb"),
}
RemapSoundEvent("dontstarve/characters/slurg","slurg/slurg_sounds")
RemapSoundEvent("dontstarve/characters/slurg/slurg_LU","slurg/slurg_sounds/slurg_LU")

AddMinimapAtlas("images/map_icons/slurg.xml")
	
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS    

-- The character select screen lines
STRINGS.CHARACTER_TITLES.slurg = "Slurg the Slime"
STRINGS.CHARACTER_NAMES.slurg = "slurg"
STRINGS.CHARACTER_DESCRIPTIONS.slurg = "*Iron Gut\n*High Potential\n*Craves frequent food"
STRINGS.CHARACTER_QUOTES.slurg = "\"A wild Slurg has appeared\""
STRINGS.CHARACTER_SURVIVABILITY.slurg = "Slimey"

-- Custom speech strings
STRINGS.CHARACTERS.SLURG = require "speech_slurg"

-- The character's name as appears in-game 
STRINGS.NAMES.SLURG = "slurg"
STRINGS.SKIN_NAMES.slurg_none = "slurg"

-- Droppings are not food in vanilla, so Slurg needs an edible component added
-- to them. A plain edible component would make them food for EVERY character,
-- so they get their own food type instead: Eater:TestFood only matches an
-- "edible_<TYPE>" tag on the food against the eater's caneat list, and nothing
-- but Slurg has SLURGROT in its diet.
--
-- This is safe to add globally. IsCookingIngredient works off an explicit
-- prefab registry rather than the edible component, so these do not become
-- crockpot ingredients, and SLURGROT is in no FOODGROUP so no creature will
-- eat them either.
GLOBAL.FOODTYPE.SLURGROT = "SLURGROT"

local SLURG_GARBAGE_PREFABS = {
	"poop",
	"guano",
	"compost",
}

for _, prefabname in ipairs(SLURG_GARBAGE_PREFABS) do
	AddPrefabPostInit(prefabname, function(inst)
		-- Clients need this tag too: componentactions.lua decides whether to offer
		-- the EAT action purely from the edible_<TYPE> and <TYPE>_eater tags.
		inst:AddTag("edible_" .. GLOBAL.FOODTYPE.SLURGROT)

		if not GLOBAL.TheWorld.ismastersim then
			return
		end

		if inst.components.edible == nil then
			inst:AddComponent("edible")
		end
		-- Assigning foodtype fires the component's setter, which adds the tag.
		inst.components.edible.foodtype = GLOBAL.FOODTYPE.SLURGROT
		-- Slurg's real numbers live in food_stat_dict in prefabs/slurg.lua; these
		-- are only a fallback, and nobody else can eat these anyway.
		inst.components.edible.healthvalue = 0
		inst.components.edible.hungervalue = 0
		inst.components.edible.sanityvalue = 0
	end)
end

-- Item Info, and its "Item Info Updated" fork, show food values client side.
-- Neither has an extension hook, and neither can be made to work from inside
-- this mod alone: they render from their own cache of the prefab's raw edible
-- values, while Slurg's numbers are worked out per eater at the moment he eats
-- and never live on the item. Writing them onto the item is only safe on a
-- remote client, where food has no edible component and nothing else reads it;
-- on a host it would change the values for everyone on the server.
--
-- Both versions do leave what we need in globals though, so this needs no file
-- patching, no require, and no dependency on their script paths. Everything
-- below is guarded and simply does nothing when neither mod is installed.
-- Giving droppings an edible component had a side effect on everyone else: the
-- composting bin accepts any edible whose food type is not on its reject list
-- (compostingbin.lua:202), and SLURGROT is not on it. That silently made poop
-- and guano compostable for every character, and let compost be fed back into
-- the bin that produces it.
--
-- calcmaterialvalue is a field on the bin's component, so wrap it and refuse
-- our own food type. Returning nil is how the bin already rejects an item.
AddPrefabPostInit("compostingbin", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	local compostingbin = inst.components.compostingbin
	if compostingbin == nil or compostingbin.calcmaterialvalue == nil then
		return
	end

	local old_calcmaterialvalue = compostingbin.calcmaterialvalue
	compostingbin.calcmaterialvalue = function(bin, item)
		if item ~= nil and item.components.edible ~= nil
			and item.components.edible.foodtype == GLOBAL.FOODTYPE.SLURGROT then
			return nil
		end
		return old_calcmaterialvalue(bin, item)
	end
end)

-- TEMPORARY diagnostics for the Item Info integration.
 Everything it prints is
-- prefixed SLURGDBG so it can be grepped straight out of client_log.txt. Set
-- SLURG_DEBUG to false, or delete this block and its callers, once the
-- integration is confirmed working.
local SLURG_DEBUG = false
local slurg_logged_items = 0
local slurg_logged_values = 0
local function dbg(msg)
	if SLURG_DEBUG then
		print("SLURGDBG " .. tostring(msg))
	end
end

local function PatchItemInfo()
	-- These globals only exist when Item Info is loaded, which on a server it is
	-- not. Read them with rawget: the game installs strict.lua, whose __index
	-- raises "variable is not declared" for a plain read of an absent global
	-- rather than returning nil.
	local function GetGlobal(name)
		return GLOBAL.rawget(GLOBAL, name)
	end

	-- Character traits. Both versions read these plain globals, so registering
	-- Slurg here stops them applying spoilage and monster meat penalties he does
	-- not actually take.
	local strongstomach = GetGlobal("StrongStomachEaters")
	if strongstomach ~= nil then
		strongstomach.slurg = true
	end
	local ignorespoilage = GetGlobal("IgnoreSpoilageEaters")
	if ignorespoilage ~= nil then
		ignorespoilage.slurg = true
	end

	-- Custom values. The current version routes every lookup through a global
	-- InfoFetcher singleton, which is the safest thing to wrap.
	local iteminfo = GetGlobal("MOD_ITEMINFO")
	local fetcher = iteminfo ~= nil and iteminfo.INFO_FETCHER or nil

	dbg("patch: isclient=" .. tostring(GLOBAL.TheNet:GetIsClient())
		.. " isserver=" .. tostring(GLOBAL.TheNet:GetIsServer())
		.. " StrongStomachEaters=" .. tostring(strongstomach ~= nil)
		.. " IgnoreSpoilageEaters=" .. tostring(ignorespoilage ~= nil)
		.. " MOD_ITEMINFO=" .. tostring(iteminfo ~= nil)
		.. " INFO_FETCHER=" .. tostring(fetcher ~= nil)
		.. " GetEdibleValues=" .. tostring(fetcher ~= nil and fetcher.GetEdibleValues ~= nil))

	if fetcher ~= nil and fetcher.GetEdibleValues ~= nil and not fetcher.slurg_patched then
		fetcher.slurg_patched = true
		dbg("patch: GetEdibleValues wrapped")

		local old_GetEdibleValues = fetcher.GetEdibleValues
		fetcher.GetEdibleValues = function(self, inst)
			local hunger, sanity, health = old_GetEdibleValues(self, inst)

			local player = GLOBAL.ThePlayer

			if slurg_logged_items < 8 then
				slurg_logged_items = slurg_logged_items + 1
				dbg("lookup: prefab=" .. tostring(inst ~= nil and inst.prefab)
					.. " player=" .. tostring(player ~= nil and player.prefab)
					.. " hook=" .. tostring(player ~= nil and player.FoodValuesChanger ~= nil)
					.. " cached=" .. tostring(self.cached_items ~= nil and inst ~= nil
						and self.cached_items[inst.prefab] ~= nil)
					.. " vanilla=" .. tostring(hunger) .. "/" .. tostring(sanity) .. "/" .. tostring(health))
			end

			if player ~= nil and player.prefab == "slurg"
				and player.FoodValuesChanger ~= nil and inst ~= nil then

				-- Their cache holds the vanilla numbers. Pass them in as the base,
				-- because on a client the item has no edible component of its own.
				local base = self.cached_items ~= nil and self.cached_items[inst.prefab] or nil
				local e = base ~= nil and base.components ~= nil and base.components.edible or nil
				if e ~= nil then
					local h, g, sn = player:FoodValuesChanger(inst, e.health, e.hunger, e.sanity)
					if slurg_logged_values < 8 then
						slurg_logged_values = slurg_logged_values + 1
						dbg("slurg values: " .. tostring(inst.prefab) .. " -> "
							.. tostring(g) .. "/" .. tostring(sn) .. "/" .. tostring(h))
					end
					if sn ~= nil then
						-- returns hunger, sanity, health, in that order
						return g, sn, h
					end
				end
			end

			return hunger, sanity, health
		end
	end
end

AddSimPostInit(function()
	dbg("AddSimPostInit fired")
	PatchItemInfo()
end)

-- The skins shown in the cycle view window on the character select screen.

-- A good place to see what you can put in here is in skinutils.lua, in the function GetSkinModes
local skin_modes = {
    {
        type = "ghost_skin",
        anim_bank = "ghost",
        idle_anim = "idle", 
        scale = 0.75, 
        offset = { 0, -25 } 
    },
}

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("slurg", "NEUTRAL", skin_modes)
