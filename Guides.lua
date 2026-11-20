local _, ns = ...

-- Leveling guides for the crafter alts, from wow-professions.com's Forever
-- guides (beta data, October 2026; re-checked against the pages 2026-11-16 —
-- they still say "untested on live"). `uses` lists everything a step consumes
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
--   https://www.wow-professions.com/forever/cooking-leveling-guide   (panel only)
--   https://www.wow-professions.com/forever/first-aid-leveling-guide (panel only)

-- Herbs
local PEACEBLOOM, SILVERLEAF, MAGEROYAL, EARTHROOT, BRIARTHORN = 2447, 765, 785, 2449, 2450
local STRANGLEKELP, KINGSBLOOD, LIFEROOT, ARTHAS_TEARS = 3820, 3356, 3357, 8836
local SUNGRASS, BLINDWEED, FIREFIN, PURPLE_LOTUS = 8838, 8839, 6359, 8831
local FIRE_OIL, ELIXIR_WISDOM = 6371, 3383
local KHADGARS_WHISKER = 3358
local STONESCALE_EEL, STONESCALE_OIL = 13422, 13423 -- eel is fished; 1 eel makes 2 oil

-- Leather
local SCRAPS, LIGHT_LEATHER, LIGHT_HIDE, MEDIUM_LEATHER, MEDIUM_HIDE = 2934, 2318, 783, 2319, 4232
local HEAVY_LEATHER, HEAVY_HIDE, THICK_LEATHER, RUGGED_LEATHER = 4234, 4235, 4304, 8170
local CURED_LIGHT, CURED_MEDIUM, CURED_HEAVY, FINE_BELT = 4231, 4233, 4236, 4246

-- Cloth and bolts
local LINEN, WOOL, SILK, MAGEWEAVE = 2589, 2592, 4306, 4338
local BOLT_LINEN, BOLT_WOOL, BOLT_SILK, BOLT_MAGEWEAVE = 2996, 2997, 4305, 4339
local RUNECLOTH, BOLT_RUNECLOTH = 14047, 14048
local IRONWEB_SILK = 14227

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
local STEEL_BAR, MITHRIL_BAR, THORIUM_BAR, TRUESILVER_BAR = 3859, 3860, 12359, 6037
local THORIUM_ORE, TRUESILVER_ORE = 10620, 7911
local ROUGH_STONE, COARSE_STONE, HEAVY_STONE, SOLID_STONE, DENSE_STONE = 2835, 2836, 2838, 7912, 12365
local ROUGH_GS, COARSE_GS, HEAVY_GS, SOLID_GS, DENSE_GS = 3470, 3478, 3486, 7966, 12644
local CITRINE, STAR_RUBY, AQUAMARINE = 3864, 7910, 7909

