-- This information tells other players more about the mod
name = "Slurg"
description = [[
A scavenger who turns the world's garbage into growth. Slurg starts small,
frail and slow, then eats his way into becoming the biggest thing on the map.

EAT GARBAGE, GROW
Every piece of filth he swallows raises his Level, permanently increasing his
health, stomach, damage and size. The cap is Level 5000.

  Rot, Spoiled Fish ....... +1 level    constant, everywhere
  Poop, Guano ............. +2 levels   beefalo, pigs, caves
  Compost ................. +5 levels   needs a Composting Bin
  Rotten Egg .............. +10 levels  birdcage farming
  Glommer's Goop .......... +25 levels  one per full moon


AS HE LEVELS                  level 0  ->  max level

  Health .................... 50       ->  300
  Stomach ................... 100      ->  1000
  Sanity .................... 150      ->  150
  Damage .................... 1x       ->  2.5x
  Size ...................... 1.5x     ->  3x
  Speed, full belly ......... 1.33x    ->  2x
  Speed, empty belly ........ 0.67x    ->  0.67x


FOOD VALUES                   health / hunger / sanity

  Rot .............. -1 / -10 / 0    ->  +3 / 2-11 / +1      (Slurg)
  Spoiled Fish ..... -1 / -10 / 0    ->  +3 / 2-11 / +1      (Slurg)
  Rotten Egg ....... -1 / -10 / 0    ->  +25 / 10-55 / +10   (Slurg)
  Poop ............. inedible        ->  +4 / 13-40 / +5     (Slurg)
  Guano ............ inedible        ->  +5 / 14-50 / +5     (Slurg)
  Compost .......... inedible        ->  +15 / 21-75 / +15   (Slurg)
  Glommer's Goop ... +40 / 9 / -50   ->  +50 / 30-120 / +50  (Slurg)
  Wet Goop ......... 0 / 0 / 0       ->  +5 / +5 / +5        (Slurg)
  Gears ............ +60 / 75 / +50  ->  +10 / 12.5 / +10    (Slurg)

  Raw meat ......... full value      ->  half value          (Slurg)
  Monster food ..... full value      ->  half value          (Slurg)
  Mushrooms ........ hurts health    ->  costs sanity        (Slurg)
  Everything else .. penalties       ->  no penalties        (Slurg)

Hunger ranges grow with level, since garbage fills a share of his stomach.
Poop, Guano and Compost are food for Slurg alone; nobody else can touch them.


IRON GUT
Spoiled food loses nothing. Monster meat costs him nothing. No food in the
game can drain his health, hunger or sanity.

Mushrooms are the one exception. Their toxicity still bites, but it hits his
mind instead of his body: a mushroom's health damage becomes sanity loss.


A FULL SLURG IS A FAST SLURG
He swells as he fills up and shrinks as he empties, and his size carries his
speed with it. An empty Slurg crawls no matter how much he has eaten in his
life. All that progress is only worth something if you keep him fed.


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
version = "1.05" -- This is the version of the template. Change it to your own number.

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
