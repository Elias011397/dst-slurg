local assets =
{
	Asset( "ANIM", "anim/slurg.zip" ),
	Asset( "ANIM", "anim/ghost_slurg_build.zip" ),
}

local skins =
{
	normal_skin = "slurg",
	ghost_skin = "ghost_slurg_build",
}

return CreatePrefabSkin("slurg_none",
{
	base_prefab = "slurg",
	type = "base",
	assets = assets,
	skins = skins, 
	skin_tags = {"SLURG", "CHARACTER", "BASE"},
	build_name_override = "slurg",
	rarity = "Character",
})