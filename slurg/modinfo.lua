-- This information tells other players more about the mod
name = "Slurg"
description = [[
A scavenger who turns the world's garbage into growth. Slurg starts small,
frail and slow, then eats his way into becoming the biggest thing on the map.

EAT GARBAGE, GROW
Eating any type of rotted food or excrement will raise his Level, permanently
increasing his health, stomach and damage, and raising the cap on his size
and speed. Richer garbage is worth far more:

  Rot, Spoiled Fish ....... +1    constant, everywhere
  Poop, Guano ............. +2    beefalo, pigs, caves
  Wet Goop ................ +3    any failed crock pot dish
  Compost ................. +5    needs a Composting Bin
  Rotten Egg .............. +10   birdcage farming
  Glommer's Goop .......... +25   one per full moon

At the level cap he reaches 300 health, a 1000 stomach, 2.5x damage and
triple size.

HE EATS WHAT NOBODY ELSE WILL
  - Poop, Guano and Compost become food, for Slurg alone.
  - Slime stomach. Spoiled food loses nothing, monster meat costs him nothing.
  - No food in the game can drain his health, hunger or sanity.
  - Raw meat, monster food and gears feed him at half value. He wants
    garbage, not groceries.

Mushrooms are the exception. Their toxicity still bites, but it hits his mind
instead of his body: a mushroom's health damage becomes sanity loss.

A FULL SLURG IS A FAST SLURG
He swells as he fills up and shrinks as he empties, and his size carries his
speed with it. Running on empty he is normal sized and a quarter slower than
his usual pace, at every level, however much he has eaten in his life. Filled
up he reaches triple size and double speed at the cap. All that progress is
only worth something if you keep him fed.

SLIME REGENERATION
He slowly heals himself, but only while well fed. Below half a stomach it
stops entirely. The fuller he is the faster it runs, and it speeds up as he
levels.

THE CATCH
  - Fragile start. 50 health and a tiny stomach.
  - Always hungry. He burns food 35% faster than everyone else.
  - Feast or famine. Empty means small, slow and no healing.

Food tooltips from Item Info and Show Me display Slurg's real values, and
only for players actually playing Slurg.
]]
author = "UnNerfable"
version = "2.0" -- This is the version of the template. Change it to your own number.

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
