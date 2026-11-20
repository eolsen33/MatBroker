local _, ns = ...

-- Farming sessions: /mb farm starts recording, /mb farm again stops. While
-- recording, every item you loot that is white quality or better is tallied,
-- greys are lumped into one vendor-price line, and looted coin is counted. The Farming tab prices the
-- haul at what it sells for on the AH (vendor price for things that can't be
-- auctioned). A recording survives /reload and logging out; only time spent
-- logged in on that character counts toward gold per hour.

local MAX_LOG = 30        -- finished sessions kept per realm
local MAX_SCAN_IDS = 60   -- farm items /mb scan will price in one go
local GREY = "|cff9d9d9d"

-- Saved data ------------------------------------------------------------

local function store()
	local realm = ns.Realm()
	realm.farm = realm.farm or {}
	realm.farm.active = realm.farm.active or {}  -- [player GUID] = session
	realm.farm.log = realm.farm.log or {}        -- finished, newest first
	return realm.farm
end

local function guid()
	return (UnitGUID and UnitGUID("player")) or UnitName("player") or "?"
end

local function active()
	return store().active[guid()]
end

function ns.FarmActive()
	return active()
end

function ns.FarmElapsed(s)
	return (s.elapsed or 0) + (s.resumed and math.max(0, time() - s.resumed) or 0)
end

function ns.FarmDuration(secs)
	secs = math.floor(secs)
	if secs < 3600 then return string.format("%dm", math.floor(secs / 60)) end
	return string.format("%dh %02dm", math.floor(secs / 3600), math.floor(secs / 60) % 60)
end

-- Prices ----------------------------------------------------------------

local BOUND = { [1] = true, [4] = true } -- bind on pickup, quest item

local function auctionatorByLink(link)
	local api = Auctionator and Auctionator.API and Auctionator.API.v1
	if not (link and api and api.GetAuctionPriceByItemLink) then return nil end
	local ok, price = pcall(api.GetAuctionPriceByItemLink, "MatBroker", link)
	return ok and price or nil
end

-- Price of one unit: copper, where it came from, and the age of scan data.
-- AH price when the item can be auctioned and we know one, else what a
-- vendor pays. No price at all: nil and "bound" or nil.
function ns.FarmPrice(it)
	local info = ns.ItemInfo(it.link) or ns.ItemInfo(it.id)
	local vendor = info and info.sellPrice or 0
	local bound = info and BOUND[info.bindType] or false
	local price, source, t
	if not bound then
		-- "of the Bear" style gear shares an item ID across suffixes, so only
		-- the link gives the right price.
		if not it.suffix then price, source, t = ns.Price(it.id) end
		if not price and (ns.db.source == "auto" or ns.db.source == "auctionator") then
			price = auctionatorByLink(it.link)
			source, t = price and "auctionator" or nil, nil
		end
	end
	if price and price >= vendor then return price, source, t end
	if vendor > 0 then return vendor, "vendor" end
	return nil, bound and "bound" or nil
end

