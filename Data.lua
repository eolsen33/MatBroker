local _, ns = ...

-- Vanilla disenchant data. Ranges are ITEM level, not required level.
-- Source: warcraft.wiki.gg/wiki/Disenchanting_tables. If Forever changes the
-- tables, edit them here; everything else reads from this file.

ns.MATS = {
	-- Dusts
	{ id = 10940, kind = "dust" },    -- Strange Dust
	{ id = 11083, kind = "dust" },    -- Soul Dust
	{ id = 11137, kind = "dust" },    -- Vision Dust
	{ id = 11176, kind = "dust" },    -- Dream Dust
	{ id = 16204, kind = "dust" },    -- Illusion Dust
	-- Essences
	{ id = 10938, kind = "essence" }, -- Lesser Magic Essence
	{ id = 10939, kind = "essence" }, -- Greater Magic Essence
	{ id = 10998, kind = "essence" }, -- Lesser Astral Essence
	{ id = 11082, kind = "essence" }, -- Greater Astral Essence
	{ id = 11134, kind = "essence" }, -- Lesser Mystic Essence
	{ id = 11135, kind = "essence" }, -- Greater Mystic Essence
	{ id = 11174, kind = "essence" }, -- Lesser Nether Essence
	{ id = 11175, kind = "essence" }, -- Greater Nether Essence
	{ id = 16202, kind = "essence" }, -- Lesser Eternal Essence
	{ id = 16203, kind = "essence" }, -- Greater Eternal Essence
	-- Shards and crystals
	{ id = 10978, kind = "shard" },   -- Small Glimmering Shard
	{ id = 11084, kind = "shard" },   -- Large Glimmering Shard
	{ id = 11138, kind = "shard" },   -- Small Glowing Shard
	{ id = 11139, kind = "shard" },   -- Large Glowing Shard
	{ id = 11177, kind = "shard" },   -- Small Radiant Shard
	{ id = 11178, kind = "shard" },   -- Large Radiant Shard
	{ id = 14343, kind = "shard" },   -- Small Brilliant Shard
	{ id = 14344, kind = "shard" },   -- Large Brilliant Shard
	{ id = 20725, kind = "shard" },   -- Nexus Crystal
}

-- Fallback names until the client has the item cached.
ns.MAT_NAMES = {
	[10940] = "Strange Dust", [11083] = "Soul Dust", [11137] = "Vision Dust",
	[11176] = "Dream Dust", [16204] = "Illusion Dust",
	[10938] = "Lesser Magic Essence", [10939] = "Greater Magic Essence",
	[10998] = "Lesser Astral Essence", [11082] = "Greater Astral Essence",
	[11134] = "Lesser Mystic Essence", [11135] = "Greater Mystic Essence",
	[11174] = "Lesser Nether Essence", [11175] = "Greater Nether Essence",
	[16202] = "Lesser Eternal Essence", [16203] = "Greater Eternal Essence",
	[10978] = "Small Glimmering Shard", [11084] = "Large Glimmering Shard",
	[11138] = "Small Glowing Shard", [11139] = "Large Glowing Shard",
	[11177] = "Small Radiant Shard", [11178] = "Large Radiant Shard",
	[14343] = "Small Brilliant Shard", [14344] = "Large Brilliant Shard",
	[20725] = "Nexus Crystal",
}

ns.IS_MAT = {}
for _, m in ipairs(ns.MATS) do ns.IS_MAT[m.id] = true end

-- Each outcome: { itemID, chance (0-1), minQty, maxQty }.
-- Quantity is an even split across min..max, so the average is (min+max)/2.

