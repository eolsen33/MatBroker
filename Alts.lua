local _, ns = ...

-- Alt routing: where your herbs, skins, cloth, ore and enchanting mats should
-- go. Every character records its own professions, bags, bank and mailbox
-- when you play it. A crafter alt (anyone with a guide in Guides.lua) gets
-- mats until it holds everything left in its guide; after that they're
-- surplus for the AH alt (Enchanting or Tailoring), or for the AH if there is
-- none. A mat two guides use goes to the first guide that still needs it.

local GREY, GREEN, YELLOW, GOLD, RED = "|cff9d9d9d", "|cff40ff40", "|cffffff60", "|cffffd100", "|cffff5555"

local ATTACH_SEND = ATTACHMENTS_MAX_SEND or 12
local ATTACH_RECEIVE = ATTACHMENTS_MAX_RECEIVE or 16

local Container = C_Container or {}
local GetNumSlots = Container.GetContainerNumSlots or GetContainerNumSlots
local PickupItem = Container.PickupContainerItem or PickupContainerItem
local SplitItem = Container.SplitContainerItem or SplitContainerItem

local function slotItem(bag, slot)
	if Container.GetContainerItemInfo then
		local info = Container.GetContainerItemInfo(bag, slot)
		if info then return info.itemID, info.stackCount, info.isLocked end
		return nil
	end
	local _, count, locked, _, _, _, _, _, _, id = GetContainerItemInfo(bag, slot)
	return id, count, locked
end

