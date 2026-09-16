-- This information tells other players more about the mod
name = "Slurg"
description = [[
A scavenger who turns the world's garbage into growth. Slurg starts frail and
no quicker than anyone else, then eats his way into becoming the biggest and
fastest thing on the map.

EAT GARBAGE, GROW
Eating any type of rotted food or excrement will raise his Level, permanently
increasing his health, stomach, damage and size, tripling the speed a full belly
is worth to him, and wearing down the penalty for an empty one. Richer garbage
is worth far more:

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
  - Food can never cost him health or hunger.
  - Spoiled food loses none of its value to him.
  - Monster food and raw meat carry no penalty of any kind.

Sanity is the only meter eating can still cost him. Anything that would
normally hurt him adds that damage onto the food's sanity cost, so a food
that already drained sanity drains that much more of it. Durian normally
takes 3 health and 5 sanity; for Slurg it takes 8 sanity and no health.

Mushrooms are the one thing that still really hurts him. A raw Red Cap
normally takes 20 health and no sanity, so for Slurg it takes 20 sanity.

They do fill him, though. Every mushroom restores an extra 2% of his stomach
on top of its own hunger, 2 at level 0 and 20 at the cap. Fungus is food and
poison at once.

A FED SLURG IS A FAST SLURG
His belly sets a speed bonus either side of normal: a quarter slower when
empty, dead level with everyone at half full, a quarter faster at three
quarters and above.

Levelling then pulls the two halves apart. The reward for being full grows to
three times its size, and the penalty for being empty wears away to nothing, so
half a belly is always the break-even point. Speeds are multiples of Wilson's
run, which is what every character is measured against:

                       empty     half full    3/4 full or more
  Level 0 .........    x0.75       x1.00          x1.25
  Level 2500 ......    x0.88       x1.00          x1.50
  Level 5000 ......    x1.00       x1.00          x1.75

A full Level 0 Slurg matches a Walking Cane. A full maxed Slurg just edges out
a Hound. By the cap, running on empty costs him nothing at all.

His size grows with his Level too, half again to triple, but that is cosmetic
and does not change how fast he moves.

SLIME REGENERATION
He heals himself, but only while fed. Below half a stomach it stops entirely.
Above that it speeds up smoothly the fuller he is, and again the further he
has levelled. Seconds per hit point:

  belly          level 0    level 2500   level 5000
   50% .......... 240 .......... 53 .......... 30
   70% .......... 140 .......... 31 .......... 18
   90% ........... 40 ........... 9 ........... 5

Every hunger point and every level counts, not just these. At the cap he heals
eight times faster than a fresh Slurg, which more than covers his health bar
being six times bigger.

THE CATCH
  - Fragile start. 50 health and a tiny stomach.
  - Always hungry. He burns food 35% faster than everyone else.
  - Feast or famine. Below half a stomach he stops healing entirely, at any
    Level. The speed penalty wears off as he grows; the healing never does.

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
