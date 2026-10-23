local _, ns = ...

-- Auction House scanning. Forever's AH API wasn't confirmed before launch, so
-- this supports both the modern C_AuctionHouse API and the legacy
-- QueryAuctionItems API and picks whichever the client has.

local SAMPLE_UNITS = 20   -- mat price = average of the cheapest 20 units listed
local MAX_LEGACY_PAGES = 40
local TIMEOUT = 8

local function modern() return C_AuctionHouse and C_AuctionHouse.SendSearchQuery ~= nil end
local function legacy() return QueryAuctionItems ~= nil end

ns.ahOpen = false
ns.On("AUCTION_HOUSE_SHOW", function() ns.ahOpen = true; ns.Refresh() end)
ns.On("AUCTION_HOUSE_CLOSED", function() ns.ahOpen = false; ns.Refresh() end)

-- Coroutine runner: one job at a time, resumed every frame. -------------

local runner = CreateFrame("Frame")
local job, jobName

runner:SetScript("OnUpdate", function()
	if not job then return end
	local ok, err = coroutine.resume(job)
	if not ok then
		ns.Print("|cffff5555error:|r", err)
		job = nil
	elseif coroutine.status(job) == "dead" then
		job = nil
	end
	if not job then ns.status = nil; ns.Refresh() end
end)

local function start(name, fn)
	if job then ns.Print("busy with", jobName, "- wait for it to finish.") return end
	if not ns.ahOpen then ns.Print("open the Auction House first.") return end
	if not modern() and not legacy() then ns.Print("this client has no Auction House API I recognize.") return end
	job, jobName = coroutine.create(fn), name
end

local function waitFor(pred, timeout)
	local deadline = GetTime() + (timeout or TIMEOUT)
	while not pred() do
		if not ns.ahOpen then error("Auction House closed", 0) end
		if GetTime() > deadline then return false end
		coroutine.yield()
	end
	return true
end

local function setStatus(text)
	ns.status = text
	ns.Refresh()
end

-- Event flags the coroutines wait on. -----------------------------------

local got = {}
for _, e in ipairs({
	"COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED",
	"AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
	"AUCTION_ITEM_LIST_UPDATE",
}) do
	pcall(ns.On, e, function(arg) got[e] = arg or true end)
end

local function throttleReady()
	if C_AuctionHouse and C_AuctionHouse.IsThrottledMessageSystemReady then
		return C_AuctionHouse.IsThrottledMessageSystemReady()
	end
	return true
end

-- Average unit price of the cheapest `SAMPLE_UNITS` units.
-- `listings` is a list of { unit = copper, qty = n }, cheapest first.
local function samplePrice(listings)
	table.sort(listings, function(a, b) return a.unit < b.unit end)
	local units, spent = 0, 0
	for _, l in ipairs(listings) do
		local take = math.min(l.qty, SAMPLE_UNITS - units)
		units, spent = units + take, spent + take * l.unit
		if units >= SAMPLE_UNITS then break end
	end
	local total = 0
	for _, l in ipairs(listings) do total = total + l.qty end
	if units == 0 then return nil end
	return spent / units, listings[1].unit, total
end

-- Mat price scan --------------------------------------------------------

local function modernSearch(id)
	waitFor(throttleReady, 30)
	got.COMMODITY_SEARCH_RESULTS_UPDATED, got.ITEM_SEARCH_RESULTS_UPDATED = nil, nil
	local key = C_AuctionHouse.MakeItemKey(id)
	local sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } }
	C_AuctionHouse.SendSearchQuery(key, sorts, false)

	local found = waitFor(function()
		return got.COMMODITY_SEARCH_RESULTS_UPDATED == id or got.ITEM_SEARCH_RESULTS_UPDATED
	end)
	if not found then return {} end

	local listings = {}
	if got.COMMODITY_SEARCH_RESULTS_UPDATED == id then
		for i = 1, C_AuctionHouse.GetNumCommoditySearchResults(id) do
			local r = C_AuctionHouse.GetCommoditySearchResultInfo(id, i)
			if r and r.unitPrice then table.insert(listings, { unit = r.unitPrice, qty = r.quantity or 1 }) end
		end
	else
		for i = 1, C_AuctionHouse.GetNumItemSearchResults(key) do
			local r = C_AuctionHouse.GetItemSearchResultInfo(key, i)
			if r and r.buyoutAmount then
				local qty = math.max(r.quantity or 1, 1)
				table.insert(listings, { unit = r.buyoutAmount / qty, qty = qty })
			end
		end
	end
	return listings
end

local function legacyQuery(text, page, rarity, exact, filters)
	waitFor(function() return CanSendAuctionQuery() end, 30)
	got.AUCTION_ITEM_LIST_UPDATE = nil
	QueryAuctionItems(text, nil, nil, page, false, rarity, false, exact, filters)
	return waitFor(function() return got.AUCTION_ITEM_LIST_UPDATE end)
end

