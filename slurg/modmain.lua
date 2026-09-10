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
