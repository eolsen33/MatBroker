local ADDON, ns = ...

local DEFAULTS = {
	ahCut = 0.05,       -- AH takes 5% of the sale
	margin = 0.10,      -- profit you want on top of the buy price
	source = "auto",    -- auto | scan | auctionator | manual
	tooltip = true,
	guideAuto = true,   -- open the leveling guide on login for crafter alts
	mailGreens = true,  -- offer unbound green gear to the AH seller at the mailbox
}

ns.events = CreateFrame("Frame")
local handlers = {}

function ns.On(event, fn)
	handlers[event] = handlers[event] or {}
	table.insert(handlers[event], fn)
	ns.events:RegisterEvent(event)
end

ns.events:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event] or {}) do fn(...) end
end)

function ns.Print(...)
	DEFAULT_CHAT_FRAME:AddMessage("|cff9d7cffMatBroker|r: " .. string.join(" ", tostringall(...)))
end

-- Money ---------------------------------------------------------------

function ns.Money(copper)
	if not copper then return "|cff808080--|r" end
	copper = math.floor(copper + 0.5)
	local neg = copper < 0
	copper = math.abs(copper)
	local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
	local out
	if g > 0 then
		out = string.format("%d|cffffd700g|r %02d|cffc7c7cfs|r %02d|cffeda55fc|r", g, s, c)
	elseif s > 0 then
		out = string.format("%d|cffc7c7cfs|r %02d|cffeda55fc|r", s, c)
	else
		out = string.format("%d|cffeda55fc|r", c)
	end
	return neg and ("-" .. out) or out
end

-- "1g20s", "1g 20s 5c", "35s", "80c", or a plain number (gold, e.g. 2.5).
function ns.ParseMoney(text)
	text = (text or ""):lower():gsub("%s", "")
	if text == "" then return nil end
	if text:match("^[%d%.]+$") then
		return math.floor(tonumber(text) * 10000 + 0.5)
	end
	local total, matched = 0, false
	for num, unit in text:gmatch("([%d%.]+)([gsc])") do
		matched = true
		local n = tonumber(num) or 0
		total = total + n * (unit == "g" and 10000 or unit == "s" and 100 or 1)
	end
	return matched and math.floor(total + 0.5) or nil
end

-- Items ---------------------------------------------------------------

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo

-- Returns a table, or nil if the item isn't cached yet (a load is requested).
function ns.ItemInfo(item)
	local name, link, quality, ilvl, reqLevel, _, _, _, equipLoc, icon, sellPrice, classID, subclassID = GetItemInfo(item)
	if not name then
		local id = tonumber(item) or (type(item) == "string" and tonumber(item:match("item:(%d+)")))
		if id and C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
		return nil
	end
	return {
		name = name, link = link, quality = quality, ilvl = ilvl, reqLevel = reqLevel,
		equipLoc = equipLoc, icon = icon, sellPrice = sellPrice or 0,
		classID = classID, subclassID = subclassID,
	}
end

function ns.MatName(id)
	local info = ns.ItemInfo(id)
	return info and info.name or ns.MAT_NAMES[id] or ("item:" .. id)
end

function ns.MatIcon(id)
	local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
	return icon or 134400 -- question mark
end

-- Professions ---------------------------------------------------------

-- skillLine ID -> profession spell (for the localized name) and English name.
local PROFESSIONS = {
	[171] = { 2259, "Alchemy" },      [165] = { 2108, "Leatherworking" },
	[333] = { 7411, "Enchanting" },   [197] = { 3908, "Tailoring" },
	[164] = { 2018, "Blacksmithing" }, [182] = { 2366, "Herbalism" },
	[393] = { 8613, "Skinning" },     [186] = { 2575, "Mining" },
}
ns.ENCHANTING, ns.TAILORING = 333, 197

local function spellName(id)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(id)
		return info and info.name
	end
	return GetSpellInfo and (GetSpellInfo(id))
end

function ns.ProfessionName(skillLine)
	local p = PROFESSIONS[skillLine]
	return p and p[2] or tostring(skillLine)
