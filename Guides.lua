local _, ns = ...

-- Leveling guides for the crafter alts, from wow-professions.com's Forever
-- guides (beta data, October 2026). `uses` lists everything a step consumes
-- in total; only the mats in `mats` are routed between alts, the vendor
-- items (vials, thread, flux, dye) just show on the guide panel.
-- Steps with a `choice` only count when that option is picked
-- (/mb path <choice> <option>; the first option is the default). A step can
-- name one `option` or a list of `options`. `makes` credits items a step
-- produces that a later step uses; `madeFrom` turns an in-between item the
-- crafter is short of back into the raw mats it's made from (one source, or
-- a list of them). Gathering guides (Mining) have `zones` steps instead of
-- crafts, and `window` names the trade window they dock to.
--
-- Update from:
--   https://www.wow-professions.com/forever/alchemy-leveling-guide
--   https://www.wow-professions.com/forever/leatherworking-leveling-guide
--   https://www.wow-professions.com/forever/tailoring-leveling-guide
--   https://www.wow-professions.com/forever/enchanting-leveling-guide
--   https://www.wow-professions.com/forever/blacksmithing-leveling-guide
--   https://www.wow-professions.com/forever/mining-leveling-guide

-- Herbs
local PEACEBLOOM, SILVERLEAF, MAGEROYAL, EARTHROOT, BRIARTHORN = 2447, 765, 785, 2449, 2450
local STRANGLEKELP, KINGSBLOOD, LIFEROOT, ARTHAS_TEARS = 3820, 3356, 3357, 8836
local SUNGRASS, BLINDWEED, FIREFIN, PURPLE_LOTUS = 8838, 8839, 6359, 8831
local FIRE_OIL, ELIXIR_WISDOM = 6371, 3383

-- Leather
local SCRAPS, LIGHT_LEATHER, LIGHT_HIDE, MEDIUM_LEATHER, MEDIUM_HIDE = 2934, 2318, 783, 2319, 4232
local HEAVY_LEATHER, HEAVY_HIDE, THICK_LEATHER = 4234, 4235, 4304
local CURED_LIGHT, CURED_MEDIUM, CURED_HEAVY, FINE_BELT = 4231, 4233, 4236, 4246

-- Cloth and bolts
local LINEN, WOOL, SILK, MAGEWEAVE = 2589, 2592, 4306, 4338
local BOLT_LINEN, BOLT_WOOL, BOLT_SILK, BOLT_MAGEWEAVE = 2996, 2997, 4305, 4339

-- Enchanting mats
local STRANGE_DUST, SOUL_DUST, VISION_DUST, DREAM_DUST, ILLUSION_DUST = 10940, 11083, 11137, 11176, 16204
local LESSER_MAGIC, GREATER_ASTRAL, GREATER_MYSTIC, LESSER_NETHER, GREATER_ETERNAL = 10938, 11082, 11135, 11174, 16203
local SMALL_BRILLIANT, LARGE_BRILLIANT = 14343, 14344
local SHADOWGEM, IRIDESCENT_PEARL, BLACK_PEARL, GOLDEN_PEARL = 1210, 5500, 7971, 12800
local COPPER_ROD, SILVER_ROD, GOLDEN_ROD, TRUESILVER_ROD, ARCANITE_ROD = 6217, 11128, 11144, 11145, 16206
local MOTE_OF_MAGIC = 247786 -- Forever-only vendor reagent

-- Ore, bars and stone
local COPPER_ORE, TIN_ORE, SILVER_ORE, IRON_ORE, GOLD_ORE, MITHRIL_ORE = 2770, 2771, 2775, 2772, 2776, 3858
local COPPER_BAR, TIN_BAR, BRONZE_BAR, SILVER_BAR, IRON_BAR, GOLD_BAR = 2840, 3576, 2841, 2842, 3575, 3577
local STEEL_BAR, MITHRIL_BAR = 3859, 3860
local ROUGH_STONE, COARSE_STONE, HEAVY_STONE, SOLID_STONE = 2835, 2836, 2838, 7912
local ROUGH_GS, COARSE_GS, HEAVY_GS, SOLID_GS = 3470, 3478, 3486, 7966

-- Vendor items
local EMPTY_VIAL, LEADED_VIAL, CRYSTAL_VIAL = 3371, 3372, 8925
local SALT, COARSE_THREAD, FINE_THREAD, SILKEN_THREAD, HEAVY_SILKEN_THREAD = 4289, 2320, 2321, 4291, 8343
local GRAY_DYE, RED_DYE, GREEN_DYE = 4340, 2604, 2605
local MOSS_AGATE, IRON_BUCKLE = 1206, 7071
local MAPLE_SEED, STRANGLETHORN_SEED = 17034, 17035
local WEAK_FLUX, STRONG_FLUX, COAL = 2880, 3466, 3857

-- Trainer ranks. Learn the next rank once you reach `skill`, before you hit
-- the cap; `max` is the new cap it gives.
local function ranks(journeyman, expert, artisan)
	return {
		{ name = "Journeyman", skill = 50, level = 10, max = 150, trainers = journeyman },
		{ name = "Expert", skill = 125, level = 20, max = 225, cost = "50s", trainers = expert },
		{ name = "Artisan", skill = 200, level = 35, max = 300, trainers = artisan },
	}
end

