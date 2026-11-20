local _, ns = ...

-- Fishing tracker: equip a fishing pole and a box shows what you've caught,
-- this outing and for the life of the character, priced the same way as a
-- farming session (AH price for whites and better, greys at vendor price).
-- Put the pole away and the box goes with it. Picking the pole back up
-- within ten minutes carries the outing on; after that a new one starts.
-- Only time with the pole equipped counts toward gold per hour.

local SAME_OUTING = 600   -- seconds without the pole before "current" starts over
local LOOT_WINDOW = 5     -- seconds after a fishing loot window that loot counts as a catch
local MAIN_HAND = 16
local WEAPON, FISHING_POLE = 2, 20
local GREY, BLUE = "|cff9d9d9d", "|cff66ccff"

-- Saved data ------------------------------------------------------------

local function guid()
	return (UnitGUID and UnitGUID("player")) or UnitName("player") or "?"
end

local function blank(zone)
	local _, key = ns.Me()
	return { char = key, zone = zone, start = time(), elapsed = 0, coin = 0, catches = 0, items = {} }
end

-- This character's record: .life (everything, ever) and .cur (this outing).
local function mine()
	local realm = ns.Realm()
	realm.fish = realm.fish or {}
	local rec = realm.fish[guid()]
	if not rec then
		rec = { life = blank("Fishing, lifetime") }
		realm.fish[guid()] = rec
	end
	return rec
end

function ns.FishRecord()
	return mine()
end

-- Is the pole out? ------------------------------------------------------

local function poleEquipped()
	local id = GetInventoryItemID and GetInventoryItemID("player", MAIN_HAND)
	if not id then return false end
	local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if instant then
		local _, _, _, _, _, class, sub = instant(id)
		if class then return class == WEAPON and sub == FISHING_POLE end
	end
	local info = ns.ItemInfo(id)
	return info ~= nil and info.classID == WEAPON and info.subclassID == FISHING_POLE
end

-- Clocks ----------------------------------------------------------------

local function running()
	local cur = mine().cur
	return cur ~= nil and cur.resumed ~= nil
end

local function pause(upTo)
	local rec = mine()
	local cur = rec.cur
	if not (cur and cur.resumed) then return end
	local spent = math.max(0, (upTo or time()) - cur.resumed)
	cur.elapsed, cur.resumed, cur.stopped = (cur.elapsed or 0) + spent, nil, upTo or time()
	rec.life.elapsed, rec.life.resumed = (rec.life.elapsed or 0) + spent, nil
end

local function resume()
	local rec = mine()
	local cur = rec.cur
	if cur and cur.resumed then return end
	if not cur or time() - (cur.stopped or 0) > SAME_OUTING then
		cur = blank((GetRealZoneText and GetRealZoneText()) or "")
		cur.zone = "Fishing, " .. (cur.zone ~= "" and cur.zone or "this outing")
		rec.cur = cur
	end
	cur.resumed, cur.seen = time(), time()
	rec.life.resumed = cur.resumed
end

-- Box -------------------------------------------------------------------

local box