end

-- Every profession this character has: { [skillLine] = rank }, and
-- { [skillLine] = current cap }.
function ns.Professions()
	local out, max = {}, {}
	if GetProfessions and GetProfessionInfo then
		for _, index in pairs({ GetProfessions() }) do
			local _, _, rank, maxRank, _, _, skillLine = GetProfessionInfo(index)
			if PROFESSIONS[skillLine] then out[skillLine], max[skillLine] = rank, maxRank end
		end
		if next(out) then return out, max end
	end
	if GetNumSkillLines and GetSkillLineInfo then
		local byName = {}
		for id, p in pairs(PROFESSIONS) do
			byName[p[2]] = id
			local localized = spellName(p[1])
			if localized then byName[localized] = id end
		end
		for i = 1, GetNumSkillLines() do
			local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
			if not isHeader and byName[name] then out[byName[name]], max[byName[name]] = rank, maxRank end
		end
	end
	return out, max
end

function ns.EnchantingSkill()
	return (ns.Professions())[ns.ENCHANTING]
end

-- Saved data ----------------------------------------------------------

function ns.RealmKey()
	return (GetRealmName() or "?") .. "-" .. (UnitFactionGroup("player") or "?")
end

function ns.Realm()
	local key = ns.RealmKey()
	MatBrokerDB.realms[key] = MatBrokerDB.realms[key] or { scan = {}, manual = {} }
	return MatBrokerDB.realms[key]
end

ns.On("ADDON_LOADED", function(name)
	if name ~= ADDON then return end
	MatBrokerDB = MatBrokerDB or {}
	MatBrokerDB.settings = MatBrokerDB.settings or {}
	for k, v in pairs(DEFAULTS) do
		if MatBrokerDB.settings[k] == nil then MatBrokerDB.settings[k] = v end
	end
	MatBrokerDB.settings.paths = MatBrokerDB.settings.paths or {}
	MatBrokerDB.realms = MatBrokerDB.realms or {}
	ns.db = MatBrokerDB.settings
end)

ns.On("PLAYER_LOGIN", function()
	-- Warm the item cache so mat names and icons are ready.
	for _, m in ipairs(ns.MATS) do ns.ItemInfo(m.id) end
end)

-- Slash commands ------------------------------------------------------

local function findMat(text)
	local id = tonumber(text:match("item:(%d+)")) or tonumber(text)
	if id then return ns.IS_MAT[id] and id or nil end
	text = text:lower()
	for _, m in ipairs(ns.MATS) do
		if ns.MatName(m.id):lower() == text then return m.id end
	end
	for _, m in ipairs(ns.MATS) do
		if ns.MatName(m.id):lower():find(text, 1, true) then return m.id end
	end
end

local HELP = {
	"/mb  - open the window",
	"/mb scan  - scan mat prices (Auction House must be open)",
	"/mb deals  - search the AH for greens worth buying to DE",
	"/mb set <mat or link> <price>  - set a price by hand, e.g. /mb set strange dust 25s",
	"/mb clear <mat or link>  - remove a hand-set price",
	"/mb margin <percent>  - profit you want on top of the buy price (now %g%%)",
	"/mb cut <percent>  - AH cut on sales (now %g%%)",
	"/mb source auto|scan|auctionator|manual  - where prices come from (now %s)",
	"/mb tooltip  - toggle tooltip lines",
	"/mb greens  - toggle mailing BoE greens to the AH seller",
	"/mb alts  - what each crafter alt still needs, and where your herbs and skins go",
	"/mb path <choice> <option>  - pick a guide route (/mb path alone lists them)",
	"/mb chars  - characters MatBroker knows and their professions",
	"/mb forget <name>  - drop a character",
	"/mb seller <name>  - which character sells the surplus on the AH (none = auto)",
	"/mb name <First Last>  - set a full mail name by hand if login didn't pick it up (/mb name Whoo = Whoo Deyy for another one)",
	"/mb probe  - show where this client exposes the full name",
	"/mb ids  - check the guide item IDs against the game",
	"/mb mailui  - list the send-mail edit boxes (if Fill mail won't set the name)",
	"/mb guide  - show or hide the leveling guide (Alchemy, Leatherworking, Tailoring, Enchanting, Blacksmithing, Mining)",
	"/mb guide auto  - turn the guide popping up on login on or off",
	"/mb minimap  - hide or show the minimap button",
}