-- Rows for a session, most valuable first, then totals:
-- rows, item value, units looted, how many different items have no price.
-- The totals include the greys' vendor value (s.grey); the rows don't.
function ns.FarmSummary(s)
	local rows, total, units, unpriced = {}, 0, 0, 0
	for _, it in pairs(s.items) do
		local each, source, t = ns.FarmPrice(it)
		local value = each and each * it.qty
		total, units = total + (value or 0), units + it.qty
		if not each and source ~= "bound" then unpriced = unpriced + 1 end
		rows[#rows + 1] = { item = it, each = each, value = value, source = source, time = t }
	end
	if s.grey then total, units = total + s.grey.value, units + s.grey.qty end
	table.sort(rows, function(a, b)
		if (a.value or -1) ~= (b.value or -1) then return (a.value or -1) > (b.value or -1) end
		return (a.item.link or "") < (b.item.link or "")
	end)
	return rows, total, units, unpriced
end

-- Unsuffixed, auctionable items from the session on screen, so the window's
-- Scan button prices the haul too.
function ns.FarmScanIDs()
	local out, seen = {}, {}
	local s = ns.FarmView()
	if not s then return out end
	for _, it in pairs(s.items) do
		local info = ns.ItemInfo(it.id)
		if not it.suffix and not seen[it.id] and not ns.IS_MAT[it.id]
			and info and not BOUND[info.bindType] then
			seen[it.id] = true
			out[#out + 1] = it.id
		end
	end
	table.sort(out)
	while #out > MAX_SCAN_IDS do table.remove(out) end
	return out
end

-- Which session the tab shows ---------------------------------------------

local viewIndex = 1

local function views()
	local list = {}
	local s = active()
	if s then list[1] = s end
	for _, old in ipairs(store().log) do list[#list + 1] = old end
	-- The fishing tracker's two tallies sit at the far end.
	local fish = ns.FishRecord and ns.FishRecord()
	if fish then
		for _, t in ipairs({ fish.cur or false, fish.life }) do
			if t and (next(t.items) or t.grey) then list[#list + 1] = t end
		end
	end
	return list
end

-- Open the Farming tab on one particular session.
function ns.FarmShow(s)
	for i, v in ipairs(views()) do
		if v == s then viewIndex = i break end
	end
	ns.ShowTab("farm")
end

-- The session on screen, its position, how many there are, and whether it
-- is the one being recorded.
function ns.FarmView()
	local list = views()
	if viewIndex > #list then viewIndex = math.max(#list, 1) end
	local s = list[viewIndex]
	return s, viewIndex, #list, s ~= nil and s == active()
end

function ns.FarmPage(step)
	local _, _, count = ns.FarmView()
	viewIndex = math.max(1, math.min(count, viewIndex + step))
	ns.Refresh()
end

-- One line describing a session, for chat and the window.
function ns.FarmLine(s)
	local _, total = ns.FarmSummary(s)
	local secs = ns.FarmElapsed(s)
	local all = total + (s.coin or 0)
	local line = string.format("%s, %s, %s: %s", s.char or "?", s.zone or "?", ns.FarmDuration(secs), ns.Money(all))
	if secs >= 60 then line = line .. string.format(" (%s per hour)", ns.Money(all / secs * 3600)) end
	return line, total, secs
end

-- Tracker box -------------------------------------------------------------

-- A small box in the bottom-right corner while recording: time, value so
-- far, gold per hour and the last thing looted. Drag to move, click to open
-- the Farming tab. /mb farm box (or the minimap menu) hides it.
local box

local function buildBox()
	box = CreateFrame("Button", "MatBrokerFarmBox", UIParent)
	box:SetSize(200, 76)
	box:SetScale(1.7) -- big, but narrow enough to clear the action bars
	box:SetFrameStrata("MEDIUM")
	box:SetClampedToScreen(true)
	box:SetMovable(true)
	box:RegisterForDrag("LeftButton")
	local p = ns.db.farmBoxPos2
	if p then
		box:SetPoint(p[1], UIParent, p[2], p[3], p[4])
	else
		box:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 65)
	end
	box:SetScript("OnDragStart", box.StartMoving)
	box:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, rel, x, y = self:GetPoint(1)
		ns.db.farmBoxPos2 = { point, rel, x, y }
	end)

	local bg = box:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.65)
	local edge = box:CreateTexture(nil, "BORDER")
	edge:SetPoint("TOPLEFT")
	edge:SetPoint("TOPRIGHT")
	edge:SetHeight(2)
	edge:SetColorTexture(0.25, 1, 0.25, 0.9)

	box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	box.title:SetPoint("TOPLEFT", 8, -8)
	box.total = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	box.total:SetPoint("TOPLEFT", 8, -24)
	box.rate = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	box.rate:SetPoint("TOPLEFT", 8, -42)
	box.last = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	box.last:SetPoint("TOPLEFT", 8, -57)
	box.last:SetPoint("RIGHT", -8, 0)
	box.last:SetJustifyH("LEFT")
	box.last:SetWordWrap(false)

	box.stop = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
	box.stop:SetSize(44, 18)
	box.stop:SetPoint("TOPRIGHT", -5, -5)
	box.stop:SetText("Stop")
	box.stop:SetScript("OnClick", function() ns.FarmStop() end)

	box:SetScript("OnClick", function() ns.ShowTab("farm") end)
	box:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine("MatBroker farming")
		GameTooltip:AddLine(GREY .. "Click:|r open the Farming tab", 1, 1, 1)
		GameTooltip:AddLine(GREY .. "Drag:|r move this box", 1, 1, 1)
		GameTooltip:Show()
	end)
	box:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.FarmBoxUpdate()
	local s = active()
	if not s or ns.db.farmBoxHidden then
		if box then box:Hide() end
		return
	end
	if not box then buildBox() end
	local _, total, units = ns.FarmSummary(s)
	local secs = ns.FarmElapsed(s)
	local all = total + (s.coin or 0)
	box.title:SetText("|cff40ff40Farming|r  " .. ns.FarmDuration(secs))
	box.total:SetText(ns.Money(all))
	box.rate:SetText(string.format("%s%s  %d items|r",
		secs >= 60 and (ns.Money(all / secs * 3600) .. "/hr  ") or "", GREY, units))
	box.last:SetText(s.last and string.format("+%d %s", s.last.qty, s.last.link) or (GREY .. "Nothing looted yet|r"))
	box:Show()
