local _, ns = ...

local CALLER = "MatBroker"

local function auctionatorPrice(id)
	local api = Auctionator and Auctionator.API and Auctionator.API.v1
	if not (api and api.GetAuctionPriceByItemID) then return nil end
	local ok, price = pcall(api.GetAuctionPriceByItemID, CALLER, id)
	return ok and price or nil
end

local function scanPrice(id)
	local entry = ns.Realm().scan[id]
	return entry and entry.price, entry and entry.time
end

-- Returns price (copper per unit), source label, and time of the data (or nil).
function ns.Price(id)
	local realm = ns.Realm()
	local mode = ns.db.source

	if mode == "manual" or mode == "auto" then
		local manual = realm.manual[id]
		if manual then return manual, "manual" end
		if mode == "manual" then return nil end
	end
	if mode == "scan" or mode == "auto" then
		local price, time = scanPrice(id)
		if price then return price, "scan", time end
		if mode == "scan" then return nil end
	end
	local price = auctionatorPrice(id)
	if price then return price, "auctionator" end
	return nil
end

function ns.SaveScan(id, price, minPrice, quantity)
	ns.Realm().scan[id] = { price = price, min = minPrice, qty = quantity, time = time() }
end

function ns.Age(t)
	if not t then return "" end
	local secs = time() - t
	if secs < 3600 then return string.format("%dm", math.max(1, math.floor(secs / 60))) end
	if secs < 86400 then return string.format("%dh", math.floor(secs / 3600)) end
	return string.format("%dd", math.floor(secs / 86400))
end