ns.GUIDES = {
	{
		key = "alchemy", name = "Alchemy", skillLine = 171, top = 290,
		choices = { oil = { "fireoil", "manapot", label = "130-165" } },
		mats = { PEACEBLOOM, SILVERLEAF, MAGEROYAL, EARTHROOT, BRIARTHORN, STRANGLEKELP, FIREFIN,
			KINGSBLOOD, LIFEROOT, ARTHAS_TEARS, SUNGRASS, BLINDWEED },
		madeFrom = { [FIRE_OIL] = { FIREFIN, 1 } },
		ranks = ranks(
			{ Horde = "Yelmak (Orgrimmar), Doctor Marsh (Undercity), Bena Winterhoof (Thunder Bluff)",
			  Alliance = "Lilyssia Nightbreeze (Stormwind), Tally Berryfizz (Ironforge), Sylvanna Forestmoon (Darnassus)" },
			{ Horde = "Doctor Herbert Halsey (Undercity)", Alliance = "Ainethil (Darnassus)" },
			{ Horde = "Rogvar (Stonard, Swamp of Sorrows)", Alliance = "Kylanna Windwhisper (Feathermoon Stronghold, Feralas)" }),
		steps = {
			{ lo = 1,   hi = 10,  crafts = 9,  recipe = "Minor Arcane Elixir", uses = { [PEACEBLOOM] = 9, [EMPTY_VIAL] = 9 },
				note = "Vials: Alchemy or Trade Supply vendor, most trainers have one nearby." },
			{ lo = 10,  hi = 55,  crafts = 45, recipe = "Elixir of Minor Defense", uses = { [SILVERLEAF] = 45, [PEACEBLOOM] = 45, [EMPTY_VIAL] = 45 } },
			{ lo = 55,  hi = 65,  crafts = 10, recipe = "Minor Mana Potion", uses = { [MAGEROYAL] = 10, [PEACEBLOOM] = 10, [EMPTY_VIAL] = 10 } },
			{ lo = 65,  hi = 90,  crafts = 27, recipe = "Elixir of Minor Fortitude", uses = { [EARTHROOT] = 54, [PEACEBLOOM] = 27, [EMPTY_VIAL] = 27 },
				note = "Turns yellow at 80, so the last 10 points take a few more crafts." },
			{ lo = 90,  hi = 120, crafts = 30, recipe = "Elixir of Wisdom", uses = { [MAGEROYAL] = 30, [BRIARTHORN] = 60, [EMPTY_VIAL] = 30 },
				makes = { [ELIXIR_WISDOM] = 30 },
				note = "Keep the elixirs: your Tailor's Gloves of Meditation use 29 of them." },
			{ lo = 120, hi = 130, crafts = 10, recipe = "Lesser Mana Potion", uses = { [MAGEROYAL] = 10, [STRANGLEKELP] = 10, [EMPTY_VIAL] = 10 } },
			{ lo = 130, hi = 150, crafts = 20, recipe = "Fire Oil", choice = "oil", option = "fireoil",
				uses = { [FIREFIN] = 40, [EMPTY_VIAL] = 20 }, makes = { [FIRE_OIL] = 40 },
				note = "2 oils per craft. Keep 30 for the Elixir of Fire Power at 150." },
			{ lo = 130, hi = 150, crafts = 20, recipe = "Lesser Mana Potion", choice = "oil", option = "manapot",
				uses = { [MAGEROYAL] = 20, [STRANGLEKELP] = 20, [EMPTY_VIAL] = 20 } },
			{ lo = 150, hi = 165, crafts = 15, recipe = "Elixir of Fire Power", choice = "oil", option = "fireoil",
				uses = { [FIRE_OIL] = 30, [KINGSBLOOD] = 15, [LEADED_VIAL] = 15 }, note = "Uses the Fire Oil you kept." },
			{ lo = 150, hi = 165, crafts = 22, recipe = "Lesser Mana Potion", choice = "oil", option = "manapot",
				uses = { [MAGEROYAL] = 22, [STRANGLEKELP] = 22, [EMPTY_VIAL] = 22 } },
			{ lo = 165, hi = 195, crafts = 36, recipe = "Mana Potion", uses = { [STRANGLEKELP] = 36, [KINGSBLOOD] = 36, [LEADED_VIAL] = 36 } },
			{ lo = 195, hi = 225, crafts = 36, recipe = "Nature Protection Potion", uses = { [LIFEROOT] = 36, [STRANGLEKELP] = 36, [LEADED_VIAL] = 36 },
				note = "Recipe is bind on pickup, buy it on this alt: Bronk or Logannas (Feralas), Glyx Brewright (Stranglethorn), Alchemist Pestlezugg (Tanaris)." },
			-- 225+ is untested in the guide (beta cap). 290-300 isn't decided yet.
			{ lo = 225, hi = 230, crafts = 12, recipe = "Nature Protection Potion", uses = { [LIFEROOT] = 12, [STRANGLEKELP] = 12, [LEADED_VIAL] = 12 } },
			{ lo = 230, hi = 265, crafts = 45, recipe = "Draught of Detect Undead", uses = { [ARTHAS_TEARS] = 45, [CRYSTAL_VIAL] = 45 },
				note = "Yellow from 245, so expect a few extra crafts." },
			{ lo = 265, hi = 275, crafts = 10, recipe = "Superior Mana Potion", uses = { [SUNGRASS] = 20, [BLINDWEED] = 20, [CRYSTAL_VIAL] = 10 },
				note = "Recipe: Algernon (Undercity) or Ulthir (Darnassus)." },
			{ lo = 275, hi = 290, crafts = 20, recipe = "Superior Mana Potion", uses = { [SUNGRASS] = 40, [BLINDWEED] = 40, [CRYSTAL_VIAL] = 20 },
				note = "Already yellow. Elixir of Greater Defense or Elixir of Shadow Power also work if they're cheaper." },
		},
	},
	{
		key = "leatherworking", name = "Leatherworking", skillLine = 165, top = 225,
		choices = {
			start = { "scraps", "kit", label = "1-30" },
			heavy = { "hide", "nohide", label = "130-175" },
		},
		mats = { SCRAPS, LIGHT_LEATHER, LIGHT_HIDE, MEDIUM_LEATHER, MEDIUM_HIDE, HEAVY_LEATHER, HEAVY_HIDE, THICK_LEATHER },
		madeFrom = {
			[CURED_LIGHT] = { LIGHT_HIDE, 1 }, [CURED_MEDIUM] = { MEDIUM_HIDE, 1 },
			[CURED_HEAVY] = { HEAVY_HIDE, 1 }, [FINE_BELT] = { LIGHT_LEATHER, 6 },
		},
		ranks = ranks(
			{ Horde = "Karolek (Orgrimmar), Arthur Moore (Undercity), Tarn (Thunder Bluff)",
			  Alliance = "Simon Tanner (Stormwind), Fimble Finespindle (Ironforge), Faldron (Darnassus)" },
			{ Horde = "Una (Thunder Bluff)", Alliance = "Telonis (Darnassus)" },
			{ Horde = "Hahrana Ironhide (Camp Mojache, Feralas)", Alliance = "Drakk Stonehand (Aerie Peak, Hinterlands)" }),
		steps = {
			{ lo = 1,   hi = 30,  crafts = 33, recipe = "Light Leather", choice = "start", option = "scraps",
				uses = { [SCRAPS] = 100 }, makes = { [LIGHT_LEATHER] = 33 }, note = "Turns yellow at 20." },
			{ lo = 1,   hi = 30,  crafts = 27, recipe = "Light Armor Kit", choice = "start", option = "kit",
				uses = { [LIGHT_LEATHER] = 27 }, note = "1 Light Leather each." },
			{ lo = 30,  hi = 55,  crafts = 27, recipe = "Cured Light Hide", uses = { [LIGHT_HIDE] = 27, [SALT] = 27 },
				makes = { [CURED_LIGHT] = 27 }, note = "Keep 24 for the Light Leather Pants at 100." },
			{ lo = 55,  hi = 75,  crafts = 21, recipe = "Embossed Leather Gloves", uses = { [LIGHT_LEATHER] = 63, [COARSE_THREAD] = 42 } },
			{ lo = 75,  hi = 80,  crafts = 8,  recipe = "Medium Leather", uses = { [LIGHT_LEATHER] = 32 }, makes = { [MEDIUM_LEATHER] = 8 } },
			{ lo = 80,  hi = 90,  crafts = 10, recipe = "Cured Medium Hide", uses = { [MEDIUM_HIDE] = 10, [SALT] = 10 },
				makes = { [CURED_MEDIUM] = 10 }, note = "Keep them for the Dark Leather Belts at 115." },
			{ lo = 90,  hi = 100, crafts = 19, recipe = "Fine Leather Belt", uses = { [LIGHT_LEATHER] = 114, [COARSE_THREAD] = 38 },
				makes = { [FINE_BELT] = 19 }, note = "Keep 10 belts for the Dark Leather Belts at 115." },
			{ lo = 100, hi = 115, crafts = 24, recipe = "Light Leather Pants", uses = { [LIGHT_LEATHER] = 240, [CURED_LIGHT] = 24, [FINE_THREAD] = 24 } },
			{ lo = 115, hi = 125, crafts = 10, recipe = "Dark Leather Belt",
				uses = { [FINE_BELT] = 10, [CURED_MEDIUM] = 10, [FINE_THREAD] = 20, [GRAY_DYE] = 10 } },
			{ lo = 125, hi = 130, crafts = 7,  recipe = "Heavy Leather", uses = { [MEDIUM_LEATHER] = 35 }, makes = { [HEAVY_LEATHER] = 7 } },
			{ lo = 130, hi = 140, crafts = 20, recipe = "Cured Heavy Hide", choice = "heavy", option = "hide",
				uses = { [HEAVY_HIDE] = 20, [SALT] = 60 }, makes = { [CURED_HEAVY] = 20 }, note = "You need these later." },
			{ lo = 140, hi = 155, crafts = 20, recipe = "Hillman's Leather Gloves", choice = "heavy", option = "hide",
				uses = { [MEDIUM_LEATHER] = 280, [FINE_THREAD] = 80 } },
			{ lo = 155, hi = 165, crafts = 10, recipe = "Barbaric Shoulders", choice = "heavy", option = "hide",
				uses = { [HEAVY_LEATHER] = 80, [CURED_HEAVY] = 10, [FINE_THREAD] = 20 } },
			{ lo = 165, hi = 175, crafts = 10, recipe = "Guardian Gloves", choice = "heavy", option = "hide",
				uses = { [HEAVY_LEATHER] = 40, [CURED_HEAVY] = 10, [SILKEN_THREAD] = 10 } },
			{ lo = 130, hi = 155, crafts = 30, recipe = "Hillman's Leather Gloves", choice = "heavy", option = "nohide",
				uses = { [MEDIUM_LEATHER] = 420, [FINE_THREAD] = 120 } },
			{ lo = 155, hi = 170, crafts = 17, recipe = "Barbaric Leggings", choice = "heavy", option = "nohide",
				uses = { [HEAVY_LEATHER] = 170, [FINE_THREAD] = 34, [MOSS_AGATE] = 17 },
				note = "Pattern: Jandia (Thousand Needles), Keena or Hammon Karwn (Arathi Highlands), Lardan (Ashenvale)." },
			{ lo = 170, hi = 175, crafts = 5,  recipe = "Barbaric Harness", choice = "heavy", option = "nohide",
				uses = { [HEAVY_LEATHER] = 70, [FINE_THREAD] = 10, [IRON_BUCKLE] = 5 } },
			-- Both routes meet here. Without Heavy Hide you buy or skin the 26 hides for this step.
			{ lo = 175, hi = 195, crafts = 26, recipe = "Guardian Gloves", uses = { [HEAVY_LEATHER] = 104, [CURED_HEAVY] = 26, [SILKEN_THREAD] = 26 },
				note = "Got Heavy Hide instead? Cure it first, 3 Salt each." },
			{ lo = 195, hi = 210, crafts = 21, recipe = "Nightscape Headband", uses = { [THICK_LEATHER] = 105, [SILKEN_THREAD] = 42 } },
			{ lo = 210, hi = 225, crafts = 15, recipe = "Nightscape Pants", uses = { [THICK_LEATHER] = 210, [SILKEN_THREAD] = 60 },
				note = "Only the Artisan trainers teach this one, not the Expert trainers." },
			-- The guide stops at 225 until Forever's level cap allows more.
		},
	},
	{
		key = "tailoring", name = "Tailoring", skillLine = 197, top = 225,
		choices = {
			silk = { "bolts", "shoulders", label = "100-120" },
			mageweave = { "bolts", "shirts", label = "140-150" },
		},
		-- Cloth drops for everyone, so every alt routes it here. The elixirs
		-- come from the Alchemy alt (or the AH).
		mats = { LINEN, WOOL, SILK, MAGEWEAVE, ELIXIR_WISDOM },
		madeFrom = {
			[BOLT_LINEN] = { LINEN, 2 }, [BOLT_WOOL] = { WOOL, 3 },
			[BOLT_SILK] = { SILK, 4 }, [BOLT_MAGEWEAVE] = { MAGEWEAVE, 5 },
		},
		ranks = ranks(
			{ Horde = "Magar (Orgrimmar), Rhiannon Davis (Undercity), Tepa (Thunder Bluff)",
			  Alliance = "Sellandus (Stormwind), Jormund Stonebrow (Ironforge), Me'lynn (Darnassus)" },
			{ Horde = "Josef Gregorian (Undercity)", Alliance = "Georgio Bolero (Stormwind)" },
			{ Horde = "Daryl Stack (Tarren Mill, Hillsbrad Foothills)", Alliance = "Timothy Worthington (Theramore, Dustwallow Marsh)" }),
		steps = {
			{ lo = 1,   hi = 30,  crafts = 30, recipe = "Bolt of Linen Cloth", uses = { [LINEN] = 60 }, makes = { [BOLT_LINEN] = 30 },
				note = "Keep the bolts for the belts. Thread and dye: Tailoring Supply vendor by the trainer (in Tirisfal, Abigail Shiel in Brill)." },
			{ lo = 30,  hi = 55,  crafts = 28, recipe = "Linen Belt", uses = { [BOLT_LINEN] = 28, [COARSE_THREAD] = 28 } },
			{ lo = 55,  hi = 80,  crafts = 45, recipe = "Bolt of Woolen Cloth", uses = { [WOOL] = 135 }, makes = { [BOLT_WOOL] = 45 },
				note = "Learn Journeyman first or you stop at 75. You need 153 bolts (459 Wool) through 140, so make them all now if you like." },
			{ lo = 80,  hi = 95,  crafts = 22, recipe = "Woolen Cape", uses = { [BOLT_WOOL] = 22, [FINE_THREAD] = 22 },
				note = "If the bolts already took you past 80, make capes until 95." },
			{ lo = 95,  hi = 100, crafts = 5,  recipe = "Double-stitched Woolen Shoulders", uses = { [BOLT_WOOL] = 15, [FINE_THREAD] = 10 } },
			{ lo = 100, hi = 120, crafts = 54, recipe = "Bolt of Silk Cloth", choice = "silk", option = "bolts",
				uses = { [SILK] = 216 }, makes = { [BOLT_SILK] = 54 },
				note = "Keep the bolts: 184 (736 Silk) through 190." },
			{ lo = 100, hi = 120, crafts = 23, recipe = "Double-stitched Woolen Shoulders", choice = "silk", option = "shoulders",
				uses = { [BOLT_WOOL] = 69, [FINE_THREAD] = 46 },
				note = "Beta route for an alt that stops at 150. The silk bolts still get made later." },
			{ lo = 120, hi = 125, crafts = 5,  recipe = "Gloves of Meditation",
				uses = { [BOLT_WOOL] = 20, [FINE_THREAD] = 15, [ELIXIR_WISDOM] = 5 },
				note = "Elixir of Wisdom: your Alchemy alt makes 30 at 90-120, or the AH." },
			{ lo = 125, hi = 140, crafts = 24, recipe = "Gloves of Meditation",
				uses = { [BOLT_WOOL] = 96, [FINE_THREAD] = 72, [ELIXIR_WISDOM] = 24 },
				note = "Expert first. Yellow the whole way, so expect a few extra crafts." },
			{ lo = 140, hi = 150, crafts = 23, recipe = "Bolt of Mageweave", choice = "mageweave", option = "bolts",
				uses = { [MAGEWEAVE] = 115 }, makes = { [BOLT_MAGEWEAVE] = 23 },
				note = "Keep the bolts: 180 (900 Mageweave) through 225." },
			{ lo = 140, hi = 150, crafts = 10, recipe = "Red Swashbuckler's Shirt", choice = "mageweave", option = "shirts",
				uses = { [BOLT_SILK] = 30, [RED_DYE] = 20, [SILKEN_THREAD] = 10 },
				note = "Beta: Mageweave is rare and dear, the shirts use silk instead." },
			{ lo = 150, hi = 170, crafts = 20, recipe = "Crimson Silk Vest", uses = { [BOLT_SILK] = 80, [RED_DYE] = 40, [FINE_THREAD] = 40 } },
			{ lo = 170, hi = 190, crafts = 26, recipe = "Crimson Silk Pantaloons", uses = { [BOLT_SILK] = 104, [RED_DYE] = 52, [SILKEN_THREAD] = 52 },
				note = "Yellow at 180. Beta: Bolt of Mageweave is cheaper on the AH than the cloth." },
			{ lo = 190, hi = 215, crafts = 38, recipe = "Black Mageweave Gloves", uses = { [BOLT_MAGEWEAVE] = 76, [HEAVY_SILKEN_THREAD] = 76 },
				note = "Yellow from 195, green from 210, so expect extra crafts." },
			{ lo = 215, hi = 225, crafts = 26, recipe = "Mageweave Bag", uses = { [BOLT_MAGEWEAVE] = 104, [SILKEN_THREAD] = 52 } },
			-- 225-300 isn't written yet (Artisan untested on beta).
		},
	},
	{
		key = "enchanting", name = "Enchanting", skillLine = 333, top = 300,
		choices = {
			ench = { "essence", "dust", "noformula", label = "20-150" },
			vision = { "souldust", "visiondust", label = "185-200" },
			lotus = { "manaoil", "bracer", label = "250-265" },
		},
		-- Dusts and essences mostly come from this alt's own disenchanting;
		-- the rods come from the Blacksmith.
		mats = { STRANGE_DUST, LESSER_MAGIC, SOUL_DUST, VISION_DUST, DREAM_DUST, ILLUSION_DUST,
			GREATER_ASTRAL, GREATER_MYSTIC, LESSER_NETHER, GREATER_ETERNAL, SMALL_BRILLIANT, LARGE_BRILLIANT,
			SHADOWGEM, IRIDESCENT_PEARL, BLACK_PEARL, GOLDEN_PEARL, PURPLE_LOTUS,
			SILVER_ROD, GOLDEN_ROD, TRUESILVER_ROD, ARCANITE_ROD },
		madeFrom = {},
		ranks = ranks(
			{ Horde = "Godan (Orgrimmar), Lavinia Crowe (Undercity), Teg Dawnstrider (Thunder Bluff)",
			  Alliance = "Lucan Cordell (Stormwind), Gimble Thistlefuzz (Ironforge), Taladan (Darnassus)" },
			{ Horde = "Hgarth (Sun Rock Retreat, Stonetalon Mountains)", Alliance = "Kitta Firewind (top of the Tower of Azora, Elwynn Forest)" },
			{ Horde = "Annora (Uldaman, both factions)", Alliance = "Annora (Uldaman, both factions)" }),
		steps = {
			{ lo = 1,   hi = 2,   crafts = 1,  recipe = "Runed Copper Rod", uses = { [COPPER_ROD] = 1, [MOTE_OF_MAGIC] = 1 },
				note = "Rod and Motes: Enchanting Supply vendor by the capital trainer (10c each), not the AH. Starting-zone trainers don't have one, except Zephras Isle." },
			{ lo = 2,   hi = 20,  crafts = 18, recipe = "Enchant Bracer - Inferior Stamina", uses = { [MOTE_OF_MAGIC] = 18 } },
			{ lo = 20,  hi = 70,  crafts = 50, recipe = "Enchant Bracer - Minor Deflect", choice = "ench", options = { "essence", "noformula" },
				uses = { [LESSER_MAGIC] = 50 }, note = "Greater Magic Essence splits into 3 Lesser (right-click it)." },
			{ lo = 20,  hi = 70,  crafts = 50, recipe = "Enchant Chest - Inferior Stamina", choice = "ench", option = "dust",
				uses = { [STRANGE_DUST] = 50 } },
			{ lo = 70,  hi = 100, crafts = 33, recipe = "Enchant Chest - Minor Absorption", choice = "ench", options = { "essence", "noformula" },
				uses = { [LESSER_MAGIC] = 33 }, note = "Journeyman first." },
			{ lo = 100, hi = 109, crafts = 18, recipe = "Enchant Chest - Minor Absorption", choice = "ench", options = { "essence", "noformula" },
				uses = { [LESSER_MAGIC] = 18 } },
			{ lo = 70,  hi = 100, crafts = 30, recipe = "Enchant Bracer - Minor Stamina", choice = "ench", option = "dust",
				uses = { [STRANGE_DUST] = 60 }, note = "Journeyman first." },
			{ lo = 100, hi = 109, crafts = 9,  recipe = "Enchant Cloak - Minor Protection", choice = "ench", option = "dust",
				uses = { [STRANGE_DUST] = 18 } },
			{ lo = 109, hi = 110, crafts = 1,  recipe = "Runed Silver Rod",
				uses = { [SILVER_ROD] = 1, [STRANGE_DUST] = 3, [LESSER_MAGIC] = 4, [SHADOWGEM] = 1 },
				note = "Silver Rod: your Blacksmith makes it (Silver Bar + 2 Rough Grinding Stone), or the AH." },
			{ lo = 110, hi = 130, crafts = 20, recipe = "Enchant 2H Weapon - Lesser Intellect", choice = "ench", option = "essence",
				uses = { [LESSER_MAGIC] = 80 },
				note = "Formula: Kithas (Orgrimmar), Nata Dawnstrider (Thunder Bluff), Leo Sarn (Silverpine), Tilli Thistlefuzz (Ironforge). Buy Minor Mana Oil and Lesser Wizard Oil there too, for 150 and 200." },
			{ lo = 130, hi = 150, crafts = 32, recipe = "Enchant 2H Weapon - Lesser Intellect", choice = "ench", option = "essence",
				uses = { [LESSER_MAGIC] = 128 } },
			{ lo = 110, hi = 130, crafts = 32, recipe = "Enchant Cloak - Minor Protection", choice = "ench", options = { "dust", "noformula" },
				uses = { [STRANGE_DUST] = 64 } },
			{ lo = 130, hi = 150, crafts = 20, recipe = "Enchant Boots - Minor Stamina", choice = "ench", options = { "dust", "noformula" },
				uses = { [STRANGE_DUST] = 80 },
				note = "If 20 Soul Dust costs less than 80 Strange Dust, make Enchant Bracer - Lesser Stamina instead." },
			{ lo = 150, hi = 151, crafts = 1,  recipe = "Runed Golden Rod",
				uses = { [GOLDEN_ROD] = 1, [IRIDESCENT_PEARL] = 1, [GREATER_ASTRAL] = 1, [SOUL_DUST] = 1 }, note = "Expert first." },
			{ lo = 151, hi = 165, crafts = 16, recipe = "Minor Mana Oil",
				uses = { [SOUL_DUST] = 16, [MAPLE_SEED] = 32, [LEADED_VIAL] = 16 },
				note = "Formula: Kithas, Nata Dawnstrider, Thaddeus Webb (Undercity), Vaean (Darnassus), Tilli Thistlefuzz, Jessara Cordell (Stormwind). Maple Seed: Reagent vendor. Leaded Vial: Alchemy Supply." },
			{ lo = 165, hi = 185, crafts = 22, recipe = "Enchant Boots - Lesser Agility", uses = { [SOUL_DUST] = 22 } },
			{ lo = 185, hi = 200, crafts = 22, recipe = "Enchant Boots - Lesser Agility", choice = "vision", option = "souldust",
				uses = { [SOUL_DUST] = 22 }, note = "Beta: Vision Dust is dear at the cap and Soul Dust isn't. Yellow, so expect extra crafts." },
			{ lo = 185, hi = 200, crafts = 15, recipe = "Enchant Bracer - Strength", choice = "vision", option = "visiondust",
				uses = { [VISION_DUST] = 15 } },
			{ lo = 200, hi = 201, crafts = 1,  recipe = "Runed Truesilver Rod",
				uses = { [TRUESILVER_ROD] = 1, [BLACK_PEARL] = 1, [GREATER_MYSTIC] = 1, [VISION_DUST] = 1 } },
			{ lo = 201, hi = 220, crafts = 25, recipe = "Lesser Wizard Oil",
				uses = { [VISION_DUST] = 25, [STRANGLETHORN_SEED] = 50, [LEADED_VIAL] = 25 },
				note = "Stranglethorn Seed: Reagent vendor. Leaded Vial: Alchemy Supply." },
			{ lo = 220, hi = 225, crafts = 5,  recipe = "Enchant Cloak - Greater Defense", uses = { [VISION_DUST] = 5 } },
			-- 225+ is untested in the guide (beta cap); it's the Classic route.
			{ lo = 225, hi = 230, crafts = 5,  recipe = "Enchant Gloves - Agility", uses = { [VISION_DUST] = 5 },
				note = "Artisan: Annora in Uldaman (back entrance), she spawns once her room is cleared. Learn everything she teaches while you're there, about 100 Vision Dust gets you to 250." },
			{ lo = 230, hi = 235, crafts = 5,  recipe = "Enchant Boots - Stamina", uses = { [VISION_DUST] = 10 } },
			{ lo = 235, hi = 250, crafts = 20, recipe = "Enchant Chest - Superior Stamina", uses = { [VISION_DUST] = 60 } },
			{ lo = 250, hi = 265, crafts = 20, recipe = "Lesser Mana Oil", choice = "lotus", option = "manaoil",
				uses = { [DREAM_DUST] = 20, [PURPLE_LOTUS] = 20, [CRYSTAL_VIAL] = 20 },
				note = "Formula: Kania, upstairs at the Silithus inn. Crystal Vial: Mishta there, or any Alchemy Supply vendor." },
			{ lo = 250, hi = 265, crafts = 20, recipe = "Enchant Bracer - Greater Strength", choice = "lotus", option = "bracer",
				uses = { [DREAM_DUST] = 20, [LESSER_NETHER] = 40 }, note = "Taught by Annora. For when there's no Purple Lotus." },
			{ lo = 265, hi = 294, crafts = 32, recipe = "Enchant Shield - Greater Stamina", uses = { [DREAM_DUST] = 192 },
				note = "Formula: Daniel Bartlett (Undercity), Mythrin'dir (Darnassus). Bind on pickup, buy it on this alt." },
			{ lo = 294, hi = 295, crafts = 1,  recipe = "Runed Arcanite Rod",
				uses = { [ARCANITE_ROD] = 1, [GOLDEN_PEARL] = 1, [ILLUSION_DUST] = 10, [GREATER_ETERNAL] = 4, [SMALL_BRILLIANT] = 4, [LARGE_BRILLIANT] = 2 },
				note = "Formula: Lorelae Wintersong, Nighthaven (Moonglade). Buy the next formula there too." },
			{ lo = 295, hi = 300, crafts = 5,  recipe = "Enchant Cloak - Superior Defense", uses = { [ILLUSION_DUST] = 40 },
				note = "Or keep making Greater Stamina shields if Dream Dust is plentiful and Illusion Dust dear." },
		},
	},
	{
		key = "blacksmithing", name = "Blacksmithing", skillLine = 164, top = 225,
		choices = {
			rod = { "belt", "silverrod", label = "75-80" },
			mithril = { "mithril", "steel", label = "185-215" },
			spurs = { "breastplate", "spurs", label = "215-225" },
		},
		-- Ore and stone come from the Miner, Medium Leather from the Skinners.
		-- Bars are smelted from ore (or bought), so shortfalls show as ore.
		mats = { ROUGH_STONE, COARSE_STONE, HEAVY_STONE, SOLID_STONE,
			COPPER_ORE, TIN_ORE, SILVER_ORE, IRON_ORE, MITHRIL_ORE, MEDIUM_LEATHER },
		madeFrom = {
			[ROUGH_GS] = { ROUGH_STONE, 2 }, [COARSE_GS] = { COARSE_STONE, 2 },
			[HEAVY_GS] = { HEAVY_STONE, 3 }, [SOLID_GS] = { SOLID_STONE, 4 },
			[COPPER_BAR] = { COPPER_ORE, 1 }, [SILVER_BAR] = { SILVER_ORE, 1 },
			[IRON_BAR] = { IRON_ORE, 1 }, [MITHRIL_BAR] = { MITHRIL_ORE, 1 },
			[BRONZE_BAR] = { { COPPER_ORE, 0.5 }, { TIN_ORE, 0.5 } }, -- 1 Copper + 1 Tin = 2 Bronze
			[STEEL_BAR] = { { IRON_ORE, 1 }, { COAL, 1 } },
		},
		ranks = ranks(
			{ Horde = "Snarl (Orgrimmar), James Van Brunt (Undercity), Karn Stonehoof (Thunder Bluff)",
			  Alliance = "Therum Deepforge (Stormwind), Rotgath Stonebeard (Ironforge)" },
			{ Horde = "Saru Steelfury (Orgrimmar)", Alliance = "Bengus Deepforge (Ironforge)" },
			{ Horde = "Brikk Keencraft (Booty Bay, both factions)", Alliance = "Brikk Keencraft (Booty Bay, both factions)" }),
		steps = {
			{ lo = 1,   hi = 25,  crafts = 30, recipe = "Rough Sharpening Stone", uses = { [ROUGH_STONE] = 30 },
				note = "Buy a Blacksmith Hammer from the vendor by the trainer, you need it from 67." },
			{ lo = 25,  hi = 50,  crafts = 30, recipe = "Rough Grinding Stone", uses = { [ROUGH_STONE] = 60 }, makes = { [ROUGH_GS] = 30 },
				note = "Keep 26: 16 for the gauntlets at 67, 10 for Silver Rods at 75." },
			{ lo = 50,  hi = 67,  crafts = 36, recipe = "Coarse Grinding Stone", uses = { [COARSE_STONE] = 72 }, makes = { [COARSE_GS] = 36 },
				note = "Keep all 36 for the bracers at 95 and 112." },
			{ lo = 67,  hi = 75,  crafts = 8,  recipe = "Runed Copper Gauntlets", uses = { [COPPER_BAR] = 64, [ROUGH_GS] = 16 },
				note = "Journeyman at 75." },
			{ lo = 75,  hi = 80,  crafts = 5,  recipe = "Runed Copper Belt", choice = "rod", option = "belt", uses = { [COPPER_BAR] = 50 } },
			{ lo = 75,  hi = 80,  crafts = 5,  recipe = "Silver Rod", choice = "rod", option = "silverrod",
				uses = { [SILVER_BAR] = 5, [ROUGH_GS] = 10 }, makes = { [SILVER_ROD] = 5 },
				note = "If you have Silver Bars. Your Enchanter needs one of these at 109; the rest sell." },
			{ lo = 80,  hi = 95,  crafts = 15, recipe = "Rough Bronze Leggings", uses = { [BRONZE_BAR] = 90 } },
			{ lo = 95,  hi = 100, crafts = 5,  recipe = "Patterned Bronze Bracers", uses = { [BRONZE_BAR] = 25, [COARSE_GS] = 10 } },
			{ lo = 100, hi = 112, crafts = 20, recipe = "Heavy Grinding Stone", uses = { [HEAVY_STONE] = 60 }, makes = { [HEAVY_GS] = 20 },
				note = "Keep all 20 for the Golden Scale Bracers at 175." },
			{ lo = 112, hi = 125, crafts = 13, recipe = "Patterned Bronze Bracers", uses = { [BRONZE_BAR] = 65, [COARSE_GS] = 26 } },
			{ lo = 125, hi = 140, crafts = 24, recipe = "Bronze Shortsword", uses = { [BRONZE_BAR] = 120, [WEAK_FLUX] = 96, [MEDIUM_LEATHER] = 48 },
				note = "Flux: Blacksmithing Supply vendor by the trainer in every capital." },
			{ lo = 140, hi = 150, crafts = 10, recipe = "Bronze Warhammer", uses = { [BRONZE_BAR] = 80, [STRONG_FLUX] = 10, [MEDIUM_LEATHER] = 10 } },
			{ lo = 150, hi = 165, crafts = 19, recipe = "Bronze Warhammer", uses = { [BRONZE_BAR] = 152, [STRONG_FLUX] = 19, [MEDIUM_LEATHER] = 19 },
				note = "Expert first." },
			{ lo = 165, hi = 175, crafts = 15, recipe = "Green Iron Bracers", uses = { [IRON_BAR] = 90, [GREEN_DYE] = 15 },
				note = "Green Dye: Tamar (Orgrimmar) or Bombus Finespindle (Ironforge)." },
			{ lo = 175, hi = 185, crafts = 10, recipe = "Golden Scale Bracers", uses = { [STEEL_BAR] = 50, [HEAVY_GS] = 20 },
				note = "Steel: smelt Iron Bar + Coal yourself at Mining 165. Coal: Blacksmithing Supply vendor." },
			{ lo = 185, hi = 215, crafts = 36, recipe = "Mithril Plate Pants", choice = "mithril", option = "mithril", uses = { [MITHRIL_BAR] = 432 } },
			{ lo = 185, hi = 200, crafts = 15, recipe = "Steel Breastplate", choice = "mithril", option = "steel",
				uses = { [STEEL_BAR] = 240, [HEAVY_GS] = 45 }, note = "The steel route, for when Mithril is dearer than Steel + stone." },
			{ lo = 200, hi = 215, crafts = 17, recipe = "Steel Plate Helm", choice = "mithril", option = "steel",
				uses = { [STEEL_BAR] = 238, [SOLID_GS] = 17 } },
			{ lo = 215, hi = 225, crafts = 10, recipe = "Heavy Mithril Breastplate", choice = "spurs", option = "breastplate",
				uses = { [MITHRIL_BAR] = 160 }, note = "Artisan: Brikk Keencraft, Booty Bay." },
			{ lo = 215, hi = 225, crafts = 10, recipe = "Mithril Spurs", choice = "spurs", option = "spurs",
				uses = { [MITHRIL_BAR] = 40, [SOLID_GS] = 30 }, note = "Plans: Mithril Spurs is a world drop, check the AH." },
			-- 225+ is untested in the guide (beta cap).
		},
	},
	{
		key = "mining", name = "Mining", skillLine = 186, top = 300, window = "Smelting",
		choices = {},
		-- Nothing is routed to the Miner; the ore goes to the Blacksmith.
		-- These steps are where to mine and what to smelt for points.
		mats = {},
		madeFrom = {},
		ranks = ranks(
			{ Horde = "Makaru (Orgrimmar), Brom Killian (Undercity), Brek Stonehoof (Thunder Bluff)",
			  Alliance = "Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge), Kurdram Stonehammer (Auberdine)" },
			{ Horde = "Makaru (Orgrimmar), Brom Killian (Undercity), Brek Stonehoof (Thunder Bluff)",
			  Alliance = "Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge), Kurdram Stonehammer (Auberdine)" },
			{ Horde = "Makaru (Orgrimmar), Brom Killian (Undercity), Brek Stonehoof (Thunder Bluff)",
			  Alliance = "Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge), Kurdram Stonehammer (Auberdine)" }),
		steps = {
			{ lo = 1,   hi = 65,  recipe = "Mine Copper Ore",
				zones = { Horde = "Durotar (best), Mulgore, Tirisfal Glades, Zephras Isle",
					Alliance = "Elwynn Forest (best), Dun Morogh, Teldrassil, Zephras Isle" },
				note = "Smelt as you go at the forge in Razor Hill, Brill, Goldshire or Kharanos. Keep 70 Copper Bars for Bronze. Starting-zone trainers only teach to 75." },
			{ lo = 65,  hi = 75,  crafts = 70, recipe = "Smelt Tin", uses = { [TIN_ORE] = 70 }, makes = { [TIN_BAR] = 70 },
				note = "Learn Smelt Tin and Smelt Bronze at 65. Tin goes grey at 75." },
			{ lo = 75,  hi = 105, crafts = 70, recipe = "Smelt Bronze", uses = { [COPPER_BAR] = 70, [TIN_BAR] = 70 }, makes = { [BRONZE_BAR] = 140 },
				note = "2 bars a smelt. It may take a few more than 70 to reach 105." },
			{ lo = 105, hi = 125, recipe = "Mine Tin and Silver",
				zones = { Horde = "Silverpine Forest cave, Hillsbrad Foothills, the Barrens, Ashenvale, Stonetalon Mountains",
					Alliance = "Wetlands (best), Westfall, Hillsbrad Foothills, the Barrens, Ashenvale, Stonetalon Mountains" },
				note = "Smelt Silver (105) is optional, 35-45 smelts to 120. Ashenvale sometimes spawns Iron you can't mine until 125." },
			{ lo = 125, hi = 155, recipe = "Mine Iron",
				zones = { Horde = "Thousand Needles (about level 30), Arathi Highlands (higher, or mounted), Desolace",
					Alliance = "Thousand Needles (about level 30), Arathi Highlands (higher, or mounted), Desolace" },
				note = "Smelt Iron rarely gives a point after 135. Beta cap was 30, so Arathi and Desolace weren't tested." },
			{ lo = 155, hi = 170, crafts = 22, recipe = "Smelt Gold", uses = { [GOLD_ORE] = 22 }, makes = { [GOLD_BAR] = 22 },
				note = "Learn Smelt Gold at 155. A point every smelt to 170, and about 22 ore reaches 175." },
			{ lo = 170, hi = 175, recipe = "Mine Iron and Gold",
				zones = { Horde = "Arathi Highlands, Desolace", Alliance = "Arathi Highlands, Desolace" } },
			{ lo = 175, hi = 245, recipe = "Mine Mithril (Truesilver from 230)",
				zones = { Horde = "The Hinterlands, Tanaris", Alliance = "The Hinterlands, Tanaris" },
				note = "Train Artisan at 200, before you cap at 225." },
			{ lo = 245, hi = 275, recipe = "Mine Mithril, Truesilver and Small Thorium",
				zones = { Horde = "Un'Goro Crater, Blasted Lands, Felwood", Alliance = "Un'Goro Crater, Felwood, Blasted Lands (not inside the Garrison Armory)" } },
			{ lo = 275, hi = 300, recipe = "Mine Thorium and Rich Thorium",
				zones = { Horde = "Un'Goro Crater, Eastern Plaguelands, Winterspring, Burning Steppes",
					Alliance = "Un'Goro Crater, Eastern Plaguelands, Winterspring, Burning Steppes" } },
		},
	},
}

