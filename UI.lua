local _, ns = ...

local ROW_H = 18
local GREY = "|cff9d9d9d"
local frame, scrollChild, rows, activeTab
local tabButtons = {}

-- Column layout per tab: { header, width, justify }
local COLUMNS = {
	mats = {
		{ "Mat", 190, "LEFT" }, { "Price", 110, "RIGHT" }, { "Lowest", 110, "RIGHT" },
		{ "Listed", 50, "RIGHT" }, { "Source", 100, "RIGHT" },
	},
	brackets = {
		{ "Green item level", 110, "LEFT" }, { "Armor DE", 100, "RIGHT" }, { "Buy armor under", 115, "RIGHT" },
		{ "Weapon DE", 100, "RIGHT" }, { "Buy weapon under", 120, "RIGHT" },
	},
	alts = {
		{ "Mat", 190, "LEFT" }, { "Mailed", 75, "RIGHT" }, { "Guide total", 85, "RIGHT" },
		{ "Still needed", 90, "RIGHT" }, { "Goes to", 100, "RIGHT" },
	},
	deals = {
		{ "Item", 200, "LEFT" }, { "ilvl", 35, "RIGHT" }, { "Price", 95, "RIGHT" },
		{ "DE value", 95, "RIGHT" }, { "Profit", 95, "RIGHT" },
	},
	farm = {
		{ "Looted", 200, "LEFT" }, { "Qty", 40, "RIGHT" }, { "Sells for", 95, "RIGHT" },
		{ "Total", 95, "RIGHT" }, { "Price from", 90, "RIGHT" },
	},
}