local function legacySearch(id)
	local name = ns.MatName(id)
	local listings = {}
	for page = 0, 2 do
		if not legacyQuery(name, page, nil, true) then break end
		local batch, total = GetNumAuctionItems("list")
		for i = 1, batch do
			local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = GetAuctionItemInfo("list", i)
			if itemID == id and buyout and buyout > 0 then
				count = math.max(count or 1, 1)
				table.insert(listings, { unit = buyout / count, qty = count })
			end
		end
		if (page + 1) * 50 >= (total or 0) then break end
	end
	return listings
end

function ns.ScanMats()
	start("mat scan", function()
		local updated = 0
		for i, m in ipairs(ns.MATS) do
			setStatus(string.format("Scanning %s (%d/%d)", ns.MatName(m.id), i, #ns.MATS))
			local listings = modern() and modernSearch(m.id) or legacySearch(m.id)
			local price, minPrice, qty = samplePrice(listings)
			if price then
				ns.SaveScan(m.id, price, minPrice, qty)
				updated = updated + 1
			end
		end
		ns.Print(string.format("scan done: %d of %d mats have listings.", updated, #ns.MATS))
	end)
end

-- Deal finder -----------------------------------------------------------

ns.deals = {}

local function consider(itemID, link, ilvl, price, out, pending)
	local info = ns.ItemInfo(link or itemID)
	if not info then pending[#pending + 1] = { itemID, link, ilvl, price } return end
	if ilvl and ilvl > 0 then info.ilvl = ilvl end
	local bracket = ns.DETable(info)
	if not bracket then return end
	local value = ns.Evaluate(bracket)
	if not value then return end
	local maxBuy = ns.MaxBuy(value)
	if price <= maxBuy then
		table.insert(out, {
			itemID = itemID, link = info.link, name = info.name, ilvl = info.ilvl,
			price = price, value = value, maxBuy = maxBuy, profit = value - price,
		})
	end
end

local function modernBrowse(candidates)
	waitFor(throttleReady, 30)
	got.AUCTION_HOUSE_BROWSE_RESULTS_UPDATED = nil
	C_AuctionHouse.SendBrowseQuery({
		searchString = "",
		sorts = { { sortOrder = Enum.AuctionHouseSortOrder.Price, reverseSort = false } },
		filters = { Enum.AuctionHouseFilter.UncommonQuality },
		itemClassFilters = { { classID = 2 }, { classID = 4 } },
	})
	if not waitFor(function() return got.AUCTION_HOUSE_BROWSE_RESULTS_UPDATED end) then return end

	local pages = 0
	while not C_AuctionHouse.HasFullBrowseResults() and pages < MAX_LEGACY_PAGES do
		pages = pages + 1
		setStatus(string.format("Loading listings (%d)", #C_AuctionHouse.GetBrowseResults()))
		waitFor(throttleReady, 30)
		got.AUCTION_HOUSE_BROWSE_RESULTS_ADDED = nil
		C_AuctionHouse.RequestMoreBrowseResults()
		if not waitFor(function() return got.AUCTION_HOUSE_BROWSE_RESULTS_ADDED end) then break end
	end

	for _, r in ipairs(C_AuctionHouse.GetBrowseResults()) do
		if r.minPrice and r.minPrice > 0 then
			table.insert(candidates, { r.itemKey.itemID, nil, r.itemKey.itemLevel, r.minPrice })
		end
	end
end

local function legacyBrowse(candidates)
	local filters = { { classID = 2 }, { classID = 4 } }
	local page, total = 0, 0
	repeat
		setStatus(string.format("Loading listings page %d", page + 1))
		if not legacyQuery("", page, 2, false, filters) then break end
		local batch
		batch, total = GetNumAuctionItems("list")
		for i = 1, batch do
			local _, _, count, quality, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = GetAuctionItemInfo("list", i)
			if quality == 2 and buyout and buyout > 0 then
				local link = GetAuctionItemLink("list", i)
				table.insert(candidates, { itemID, link, nil, buyout / math.max(count or 1, 1) })
			end
		end
		page = page + 1
	until page * 50 >= (total or 0) or page >= MAX_LEGACY_PAGES
end

function ns.FindDeals()
	start("deal search", function()
		setStatus("Searching greens...")
		local candidates = {}
		if modern() then modernBrowse(candidates) else legacyBrowse(candidates) end

		local deals, pending = {}, {}
		for _, c in ipairs(candidates) do consider(c[1], c[2], c[3], c[4], deals, pending) end

		-- Items the client hadn't cached yet: give it a moment, then retry.
		for _ = 1, 3 do
			if #pending == 0 then break end
			setStatus(string.format("Loading %d item details...", #pending))
			local deadline = GetTime() + 2
			waitFor(function() return GetTime() > deadline end, 3)
			local retry = pending
			pending = {}
			for _, c in ipairs(retry) do consider(c[1], c[2], c[3], c[4], deals, pending) end
		end

		table.sort(deals, function(a, b) return a.profit > b.profit end)
		ns.deals = deals
		ns.Print(string.format("checked %d listings, %d worth buying to DE.", #candidates, #deals))
		for i = 1, math.min(5, #deals) do
			local d = deals[i]
			ns.Print(string.format("%s for %s, DE worth %s (+%s)", d.link or d.name, ns.Money(d.price), ns.Money(d.value), ns.Money(d.profit)))
		end
		if #deals > 0 then ns.ShowTab("deals") end
	end)
end
