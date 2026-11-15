local _, ns = ...

-- Waylaid Crates: the tooltip lists several bundles ("- 20 Vision Dust") and
-- any one of them fills the crate. Read the list off the tooltip, price what
-- you'd still have to buy for each bundle, and show the cheapest first.
-- Nothing here is hard-coded per crate, so new crates work as they appear.

local GREY, GREEN, PURPLE, YELLOW = "|cff9d9d9d", "|cff40ff40", "|cff9d7cff", "|cffffff60"

local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

local function clean(text)
	return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end

-- Every text line of the tooltip, top to bottom (a font string may hold
-- several lines).
function ns.TooltipLines(tooltip, data)
	local out = {}
	local function add(text)
		if not text or text == "" then return end
		for line in clean(text):gmatch("[^\n]+") do out[#out + 1] = line end
	end
	local name = tooltip.GetName and tooltip:GetName()
	if name then
		for i = 1, tooltip:NumLines() do
			local fs = _G[name .. "TextLeft" .. i]
			add(fs and fs:GetText())
		end
	end
	if #out == 0 and data and data.lines then
		for _, l in ipairs(data.lines) do add(l.leftText) end
	end
	return out
end

-- Returns { { qty = 20, name = "Vision Dust" }, ... } or nil when the tooltip
-- isn't a crate.
function ns.ParseCrate(lines)
	local start
	for i, line in ipairs(lines) do
		local l = line:lower()
		if l:find("fill the crate", 1, true) or l:find("following list", 1, true) then start = i end
	end
	if not start then return nil end

	local bundles = {}
	for i = start + 1, #lines do
		local qty, name = lines[i]:match("^[%s%-%*•–]*(%d+)%s*x?%s+(.-)%s*$")
		if qty and name ~= "" then
			bundles[#bundles + 1] = { qty = tonumber(qty), name = name }
		elseif #bundles > 0 then
			break -- the list has ended ("Requires Level 20", ...)
		end
	end
	return #bundles > 0 and bundles or nil
end

-- Item name -> id: MatBroker's own tables, then ids learned from earlier
-- crates and bags, then whatever the client has cached.
local byName
function ns.CrateItemID(name)
	local key = name:lower()
	if not byName then
		byName = {}
		for id, n in pairs(ns.MAT_NAMES) do byName[n:lower()] = id end
	end
	if byName[key] then return byName[key] end

	local realm = ns.Realm()
	realm.crateIDs = realm.crateIDs or {}
	if realm.crateIDs[key] then return realm.crateIDs[key] end

	local id = GetItemInfoInstant and GetItemInfoInstant(name)
	if not id then id = ns.BagItemByName(name) end
	if id then realm.crateIDs[key] = id end
	return id
end

-- Bundles with what each still costs, cheapest first; unpriced ones last.
function ns.CrateOptions(bundles)
	local options = {}
	for _, b in ipairs(bundles) do
		local id = ns.CrateItemID(b.name)
		local have = id and math.min(ns.BagCount(id), b.qty) or 0
		local price = id and ns.Price(id)
		local missing = b.qty - have
		local o = { name = b.name, qty = b.qty, id = id, have = have, missing = missing, unit = price }
		if missing == 0 then o.cost = 0 elseif price then o.cost = missing * price end
		options[#options + 1] = o
	end
	table.sort(options, function(a, b)
		if (a.cost ~= nil) ~= (b.cost ~= nil) then return a.cost ~= nil end
		if a.cost and a.cost ~= b.cost then return a.cost < b.cost end
		return a.name < b.name
	end)
	return options
end

-- Ids of crate items, so /mb scan prices them too.
function ns.CrateScanIDs()
	local out, seen = {}, {}
	for _, id in pairs(ns.Realm().crateIDs or {}) do
		if not ns.IS_MAT[id] and not seen[id] then seen[id] = true; out[#out + 1] = id end
	end
	table.sort(out)
	return out
end

-- Adds the lines; returns true when the tooltip was a crate.
function ns.AddCrateLines(tooltip, data)
	local bundles = ns.ParseCrate(ns.TooltipLines(tooltip, data))
	if not bundles then return false end
	local options = ns.CrateOptions(bundles)

	tooltip:AddLine(" ")
	tooltip:AddLine(PURPLE .. "MatBroker|r cheapest way to fill it:")
	local unpriced = 0
	for i, o in ipairs(options) do
		local best = i == 1 and o.cost ~= nil
		local left = string.format("%s%d %s%s", best and (GREEN .. "> ") or "  ", o.qty, o.name, best and "|r" or "")
		if o.have > 0 and o.missing > 0 then
			left = left .. GREY .. string.format(" (have %d, buy %d)", o.have, o.missing) .. "|r"
		end
		local right
		if o.missing == 0 then
			right = GREEN .. "in your bags|r"
		elseif o.cost then
			right = ns.Money(o.cost)
		else
			right = GREY .. "no price|r"
			unpriced = unpriced + 1
		end
		tooltip:AddDoubleLine(left, right, 1, 1, 1, 1, 1, 1)
	end

	local best, second = options[1], options[2]
	if best and best.cost and best.cost > 0 and second and second.cost then
		tooltip:AddLine(GREY .. "Saves " .. ns.Money(second.cost - best.cost) .. GREY .. " over the next cheapest.|r")
	end
	if unpriced > 0 then
		tooltip:AddLine(YELLOW .. unpriced .. " without a price.|r" .. GREY .. " Open the AH and run /mb scan.|r")
	end
	return true
end
