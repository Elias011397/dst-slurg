-- This information tells other players more about the mod
name = "Slurg"
description = [[
Slurg eats garbage. Rot, poop, guano, compost, rotten eggs. Every piece raises
his Level, up to 5000, and every Level makes him tougher, bigger and faster.

He starts weak: 50 health, a small stomach, and he burns food 35% faster than
anyone else.

WHAT HE EATS
  - Poop, Guano and Compost are food for Slurg only.
  - Food never costs him health or hunger.
  - Spoiled food is worth full value.
  - Monster meat and raw meat cost him nothing.
  - Anything that would damage him costs sanity instead.
  - Mushrooms also refill 2% of his stomach.

LEVELS PER ITEM
  Rot, Spoiled Fish ....... +1
  Poop, Guano ............. +2
  Wet Goop ................ +3
  Compost ................. +5
  Rotten Egg .............. +10
  Glommer's Goop .......... +25

AT LEVEL 0 AND LEVEL 5000
  Health ......... 50  ->  300
  Stomach ....... 100  ->  1000
  Damage ....... x1.0  ->  x2.5
  Size ......... x1.5  ->  x3.0

SPEED
Speed depends on how full he is. x1.00 is Wilson's running speed.

                  empty    half full    3/4 full or more
  Level 0 .....   x0.75      x1.00           x1.25
  Level 2500 ..   x0.88      x1.00           x1.50
  Level 5000 ..   x1.00      x1.00           x1.75

An empty belly slows him down, but less and less as he levels. A full belly
speeds him up, more and more as he levels.

HEALING
He heals on his own, but only above half a stomach. Seconds per hit point:

  belly          level 0    level 2500   level 5000
   50% .......... 240 .......... 85 .......... 30
   70% .......... 140 .......... 49 .......... 18
   90% ........... 40 .......... 14 ........... 5

Below half full he does not heal at all, at any Level.

Food tooltips from Item Info and Show Me show Slurg's real values.
]]
author = "UnNerfable"
version = "2.5" -- This is the version of the template. Change it to your own number.

-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
-- forumthread = "/files/file/950-extended-sample-character/"

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

-- Compatible with Don't Starve Together
dst_compatible = true

-- Not compatible with Don't Starve
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- Character mods are required by all clients
all_clients_require_mod = true 

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- The mod's tags displayed on the server list
server_filter_tags = {
"character",
}

--configuration_options = {}