-- Vendor items
local EMPTY_VIAL, LEADED_VIAL, CRYSTAL_VIAL = 3371, 3372, 8925
local SALT, COARSE_THREAD, FINE_THREAD, SILKEN_THREAD, HEAVY_SILKEN_THREAD = 4289, 2320, 2321, 4291, 8343
local GRAY_DYE, RED_DYE, GREEN_DYE, BLACK_DYE = 4340, 2604, 2605, 2325
local RUNE_THREAD = 14341
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
		key = "alchemy", name = "Alchemy", skillLine = 171, top = 300,
		choices = {
			oil = { "fireoil", "manapot", label = "130-165" },
			eel = { "stonescale", "manapot", label = "250-300" },
		},
		mats = { PEACEBLOOM, SILVERLEAF, MAGEROYAL, EARTHROOT, BRIARTHORN, STRANGLEKELP, FIREFIN,
			KINGSBLOOD, LIFEROOT, KHADGARS_WHISKER, SUNGRASS, BLINDWEED, STONESCALE_EEL },
		madeFrom = { [FIRE_OIL] = { FIREFIN, 1 }, [STONESCALE_OIL] = { STONESCALE_EEL, 0.5 } }, -- 1 eel = 2 oil
		ranks = ranks(
			{ Horde = "Yelmak (Orgrimmar), Doctor Marsh (Undercity), Bena Winterhoof (Thunder Bluff)",
			  Alliance = "Lilyssia Nightbreeze (Stormwind), Tally Berryfizz (Ironforge), Sylvanna Forestmoon (Darnassus)" },
			{ Horde = "Doctor Herbert Halsey (Undercity)", Alliance = "Ainethil (Darnassus)" },
			{ Horde = "Rogvar (Stonard, Swamp of Sorrows)", Alliance = "Kylanna Windwhisper (Feathermoon Stronghold, Feralas)" }),
		steps = {
			{ lo = 1,   hi = 10,  crafts = 9,  recipe = "Elixir of Minor Force", uses = { [SILVERLEAF] = 9, [EMPTY_VIAL] = 9 },
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
			-- 225+ is untested in the guide (beta cap).
			{ lo = 225, hi = 235, crafts = 26, recipe = "Nature Protection Potion", uses = { [LIFEROOT] = 26, [STRANGLEKELP] = 26, [LEADED_VIAL] = 26 },
				note = "Green from 230, so expect a few extra crafts." },
			{ lo = 235, hi = 250, crafts = 15, recipe = "Elixir of Greater Intellect",
				uses = { [BLINDWEED] = 15, [KHADGARS_WHISKER] = 15, [CRYSTAL_VIAL] = 15 } },
			{ lo = 250, hi = 260, crafts = 47, recipe = "Stonescale Oil", choice = "eel", option = "stonescale",
				uses = { [STONESCALE_EEL] = 47, [LEADED_VIAL] = 47 }, makes = { [STONESCALE_OIL] = 94 },
				note = "2 oils per craft. Keep all 94 for the elixirs at 265." },
			{ lo = 260, hi = 265, crafts = 10, recipe = "Elixir of Greater Intellect", choice = "eel", option = "stonescale",
				uses = { [BLINDWEED] = 10, [KHADGARS_WHISKER] = 10, [CRYSTAL_VIAL] = 10 } },
			{ lo = 250, hi = 265, crafts = 21, recipe = "Elixir of Greater Intellect", choice = "eel", option = "manapot",
				uses = { [BLINDWEED] = 21, [KHADGARS_WHISKER] = 21, [CRYSTAL_VIAL] = 21 },
				note = "For when Stonescale Eel is dear. About 21 gets you to 265." },
			-- The guide's step text says "Elixir of Greater Defense", but its link, mats and
			-- vendor recipe are all Elixir of Superior Defense (spell 17554).
			{ lo = 265, hi = 300, crafts = 47, recipe = "Elixir of Superior Defense", choice = "eel", option = "stonescale",
				uses = { [STONESCALE_OIL] = 94, [SUNGRASS] = 47, [CRYSTAL_VIAL] = 47 },
				note = "Uses the Stonescale Oil you kept. Recipe: Kor'geld (Orgrimmar) or Soolie Berryfizz (Ironforge)." },
			{ lo = 265, hi = 300, crafts = 55, recipe = "Superior Mana Potion", choice = "eel", option = "manapot",
				uses = { [SUNGRASS] = 110, [BLINDWEED] = 110, [CRYSTAL_VIAL] = 55 },
				note = "Recipe: Algernon (Undercity) or Ulthir (Darnassus)." },
		},
	},
	{
		key = "leatherworking", name = "Leatherworking", skillLine = 165, top = 300,
		-- One route now: the guide dropped its no-hide alternatives, so there is nothing to pick.
		choices = {},
		-- Runecloth drops for everyone, so it is routed here too (the Tailor
		-- gets first call: guide order decides).
		mats = { SCRAPS, LIGHT_LEATHER, LIGHT_HIDE, MEDIUM_LEATHER, MEDIUM_HIDE, HEAVY_LEATHER, HEAVY_HIDE, THICK_LEATHER,
			RUGGED_LEATHER, RUNECLOTH },
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
			{ lo = 1,   hi = 30,  crafts = 35, recipe = "Light Leather", uses = { [SCRAPS] = 105 }, makes = { [LIGHT_LEATHER] = 35 } },
			{ lo = 30,  hi = 55,  crafts = 27, recipe = "Cured Light Hide", uses = { [LIGHT_HIDE] = 27, [SALT] = 27 },
				makes = { [CURED_LIGHT] = 27 },
				note = "Keep 24 for the Light Leather Pants at 100. Salt, thread and dye: Leatherworking Supply vendor by the trainer (in Elwynn, Tharynn Bouden in Goldshire; in Tirisfal, Abigail Shiel in Brill)." },
			{ lo = 55,  hi = 75,  crafts = 21, recipe = "Embossed Leather Gloves", uses = { [LIGHT_LEATHER] = 63, [COARSE_THREAD] = 42 } },
			{ lo = 75,  hi = 80,  crafts = 8,  recipe = "Medium Leather", uses = { [LIGHT_LEATHER] = 32 }, makes = { [MEDIUM_LEATHER] = 8 } },
			{ lo = 80,  hi = 90,  crafts = 10, recipe = "Cured Medium Hide", uses = { [MEDIUM_HIDE] = 10, [SALT] = 10 },
				makes = { [CURED_MEDIUM] = 10 }, note = "Keep them for the Dark Leather Belts at 115." },
			{ lo = 90,  hi = 100, crafts = 19, recipe = "Fine Leather Belt", uses = { [LIGHT_LEATHER] = 114, [COARSE_THREAD] = 38 },
				makes = { [FINE_BELT] = 19 }, note = "Keep 10 belts for the Dark Leather Belts at 115." },
			{ lo = 100, hi = 115, crafts = 24, recipe = "Light Leather Pants",
				uses = { [LIGHT_LEATHER] = 240, [CURED_LIGHT] = 24, [FINE_THREAD] = 24 } },
			{ lo = 115, hi = 125, crafts = 10, recipe = "Dark Leather Belt",
				uses = { [FINE_BELT] = 10, [CURED_MEDIUM] = 10, [FINE_THREAD] = 20, [GRAY_DYE] = 10 } },
			{ lo = 125, hi = 130, crafts = 7,  recipe = "Heavy Leather", uses = { [MEDIUM_LEATHER] = 35 }, makes = { [HEAVY_LEATHER] = 7 } },
			{ lo = 130, hi = 143, crafts = 30, recipe = "Cured Heavy Hide", uses = { [HEAVY_HIDE] = 30, [SALT] = 90 },
				makes = { [CURED_HEAVY] = 30 },
				note = "Keep them: 15 for the Barbaric Shoulders at 155, 15 for the Guardian Gloves at 170." },
			{ lo = 143, hi = 155, crafts = 17, recipe = "Hillman's Leather Gloves", uses = { [MEDIUM_LEATHER] = 238, [FINE_THREAD] = 68 } },
			{ lo = 155, hi = 170, crafts = 15, recipe = "Barbaric Shoulders",
				uses = { [HEAVY_LEATHER] = 120, [CURED_HEAVY] = 15, [FINE_THREAD] = 30 } },
			{ lo = 170, hi = 185, crafts = 15, recipe = "Guardian Gloves",
				uses = { [HEAVY_LEATHER] = 60, [CURED_HEAVY] = 15, [SILKEN_THREAD] = 15 } },
			{ lo = 185, hi = 195, crafts = 16, recipe = "Barbaric Harness",
				uses = { [HEAVY_LEATHER] = 224, [FINE_THREAD] = 32, [IRON_BUCKLE] = 16 },
				note = "Iron Buckles: a Blacksmith makes them, or the AH." },
			{ lo = 195, hi = 205, crafts = 12, recipe = "Nightscape Headband", uses = { [THICK_LEATHER] = 60, [SILKEN_THREAD] = 24 } },
			{ lo = 205, hi = 235, crafts = 36, recipe = "Nightscape Pants", uses = { [THICK_LEATHER] = 504, [SILKEN_THREAD] = 144 },
				note = "Only the Artisan trainers teach this one, not the Expert trainers. Nightscape Boots work too, but vendor for less." },
			-- 235-300 (guide, still "untested on live"). Rugged Leather: 1,030 in all; Runecloth: 530.
			{ lo = 235, hi = 265, crafts = 36, recipe = "Wicked Leather Gauntlets",
				uses = { [RUGGED_LEATHER] = 288, [BLACK_DYE] = 36, [RUNE_THREAD] = 36 },
				note = "Pattern: Werg Thickblade (Tirisfal Glades) or Leonard Porter (Western Plaguelands). Black Dye and Rune Thread: Tailoring/Leatherworking Supply vendor. Got the Blue Suede Shoes pattern? Make those instead (same leather, Blue Dye for Black), they vendor for more." },
			{ lo = 265, hi = 300, crafts = 53, recipe = "Runic Leather Headband",
				uses = { [RUGGED_LEATHER] = 742, [RUNECLOTH] = 530, [RUNE_THREAD] = 53 },
				note = "Pattern: Jase Farlane, Light's Hope Chapel (Eastern Plaguelands). With the patterns, Blue Suede Bracers work from 275 (10 Rugged Leather, 1 Blue Dye each) and Blue Suede Hats from 280 (they need another leatherworker's Sewing Machine)." },
		},
	},
	{
		key = "tailoring", name = "Tailoring", skillLine = 197, top = 280,
		-- No routes to pick: the guide's one alternative (Runecloth Belts for the
		-- bags at 215) is in that step's note.
		choices = {},
		-- Cloth drops for everyone, so every alt routes it here. The elixirs
		-- come from the Alchemy alt (or the AH); Rugged Leather from the Skinners.
		mats = { LINEN, WOOL, SILK, MAGEWEAVE, RUNECLOTH, RUGGED_LEATHER, IRONWEB_SILK, ELIXIR_WISDOM },
		madeFrom = {
			[BOLT_LINEN] = { LINEN, 2 }, [BOLT_WOOL] = { WOOL, 3 },
			[BOLT_SILK] = { SILK, 4 }, [BOLT_MAGEWEAVE] = { MAGEWEAVE, 5 },
			[BOLT_RUNECLOTH] = { RUNECLOTH, 5 },
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
			{ lo = 100, hi = 120, crafts = 54, recipe = "Bolt of Silk Cloth",
				uses = { [SILK] = 216 }, makes = { [BOLT_SILK] = 54 },
				note = "Keep the bolts: 184 (736 Silk) through 190." },
			{ lo = 120, hi = 140, crafts = 29, recipe = "Gloves of Meditation",
				uses = { [BOLT_WOOL] = 116, [FINE_THREAD] = 87, [ELIXIR_WISDOM] = 29 },
				note = "Elixir of Wisdom: your Alchemy alt makes 30 at 90-120, or the AH. Yellow from 125, so expect a few extra crafts." },
			{ lo = 140, hi = 150, crafts = 23, recipe = "Bolt of Mageweave",
				uses = { [MAGEWEAVE] = 115 }, makes = { [BOLT_MAGEWEAVE] = 23 },
				note = "Keep the bolts: 157 (785 Mageweave) through 225. Bolts off the AH are fine if they're cheaper than the cloth." },
			{ lo = 150, hi = 170, crafts = 20, recipe = "Crimson Silk Vest", uses = { [BOLT_SILK] = 80, [RED_DYE] = 40, [FINE_THREAD] = 40 } },
			{ lo = 170, hi = 190, crafts = 26, recipe = "Crimson Silk Pantaloons", uses = { [BOLT_SILK] = 104, [RED_DYE] = 52, [SILKEN_THREAD] = 52 },
				note = "Yellow at 180." },
			{ lo = 190, hi = 200, crafts = 19, recipe = "Black Mageweave Leggings", uses = { [BOLT_MAGEWEAVE] = 38, [SILKEN_THREAD] = 57 },
				note = "Yellow the whole way, so expect a few extra crafts." },
			{ lo = 200, hi = 205, crafts = 5,  recipe = "Black Mageweave Shoulders", uses = { [BOLT_MAGEWEAVE] = 15, [HEAVY_SILKEN_THREAD] = 10 },
				note = "Only the Artisan trainers teach this one, not the Expert trainers." },
			{ lo = 205, hi = 215, crafts = 23, recipe = "Bolt of Runecloth",
				uses = { [RUNECLOTH] = 115 }, makes = { [BOLT_RUNECLOTH] = 23 },
				note = "Keep the bolts: 311 (1,555 Runecloth) through 280, so make them all now if you like." },
			{ lo = 215, hi = 225, crafts = 26, recipe = "Mageweave Bag", uses = { [BOLT_MAGEWEAVE] = 104, [SILKEN_THREAD] = 52 },
				note = "Don't want the bags? 10 Runecloth Belts instead (30 Bolts of Runecloth, 10 Rune Thread)." },
			-- 225-280 (guide, "not final yet", untested on live).
			{ lo = 225, hi = 240, crafts = 24, recipe = "Runecloth Belt", uses = { [BOLT_RUNECLOTH] = 72, [RUNE_THREAD] = 24 },
				note = "Artisan first." },
			{ lo = 240, hi = 250, crafts = 11, recipe = "Runecloth Gloves",
				uses = { [BOLT_RUNECLOTH] = 44, [RUGGED_LEATHER] = 44, [RUNE_THREAD] = 11 },
				note = "Pattern: Qia (Everlook, Winterspring)." },
			{ lo = 250, hi = 280, crafts = 39, recipe = "Runecloth Cuffs",
				uses = { [BOLT_RUNECLOTH] = 195, [IRONWEB_SILK] = 39, [RUNE_THREAD] = 39 },
				note = "Pattern: Pexmit (Mount Hyjal). Bind on pickup, buy it on this alt. Yellow from 265, so expect a few extra crafts." },
			-- 280-300 isn't in the guide's list yet. Its candidates: Runecloth Shoulders (world drop) or
			-- Wizardweave Turban (rare) to 300; Runecloth Headband or more Cuffs only reach 290.
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
				note = "Rod and Motes: Enchanting Supply vendor by the capital trainer (10c each), not the AH. Starting-zone trainers don't have one, except Zephras Isle and Brill." },
			{ lo = 2,   hi = 20,  crafts = 18, recipe = "Enchant Bracer - Inferior Stamina", uses = { [MOTE_OF_MAGIC] = 18 } },
			{ lo = 20,  hi = 70,  crafts = 50, recipe = "Enchant Bracer - Minor Deflect", choice = "ench", options = { "essence", "noformula" },
				uses = { [LESSER_MAGIC] = 50 }, note = "Greater Magic Essence splits into 3 Lesser (right-click it)." },
			{ lo = 20,  hi = 70,  crafts = 50, recipe = "Enchant Chest - Inferior Stamina", choice = "ench", option = "dust",
				uses = { [STRANGE_DUST] = 50 } },
			{ lo = 70,  hi = 109, crafts = 49, recipe = "Enchant Chest - Minor Absorption", choice = "ench", options = { "essence", "noformula" },
				uses = { [LESSER_MAGIC] = 49 }, note = "Journeyman first." },
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
			{ lo = 185, hi = 200, crafts = 25, recipe = "Enchant Boots - Lesser Agility", choice = "vision", option = "souldust",
				uses = { [SOUL_DUST] = 25 }, note = "Yellow, so expect extra crafts. Switch to Bracer - Strength if 2 Vision Dust costs less than 3 Soul Dust." },
			{ lo = 185, hi = 200, crafts = 15, recipe = "Enchant Bracer - Strength", choice = "vision", option = "visiondust",
				uses = { [VISION_DUST] = 15 } },
			{ lo = 200, hi = 201, crafts = 1,  recipe = "Runed Truesilver Rod",
				uses = { [TRUESILVER_ROD] = 1, [BLACK_PEARL] = 1, [GREATER_MYSTIC] = 1, [VISION_DUST] = 1 } },
			{ lo = 201, hi = 220, crafts = 25, recipe = "Lesser Wizard Oil",
				uses = { [VISION_DUST] = 25, [STRANGLETHORN_SEED] = 50, [LEADED_VIAL] = 25 },
				note = "Stranglethorn Seed: Reagent vendor. Leaded Vial: Alchemy Supply." },
			{ lo = 220, hi = 225, crafts = 5,  recipe = "Enchant Cloak - Greater Defense", uses = { [VISION_DUST] = 5 } },
			-- 225+ is untested in the guide (beta cap); it's the Classic route.
			{ lo = 225, hi = 250, crafts = 37, recipe = "Enchant Gloves - Agility", uses = { [VISION_DUST] = 37 },
				note = "Artisan: Annora in Uldaman (back entrance), she spawns once her room is cleared. Learn everything she teaches while you're there, and bring about 50 Vision Dust to reach 250." },
			{ lo = 250, hi = 265, crafts = 20, recipe = "Lesser Mana Oil", choice = "lotus", option = "manaoil",
				uses = { [DREAM_DUST] = 20, [PURPLE_LOTUS] = 20, [CRYSTAL_VIAL] = 20 },
				note = "Formula: Kania, upstairs at the Silithus inn. Crystal Vial: Mishta there, or any Alchemy Supply vendor." },
			{ lo = 250, hi = 265, crafts = 20, recipe = "Enchant Bracer - Greater Strength", choice = "lotus", option = "bracer",
				uses = { [DREAM_DUST] = 20, [LESSER_NETHER] = 40 }, note = "Taught by Annora. For when there's no Purple Lotus." },
			{ lo = 265, hi = 299, crafts = 40, recipe = "Enchant Shield - Greater Stamina", uses = { [DREAM_DUST] = 240 },
				note = "Formula: Daniel Bartlett (Undercity), Mythrin'dir (Darnassus). Bind on pickup, buy it on this alt. Yellow from 285, so expect a few extra." },
			{ lo = 299, hi = 300, crafts = 1,  recipe = "Runed Arcanite Rod",
				uses = { [ARCANITE_ROD] = 1, [GOLDEN_PEARL] = 1, [ILLUSION_DUST] = 10, [GREATER_ETERNAL] = 4, [SMALL_BRILLIANT] = 4, [LARGE_BRILLIANT] = 2 },
				note = "Formula: Lorelae Wintersong, Nighthaven (Moonglade). You can make it from 290; one more shield gives the last point if you'd rather wait." },
		},
	},
	{
		key = "blacksmithing", name = "Blacksmithing", skillLine = 164, top = 300,
		choices = {
			rod = { "silverrod", "belt", label = "75-80" },
			spurs = { "breastplate", "spurs", label = "215-225" },
		},
		-- Ore, stone and gems come from the Miner, leather from the Skinners.
		-- Bars are smelted from ore (or bought), so shortfalls show as ore.
		mats = { ROUGH_STONE, COARSE_STONE, HEAVY_STONE, SOLID_STONE, DENSE_STONE,
			COPPER_ORE, TIN_ORE, SILVER_ORE, IRON_ORE, MITHRIL_ORE, THORIUM_ORE, TRUESILVER_ORE,
			MEDIUM_LEATHER, HEAVY_LEATHER, THICK_LEATHER, RUGGED_LEATHER,
			CITRINE, STAR_RUBY, AQUAMARINE },
		madeFrom = {
			[ROUGH_GS] = { ROUGH_STONE, 2 }, [COARSE_GS] = { COARSE_STONE, 2 },
			[HEAVY_GS] = { HEAVY_STONE, 3 }, [SOLID_GS] = { SOLID_STONE, 4 }, [DENSE_GS] = { DENSE_STONE, 4 },
			[COPPER_BAR] = { COPPER_ORE, 1 }, [SILVER_BAR] = { SILVER_ORE, 1 },
			[IRON_BAR] = { IRON_ORE, 1 }, [MITHRIL_BAR] = { MITHRIL_ORE, 1 },
			[THORIUM_BAR] = { THORIUM_ORE, 1 }, [TRUESILVER_BAR] = { TRUESILVER_ORE, 1 },
			[BRONZE_BAR] = { { COPPER_ORE, 0.5 }, { TIN_ORE, 0.5 } }, -- 1 Copper + 1 Tin = 2 Bronze
			[STEEL_BAR] = { { IRON_ORE, 1 }, { COAL, 1 } },
		},
		ranks = ranks(
			{ Horde = "Snarl (Orgrimmar), James Van Brunt (Undercity), Karn Stonehoof (Thunder Bluff), Angus Hammerhand (Bandarion Keep, Tirisfal), Daeann Steelwind (Valanaar, Zephras Isle)",
			  Alliance = "Therum Deepforge (Stormwind), Rotgath Stonebeard (Ironforge), Daeann Steelwind (Valanaar, Zephras Isle)" },
			{ Horde = "Saru Steelfury (Orgrimmar)", Alliance = "Bengus Deepforge (Ironforge)" },
			{ Horde = "Brikk Keencraft (Booty Bay, both factions)", Alliance = "Brikk Keencraft (Booty Bay, both factions)" }),
		steps = {
			{ lo = 1,   hi = 25,  crafts = 30, recipe = "Rough Sharpening Stone", uses = { [ROUGH_STONE] = 30 },
				note = "Buy a Blacksmith Hammer from the vendor by the trainer, you need it from 75." },
			{ lo = 25,  hi = 50,  crafts = 30, recipe = "Rough Grinding Stone", uses = { [ROUGH_STONE] = 60 }, makes = { [ROUGH_GS] = 30 },
				note = "Keep 10 for the Silver Rods at 75." },
			{ lo = 50,  hi = 75,  crafts = 36, recipe = "Coarse Grinding Stone", uses = { [COARSE_STONE] = 72 }, makes = { [COARSE_GS] = 36 },
				note = "Keep all 36 for the bracers at 95 and 112. Not at 75 yet? Make a few more. Journeyman at 75." },
			{ lo = 75,  hi = 80,  crafts = 5,  recipe = "Silver Rod", choice = "rod", option = "silverrod",
				uses = { [SILVER_BAR] = 5, [ROUGH_GS] = 10 }, makes = { [SILVER_ROD] = 5 },
				note = "Your Enchanter needs one of these at 109; the rest sell." },
			{ lo = 75,  hi = 80,  crafts = 5,  recipe = "Runed Copper Belt", choice = "rod", option = "belt", uses = { [COPPER_BAR] = 50 },
				note = "For when a Silver Bar costs more than 10 Copper Bars." },
			{ lo = 80,  hi = 95,  crafts = 18, recipe = "Runed Copper Belt", uses = { [COPPER_BAR] = 180 } },
			{ lo = 95,  hi = 100, crafts = 5,  recipe = "Patterned Bronze Bracers", uses = { [BRONZE_BAR] = 25, [COARSE_GS] = 10 } },
			{ lo = 100, hi = 112, crafts = 20, recipe = "Heavy Grinding Stone", uses = { [HEAVY_STONE] = 60 }, makes = { [HEAVY_GS] = 20 },
				note = "Keep all 20 for the Golden Scale Bracers at 180; they need 40, so 20 more (60 Heavy Stone) get made then." },
			{ lo = 112, hi = 125, crafts = 13, recipe = "Patterned Bronze Bracers", uses = { [BRONZE_BAR] = 65, [COARSE_GS] = 26 } },
			{ lo = 125, hi = 140, crafts = 24, recipe = "Bronze Shortsword", uses = { [BRONZE_BAR] = 120, [WEAK_FLUX] = 96, [MEDIUM_LEATHER] = 48 },
				note = "Flux: Blacksmithing Supply vendor by the trainer in every capital. If you disenchant your greens, 24 Patterned Bronze Bracers (48 Coarse Grinding Stone) work instead." },
			{ lo = 140, hi = 150, crafts = 10, recipe = "Bronze Warhammer", uses = { [BRONZE_BAR] = 80, [STRONG_FLUX] = 10, [MEDIUM_LEATHER] = 10 } },
			{ lo = 150, hi = 175, crafts = 30, recipe = "Green Iron Bracers", uses = { [IRON_BAR] = 180, [GREEN_DYE] = 30 },
				note = "Expert first. Green Dye: Tamar (Orgrimmar) or Bombus Finespindle (Ironforge)." },
			{ lo = 175, hi = 180, crafts = 8,  recipe = "Solid Grinding Stone", uses = { [SOLID_STONE] = 32 }, makes = { [SOLID_GS] = 8 },
				note = "Keep all 8: 6 for the Heavy Mithril Axes at 210." },
			{ lo = 180, hi = 195, crafts = 20, recipe = "Golden Scale Bracers", uses = { [STEEL_BAR] = 100, [HEAVY_GS] = 40 },
				note = "Steel: smelt Iron Bar + Coal yourself at Mining 165. Coal: Blacksmithing Supply vendor. Alliance: keep 6 in case you go Armorsmith." },
			{ lo = 195, hi = 210, crafts = 17, recipe = "Mithril Plate Pants", uses = { [MITHRIL_BAR] = 204 } },
			{ lo = 210, hi = 215, crafts = 6,  recipe = "Heavy Mithril Axe",
				uses = { [MITHRIL_BAR] = 72, [CITRINE] = 12, [SOLID_GS] = 6, [HEAVY_LEATHER] = 24 },
				note = "Keep 2 in case you go Weaponsmith." },
			{ lo = 215, hi = 225, crafts = 10, recipe = "Heavy Mithril Breastplate", choice = "spurs", option = "breastplate",
				uses = { [MITHRIL_BAR] = 160 }, note = "Artisan: Brikk Keencraft, Booty Bay. Keep 2 in case you go Armorsmith." },
			{ lo = 215, hi = 225, crafts = 10, recipe = "Mithril Spurs", choice = "spurs", option = "spurs",
				uses = { [MITHRIL_BAR] = 40, [SOLID_GS] = 30 }, note = "Plans: Mithril Spurs is a world drop, check the AH." },
			-- 225-300 (guide, still "untested on live"). The Imperial Plate plans come from
			-- Derotain Mudsipper's quests in Gadgetzan (20/20/40/60 Thorium Bar each, 140 in all,
			-- on top of the 1,770 below). The guide assumes the quests dropped from skill 265 to
			-- 240 along with the belt, but couldn't test it. World-drop plans that work from 240
			-- instead: Dazzling Mithril Rapier, Runed Mithril Hammer, Thorium Bracers.
			{ lo = 225, hi = 230, crafts = 5,  recipe = "Dense Sharpening Stone", uses = { [DENSE_STONE] = 5 } },
			{ lo = 230, hi = 240, crafts = 16, recipe = "Heavy Mithril Boots", uses = { [MITHRIL_BAR] = 224, [THICK_LEATHER] = 64 },
				note = "Keep 2 in case you go Armorsmith. With the Mithril Spurs plans, 16 spurs work here too (64 Mithril Bar, 48 Solid Grinding Stone)." },
			{ lo = 240, hi = 245, crafts = 5,  recipe = "Imperial Plate Belt",
				uses = { [THORIUM_BAR] = 110, [RUGGED_LEATHER] = 30, [AQUAMARINE] = 5 },
				note = "Plans: Derotain Mudsipper (Gadgetzan) quest, 20 Thorium Bar. Bring 250 Thorium Bar for the whole chain." },
			{ lo = 245, hi = 270, crafts = 27, recipe = "Imperial Plate Bracers", uses = { [THORIUM_BAR] = 540, [STAR_RUBY] = 27 },
				note = "Plans: the next Derotain quest, 20 Thorium Bar." },
			{ lo = 270, hi = 290, crafts = 20, recipe = "Imperial Plate Boots",
				uses = { [THORIUM_BAR] = 680, [STAR_RUBY] = 20, [AQUAMARINE] = 20 }, note = "Plans: Derotain quest, 40 Thorium Bar." },
			{ lo = 290, hi = 300, crafts = 10, recipe = "Imperial Plate Leggings", uses = { [THORIUM_BAR] = 440, [STAR_RUBY] = 20 },
				note = "Plans: Derotain quest, 60 Thorium Bar. Green by now, so expect extra crafts." },
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

-- Panel-only guides ------------------------------------------------------
-- Cooking and First Aid (added 2026-11-20 from the Forever pages). They show
-- on the guide panel when their window is open, but nothing here is routed
-- between alts: the cloth and herbs keep going where the guides above send
-- them. First Aid in Forever also makes healing potions.

-- Cooking mats
local RAW_SMALLFISH, RAW_MACKEREL, WOLF_MEAT, BOAR_MEAT = 6291, 6303, 2672, 769
local RAW_MUD_SNAPPER, RAW_ALBACORE, BEAR_MEAT, STRIDER_MEAT, RED_APPLE = 6289, 6361, 3173, 5469, 4536
local RAW_CATFISH, TANGY_CLAM, RAPTOR_EGG = 6308, 5504, 3685
local RAPTOR_FLESH, RAW_MITHRIL_TROUT, TURTLE_MEAT = 12184, 8365, 3712
local RAW_YELLOWTAIL, RAW_REDGILL, RAW_NIGHTFIN, SPRING_WATER = 4603, 13758, 13759, 159
local MILD_SPICES, HOT_SPICES, SOOTHING_SPICES = 2678, 2692, 3713
-- First Aid mats
local SPIDER_ICHOR, BRUISEWEED, GOLDEN_SANSAM, DALARAN_NOIR = 3174, 2453, 13464, 2723

local SPICES = "Spices come from Cooking Supply vendors, don't buy them on the AH."

ns.PANEL_GUIDES = {
	{
		key = "cooking", name = "Cooking", skillLine = 185, top = 300,
		choices = {
			cook1   = { "smallfish", "mackerel", "wolf", "boar", label = "1-50" },
			cook50  = { "snapper", "albacore", "bear", "strider", label = "50-100" },
			cook130 = { "catfish", "clams", "omelet", label = "130-150" },
			cook150 = { "clams", "omelet", label = "150-175" },
			cook175 = { "raptor", "trout", "bisque", label = "175-225" },
			cook225 = { "yellowtail", "redgill", label = "225-285" },
		},
		mats = {},
		madeFrom = {},
		ranks = {
			{ name = "Journeyman", skill = 50, max = 150, trainers = {
				Horde = "Any Cooking trainer: Zamja (Orgrimmar), Eunice Burch (Undercity), Aska Mistrunner (Thunder Bluff)",
				Alliance = "Any Cooking trainer: Stephen Ryback (Stormwind), Daryl Riknussun (Ironforge), Alegorn (Darnassus)" } },
			{ name = "Expert", skill = 125, max = 225, trainers = {
				Horde = "Buy the Expert Cookbook from Wulan (Shadowprey Village, Desolace)",
				Alliance = "Buy the Expert Cookbook from Shandrina (Mystral Lake, Ashenvale)" } },
			{ name = "Artisan", skill = 225, level = 35, max = 300, trainers = {
				Horde = "Quest Clamlette Surprise, Dirge Quikcleave (Gadgetzan). Bring 12 Giant Egg, 10 Zesty Clam Meat and 20 Alterac Swiss (Innkeeper Abeqwa, Freewind Post). Buy the Spotted Yellowtail and Nightfin Soup recipes from Gikkix (Steamwheedle Port) while you're in Tanaris.",
				Alliance = "Quest Clamlette Surprise, Dirge Quikcleave (Gadgetzan). Bring 12 Giant Egg, 10 Zesty Clam Meat and 20 Alterac Swiss (Ben Trias, Stormwind). Buy the Spotted Yellowtail and Nightfin Soup recipes from Gikkix (Steamwheedle Port) while you're in Tanaris." } },
		},
		steps = {
			{ lo = 1,   hi = 50,  crafts = 55, recipe = "Brilliant Smallfish", choice = "cook1", option = "smallfish",
				uses = { [RAW_SMALLFISH] = 55 },
				note = { Horde = "Recipe: Harn Longcast (Mulgore), Sewa Mistrunner (Thunder Bluff), Martine Tramblay (Tirisfal), Lizbeth Cromwell (Undercity).",
					Alliance = "Recipe: Tharynn Bouden (Elwynn), Gretta Ganter (Dun Morogh), Khara Deepwater (Loch Modan), Catherine Leland (Stormwind), Nyoma (Teldrassil)." } },
			{ lo = 1,   hi = 50,  crafts = 55, recipe = "Slitherskin Mackerel", choice = "cook1", option = "mackerel",
				uses = { [RAW_MACKEREL] = 55 },
				note = { Horde = "Recipe: Zansoa (Durotar), Martine Tramblay (Tirisfal).",
					Alliance = "Recipe: Tansy Puddlefizz (Ironforge), Nessa Shadowsong (Teldrassil), Kriggon Talsone (Westfall)." } },
			{ lo = 1,   hi = 50,  crafts = 55, recipe = "Charred Wolf Meat", choice = "cook1", option = "wolf",
				uses = { [WOLF_MEAT] = 55 }, note = "Taught by the trainer." },
			{ lo = 1,   hi = 50,  crafts = 55, recipe = "Roasted Boar Meat", choice = "cook1", option = "boar",
				uses = { [BOAR_MEAT] = 55 }, note = "Taught by the trainer." },

			{ lo = 50,  hi = 100, crafts = 55, recipe = "Longjaw Mud Snapper", choice = "cook50", option = "snapper",
				uses = { [RAW_MUD_SNAPPER] = 55 },
				note = { Horde = "Train Journeyman first or you stop at 75. Recipe: Harn Longcast (Mulgore), Killian Sanatha (Silverpine), Naal Mistrunner (Thunder Bluff), Lizbeth Cromwell (Undercity).",
					Alliance = "Train Journeyman first or you stop at 75. Recipe: Tharynn Bouden (Elwynn), Tansy Puddlefizz (Ironforge), Khara Deepwater (Loch Modan), Nyoma (Teldrassil)." } },
			{ lo = 50,  hi = 100, crafts = 55, recipe = "Rainbow Fin Albacore", choice = "cook50", option = "albacore",
				uses = { [RAW_ALBACORE] = 55 },
				note = { Horde = "Train Journeyman first or you stop at 75. Recipe: Zansoa (Durotar), Shankys (Orgrimmar), Killian Sanatha (Silverpine), Ronald Burch (Undercity), Kilxx (the Barrens).",
					Alliance = "Train Journeyman first or you stop at 75. Recipe: Heldan Galesong (Darkshore), Catherine Leland (Stormwind), Nessa Shadowsong (Teldrassil), Kriggon Talsone (Westfall), Stuart Fleming (Wetlands)." } },
			{ lo = 50,  hi = 100, crafts = 70, recipe = "Smoked Bear Meat", choice = "cook50", option = "bear",
				uses = { [BEAR_MEAT] = 70 },
				note = { Horde = "Turns yellow early, so 65-75 crafts. Recipe: Andrew Hilbert (Silverpine).",
					Alliance = "Turns yellow early, so 65-75 crafts. Recipe: Drac Roughcut (Loch Modan)." } },
			{ lo = 50,  hi = 100, crafts = 55, recipe = "Strider Stew", choice = "cook50", option = "strider",
				uses = { [STRIDER_MEAT] = 55, [RED_APPLE] = 55 },
				note = { Horde = "Apples are vendor-bought. Recipe: Tari'qa (the Barrens).",
					Alliance = "Apples are vendor-bought. Recipe: quest Easy Strider Living (Darkshore)." } },

			{ lo = 100, hi = 130, crafts = 30, recipe = "Bristle Whisker Catfish", uses = { [RAW_CATFISH] = 30 },
				note = { Horde = "Recipe: Derak Nightfall (Hillsbrad), Naal or Sewa Mistrunner (Thunder Bluff), Ronald Burch (Undercity), Kilxx (the Barrens).",
					Alliance = "Recipe: Lindea Rabonne (Hillsbrad), Catherine Leland (Stormwind). Or 35 Cooked Crab Claw (Kendor Kabonka, Stormwind)." } },
			{ lo = 130, hi = 150, crafts = 25, recipe = "Bristle Whisker Catfish", choice = "cook130", option = "catfish",
				uses = { [RAW_CATFISH] = 25 } },
			{ lo = 130, hi = 150, crafts = 25, recipe = "Goblin Deviled Clams", choice = "cook130", option = "clams",
				uses = { [TANGY_CLAM] = 25, [HOT_SPICES] = 25 }, note = "Taught by the trainer. " .. SPICES },
			{ lo = 130, hi = 150, crafts = 20, recipe = "Curiously Tasty Omelet", choice = "cook130", option = "omelet",
				uses = { [RAPTOR_EGG] = 20, [HOT_SPICES] = 20 },
				note = { Horde = "Recipe: Keena (Arathi Highlands). " .. SPICES, Alliance = "Recipe: Kendor Kabonka (Stormwind). " .. SPICES } },

			{ lo = 150, hi = 175, crafts = 30, recipe = "Goblin Deviled Clams", choice = "cook150", option = "clams",
				uses = { [TANGY_CLAM] = 30, [HOT_SPICES] = 30 }, note = "Taught by the trainer. You need the Expert Cookbook to pass 150." },
			{ lo = 150, hi = 175, crafts = 30, recipe = "Curiously Tasty Omelet", choice = "cook150", option = "omelet",
				uses = { [RAPTOR_EGG] = 30, [HOT_SPICES] = 30 },
				note = { Horde = "Recipe: Keena (Arathi Highlands). You need the Expert Cookbook to pass 150.",
					Alliance = "Recipe: Kendor Kabonka (Stormwind). You need the Expert Cookbook to pass 150." } },

			{ lo = 175, hi = 225, crafts = 55, recipe = "Roast Raptor", choice = "cook175", option = "raptor",
				uses = { [RAPTOR_FLESH] = 55, [HOT_SPICES] = 55 },
				note = { Horde = "Usually the cheapest. Recipe: Keena (Arathi Highlands), Ogg'marr (Dustwallow Marsh).",
					Alliance = "Usually the cheapest. Recipe: Hammon Karwn (Arathi Highlands)." } },
			{ lo = 175, hi = 225, crafts = 55, recipe = "Mithril Headed Trout", choice = "cook175", option = "trout",
				uses = { [RAW_MITHRIL_TROUT] = 55 },
				note = { Horde = "Recipe: Wik'Tar (Ashenvale), Shankys (Orgrimmar), Kelsey Yance (Stranglethorn), Lizbeth Cromwell (Undercity), Wulan (Desolace).",
					Alliance = "Recipe: Tansy Puddlefizz (Ironforge), Stuart Fleming (Wetlands), Heldan Galesong (Darkshore), Lindea Rabonne (Hillsbrad), Kelsey Yance (Stranglethorn)." } },
			{ lo = 175, hi = 225, crafts = 55, recipe = "Soothing Turtle Bisque", choice = "cook175", option = "bisque",
				uses = { [TURTLE_MEAT] = 55, [SOOTHING_SPICES] = 55 },
				note = { Horde = "Recipe: Hillsbrad quest from Christoph Jeffcoat (Tarren Mill).", Alliance = "Recipe: Hillsbrad quest from Chef Jessen (Southshore)." } },

			{ lo = 225, hi = 285, crafts = 72, recipe = "Spotted Yellowtail", choice = "cook225", option = "yellowtail",
				uses = { [RAW_YELLOWTAIL] = 72 }, note = "Recipe: Gikkix (Steamwheedle Port, Tanaris). Buy whichever fish is cheaper." },
			{ lo = 225, hi = 285, crafts = 72, recipe = "Filet of Redgill", choice = "cook225", option = "redgill",
				uses = { [RAW_REDGILL] = 72 }, note = "Recipe: Kelsey Yance (Booty Bay). Buy whichever fish is cheaper." },
			{ lo = 285, hi = 300, crafts = 18, recipe = "Nightfin Soup", uses = { [RAW_NIGHTFIN] = 18, [SPRING_WATER] = 18 },
				note = "Recipe: Gikkix (Steamwheedle Port, Tanaris). Water is vendor-bought." },
		},
	},
	{
		key = "firstaid", name = "First Aid", skillLine = 129, top = 300,
		choices = {
			aid1  = { "bandages", "potions", label = "1-75" },
			aid90 = { "bandages", "potions", label = "90-150" },
		},
		mats = {},
		madeFrom = {},
		ranks = {
			{ name = "Journeyman", skill = 50, max = 150, trainers = {
				Horde = "Any First Aid trainer: Arnok (Orgrimmar), Mary Edras (Undercity), Pand Stonebinder (Thunder Bluff)",
				Alliance = "Any First Aid trainer: Shaina Fuller (Stormwind), Nissa Firestone (Ironforge), Dannelor (Darnassus)" } },
			{ name = "Expert", skill = 125, max = 225, trainers = {
				Horde = "Buy Expert First Aid - Under Wraps from Balai Lok'Wein (Dustwallow Marsh). Buy the Heavy Silk Bandage and Mageweave Bandage manuals too.",
				Alliance = "Buy Expert First Aid - Under Wraps from Deneb Walker (Arathi Highlands). Buy the Heavy Silk Bandage and Mageweave Bandage manuals too." } },
			{ name = "Artisan", skill = 225, level = 35, max = 300, trainers = {
				Horde = "Quest Triage, Doctor Gregory Victor (Hammerfall, Arathi Highlands). Bring about 90 Mageweave Cloth and 20 Runecloth.",
				Alliance = "Quest Triage, Doctor Gustaf VanHowzen (Theramore, Dustwallow Marsh). Bring about 90 Mageweave Cloth and 20 Runecloth." } },
		},
		steps = {
			{ lo = 1,   hi = 40,  crafts = 50, recipe = "Linen Bandage", choice = "aid1", option = "bandages", uses = { [LINEN] = 50 } },
			{ lo = 40,  hi = 75,  crafts = 47, recipe = "Heavy Linen Bandage", choice = "aid1", option = "bandages", uses = { [LINEN] = 94 },
				note = "Train Journeyman at 50." },
			{ lo = 1,   hi = 75,  crafts = 86, recipe = "Minor Healing Potion", choice = "aid1", option = "potions",
				uses = { [PEACEBLOOM] = 86, [MILD_SPICES] = 86, [EMPTY_VIAL] = 86 },
				note = "Mild Spices: Cooking Supply vendor. Vials: Alchemy Supply vendor. Train Journeyman at 50." },
			{ lo = 75,  hi = 80,  crafts = 13, recipe = "Heavy Linen Bandage", uses = { [LINEN] = 26 } },
			{ lo = 80,  hi = 90,  crafts = 12, recipe = "Wool Bandage", uses = { [WOOL] = 12 } },
			{ lo = 90,  hi = 115, crafts = 40, recipe = "Wool Bandage", choice = "aid90", option = "bandages", uses = { [WOOL] = 40 },
				note = "Bandages if you have the wool. The potions route is cheaper if you'd buy everything." },
			{ lo = 115, hi = 150, crafts = 51, recipe = "Heavy Wool Bandage", choice = "aid90", option = "bandages", uses = { [WOOL] = 102 } },
			{ lo = 90,  hi = 125, crafts = 54, recipe = "Simple Poultice", choice = "aid90", option = "potions",
				uses = { [SPIDER_ICHOR] = 54, [MILD_SPICES] = 54, [DALARAN_NOIR] = 54 },
				note = "Mild Spices: Cooking Supply vendor. Dalaran Noir: barkeeps." },
			{ lo = 125, hi = 150, crafts = 31, recipe = "Healing Potion", choice = "aid90", option = "potions",
				uses = { [BRUISEWEED] = 31, [HOT_SPICES] = 31, [LEADED_VIAL] = 31 },
				note = "Hot Spices and Leaded Vials aren't sold in starting zones, buy them in a capital." },
			{ lo = 150, hi = 180, crafts = 44, recipe = "Silk Bandage", uses = { [SILK] = 44 },
				note = "Last recipe the trainer teaches. You need the Expert book to pass 150." },
			{ lo = 180, hi = 210, crafts = 44, recipe = "Heavy Silk Bandage", uses = { [SILK] = 88 },
				note = "Learned from Manual: Heavy Silk Bandage (same vendor as the Expert book)." },
			{ lo = 210, hi = 225, crafts = 19, recipe = "Mageweave Bandage", uses = { [MAGEWEAVE] = 19 },
				note = "Learned from Manual: Mageweave Bandage (same vendor as the Expert book)." },
			{ lo = 225, hi = 240, crafts = 26, recipe = "Mageweave Bandage", uses = { [MAGEWEAVE] = 26 },
				note = "Needs the Triage quest done (level 35)." },
			{ lo = 240, hi = 260, crafts = 30, recipe = "Heavy Mageweave Bandage", uses = { [MAGEWEAVE] = 60 },
				note = "Taught by the Triage doctor at 240." },
			{ lo = 260, hi = 275, crafts = 20, recipe = "Runecloth Bandage", uses = { [RUNECLOTH] = 20 },
				note = "Taught by the Triage doctor at 260." },
			{ lo = 275, hi = 300, crafts = 30, recipe = "Major Healing Potion",
				uses = { [GOLDEN_SANSAM] = 30, [SOOTHING_SPICES] = 90, [CRYSTAL_VIAL] = 30 },
				note = { Horde = "Manual: Major Healing Potion: AH if under 8g, else Pexmit (Mount Hyjal, 8g), or Ortak Lomgok's quest A Rest Without Pain (Elderwild, Hyjal).",
					Alliance = "Manual: Major Healing Potion: AH if under 8g, else Pexmit (Mount Hyjal, 8g)." } },
		},
	},
}

ns.ALL_GUIDES = {}
for _, g in ipairs(ns.GUIDES) do table.insert(ns.ALL_GUIDES, g) end
for _, g in ipairs(ns.PANEL_GUIDES) do table.insert(ns.ALL_GUIDES, g) end

-- Gathered mats no guide uses. They always go to the surplus (AH) alt.
ns.EXTRA_MATS = {
	2452, 2453, 3355, 3369, 3818, 3819, 3821, 4625, 8836, 8845, 8846,
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
	[STONESCALE_EEL] = "Stonescale Eel", [STONESCALE_OIL] = "Stonescale Oil", [IRONWEB_SILK] = "Ironweb Spider Silk",
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
	[THORIUM_BAR] = "Thorium Bar", [TRUESILVER_BAR] = "Truesilver Bar",
	[ROUGH_STONE] = "Rough Stone", [COARSE_STONE] = "Coarse Stone", [HEAVY_STONE] = "Heavy Stone", [SOLID_STONE] = "Solid Stone",
	[DENSE_STONE] = "Dense Stone",
	[ROUGH_GS] = "Rough Grinding Stone", [COARSE_GS] = "Coarse Grinding Stone",
	[HEAVY_GS] = "Heavy Grinding Stone", [SOLID_GS] = "Solid Grinding Stone", [DENSE_GS] = "Dense Grinding Stone",
	[RUNECLOTH] = "Runecloth", [BOLT_RUNECLOTH] = "Bolt of Runecloth", [RUNE_THREAD] = "Rune Thread", [BLACK_DYE] = "Black Dye",
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
	[RAW_SMALLFISH] = "Raw Brilliant Smallfish", [RAW_MACKEREL] = "Raw Slitherskin Mackerel",
	[WOLF_MEAT] = "Stringy Wolf Meat", [BOAR_MEAT] = "Chunk of Boar Meat",
	[RAW_MUD_SNAPPER] = "Raw Longjaw Mud Snapper", [RAW_ALBACORE] = "Raw Rainbow Fin Albacore",
	[BEAR_MEAT] = "Bear Meat", [STRIDER_MEAT] = "Strider Meat", [RED_APPLE] = "Shiny Red Apple",
	[RAW_CATFISH] = "Raw Bristle Whisker Catfish", [TANGY_CLAM] = "Tangy Clam Meat", [RAPTOR_EGG] = "Raptor Egg",
	[RAPTOR_FLESH] = "Raptor Flesh", [RAW_MITHRIL_TROUT] = "Raw Mithril Head Trout", [TURTLE_MEAT] = "Turtle Meat",
	[RAW_YELLOWTAIL] = "Raw Spotted Yellowtail", [RAW_REDGILL] = "Raw Redgill", [RAW_NIGHTFIN] = "Raw Nightfin Snapper",
	[SPRING_WATER] = "Refreshing Spring Water", [MILD_SPICES] = "Mild Spices", [HOT_SPICES] = "Hot Spices",
	[SOOTHING_SPICES] = "Soothing Spices", [SPIDER_ICHOR] = "Spider Ichor", [DALARAN_NOIR] = "Bottle of Dalaran Noir",
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
-- Everything the bag, bank and mailbox snapshots count: the routed items,
-- plus what the panel-only guides use (shown on the panel, never routed).
ns.COUNTED = {}
for id in pairs(ns.TRACKED) do ns.COUNTED[id] = true end
for _, g in ipairs(ns.PANEL_GUIDES) do
	for _, step in ipairs(g.steps) do
		for id in pairs(step.uses or {}) do ns.COUNTED[id] = true end
	end
end
for id, name in pairs(NAMES) do ns.MAT_NAMES[id] = name end
ns.GUIDE_NAMES = NAMES