end

function ns.FarmBoxToggle()
	ns.db.farmBoxHidden = not ns.db.farmBoxHidden
	ns.Print("farming tracker box", ns.db.farmBoxHidden and "hidden. /mb farm box brings it back." or "shown while you record.")
	ns.FarmBoxUpdate()
end

-- Something about the recording changed: redraw the box and the window.
local function changed()
	ns.FarmBoxUpdate()
	if ns.FishBoxUpdate then ns.FishBoxUpdate() end
	ns.Refresh()
end

-- Start / stop ------------------------------------------------------------

function ns.FarmStart()
	if active() then ns.Print("already recording. /mb farm stop ends it.") return end
	local _, key = ns.Me()
	store().active[guid()] = {
		char = key, zone = (GetRealZoneText and GetRealZoneText()) or "",
		start = time(), resumed = time(), seen = time(),
		elapsed = 0, coin = 0, items = {},
	}
	viewIndex = 1
	ns.Print("recording your farming. /mb farm stops it.")
	changed()
end

function ns.FarmStop()
	local s = active()
	if not s then ns.Print("not recording. /mb farm starts a session.") return end
	s.elapsed, s.resumed, s.stop = ns.FarmElapsed(s), nil, time()
	local farm = store()
	farm.active[guid()] = nil
	if next(s.items) or s.grey or (s.coin or 0) > 0 then
		table.insert(farm.log, 1, s)
		while #farm.log > MAX_LOG do table.remove(farm.log) end
		ns.Print("farming stopped.", (ns.FarmLine(s)))
	else
		ns.Print("farming stopped. Nothing was looted, so the session wasn't kept.")
	end
	viewIndex = 1
	changed()
end

function ns.FarmToggle()
	if active() then ns.FarmStop() else ns.FarmStart() end
end

local function printList()
	local list = views()
	if #list == 0 then ns.Print("no farming sessions yet. /mb farm starts one.") return end
	for i, s in ipairs(list) do
		ns.Print(string.format("%d. %s%s|r %s%s", i, GREY, date("%b %d %H:%M", s.start), (ns.FarmLine(s)),
			s == active() and " |cff40ff40(recording)|r" or ""))
	end
	ns.Print("/mb farm show <number> opens one; /mb farm delete <number> removes it.")
end

function ns.FarmCommand(rest)
	local cmd, arg = (rest or ""):lower():match("^(%S*)%s*(.-)$")
	if cmd == "" then
		ns.FarmToggle()
		ns.ShowTab("farm")
	elseif cmd == "start" then
		ns.FarmStart()
	elseif cmd == "stop" then
		ns.FarmStop()
	elseif cmd == "box" then
		ns.FarmBoxToggle()
	elseif cmd == "list" then
		printList()
	elseif cmd == "show" then
		local n = tonumber(arg)
		if n then viewIndex = math.max(1, math.floor(n)) end
		ns.ShowTab("farm")
	elseif cmd == "delete" then
		local list, n = views(), tonumber(arg)
		local s = n and list[n]
		if not s then ns.Print("no session with that number. /mb farm list shows them.") return end
		if s == active() then ns.Print("that one is still recording. /mb farm stop first.") return end
		local farm = store()
		local found = false
		for i, old in ipairs(farm.log) do
			if old == s then table.remove(farm.log, i) found = true break end
		end
		if not found then ns.Print("that's the fishing tracker. /mb fish reset clears it.") return end
		ns.Print("deleted session", n .. ".")
		changed()
	else
		ns.Print("/mb farm  - start or stop recording   ·   /mb farm box  - hide or show the tracker box   ·   /mb farm list  - past sessions   ·   /mb farm show <n>   ·   /mb farm delete <n>")
	end
end

-- Recording -----------------------------------------------------------------