ns.DE_UNCOMMON_ARMOR = {
	{ min = 5,  max = 15, out = { {10940, .80, 1, 2}, {10938, .20, 1, 2} } },
	{ min = 16, max = 20, out = { {10940, .75, 2, 3}, {10939, .20, 1, 2}, {10978, .05, 1, 1} } },
	{ min = 21, max = 25, out = { {10940, .75, 4, 6}, {10998, .15, 1, 2}, {10978, .10, 1, 1} } },
	{ min = 26, max = 30, out = { {11083, .75, 1, 2}, {11082, .20, 1, 2}, {11084, .05, 1, 1} } },
	{ min = 31, max = 35, out = { {11083, .75, 2, 5}, {11134, .20, 1, 2}, {11138, .05, 1, 1} } },
	{ min = 36, max = 40, out = { {11137, .75, 1, 2}, {11135, .20, 1, 2}, {11139, .05, 1, 1} } },
	{ min = 41, max = 45, out = { {11137, .75, 2, 5}, {11174, .20, 1, 2}, {11177, .05, 1, 1} } },
	{ min = 46, max = 50, out = { {11176, .75, 1, 2}, {11175, .20, 1, 2}, {11178, .05, 1, 1} } },
	{ min = 51, max = 55, out = { {11176, .75, 2, 5}, {16202, .20, 1, 2}, {14343, .05, 1, 1} } },
	{ min = 56, max = 60, out = { {16204, .75, 1, 2}, {16203, .20, 1, 2}, {14344, .05, 1, 1} } },
	{ min = 61, max = 65, out = { {16204, .75, 2, 5}, {16203, .20, 2, 3}, {14344, .05, 1, 1} } },
}

ns.DE_UNCOMMON_WEAPON = {
	{ min = 5,  max = 15, out = { {10940, .20, 1, 2}, {10938, .80, 1, 2} } },
	{ min = 16, max = 20, out = { {10940, .20, 2, 3}, {10939, .75, 1, 2}, {10978, .05, 1, 1} } },
	{ min = 21, max = 25, out = { {10940, .15, 4, 6}, {10998, .75, 1, 2}, {10978, .10, 1, 1} } },
	{ min = 26, max = 30, out = { {11083, .20, 1, 2}, {11082, .75, 1, 2}, {11084, .05, 1, 1} } },
	{ min = 31, max = 35, out = { {11083, .20, 2, 5}, {11134, .75, 1, 2}, {11138, .05, 1, 1} } },
	{ min = 36, max = 40, out = { {11137, .20, 1, 2}, {11135, .75, 1, 2}, {11139, .05, 1, 1} } },
	{ min = 41, max = 45, out = { {11137, .20, 2, 5}, {11174, .75, 1, 2}, {11177, .05, 1, 1} } },
	{ min = 46, max = 50, out = { {11176, .20, 1, 2}, {11175, .75, 1, 2}, {11178, .05, 1, 1} } },
	{ min = 51, max = 55, out = { {11176, .22, 2, 5}, {16202, .75, 1, 2}, {14343, .03, 1, 1} } },
	{ min = 56, max = 60, out = { {16204, .22, 1, 2}, {16203, .75, 1, 2}, {14344, .03, 1, 1} } },
	{ min = 61, max = 65, out = { {16204, .22, 2, 5}, {16203, .75, 2, 3}, {14344, .03, 1, 1} } },
}

ns.DE_RARE = {
	{ min = 1,  max = 25, out = { {10978, 1, 1, 1} } },
	{ min = 26, max = 30, out = { {11084, 1, 1, 1} } },
	{ min = 31, max = 35, out = { {11138, 1, 1, 1} } },
	{ min = 36, max = 40, out = { {11139, 1, 1, 1} } },
	{ min = 41, max = 45, out = { {11177, 1, 1, 1} } },
	{ min = 46, max = 50, out = { {11178, 1, 1, 1} } },
	{ min = 51, max = 55, out = { {14343, 1, 1, 1} } },
	{ min = 56, max = 65, out = { {14344, .995, 1, 1}, {20725, .005, 1, 1} } },
}

ns.DE_EPIC = {
	{ min = 40, max = 45, out = { {11177, 1, 2, 4} } },
	{ min = 46, max = 50, out = { {11178, 1, 2, 4} } },
	{ min = 51, max = 55, out = { {14343, 1, 2, 4} } },
	{ min = 56, max = 60, out = { {20725, 1, 1, 1} } },
	{ min = 61, max = 88, out = { {20725, 1, 1, 2} } },
}

-- Enchanting skill needed to disenchant, by item level.
ns.DE_SKILL = {
	{ max = 20, skill = 1 },
	{ max = 25, skill = 25 },
	{ max = 30, skill = 50 },
	{ max = 35, skill = 75 },
	{ max = 40, skill = 100 },
	{ max = 45, skill = 125 },
	{ max = 50, skill = 150 },
	{ max = 55, skill = 175 },
	{ max = 60, skill = 200 },
	{ max = 999, skill = 225 },
}