-- Gathered mats no guide uses. They always go to the surplus (AH) alt.
ns.EXTRA_MATS = {
	2452, 2453, 3355, 3358, 3369, 3818, 3819, 3821, 4625, 8845, 8846,
	13463, 13464, 13465, 13466, 13467, 13468,  -- herbs
	8169, 8170, 8171,                          -- Thick Hide, Rugged Leather, Rugged Hide
	7911, 10620, 11370, 7909, 7910, 3864, 1529, 1705,  -- Truesilver/Thorium/Dark Iron Ore, gems
	10939,                                     -- Greater Magic Essence (split it for Lesser)
}

local NAMES = {
	[PEACEBLOOM] = "Peacebloom", [SILVERLEAF] = "Silverleaf", [MAGEROYAL] = "Mageroyal",
	[EARTHROOT] = "Earthroot", [BRIARTHORN] = "Briarthorn", [STRANGLEKELP] = "Stranglekelp",
	[KINGSBLOOD] = "Kingsblood", [LIFEROOT] = "Liferoot", [ARTHAS_TEARS] = "Arthas' Tears",
	[SUNGRASS] = "Sungrass", [BLINDWEED] = "Blindweed", [FIREFIN] = "Firefin Snapper", [FIRE_OIL] = "Fire Oil",
	[PURPLE_LOTUS] = "Purple Lotus", [ELIXIR_WISDOM] = "Elixir of Wisdom",
	[SCRAPS] = "Ruined Leather Scraps", [LIGHT_LEATHER] = "Light Leather", [LIGHT_HIDE] = "Light Hide",
	[MEDIUM_LEATHER] = "Medium Leather", [MEDIUM_HIDE] = "Medium Hide", [HEAVY_LEATHER] = "Heavy Leather",
	[HEAVY_HIDE] = "Heavy Hide", [THICK_LEATHER] = "Thick Leather", [CURED_LIGHT] = "Cured Light Hide",
	[CURED_MEDIUM] = "Cured Medium Hide", [CURED_HEAVY] = "Cured Heavy Hide", [FINE_BELT] = "Fine Leather Belt",
	[LINEN] = "Linen Cloth", [WOOL] = "Wool Cloth", [SILK] = "Silk Cloth", [MAGEWEAVE] = "Mageweave Cloth",
	[BOLT_LINEN] = "Bolt of Linen Cloth", [BOLT_WOOL] = "Bolt of Woolen Cloth",
	[BOLT_SILK] = "Bolt of Silk Cloth", [BOLT_MAGEWEAVE] = "Bolt of Mageweave",
	[SHADOWGEM] = "Shadowgem", [IRIDESCENT_PEARL] = "Iridescent Pearl", [BLACK_PEARL] = "Black Pearl",
	[GOLDEN_PEARL] = "Golden Pearl", [COPPER_ROD] = "Copper Rod", [SILVER_ROD] = "Silver Rod",
	[GOLDEN_ROD] = "Golden Rod", [TRUESILVER_ROD] = "Truesilver Rod", [ARCANITE_ROD] = "Arcanite Rod",
	[MOTE_OF_MAGIC] = "Mote of Magic",
	[COPPER_ORE] = "Copper Ore", [TIN_ORE] = "Tin Ore", [SILVER_ORE] = "Silver Ore", [IRON_ORE] = "Iron Ore",
	[GOLD_ORE] = "Gold Ore", [MITHRIL_ORE] = "Mithril Ore",
	[COPPER_BAR] = "Copper Bar", [TIN_BAR] = "Tin Bar", [BRONZE_BAR] = "Bronze Bar", [SILVER_BAR] = "Silver Bar",
	[IRON_BAR] = "Iron Bar", [GOLD_BAR] = "Gold Bar", [STEEL_BAR] = "Steel Bar", [MITHRIL_BAR] = "Mithril Bar",
	[ROUGH_STONE] = "Rough Stone", [COARSE_STONE] = "Coarse Stone", [HEAVY_STONE] = "Heavy Stone", [SOLID_STONE] = "Solid Stone",
	[ROUGH_GS] = "Rough Grinding Stone", [COARSE_GS] = "Coarse Grinding Stone",
	[HEAVY_GS] = "Heavy Grinding Stone", [SOLID_GS] = "Solid Grinding Stone",
	[2452] = "Swiftthistle", [2453] = "Bruiseweed", [3355] = "Wild Steelbloom", [3358] = "Khadgar's Whisker",
	[3369] = "Grave Moss", [3818] = "Fadeleaf", [3819] = "Wintersbite", [3821] = "Goldthorn",
	[4625] = "Firebloom", [8845] = "Ghost Mushroom", [8846] = "Gromsblood",
	[13463] = "Dreamfoil", [13464] = "Golden Sansam", [13465] = "Mountain Silversage",
	[13466] = "Plaguebloom", [13467] = "Icecap", [13468] = "Black Lotus",
	[8169] = "Thick Hide", [8170] = "Rugged Leather", [8171] = "Rugged Hide",
	[7911] = "Truesilver Ore", [10620] = "Thorium Ore", [11370] = "Dark Iron Ore",
	[7909] = "Aquamarine", [7910] = "Star Ruby", [3864] = "Citrine", [1529] = "Jade", [1705] = "Lesser Moonstone",
	[EMPTY_VIAL] = "Empty Vial", [LEADED_VIAL] = "Leaded Vial", [CRYSTAL_VIAL] = "Crystal Vial",
	[SALT] = "Salt", [COARSE_THREAD] = "Coarse Thread", [FINE_THREAD] = "Fine Thread",
	[SILKEN_THREAD] = "Silken Thread", [HEAVY_SILKEN_THREAD] = "Heavy Silken Thread",
	[GRAY_DYE] = "Gray Dye", [RED_DYE] = "Red Dye", [GREEN_DYE] = "Green Dye", [MOSS_AGATE] = "Moss Agate",
	[IRON_BUCKLE] = "Iron Buckle", [MAPLE_SEED] = "Maple Seed", [STRANGLETHORN_SEED] = "Stranglethorn Seed",
	[WEAK_FLUX] = "Weak Flux", [STRONG_FLUX] = "Strong Flux", [COAL] = "Coal",
}

