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
}

AddMinimapAtlas("images/map_icons/slurg.xml")


	
local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS    




-- The character select screen lines
STRINGS.CHARACTER_TITLES.slurg = "Slurg the Goo"
STRINGS.CHARACTER_NAMES.slurg = "slurg"
STRINGS.CHARACTER_DESCRIPTIONS.slurg = "*Perk 1\n*Perk 2\n*Perk 3"
STRINGS.CHARACTER_QUOTES.slurg = "\"Quote\""
STRINGS.CHARACTER_SURVIVABILITY.slurg = "Slim"

-- Custom speech strings
STRINGS.CHARACTERS.SLURG = require "speech_slurg"

-- The character's name as appears in-game 
STRINGS.NAMES.SLURG = "slurg"
STRINGS.SKIN_NAMES.slurg_none = "slurg"

	AddPrefabPostInit("spoiled_food", function(inst)
			inst:AddComponent("edible")
			inst:AddTag("spoiled_food")
			inst.components.edible.healthvalue = 3
			inst.components.edible.sanityvalue = 5
			inst.components.edible.hungervalue = 10
					
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