local function bagIDs()
	local t = {}
	for b = 0, NUM_BAG_SLOTS or 4 do t[#t + 1] = b end
	return t
end

local function bankIDs()
	local first = (NUM_BAG_SLOTS or 4) + 1
	local t = { BANK_CONTAINER or -1 }
	for b = first, first + (NUM_BANKBAGSLOTS or 6) - 1 do t[#t + 1] = b end
	return t
end

local function countItems(bags)
	local out = {}
	for _, bag in ipairs(bags) do
		for slot = 1, GetNumSlots(bag) or 0 do
			local id, count = slotItem(bag, slot)
			if id and ns.TRACKED[id] then out[id] = (out[id] or 0) + count end
		end
	end
	return out
end

-- BoE greens for the AH ---------------------------------------------------

local scanTip
local function tooltipBind(bag, slot)
	if not scanTip then
		scanTip = CreateFrame("GameTooltip", "MatBrokerScanTip", UIParent, "GameTooltipTemplate")
		scanTip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	scanTip:ClearLines()
	scanTip:SetBagItem(bag, slot)
	local boe, bound = false, false
	for i = 2, 6 do
		local fs = _G["MatBrokerScanTipTextLeft" .. i]
		local t = fs and fs:GetText()
		if t == ITEM_SOULBOUND or t == ITEM_BIND_ON_PICKUP then bound = true end
		if t == ITEM_BIND_ON_EQUIP then boe = true end
	end
	return boe and not bound
end

local function slotDetail(bag, slot)
	if Container.GetContainerItemInfo then
		local info = Container.GetContainerItemInfo(bag, slot)
		if info then return info.itemID, info.quality, info.hyperlink, info.isBound, info.isLocked end
		return nil
	end
	local _, _, locked, quality, _, _, link, _, _, id, isBound = GetContainerItemInfo(bag, slot)
	return id, quality, link, isBound, locked
end

local function equippable(link)
	if IsEquippableItem then return IsEquippableItem(link) end
	local classID = select(12, (C_Item and C_Item.GetItemInfo or GetItemInfo)(link))
	return classID == 2 or classID == 4
end

-- Unbound green gear in the bags: { { bag, slot, id, link }, ... }.
function ns.Greens()
	local out = {}
	for _, bag in ipairs(bagIDs()) do
		for slot = 1, GetNumSlots(bag) or 0 do
			local id, quality, link, isBound = slotDetail(bag, slot)
			if id and quality == 2 and link and not isBound and equippable(link) and tooltipBind(bag, slot) then
				table.insert(out, { bag = bag, slot = slot, id = id, link = link })
			end
		end
	end
	table.sort(out, function(a, b) return (a.link or "") < (b.link or "") end)
	return out
end

-- Characters -----------------------------------------------------------

-- Forever characters have a first and a last name ("Shadow Tomb"), mail is
-- addressed to both, and two of your characters can share a first name.
-- UnitName only gives the first, so records are keyed by the full name as
-- soon as it's known: from whatever the client exposes (probed below), from
-- the recipient you typed when a mail went through, from the sender of mail
-- that arrives from an alt, or from /mb name. Until then a record is keyed
-- by the first name, with the class as the tiebreaker.

function ns.Chars()
	local realm = ns.Realm()
	realm.chars = realm.chars or {}
	return realm.chars
end

local function firstWord(name)
	return (name:gsub("%-.*$", ""):match("^(%S+)") or name):lower()
end

local function trim(text)
	return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- Places the client shows the full name. On Forever (checked 2026-10-23)
-- UnitPVPName and GetUnitName(unit, true) both return "Whoo Dey"; the rest
-- are fallbacks. Each returns a string or nil.
local PROBES = {
	{ "UnitPVPName", function() return UnitPVPName("player") end },
	{ "GetUnitName(true)", function() return GetUnitName("player", true) end },
	{ "PlayerName", function() return PlayerName and PlayerName:GetText() end },
	{ "PlayerFrame.name", function() return PlayerFrame and PlayerFrame.name and PlayerFrame.name:GetText() end },
	{ "UnitFullName", function() return (UnitFullName("player")) end },
}

-- "First Last" for the character you're on, if anything exposes it.
local function detectFullName(first)
	for _, probe in ipairs(PROBES) do
		local ok, v = pcall(probe[2])
		if ok and type(v) == "string" then
			local last = v:match("^" .. first .. "%s+(%a[%a']*)") or v:match("%s" .. first .. "%s+(%a[%a']*)")
			if last then return first .. " " .. last end
		end
	end
end

-- /mb probe: what every candidate returns on this client.
function ns.ProbeName()
	local first = UnitName("player")
	ns.Print("first name:", first, "class:", (UnitClass("player")))
	for _, probe in ipairs(PROBES) do
		local ok, v = pcall(probe[2])
		ns.Print("  " .. probe[1] .. ":", ok and tostring(v) or (RED .. "error: " .. tostring(v) .. "|r"))
	end
	ns.Print("detected:", detectFullName(first) or "nothing")
end

local function newRecord()
	return { profs = {}, bags = {}, bank = {}, inbox = {}, transit = {} }
end

local myKey

-- Move a record (and its mailed tally, seller pick) to a new key.
local function renameChar(old, new)
	if old == new then return end
	local chars, realm = ns.Chars(), ns.Realm()
	if chars[new] then
		-- Merge: keep the newer snapshot, add the tallies.
		local a, b = chars[old], chars[new]
		local keep = (a.seen or 0) >= (b.seen or 0) and a or b
		chars[new] = keep
	else
		chars[new] = chars[old]
	end
	chars[old] = nil
	if realm.mailed then
		if realm.mailed[old] then
			realm.mailed[new] = realm.mailed[new] or {}
			for id, n in pairs(realm.mailed[old]) do realm.mailed[new][id] = (realm.mailed[new][id] or 0) + n end
			realm.mailed[old] = nil
		end
	end
	if realm.seller == old then realm.seller = new end
	if myKey == old then myKey = new end
end

local function me()
	local chars = ns.Chars()
	if myKey and chars[myKey] then
		-- Keep trying for the full name until we have it.
		if not chars[myKey].mailName then
			local full = detectFullName(UnitName("player"))
			if full then
				renameChar(myKey, full)
				chars[full].mailName = full
			end
		end
		return chars[myKey], myKey
	end

	local first = UnitName("player")
	local _, class = UnitClass("player")
	local full = detectFullName(first)
	local key
	if full then
		key = full
		if not chars[key] then
			-- Claim the old first-name record if it's this class (or has none).
			for k, c in pairs(chars) do
				if not c.mailName and firstWord(k) == first:lower() and (not c.class or c.class == class) then
					renameChar(k, key)
					break
				end
			end
		end
	else
		for k, c in pairs(chars) do
			if firstWord(k) == first:lower() and c.class == class then key = k break end
		end
		if not key then
			local old = chars[first]
			if old and not old.class then
				key = first
			elseif old then
				local localized = type(LOCALIZED_CLASS_NAMES_MALE) == "table" and LOCALIZED_CLASS_NAMES_MALE[class] or class
				key = first .. " (" .. localized .. ")"
			else
				key = first
			end
		end
	end
	chars[key] = chars[key] or newRecord()
	chars[key].class = class
	if full then chars[key].mailName = full end
	myKey = key
	return chars[key], key
end

ns.Me = me

-- Known character for a typed or displayed name: the exact key or mail name,
-- else a first name that only one character has.
local function findChar(name)
	if not name or name == "" then return nil end
	local lower = trim(name):lower():gsub("%-", " ")
	for key, c in pairs(ns.Chars()) do
		if key:lower() == lower or (c.mailName and c.mailName:lower() == lower) then return key end
	end
	local first, found, count = firstWord(name), nil, 0
	local unnamed, unnamedCount = nil, 0
	for key, c in pairs(ns.Chars()) do
		if firstWord(key) == first then
			found, count = key, count + 1
			if not c.mailName then unnamed, unnamedCount = key, unnamedCount + 1 end
		end
	end
	if count == 1 then return found end
	-- Two share the first name: a typed full name that isn't the named one
	-- must be the other.
	if lower:find(" ") and unnamedCount == 1 then return unnamed end
	return nil
end

ns.FindChar = findChar

-- The name to put in the mail "To" box.
function ns.MailName(key)
	local c = key and ns.Chars()[key]
	if c and c.mailName then return c.mailName end
	return key and (key:match("^(%S+)") or key) or key
end

-- Does a record still need its last name?
function ns.NameUnknown(key)
	local c = key and ns.Chars()[key]
	return c and not c.mailName
end

-- Remember a character's full mail name once we've seen it work.
local function learnName(key, full)
	local c = key and ns.Chars()[key]
	if not c or not full then return end
	full = trim(full):gsub("%-", " ")
	if not full:find(" ") then return end -- only a first name, nothing new
	if c.mailName == full then return end
	renameChar(key, full)
	ns.Chars()[full].mailName = full
	ns.Print(full, "is now the name on file.")
	ns.RefreshMailPanel()
	ns.Refresh()
end

-- /mb name <First Last>: the full name of the character you're on.
-- "/mb name Whoo = Whoo Deyy" sets another character's.
function ns.SetName(text)
	text = trim(text)
	if text == "" then
		local c, key = me()
		ns.Print("you're", c.mailName or (key .. " (last name unknown, /mb name First Last)"))
		return
	end
	local who, full = text:match("^(.-)%s*=%s*(.+)$")
	if who then
		local key = findChar(who)
		if not key then ns.Print("no character called", who, "- /mb chars lists them.") return end
		if not full:find(" ") then ns.Print("need both names, like: /mb name", who, "=", firstWord(full), "Tomb") return end
		learnName(key, full)
		return
	end
	local _, key = me()
	if not text:find(" ") then ns.Print("need both names, like: /mb name", UnitName("player"), "Tomb") return end
	if firstWord(text) ~= UnitName("player"):lower() then
		ns.Print("that's not this character's first name (" .. UnitName("player") .. "). To name another character: /mb name Whoo = Whoo Deyy")
		return
	end
	learnName(key, text)
end

function ns.ListChars()
	local any = false
	local seller = ns.SurplusAlt()
	local _, myName = me()
	for name, c in pairs(ns.Chars()) do
		local profs = {}
		for line, rank in pairs(c.profs) do table.insert(profs, ns.ProfessionName(line) .. " " .. rank) end
		table.sort(profs)
		local label = c.mailName or (name .. GREY .. " (last name unknown)|r")
		if name == seller then label = label .. YELLOW .. " [AH seller]|r" end
		if name == myName then label = label .. GREY .. " (you)|r" end
		ns.Print(label .. ":", #profs > 0 and table.concat(profs, ", ") or (GREY .. "no professions|r"))
		any = true
	end
	if not any then ns.Print("no characters yet. Log in each alt once.") end
end

function ns.ForgetChar(text)
	local key = findChar(text)
	if not key then ns.Print("no character called", text) return end
	ns.Chars()[key] = nil
	ns.Print("forgot", key)
	ns.Refresh()
end

-- Everything a character has or has coming to it.
local function holding(c, id)
	return (c.bags[id] or 0) + (c.bank[id] or 0) + (c.inbox[id] or 0) + (c.transit[id] or 0)
end

-- Guides ---------------------------------------------------------------

function ns.Option(guide, choice)
	return ns.db.paths[choice] or guide.choices[choice][1]
end

-- Does this step count on the route you picked?
function ns.StepActive(guide, s)
	if not s.choice then return true end
	local current = ns.Option(guide, s.choice)
	if s.options then
		for _, o in ipairs(s.options) do
			if o == current then return true end
		end
		return false
	end
	return current == s.option
end

-- "/mb path oil fireoil|manapot, ..." for every choice in every guide.
function ns.PathUsage()
	local parts = {}
	for _, g in ipairs(ns.GUIDES) do
		local keys = {}
		for choice in pairs(g.choices) do table.insert(keys, choice) end
		table.sort(keys)
		for _, choice in ipairs(keys) do
			table.insert(parts, choice .. " " .. table.concat(g.choices[choice], "|"))
		end
	end
	return table.concat(parts, ", ")
end

function ns.SetPath(text)
	local choice, option = (text or ""):lower():match("^(%S+)%s+(%S+)$")
	for _, g in ipairs(ns.GUIDES) do
		local options = choice and g.choices[choice]
		if options then
			for _, o in ipairs(options) do
				if o == option then
					ns.db.paths[choice] = option
					ns.Print(g.name, options.label, "route:", option)
					ns.Refresh()
					ns.RefreshGuide()
					return
				end
			end
			ns.Print(choice, "options:", table.concat(options, ", "))
			return
		end
	end
	ns.Print("usage: /mb path <choice> <option>:", ns.PathUsage())
end

-- Raw mats still needed to finish the guide from `skill`. With a character,
-- what it already holds or has in the mail is taken off; without one, this is
-- the full shopping list from that skill.
function ns.GuideNeed(guide, skill, c)
	local need = {}
	for _, s in ipairs(guide.steps) do
		if ns.StepActive(guide, s) then
			local left = math.min(1, math.max(0, (s.hi - skill) / (s.hi - s.lo)))
			if left > 0 then
				for id, n in pairs(s.uses or {}) do need[id] = (need[id] or 0) + n * left end
				for id, n in pairs(s.makes or {}) do need[id] = (need[id] or 0) - n * left end
			end
		end
	end
	-- In-between items (cured hides, belts, bolts, bars) the crafter is short
	-- of turn back into the raw mats they're made from.
	for id, from in pairs(guide.madeFrom) do
		local short = (need[id] or 0) - (c and holding(c, id) or 0)
		if short > 0 then
			for _, f in ipairs(type(from[1]) == "table" and from or { from }) do
				need[f[1]] = (need[f[1]] or 0) + short * f[2]
			end
		end
		need[id] = nil
	end
	local out = {}
	for id, n in pairs(need) do
		if guide.raw[id] then
			out[id] = math.max(0, math.ceil(n - (c and holding(c, id) or 0) - 0.001))
		end
	end
	return out
end

-- The character leveling a guide's profession (lowest skill if there are two).
function ns.Crafter(guide)
	local best, bestName
	for name, c in pairs(ns.Chars()) do
		local skill = c.profs[guide.skillLine]
		if skill and (not best or skill < best.profs[guide.skillLine]) then best, bestName = c, name end
	end
	return best, bestName
end

-- The AH alt: the one you picked with /mb seller, else whoever has
-- Enchanting or Tailoring.
function ns.SurplusAlt(exclude)
	local picked = ns.Realm().seller
	if picked and ns.Chars()[picked] then
		if picked ~= exclude then return picked end
		return nil
	end
	local found
	for name, c in pairs(ns.Chars()) do
		if name ~= exclude and (c.profs[ns.ENCHANTING] or c.profs[ns.TAILORING]) then
			if not found or name < found then found = name end
		end
	end
	return found
end

-- /mb seller <name>: which character sells the surplus on the AH. "/mb
-- seller none" goes back to auto (Enchanting or Tailoring).
function ns.SetSeller(text)
	text = trim(text)
	local realm = ns.Realm()
	if text == "" then
		local who = ns.SurplusAlt()
		ns.Print("AH seller:", who and ns.MailName(who) or "none", realm.seller and "" or GREY .. "(auto: Enchanting or Tailoring alt)|r")
		return
	end
	if text:lower() == "none" or text:lower() == "auto" then
		realm.seller = nil
		ns.Print("AH seller: back to auto.")
	else
		local key = findChar(text)
		if not key then ns.Print("no character called", text, "- log it in once first. /mb chars lists them.") return end
		realm.seller = key
		ns.Print("AH seller:", ns.MailName(key))
	end
	ns.Refresh()
	ns.RefreshMailPanel()
end

-- Where one mat should go. Returns nil for items MatBroker doesn't route.
-- With two guides after the same mat, the first one still short of it wins;
-- once every crafter has enough it's surplus.
function ns.Route(id)
	if ns.IS_EXTRA[id] then return { extra = true, surplusTo = ns.SurplusAlt() } end
	local guides = ns.GUIDES_FOR[id]
	if not guides then return nil end
	local fallback
	for _, guide in ipairs(guides) do
		local c, name = ns.Crafter(guide)
		if c then
			local skill = c.profs[guide.skillLine]
			local r = {
				guide = guide, crafter = name, skill = skill,
				need = ns.GuideNeed(guide, skill, c)[id] or 0,
				surplusTo = ns.SurplusAlt(name),
			}
			if r.need > 0 then return r end
			fallback = fallback or r
		elseif not fallback then
			fallback = { guide = guide, surplusTo = ns.SurplusAlt() }
		end
	end
	return fallback
end

-- Running total of a mat mailed to a character (from any of your characters).
-- This is the tally, not what you gather: herbs you keep for First Aid or
-- sell never count.
function ns.Mailed(to, id)
	local m = to and ns.Realm().mailed
	return m and m[to] and m[to][id] or 0
end

-- What this character should mail, per recipient: { [name] = { [id] = qty } },
-- plus the name the surplus goes to (nil = sell it on the AH).
function ns.MailPlan()
	local mine, myName = me()
	local left = {}
	for id, n in pairs(mine.bags) do left[id] = n end
	local plan, surplus = {}, {}

	for _, guide in ipairs(ns.GUIDES) do
		local c, name = ns.Crafter(guide)
		if c and name ~= myName then
			for id, n in pairs(ns.GuideNeed(guide, c.profs[guide.skillLine], c)) do
				local give = math.min(n, left[id] or 0)
				if give > 0 then
					plan[name] = plan[name] or {}
					plan[name][id] = (plan[name][id] or 0) + give
					left[id] = left[id] - give
				end
			end
		elseif c then
			-- This is the crafter: keep what the rest of the guide uses.
			local full = ns.GuideNeed(guide, c.profs[guide.skillLine])
			for id in pairs(guide.raw) do
				local keep = math.max(0, (full[id] or 0) - (holding(c, id) - (c.bags[id] or 0)))
				left[id] = math.max(0, (left[id] or 0) - keep)
			end
		else
			-- No crafter known yet, so we can't say what's surplus. Hold on to it.
			for id in pairs(guide.raw) do left[id] = nil end
		end
	end

	local surplusTo = ns.SurplusAlt()
	if surplusTo == myName then return plan, nil, nil, nil end
	local greens = ns.db.mailGreens and ns.Greens() or nil
	if greens and #greens == 0 then greens = nil end
	for id, n in pairs(left) do
		if n > 0 and (ns.GUIDES_FOR[id] or ns.IS_EXTRA[id]) then surplus[id] = n end
	end
	return plan, surplus, surplusTo, greens
end

-- Item ID check -----------------------------------------------------------

function ns.CheckIDs()
	local bad, pending = 0, 0
	for id in pairs(ns.TRACKED) do
		local info = ns.ItemInfo(id)
		local expected = ns.GUIDE_NAMES[id]
		if not info then
			pending = pending + 1
		elseif expected and info.name ~= expected then
			bad = bad + 1
			ns.Print(string.format("item %d is %s, expected %s", id, info.name, expected))
		end
	end
	if pending > 0 then ns.Print(pending, "items not loaded yet, run /mb ids again in a moment.") end
	if bad == 0 and pending == 0 then ns.Print("all guide item IDs match.") end
end

-- Events: professions, bags, bank, loot ------------------------------------

local bankOpen = false

local function snapshot()
	local c = me()
	local profs, max = ns.Professions()
	if next(profs) or not next(c.profs) then c.profs, c.profMax = profs, max end
	c.bags = countItems(bagIDs())
	if bankOpen then c.bank = countItems(bankIDs()) end
	c.seen = time()
end

local pendingRefresh = false
local function snapshotSoon()
	if pendingRefresh then return end
	pendingRefresh = true
	C_Timer.After(0.3, function()
		pendingRefresh = false
		snapshot()
		ns.Refresh()
		ns.RefreshMailPanel()
		ns.RefreshGuide()
	end)
end

ns.On("PLAYER_LOGIN", snapshotSoon)
ns.On("SKILL_LINES_CHANGED", snapshotSoon)
ns.On("BAG_UPDATE_DELAYED", snapshotSoon)
ns.On("BANKFRAME_OPENED", function() bankOpen = true; snapshotSoon() end)
ns.On("BANKFRAME_CLOSED", function() bankOpen = false end)
ns.On("PLAYERBANKSLOTS_CHANGED", snapshotSoon)

-- Mail: what's on its way, and what's waiting --------------------------------

local sending

hooksecurefunc("SendMail", function(recipient)
	sending = nil
	local to = findChar(recipient)
	local _, myName = me()
	if not to or to == myName then return end
	local items = {}
	for i = 1, ATTACH_SEND do
		local _, id, _, count = GetSendMailItem(i)
		if id and ns.TRACKED[id] then items[id] = (items[id] or 0) + (count or 1) end
	end
	sending = { to = to, items = items, typed = recipient }
end)

ns.On("MAIL_SEND_SUCCESS", function()
	if sending then
		learnName(sending.to, sending.typed)
		if not next(sending.items) then sending = nil return end
		local c = ns.Chars()[sending.to]
		if c then
			for id, n in pairs(sending.items) do c.transit[id] = (c.transit[id] or 0) + n end
		end
		local realm = ns.Realm()
		realm.mailed = realm.mailed or {}
		local tally = realm.mailed[sending.to] or {}
		realm.mailed[sending.to] = tally
		for id, n in pairs(sending.items) do tally[id] = (tally[id] or 0) + n end
	end
	sending = nil
	ns.Refresh()
end)
ns.On("MAIL_FAILED", function() sending = nil end)

ns.On("MAIL_INBOX_UPDATE", function()
	local c = me()
	local inbox = {}
	for i = 1, GetInboxNumItems() do
		local _, _, sender = GetInboxHeaderInfo(i)
		if sender then
			local from = findChar(sender)
			local _, myName = me()
			if from and from ~= myName then learnName(from, sender) end
		end
		for a = 1, ATTACH_RECEIVE do
			local _, id, _, count = GetInboxItem(i, a)
			if id and ns.TRACKED[id] then inbox[id] = (inbox[id] or 0) + (count or 1) end
		end
	end
	c.inbox = inbox
	-- Mail between your own characters arrives right away, so anything sent
	-- to this character is in the inbox (or already in its bags) by now.
	c.transit = {}
	ns.Refresh()
	ns.RefreshMailPanel()
end)

-- Filling a mail ------------------------------------------------------------

local function freeAttachSlot()
	for i = 1, ATTACH_SEND do
		if not GetSendMailItem(i) then return i end
	end
end

-- Bag moves to attach `items` ({ [id] = qty }): whole stacks first, then a
-- split for the remainder.
local function attachMoves(items)
	local moves = {}
	for id, want in pairs(items) do
		local partial
		for _, bag in ipairs(bagIDs()) do
			for slot = 1, GetNumSlots(bag) or 0 do
				local itemID, count = slotItem(bag, slot)
				if itemID == id and want > 0 then
					if count <= want then
						table.insert(moves, { bag = bag, slot = slot, count = count, whole = true })
						want = want - count
					elseif not partial then
						partial = { bag = bag, slot = slot }
					end
				end
			end
		end
		if want > 0 and partial then
			table.insert(moves, { bag = partial.bag, slot = partial.slot, count = want })
		end
	end
	return moves
end

local filling

-- The recipient and subject boxes. Classic names them SendMailNameEditBox
-- and SendMailSubjectEditBox; if this client doesn't, walk the send frame
-- for edit boxes instead (first one = recipient, second = subject).
local function editBoxes(frame, out)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child:IsObjectType("EditBox") then table.insert(out, child) end
		editBoxes(child, out)
	end
	return out
end

local function mailBoxes()
	local name, subject = SendMailNameEditBox, SendMailSubjectEditBox
	if (name and subject) or not SendMailFrame then return name, subject end
	local found = editBoxes(SendMailFrame, {})
	for _, box in ipairs(found) do
		local n = (box:GetName() or ""):lower()
		if n:find("name") or n:find("recipient") or n:find("target") then name = name or box end
		if n:find("subject") then subject = subject or box end
	end
	name = name or found[1]
	subject = subject or found[2]
	return name, subject
end

-- /mb mailui: what the send-mail frame's edit boxes are called on this client.
function ns.DumpMailUI()
	if not SendMailFrame then ns.Print("no SendMailFrame on this client.") return end
	local found = editBoxes(SendMailFrame, {})
	ns.Print("SendMailFrame edit boxes:", #found)
	for i, box in ipairs(found) do
		ns.Print(i, box:GetName() or "(unnamed)", box:GetObjectType(), "shown:", tostring(box:IsShown()), "text:", box:GetText())
	end
	ns.Print("SendMailNameEditBox:", tostring(SendMailNameEditBox), "SendMailSubjectEditBox:", tostring(SendMailSubjectEditBox))
	local keys = {}
	for k, v in pairs(SendMailFrame) do
		if type(v) == "table" and v.IsObjectType and v:IsObjectType("EditBox") then table.insert(keys, k) end
	end
	ns.Print("EditBox fields on SendMailFrame:", #keys > 0 and table.concat(keys, ", ") or "none")
end

local function setRecipient(to)
	local name, subject = mailBoxes()
	if not name then
		ns.Print("couldn't find the recipient box, type", to, "yourself. /mb mailui shows what this client has.")
		return
	end
	name:SetText(to)
	if name.SetCursorPosition then name:SetCursorPosition(#to) end
	if subject and subject:GetText() == "" then subject:SetText("Mats") end
end

function ns.FillMail(to, items, slots)
	if filling then return end
	if not (SendMailFrame and SendMailFrame:IsShown()) then
		if MailFrameTab_OnClick then MailFrameTab_OnClick(nil, 2) elseif MailFrameTab2 then MailFrameTab2:Click() end
	end
	local full = ns.MailName(to)
	if ns.NameUnknown(to) then
		ns.Print(full .. "'s last name isn't known yet, so only the first name is filled in. Finish it in the To box: once the mail goes through I'll remember it.")
	end
	setRecipient(full)
	-- Showing the send tab can reset the form, so set the name again once it settles.
	C_Timer.After(0.1, function()
		local name = mailBoxes()
		if name and name:GetText() ~= full then setRecipient(full) end
	end)

	local moves, i = attachMoves(items or {}), 0
	for _, g in ipairs(slots or {}) do
		table.insert(moves, { bag = g.bag, slot = g.slot, count = 1, whole = true })
	end
	filling = C_Timer.NewTicker(0.2, function(ticker)
		i = i + 1
		local m = moves[i]
		local slot = m and freeAttachSlot()
		if not m or not slot then
			ticker:Cancel()
			filling = nil
			if m then ns.Print("mail is full. Send it, then click Fill again for the rest.") end
			return
		end
		local _, _, locked = slotItem(m.bag, m.slot)
		if locked then i = i - 1 return end -- wait for the last move to settle
		ClearCursor()
		if m.whole then PickupItem(m.bag, m.slot) else SplitItem(m.bag, m.slot, m.count) end
		ClickSendMailItemButton(slot)
		ClearCursor()
	end)
end

-- Mailbox panel ---------------------------------------------------------------

local panel
local SECTIONS = 5

local function itemLines(items)
	local list = {}
	for id, n in pairs(items) do table.insert(list, { id = id, n = n }) end
	table.sort(list, function(a, b) return ns.MatName(a.id) < ns.MatName(b.id) end)
	local lines = {}
	for _, e in ipairs(list) do
		table.insert(lines, string.format("|T%s:14|t %s x%d", ns.MatIcon(e.id), ns.MatName(e.id), e.n))
	end
	return table.concat(lines, "\n"), #list
end

local function gearLines(greens)
	local lines = {}
	for _, g in ipairs(greens) do
		table.insert(lines, string.format("|T%s:14|t %s", ns.MatIcon(g.id), g.link))
	end
	return table.concat(lines, "\n"), #greens
end

local function buildPanel()
	panel = CreateFrame("Frame", "MatBrokerMailPanel", MailFrame, "BasicFrameTemplateWithInset")
	panel:SetSize(260, 120)
	panel:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 4, 0)
	panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	panel.title:SetPoint("TOP", 0, -5)
	panel.title:SetText("MatBroker: mail out")
	panel.sections = {}
	for s = 1, SECTIONS do
		local sec = {}
		sec.header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		sec.header:SetJustifyH("LEFT")
		sec.body = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		sec.body:SetJustifyH("LEFT")
		sec.body:SetSpacing(2)
		sec.button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		sec.button:SetSize(110, 20)
		sec.button:SetScript("OnClick", function(self) ns.FillMail(self.to, self.items, self.slots) end)
		panel.sections[s] = sec
	end
	panel.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	panel.empty:SetPoint("TOPLEFT", 14, -34)
	panel.empty:SetWidth(232)
	panel.empty:SetJustifyH("LEFT")
end

function ns.RefreshMailPanel()
	if not (MailFrame and MailFrame:IsShown()) or not ns.db then return end
	if not panel then buildPanel() end

	local plan, surplus, surplusTo, greens = ns.MailPlan()
	local entries = {}
	for to, items in pairs(plan) do
		table.insert(entries, { header = GREEN .. "Send to " .. ns.MailName(to) .. "|r", to = to, items = items })
	end
	table.sort(entries, function(a, b) return a.to < b.to end)
	if surplus and next(surplus) then
		table.insert(entries, {
			header = YELLOW .. "Surplus" .. (surplusTo and (": send to " .. ns.MailName(surplusTo)) or ": sell on the AH") .. "|r",
			to = surplusTo, items = surplus,
		})
	end
	if greens then
		table.insert(entries, {
			header = GREEN .. "Greens for the AH" .. (surplusTo and (": send to " .. ns.MailName(surplusTo)) or "") .. "|r",
			to = surplusTo, items = {}, slots = greens, gear = true,
		})
	end

	local y = -32
	for s = 1, SECTIONS do
		local sec, e = panel.sections[s], entries[s]
		local shown = e ~= nil
		sec.header:SetShown(shown)
		sec.body:SetShown(shown)
		sec.button:SetShown(shown and e.to ~= nil)
		if shown then
			local text, count
			if e.gear then text, count = gearLines(e.slots) else text, count = itemLines(e.items) end
			sec.header:ClearAllPoints()
			sec.header:SetPoint("TOPLEFT", 14, y)
			sec.header:SetText(e.header)
			sec.body:ClearAllPoints()
			sec.body:SetPoint("TOPLEFT", 18, y - 18)
			sec.body:SetText(text)
			y = y - 18 - count * 16
			if e.to then
				sec.button:ClearAllPoints()
				sec.button:SetPoint("TOPLEFT", 14, y - 4)
				sec.button:SetText("Fill mail")
				sec.button.to, sec.button.items, sec.button.slots = e.to, e.items, e.slots
				y = y - 28
			end
			y = y - 8
		end
	end

	local missing = {}
	for _, g in ipairs(ns.GUIDES) do
		if not ns.Crafter(g) then table.insert(missing, g.name) end
	end
	local notes = {}
	if #entries == 0 then table.insert(notes, "Nothing to mail from these bags.") end
	if greens and not surplusTo then table.insert(notes, "Pick an AH seller to mail the greens to: /mb seller <name>.") end
	if #missing > 0 then table.insert(notes, "No " .. table.concat(missing, " or ") .. " alt known yet. Log it in once.") end
	local seller = ns.SurplusAlt()
	table.insert(notes, "AH seller: " .. (seller and ns.MailName(seller) or "none") .. " (/mb seller <name>)")
	for _, e in ipairs(entries) do
		if e.to and ns.NameUnknown(e.to) then
			table.insert(notes, ns.MailName(e.to) .. "'s last name is unknown: finish it in the To box once, or /mb name " .. ns.MailName(e.to) .. " = First Last.")
		end
	end
	local note = GREY .. table.concat(notes, "\n") .. "|r"
	panel.empty:ClearAllPoints()
	panel.empty:SetPoint("TOPLEFT", 14, y)
	panel.empty:SetText(note)
	panel:SetHeight(-y + 16 + (note ~= "" and panel.empty:GetStringHeight() or 0))
	panel:Show()
end

ns.On("MAIL_SHOW", function() C_Timer.After(0.1, ns.RefreshMailPanel) end)
ns.On("MAIL_SEND_SUCCESS", function() C_Timer.After(0.5, ns.RefreshMailPanel) end)