SLASH_MATBROKER1 = "/mb"
SLASH_MATBROKER2 = "/matbroker"
SlashCmdList.MATBROKER = function(msg)
	local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
	cmd = cmd:lower()

	if cmd == "" then
		ns.ToggleWindow()
	elseif cmd == "scan" then
		ns.ScanMats()
	elseif cmd == "deals" then
		ns.FindDeals()
	elseif cmd == "set" then
		-- price is the last word; everything before it is the mat
		local matText, priceText = rest:match("^(.-)%s+(%S+)$")
		local id = matText and findMat(matText)
		local price = priceText and ns.ParseMoney(priceText)
		if not id or not price then
			ns.Print("usage: /mb set <mat name or shift-click link> <price>, e.g. /mb set soul dust 1g20s")
			return
		end
		ns.Realm().manual[id] = price
		ns.Print(ns.MatName(id), "set to", ns.Money(price))
		ns.Refresh()
	elseif cmd == "clear" then
		local id = findMat(rest)
		if not id then ns.Print("unknown mat:", rest) return end
		ns.Realm().manual[id] = nil
		ns.Print("cleared hand-set price for", ns.MatName(id))
		ns.Refresh()
	elseif cmd == "margin" or cmd == "cut" then
		local n = tonumber(rest)
		if not n or n < 0 or n > 100 then ns.Print("give a percent from 0 to 100") return end
		ns.db[cmd == "margin" and "margin" or "ahCut"] = n / 100
		ns.Print(cmd == "margin" and "Target profit" or "AH cut", "set to", n .. "%")
		ns.Refresh()
	elseif cmd == "source" then
		local s = rest:lower()
		if s ~= "auto" and s ~= "scan" and s ~= "auctionator" and s ~= "manual" then
			ns.Print("source must be auto, scan, auctionator or manual")
			return
		end
		ns.db.source = s
		ns.Print("price source:", s)
		ns.Refresh()
	elseif cmd == "alts" then
		ns.ShowTab("alts")
	elseif cmd == "path" then
		ns.SetPath(rest)
	elseif cmd == "chars" then
		ns.ListChars()
	elseif cmd == "mailui" then
		ns.DumpMailUI()
	elseif cmd == "seller" then
		ns.SetSeller(rest)
	elseif cmd == "name" then
		ns.SetName(rest)
	elseif cmd == "probe" then
		ns.ProbeName()
	elseif cmd == "forget" then
		ns.ForgetChar(rest)
	elseif cmd == "guide" then
		if rest:lower() == "auto" then
			ns.db.guideAuto = not ns.db.guideAuto
			ns.Print("guide pops up on login:", ns.db.guideAuto and "on" or "off")
		else
			ns.ToggleGuide()
		end
	elseif cmd == "minimap" then
		ns.ToggleMinimapButton()
	elseif cmd == "ids" then
		ns.CheckIDs()
	elseif cmd == "greens" then
		ns.db.mailGreens = not ns.db.mailGreens
		ns.Print("BoE greens to the AH seller:", ns.db.mailGreens and "on" or "off")
		ns.RefreshMailPanel()
	elseif cmd == "tooltip" then
		ns.db.tooltip = not ns.db.tooltip
		ns.Print("tooltip lines", ns.db.tooltip and "on" or "off")
	else
		for i, line in ipairs(HELP) do
			if i == 6 then line = line:format(ns.db.margin * 100)
			elseif i == 7 then line = line:format(ns.db.ahCut * 100)
			elseif i == 8 then line = line:format(ns.db.source) end
			ns.Print(line)
		end
	end
end
