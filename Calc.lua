local _, ns = ...

local ARMOR, WEAPON = 4, 2
local NOT_DISENCHANTABLE_SLOTS = { INVTYPE_BODY = true, INVTYPE_TABARD = true }

local function findBracket(tbl, ilvl)
	for _, b in ipairs(tbl) do
		if ilvl >= b.min and ilvl <= b.max then return b end
	end
end

-- The DE table for an item, or nil if it can't be disenchanted.
function ns.DETable(info)
	if not info or NOT_DISENCHANTABLE_SLOTS[info.equipLoc] then return nil end
	if info.classID ~= ARMOR and info.classID ~= WEAPON then return nil end
	if info.equipLoc == nil or info.equipLoc == "" then return nil end
	local tbl
	if info.quality == 2 then
		tbl = info.classID == WEAPON and ns.DE_UNCOMMON_WEAPON or ns.DE_UNCOMMON_ARMOR
	elseif info.quality == 3 then
		tbl = ns.DE_RARE
	elseif info.quality == 4 then
		tbl = ns.DE_EPIC
	else
		return nil
	end
	return findBracket(tbl, info.ilvl or 0)
end

function ns.SkillFor(ilvl)
	for _, row in ipairs(ns.DE_SKILL) do
		if ilvl <= row.max then return row.skill end
	end
end

-- Value of one disenchant after the AH cut.
-- Returns value (copper), and a list of { id, chance, avgQty, price, value }.
-- If any outcome has no price, value is nil and `missing` lists those mats.
function ns.Evaluate(bracket)
	local rows, total, missing = {}, 0, nil
	local keep = 1 - ns.db.ahCut
	for _, o in ipairs(bracket.out) do
		local id, chance, lo, hi = o[1], o[2], o[3], o[4]
		local avgQty = (lo + hi) / 2
		local price = ns.Price(id)
		local value = price and chance * avgQty * price * keep
		if value then
			total = total + value
		else
			missing = missing or {}
			table.insert(missing, id)
		end
		table.insert(rows, { id = id, chance = chance, lo = lo, hi = hi, avgQty = avgQty, price = price, value = value })
	end
	return (not missing) and total or nil, rows, missing
end

-- Most you should pay so that selling the mats beats the buy price by `margin`.
function ns.MaxBuy(value)
	if not value then return nil end
	return value / (1 + ns.db.margin)
end

-- Convenience for an item link/ID: info, bracket, value, maxBuy, rows, missing.
function ns.EvaluateItem(item)
	local info = ns.ItemInfo(item)
	local bracket = ns.DETable(info)
	if not bracket then return info end
	local value, rows, missing = ns.Evaluate(bracket)
	return info, bracket, value, ns.MaxBuy(value), rows, missing
end