local function makeRow(parent, i)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(560, ROW_H)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()
	row.bg:SetColorTexture(1, 1, 1, i % 2 == 0 and 0.04 or 0)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_H - 2, ROW_H - 2)
	row.icon:SetPoint("LEFT", 2, 0)
	row.cells = {}
	for c = 1, 5 do
		local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetHeight(ROW_H)
		fs:SetWordWrap(false)
		row.cells[c] = fs
	end
	row:SetScript("OnEnter", function(self)
		if not self.link then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(self.link)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row:SetScript("OnClick", function(self)
		if self.link and IsModifiedClick("CHATLINK") then ChatEdit_InsertLink(self.link) end
	end)
	return row
end

local function layoutRow(row, cols, hasIcon)
	local x = hasIcon and (ROW_H + 4) or 4
	for c, col in ipairs(cols) do
		local fs = row.cells[c]
		fs:ClearAllPoints()
		fs:SetPoint("LEFT", x, 0)
		fs:SetWidth(col[2] - (c == 1 and hasIcon and ROW_H or 0))
		fs:SetJustifyH(col[3])
		x = x + col[2] - (c == 1 and hasIcon and ROW_H or 0) + 4
	end
	row.icon:SetShown(hasIcon)
end

local function getRow(i)
	rows[i] = rows[i] or makeRow(scrollChild, i)
	return rows[i]
end

local function setHeaders(cols, hasIcon)
	local x = hasIcon and (ROW_H + 4) or 4
	for c = 1, 5 do
		local h = frame.headers[c]
		local col = cols[c]
		h:SetShown(col ~= nil)
		if col then
			local w = col[2] - (c == 1 and hasIcon and ROW_H or 0)
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", frame.listArea, "TOPLEFT", x, 16)
			h:SetWidth(w)
			h:SetJustifyH(col[3])
			h:SetText(col[1])
			x = x + w + 4
		end
	end
end

-- Tab contents ----------------------------------------------------------

local function fillMats()
	local list = {}
	local realm = ns.Realm()
	for _, m in ipairs(ns.MATS) do
		local price, source, t = ns.Price(m.id)
		local scan = realm.scan[m.id]
		local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(m.id)
		table.insert(list, {
			icon = ns.MatIcon(m.id), link = link,
			ns.MatName(m.id), ns.Money(price), ns.Money(scan and scan.min),
			scan and scan.qty and tostring(scan.qty) or (GREY .. "--|r"),
			price and (source .. (t and (" " .. ns.Age(t)) or "")) or (GREY .. "none|r"),
		})
	end
	return list, true
end

local function fillBrackets()
	local list = {}
	for i, armor in ipairs(ns.DE_UNCOMMON_ARMOR) do
		local weapon = ns.DE_UNCOMMON_WEAPON[i]
		local av = ns.Evaluate(armor)
		local wv = weapon and ns.Evaluate(weapon)
		local skill = ns.SkillFor(armor.max)
		table.insert(list, {
			string.format("%d-%d %s(skill %d)|r", armor.min, armor.max, GREY, skill),
			ns.Money(av), "|cff40ff40" .. ns.Money(ns.MaxBuy(av)) .. "|r",
			ns.Money(wv), "|cff40ff40" .. ns.Money(ns.MaxBuy(wv)) .. "|r",
		})
	end
	return list, false
end

local function fillDeals()
	local list = {}
	for _, d in ipairs(ns.deals) do
		table.insert(list, {
			link = d.link,
			d.link or d.name or ("item:" .. d.itemID), tostring(d.ilvl or ""),
			ns.Money(d.price), ns.Money(d.value), "|cff40ff40+" .. ns.Money(d.profit) .. "|r",
		})
	end
	if #list == 0 then
		table.insert(list, { GREY .. "No deals yet. Open the AH and click Find deals.|r", "", "", "", "" })
	end
	return list, false
end

local GOLD, GREEN, YELLOW = "|cffffd100", "|cff40ff40", "|cffffff60"

local function fillAlts()
	local list = {}
	for _, g in ipairs(ns.GUIDES) do
		local c, name = ns.Crafter(g)
		local skill = c and c.profs[g.skillLine]
		local routes = {}
		for choice, options in pairs(g.choices) do
			table.insert(routes, options.label .. " " .. ns.Option(g, choice))
		end
		table.sort(routes)
		table.insert(list, {
			GOLD .. g.name .. "|r", "", GREY .. table.concat(routes, ", ") .. "|r", "",
			name and string.format("%s %s%d|r", ns.MailName(name), GREY, skill) or (GREY .. "log in your alt|r"),
		})
		local total = ns.GuideNeed(g, 0)
		local need = c and ns.GuideNeed(g, skill, c)
		local surplusTo = ns.MailName(ns.SurplusAlt(name)) or "AH"
		for _, id in ipairs(g.mats) do
			if (total[id] or 0) > 0 or ns.Mailed(name, id) > 0 then
				local n = need and need[id] or 0
				local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(id)
				table.insert(list, {
					icon = ns.MatIcon(id), link = link,
					ns.MatName(id), tostring(ns.Mailed(name, id)), tostring(total[id] or 0),
					need and (n > 0 and tostring(n) or (GREEN .. "done|r")) or (GREY .. "?|r"),
					need and (n > 0 and (GREEN .. ns.MailName(name) .. "|r") or (YELLOW .. surplusTo .. "|r")) or "",
				})
			end
		end
	end
	local extras = {}
	for _, id in ipairs(ns.EXTRA_MATS) do
		if ns.Mailed(ns.SurplusAlt(), id) > 0 then table.insert(extras, id) end
	end
	if #extras > 0 then
		table.insert(list, { GOLD .. "Not in a guide|r", "", "", "", "" })
		local surplusTo = ns.MailName(ns.SurplusAlt()) or "AH"
		for _, id in ipairs(extras) do
			local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(id)
			table.insert(list, {
				icon = ns.MatIcon(id), link = link,
				ns.MatName(id), tostring(ns.Mailed(ns.SurplusAlt(), id)), "", "", YELLOW .. surplusTo .. "|r",
			})
		end
	end
	return list, true
end

local function fillFarm()
	local list = {}
	local s = ns.FarmView()
	if not s then
		table.insert(list, { GREY .. "Nothing recorded yet. Click Start farming, then go loot.|r", "", "", "", "" })
		return list, false
	end
	for _, r in ipairs((ns.FarmSummary(s))) do
		local it = r.item
		local from = r.source and (r.source .. (r.time and (" " .. ns.Age(r.time)) or "")) or "none"
		if r.source == "bound" then from = "can't sell" end
		table.insert(list, {
			icon = ns.MatIcon(it.id), link = it.link,
			it.link or ns.MatName(it.id), tostring(it.qty), ns.Money(r.each), ns.Money(r.value),
			(r.each and r.source ~= "vendor") and from or (GREY .. from .. "|r"),
		})
	end
	if s.grey then
		table.insert(list, {
			icon = 133784, -- coin
			GREY .. "Grey items|r", tostring(s.grey.qty), "", ns.Money(s.grey.value), GREY .. "vendor|r",
		})
	end
	if #list == 0 then
		table.insert(list, { GREY .. "Recording. Nothing looted yet.|r", "", "", "", "" })
		return list, false
	end
	return list, true
end

local function farmStatus()
	local s, index, count, recording = ns.FarmView()
	if not s then return "", GREY .. "Whites and better are listed at AH price (your scan or Auctionator); greys add up at vendor price.|r" end
	local _, total, units, unpriced = ns.FarmSummary(s)
	local secs = ns.FarmElapsed(s)
	local all = total + (s.coin or 0)
	local status = string.format("Items %s  +  coin %s", ns.Money(total), ns.Money(s.coin or 0))
	if secs >= 60 then status = status .. string.format("  =  %s/hr", ns.Money(all / secs * 3600)) end
	local where = string.format("%s%s  ·  %s  ·  %s  ·  %s  ·  %d items%s  ·  session %d of %d|r",
		recording and "|cff40ff40Recording|r  ·  " or "", GREY .. (s.char or "?"), s.zone or "?",
		date("%b %d %H:%M", s.start), ns.FarmDuration(secs), units,
		unpriced > 0 and string.format("  ·  %d with no price (scan the AH)", unpriced) or "", index, count)
	return status, where
end

local FILL = { mats = fillMats, brackets = fillBrackets, alts = fillAlts, deals = fillDeals, farm = fillFarm }

function ns.Refresh()
	if not frame or not frame:IsShown() then return end
	local cols = COLUMNS[activeTab]
	local list, hasIcon = FILL[activeTab]()
	setHeaders(cols, hasIcon)
	for i, data in ipairs(list) do
		local row = getRow(i)
		layoutRow(row, cols, hasIcon)
		row.link = data.link
		if hasIcon then row.icon:SetTexture(data.icon) end
		row.icon:SetShown(hasIcon and data.icon ~= nil)
		for c = 1, 5 do row.cells[c]:SetText(data[c] or "") end
		row:Show()
	end
	for i = #list + 1, #rows do rows[i]:Hide() end
	scrollChild:SetHeight(math.max(#list * ROW_H, 1))

	for name, b in pairs(tabButtons) do
		if name == activeTab then b:LockHighlight() else b:UnlockHighlight() end
	end
	frame.scanBtn:SetEnabled(ns.ahOpen)
	frame.dealsBtn:SetEnabled(ns.ahOpen)
	local farming = activeTab == "farm"
	frame.dealsBtn:SetShown(not farming)
	frame.farmBtn:SetShown(farming)
	frame.prevBtn:SetShown(farming)
	frame.nextBtn:SetShown(farming)
	if farming then
		local _, index, count = ns.FarmView()
		frame.farmBtn:SetText(ns.FarmActive() and "Stop farming" or "Start farming")
		frame.prevBtn:SetEnabled(index < count)
		frame.nextBtn:SetEnabled(index > 1)
		local status, where = farmStatus()
		frame.status:SetText(ns.status or status)
		frame.settings:SetText(where)
		return
	end
	if activeTab == "alts" then
		frame.status:SetText(GREY .. "Mailed = total you've sent that alt. Still needed = rest of the guide minus what it holds or has in the mail.|r")
	else
		frame.status:SetText(ns.status or (ns.ahOpen and "" or (GREY .. "Open the Auction House to scan.|r")))
	end
	frame.settings:SetText(string.format("%sAH cut %g%%  ·  target profit %g%%  ·  prices: %s|r",
		GREY, ns.db.ahCut * 100, ns.db.margin * 100, ns.db.source))
end

-- Window ----------------------------------------------------------------

local function build()
	frame = CreateFrame("Frame", "MatBrokerFrame", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(600, 470)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame:SetScript("OnShow", ns.Refresh)
	tinsert(UISpecialFrames, "MatBrokerFrame") -- Esc closes it
	ns.FixClose(frame)

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("TOP", 0, -5)
	frame.title:SetText("MatBroker")

	local tabs = { { "mats", "Mat prices" }, { "brackets", "Green DE values" }, { "deals", "Deals" }, { "alts", "Alt mats" }, { "farm", "Farming" } }
	for i, t in ipairs(tabs) do
		local b = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		b:SetSize(112, 22)
		b:SetPoint("TOPLEFT", 12 + (i - 1) * 116, -30)
		b:SetText(t[2])
		b:SetScript("OnClick", function() ns.ShowTab(t[1]) end)
		tabButtons[t[1]] = b
	end

	frame.listArea = CreateFrame("Frame", nil, frame)
	frame.listArea:SetPoint("TOPLEFT", 14, -78)
	frame.listArea:SetPoint("BOTTOMRIGHT", -32, 64)

	frame.headers = {}
	for c = 1, 5 do
		local h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		frame.headers[c] = h
	end

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetAllPoints(frame.listArea)
	scrollChild = CreateFrame("Frame", nil, scroll)
	scrollChild:SetSize(560, 1)
	scroll:SetScrollChild(scrollChild)
	rows = {}

	frame.scanBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.scanBtn:SetSize(110, 22)
	frame.scanBtn:SetPoint("BOTTOMLEFT", 12, 34)
	frame.scanBtn:SetText("Scan mats")
	frame.scanBtn:SetScript("OnClick", ns.ScanMats)

	frame.dealsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.dealsBtn:SetSize(110, 22)
	frame.dealsBtn:SetPoint("LEFT", frame.scanBtn, "RIGHT", 6, 0)
	frame.dealsBtn:SetText("Find deals")
	frame.dealsBtn:SetScript("OnClick", ns.FindDeals)

	-- Farming tab: Start/Stop sits where Find deals is, with older/newer
	-- session arrows; the status text moves right to clear them.
	frame.farmBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.farmBtn:SetSize(110, 22)
	frame.farmBtn:SetPoint("LEFT", frame.scanBtn, "RIGHT", 6, 0)
	frame.farmBtn:SetScript("OnClick", ns.FarmToggle)
	frame.prevBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.prevBtn:SetSize(24, 22)
	frame.prevBtn:SetPoint("LEFT", frame.farmBtn, "RIGHT", 6, 0)
	frame.prevBtn:SetText("<")
	frame.prevBtn:SetScript("OnClick", function() ns.FarmPage(1) end)
	frame.nextBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.nextBtn:SetSize(24, 22)
	frame.nextBtn:SetPoint("LEFT", frame.prevBtn, "RIGHT", 2, 0)
	frame.nextBtn:SetText(">")
	frame.nextBtn:SetScript("OnClick", function() ns.FarmPage(-1) end)

	frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.status:SetPoint("LEFT", frame.nextBtn, "RIGHT", 10, 0)
	frame.status:SetPoint("RIGHT", -14, 0)
	frame.status:SetJustifyH("LEFT")

	frame.settings = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.settings:SetPoint("BOTTOMLEFT", 14, 14)
	frame.settings:SetPoint("BOTTOMRIGHT", -14, 14)
	frame.settings:SetJustifyH("LEFT")

	activeTab = "mats"
	frame:Hide()
end

function ns.ShowTab(name)
	if not frame then build() end
	activeTab = name
	frame:Show()
	ns.Refresh()
end

function ns.ToggleWindow()
	if not frame then build() end
	frame:SetShown(not frame:IsShown())
end

-- Show the window alongside the AH, and refresh when item data arrives.
ns.On("AUCTION_HOUSE_SHOW", function()
	if not frame then build() end
	local ah = AuctionHouseFrame or AuctionFrame
	if ah and not frame.placed then
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", ah, "TOPRIGHT", 8, 0)
		frame.placed = true
	end
	frame:Show()
end)
ns.On("GET_ITEM_INFO_RECEIVED", function()
	if frame and frame:IsShown() and not ns.refreshQueued then
		ns.refreshQueued = true
		C_Timer.After(0.2, function() ns.refreshQueued = false; ns.Refresh() end)
	end
end)