-- Turns a game format string ("You receive loot: %sx%d.") into a pattern.
local function toPattern(fmt, fallback, anchored)
	fmt = type(fmt) == "string" and fmt or fallback
	fmt = fmt:gsub("%%%d%$", "%%")                         -- "%1$s" -> "%s"
	fmt = fmt:gsub("[%^%$%(%)%.%[%]%*%+%-%?%%]", "%%%0")   -- escape magic
	fmt = fmt:gsub("%%%%s", "(.+)")
	fmt = fmt:gsub("%%%%d", "(%%d+)")
	return anchored and ("^" .. fmt .. "$") or fmt
end

local SELF_MULTI = toPattern(LOOT_ITEM_SELF_MULTIPLE, "You receive loot: %sx%d.", true)
local SELF_ONE = toPattern(LOOT_ITEM_SELF, "You receive loot: %s.", true)
local GOLD = toPattern(GOLD_AMOUNT, "%d Gold")
local SILVER = toPattern(SILVER_AMOUNT, "%d Silver")
local COPPER = toPattern(COPPER_AMOUNT, "%d Copper")

-- Grey by the link's colour, for an item the client hasn't cached.
local function greyLink(link)
	return link:find("|cff9d9d9d", 1, true) ~= nil or link:find("|cnIQ0:", 1, true) ~= nil
end

function ns.FarmAdd(s, link, qty)
	local id = tonumber(link:match("item:(%d+)"))
	if not id then return end
	local info = ns.ItemInfo(link)
	local quality = info and info.quality
	if quality == 0 or (quality == nil and greyLink(link)) then
		-- Greys aren't listed; they add up to one vendor-price line.
		s.grey = s.grey or { qty = 0, value = 0 }
		s.grey.qty = s.grey.qty + qty
		s.grey.value = s.grey.value + (info and info.sellPrice or 0) * qty
		s.last = { link = link, qty = qty }
		s.seen = time()
		changed()
		return
	end

	-- The 7th link field is the random suffix ("of the Monkey").
	local suffix = link:match("item:%d+:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:(%-?%d+)")
	if suffix == "0" then suffix = nil end
	local key = suffix and (id .. ":" .. suffix) or tostring(id)
	local it = s.items[key]
	if not it then
		it = { id = id, link = link, suffix = suffix, qty = 0 }
		s.items[key] = it
	end
	it.qty = it.qty + qty
	s.last = { link = link, qty = qty }
	s.seen = time()
	changed()
end

ns.On("CHAT_MSG_LOOT", function(text)
	if type(text) ~= "string" then return end
	local got, qty = text:match(SELF_MULTI)
	if not got then got, qty = text:match(SELF_ONE), 1 end
	if not got then return end -- someone else's loot, a roll, a craft
	local link = got:match("(|c.-|Hitem:.-|h.-|h|r)") or got:match("(|Hitem:.-|h.-|h)") or got
	qty = tonumber(qty) or 1
	local s = active()
	if s then ns.FarmAdd(s, link, qty) end
	if ns.FishLoot then ns.FishLoot(link, qty) end
end)

ns.On("CHAT_MSG_MONEY", function(text)
	local s = active()
	if not s or type(text) ~= "string" then return end
	local copper = (tonumber(text:match(GOLD)) or 0) * 10000
		+ (tonumber(text:match(SILVER)) or 0) * 100
		+ (tonumber(text:match(COPPER)) or 0)
	if copper > 0 then
		s.coin = (s.coin or 0) + copper
		s.seen = time()
		changed()
	end
end)

-- Only time logged in counts. PLAYER_LOGOUT (also fired by /reload) banks
-- the clock; if the game crashed instead, `resumed` is still set at the
-- next login and we count up to the last loot we saw.
ns.On("PLAYER_LOGOUT", function()
	local s = active()
	if s and s.resumed then s.elapsed, s.resumed = ns.FarmElapsed(s), nil end
end)

ns.On("PLAYER_LOGIN", function()
	local s = active()
	if s then
		if s.resumed then
			s.elapsed = (s.elapsed or 0) + math.max(0, (s.seen or s.resumed) - s.resumed)
		end
		s.resumed = time()
		ns.Print("still recording your farming (" .. ns.FarmDuration(ns.FarmElapsed(s)) .. " so far). /mb farm stops it.")
		ns.FarmBoxUpdate()
	end
	if C_Timer and C_Timer.NewTicker then
		C_Timer.NewTicker(10, function() if active() then changed() end end)
	end
end)