local function buildBox()
	box = CreateFrame("Button", "MatBrokerFishBox", UIParent)
	box:SetSize(200, 92)
	box:SetScale(1.7)
	box:SetFrameStrata("MEDIUM")
	box:SetClampedToScreen(true)
	box:SetMovable(true)
	box:RegisterForDrag("LeftButton")
	local p = ns.db.fishBoxPos
	if p then
		box:SetPoint(p[1], UIParent, p[2], p[3], p[4])
	else
		box:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 147) -- above the farming box
	end
	box:SetScript("OnDragStart", box.StartMoving)
	box:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, rel, x, y = self:GetPoint(1)
		ns.db.fishBoxPos = { point, rel, x, y }
	end)

	local bg = box:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.65)
	local edge = box:CreateTexture(nil, "BORDER")
	edge:SetPoint("TOPLEFT")
	edge:SetPoint("TOPRIGHT")
	edge:SetHeight(2)
	edge:SetColorTexture(0.4, 0.8, 1, 0.9)

	local function line(template, y)
		local fs = box:CreateFontString(nil, "OVERLAY", template)
		fs:SetPoint("TOPLEFT", 8, y)
		fs:SetPoint("RIGHT", -8, 0)
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(false)
		return fs
	end
	box.title = line("GameFontNormalSmall", -8)
	box.now = line("GameFontHighlight", -24)
	box.nowRate = line("GameFontHighlightSmall", -42)
	box.life = line("GameFontHighlightSmall", -57)
	box.last = line("GameFontHighlightSmall", -72)

	box:SetScript("OnClick", function() ns.FarmShow(mine().cur) end)
	box:SetScript("OnEnter", function(self)
		local rec = mine()
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine("MatBroker fishing")
		for _, part in ipairs({ { "This outing", rec.cur }, { "Lifetime", rec.life } }) do
			local s = part[2]
			if s then
				local rows, total = ns.FarmSummary(s)
				GameTooltip:AddDoubleLine(part[1] .. GREY .. "  " .. (s.catches or 0) .. " catches, "
					.. ns.FarmDuration(ns.FarmElapsed(s)) .. "|r", ns.Money(total), 0.4, 0.8, 1, 1, 1, 1)
				for i = 1, math.min(6, #rows) do
					local r = rows[i]
					GameTooltip:AddDoubleLine("  " .. r.item.qty .. " " .. (r.item.link or ns.MatName(r.item.id)),
						ns.Money(r.value), 1, 1, 1, 1, 1, 1)
				end
				if s.grey then
					GameTooltip:AddDoubleLine(GREY .. "  " .. s.grey.qty .. " grey items|r", ns.Money(s.grey.value), 1, 1, 1, 1, 1, 1)
				end
			end
		end
		GameTooltip:AddLine(GREY .. "Click:|r full list in the Farming tab   " .. GREY .. "Drag:|r move", 1, 1, 1)
		GameTooltip:Show()
	end)
	box:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function worth(s)
	local _, total = ns.FarmSummary(s)
	local secs = ns.FarmElapsed(s)
	return total + (s.coin or 0), secs
end

local function perHour(all, secs)
	return secs >= 60 and (ns.Money(all / secs * 3600) .. "/hr") or (GREY .. "-/hr|r")
end

function ns.FishBoxUpdate()
	if not ns.db then return end
	local rec = mine()
	local cur = rec.cur
	if not (cur and cur.resumed) or ns.db.fishBoxHidden then
		if box then box:Hide() end
		return
	end
	if not box then buildBox() end
	local nowAll, nowSecs = worth(cur)
	local lifeAll, lifeSecs = worth(rec.life)
	box.title:SetText(string.format("%sFishing|r  %s  %s%d catches|r", BLUE, ns.FarmDuration(nowSecs), GREY, cur.catches or 0))
	box.now:SetText(ns.Money(nowAll))
	box.nowRate:SetText(perHour(nowAll, nowSecs))
	box.life:SetText(string.format("%sLifetime|r %s  %s%d catches, %s, |r%s", BLUE, ns.Money(lifeAll), GREY,
		rec.life.catches or 0, ns.FarmDuration(lifeSecs), perHour(lifeAll, lifeSecs)))
	box.last:SetText(cur.last and string.format("+%d %s", cur.last.qty, cur.last.link) or (GREY .. "Nothing caught yet|r"))
	box:Show()
end

-- The pole went on or came off.
local function check()
	if not ns.db then return end
	local out = poleEquipped()
	if out and not running() then
		resume()
	elseif not out and running() then
		pause()
	end
	ns.FishBoxUpdate()
end

-- Catches ---------------------------------------------------------------

local catchUntil, lastCatch = 0, 0

-- A loot window opened: is it a fish on the line?
local function lootOpened()
	if not running() or not IsFishingLoot or not IsFishingLoot() then return end
	local now = GetTime()
	catchUntil = now + LOOT_WINDOW
	if now - lastCatch < 1 then return end -- LOOT_READY and LOOT_OPENED for the same catch
	lastCatch = now
	local rec = mine()
	rec.cur.catches = (rec.cur.catches or 0) + 1
	rec.life.catches = (rec.life.catches or 0) + 1
	rec.cur.seen = time()
	ns.FishBoxUpdate()
end

-- Called by the farming recorder for every item you loot yourself.
function ns.FishLoot(link, qty)
	if not ns.db or not running() then return end
	-- Mob loot with the pole out isn't a catch. (A client without
	-- IsFishingLoot can't tell, so there everything counts.)
	if IsFishingLoot and GetTime() > catchUntil then return end
	local rec = mine()
	ns.FarmAdd(rec.cur, link, qty)
	ns.FarmAdd(rec.life, link, qty)
end

pcall(ns.On, "LOOT_READY", lootOpened)
pcall(ns.On, "LOOT_OPENED", lootOpened)
ns.On("PLAYER_EQUIPMENT_CHANGED", function(slot)
	if slot == nil or slot == MAIN_HAND then check() end
end)

ns.On("PLAYER_LOGOUT", function()
	if ns.db then pause() end
end)

ns.On("PLAYER_LOGIN", function()
	-- The game crashed with the pole out: count up to the last catch we saw.
	local cur = mine().cur
	if cur and cur.resumed then pause(math.max(cur.resumed, cur.seen or cur.resumed)) end
	check()
	-- Item data may not be loaded yet right at login.
	if C_Timer then C_Timer.After(3, check) end
	if C_Timer and C_Timer.NewTicker then
		C_Timer.NewTicker(10, function() if running() then ns.FishBoxUpdate() end end)
	end
end)

-- Commands --------------------------------------------------------------

local function printLine(label, s)
	local all, secs = worth(s)
	ns.Print(string.format("%s: %s, %d catches, %s%s", label, ns.Money(all), s.catches or 0, ns.FarmDuration(secs),
		secs >= 60 and string.format(" (%s per hour)", ns.Money(all / secs * 3600)) or ""))
end

function ns.FishCommand(rest)
	local cmd, arg = (rest or ""):lower():match("^(%S*)%s*(.-)$")
	local rec = mine()
	if cmd == "" then
		if rec.cur then printLine("fishing, this outing", rec.cur) end
		printLine("fishing, lifetime", rec.life)
		ns.Print("/mb fish box hides or shows the tracker · /mb fish show [lifetime] lists the catch · /mb fish reset [lifetime]")
	elseif cmd == "box" then
		ns.db.fishBoxHidden = not ns.db.fishBoxHidden
		ns.Print("fishing tracker box", ns.db.fishBoxHidden and "hidden. /mb fish box brings it back." or "shown while a fishing pole is equipped.")
		ns.FishBoxUpdate()
	elseif cmd == "show" then
		ns.FarmShow(arg == "lifetime" and rec.life or rec.cur or rec.life)
	elseif cmd == "reset" then
		local wasRunning = running()
		pause()
		if arg == "lifetime" then
			rec.life = blank("Fishing, lifetime")
			rec.cur = nil
			ns.Print("fishing lifetime totals cleared for this character.")
		else
			rec.cur = nil
			ns.Print("fishing: started a new outing. Lifetime totals are kept.")
		end
		if wasRunning then resume() end
		ns.FishBoxUpdate()
		ns.Refresh()
	else
		ns.Print("/mb fish  - totals   ·   /mb fish box   ·   /mb fish show [lifetime]   ·   /mb fish reset [lifetime]")
	end
end