-- Lookups: which guides a raw mat belongs to (in guide order, the first one
-- that still needs it wins), and every item worth counting.
ns.GUIDES_FOR, ns.IS_EXTRA, ns.TRACKED = {}, {}, {}
for _, g in ipairs(ns.GUIDES) do
	g.raw = {}
	for _, id in ipairs(g.mats) do
		g.raw[id] = true
		ns.GUIDES_FOR[id] = ns.GUIDES_FOR[id] or {}
		table.insert(ns.GUIDES_FOR[id], g)
		ns.TRACKED[id] = true
	end
	for id in pairs(g.madeFrom) do ns.TRACKED[id] = true end
	-- Vendor items and in-between items too, so bank snapshots include them
	-- for the guide panel.
	for _, step in ipairs(g.steps) do
		for id in pairs(step.uses or {}) do ns.TRACKED[id] = true end
		for id in pairs(step.makes or {}) do ns.TRACKED[id] = true end
	end
end
for _, id in ipairs(ns.EXTRA_MATS) do
	if not ns.GUIDES_FOR[id] then
		ns.IS_EXTRA[id] = true
		ns.TRACKED[id] = true
	end
end
for id, name in pairs(NAMES) do ns.MAT_NAMES[id] = name end
ns.GUIDE_NAMES = NAMES
