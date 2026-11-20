local _, ns = ...

-- Leveling guide for the crafter alts: the step you're on, what it still
-- takes, when to visit the trainer, and what comes next. Progress is your
-- skill level, so it moves as you craft. Opens on login for a character with
-- a guided profession, and docks to the bottom-right corner of the profession
-- window, following whichever profession that window is showing. Gathering
-- steps (Mining) show where to go instead of what to make.

local GREY, GREEN, RED, GOLD, ORANGE = "|cff9d9d9d", "|cff40ff40", "|cffff5555", "|cffffd100", "|cffff9933"
local WIDTH, PAD = 310, 14
local NEXT_STEPS = 3

local panel, guideKey
local hiding, dismissed = false, nil -- dismissed: guide key you closed with the X while its window was up

local function myGuides()
	local c = ns.Me()
	local list = {}
	for _, g in ipairs(ns.ALL_GUIDES) do
		if c.profs[g.skillLine] then table.insert(list, g) end
	end
	return list, c
end

local function currentGuide()
	local list = myGuides()
	for _, g in ipairs(list) do
		if g.key == guideKey then return g end
	end
	return list[1]
end

-- The steps on the route you picked, and the index of the one you're on
-- (nil once you're past the end of the guide).
function ns.GuideSteps(guide, skill)
	local steps, at = {}, nil
	for _, s in ipairs(guide.steps) do
		if ns.StepActive(guide, s) then table.insert(steps, s) end
	end
	table.sort(steps, function(a, b) return a.lo < b.lo end)
	for i, s in ipairs(steps) do
		if s.hi > skill then at = i break end
	end
	return steps, at
end

local function stepLeft(s, skill)
	return math.min(1, math.max(0, (s.hi - skill) / (s.hi - s.lo)))
end

-- The next trainer rank you should learn, if any.
local function trainingDue(guide, skill, max)
	if not max then return nil end
	for _, r in ipairs(guide.ranks) do
		if max < r.max and skill >= r.skill then return r end
	end
end

local function have(c, id)
	return (c.bags[id] or 0) + (c.bank[id] or 0) + (c.inbox[id] or 0)
end

-- Profession window ------------------------------------------------------
-- Forever has the retail window (ProfessionsFrame + C_TradeSkillUI); the old
-- TradeSkillFrame calls are kept as a fallback.

local function profWindow()
	if ProfessionsFrame and ProfessionsFrame:IsShown() then return ProfessionsFrame end
	if TradeSkillFrame and TradeSkillFrame:IsShown() then return TradeSkillFrame end
end

-- The profession the window is showing: skill line ID, name, skill, cap.
local function openProfession()
	if not profWindow() then return nil end
	local T = C_TradeSkillUI
	if T and T.GetBaseProfessionInfo then
		local ok, info = pcall(T.GetBaseProfessionInfo)
		if ok and type(info) == "table" and (info.professionID or 0) > 0 then
			local skill, max = info.skillLevel, info.maxSkillLevel
			if not (skill and skill > 0) then skill, max = nil, nil end
			return info.professionID, info.professionName, skill, max
		end
	end
	if GetTradeSkillLine then
		local name, skill, max = GetTradeSkillLine()
		if name and name ~= "UNKNOWN" then return nil, name, skill, max end
	end
end

-- The guide for the open profession (nil when it has none), and whether a
-- profession is open at all.
local function openGuide()
	local id, name, skill, max = openProfession()
	if not (id or name) then return nil, false end
	for _, g in ipairs(ns.ALL_GUIDES) do
		if (id and g.skillLine == id) or (name and (name == g.name or name == g.window
			or name == ns.ProfessionName(g.skillLine))) then
			return g, true, skill, max
		end
	end
	return nil, true
end

-- A recipe you know in the open window, by name.
local function findRecipe(recipe)
	local T = C_TradeSkillUI
	if T and T.GetAllRecipeIDs and T.GetRecipeInfo then
		local ok, ids = pcall(T.GetAllRecipeIDs)
		if ok and type(ids) == "table" and #ids > 0 then
			for _, id in ipairs(ids) do
				local info = T.GetRecipeInfo(id)
				if info and info.name == recipe and info.learned ~= false then
					return { id = id, available = info.numAvailable or 0 }
				end
			end
			return nil
		end
	end
	if GetNumTradeSkills and GetTradeSkillInfo then
		for i = 1, GetNumTradeSkills() do
			local name, kind, available = GetTradeSkillInfo(i)
			if kind ~= "header" and name == recipe then return { index = i, available = available or 0 } end
		end
	end
end

local function selectRecipe(r)
	if r.id then
		if C_TradeSkillUI.OpenRecipe then pcall(C_TradeSkillUI.OpenRecipe, r.id) end
	elseif TradeSkillFrame_SetSelection then
		TradeSkillFrame_SetSelection(r.index)
		if TradeSkillFrame_Update then TradeSkillFrame_Update() end
	end
end

local function craftRecipe(r, count)
	if r.id then C_TradeSkillUI.CraftRecipe(r.id, count) else DoTradeSkill(r.index, count) end
end

-- Sit in the bottom-right corner of the profession window, under its
-- profession tabs. A guide too tall to fit under the tabs moves out past
-- them so they stay clickable.
local DOCK_GAP, DOCK_PAST_TABS, DOCK_ROOM = 16, 62, 0.4

local function dock()
	local frame = profWindow()
	if not (panel and frame) then return false end
	local tall = panel:GetHeight() > frame:GetHeight() * DOCK_ROOM
	panel:ClearAllPoints()
	panel:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", tall and DOCK_PAST_TABS or DOCK_GAP, 0)
	return true
end

local function undock()
	if not panel then return end
	local pos = ns.db.guidePos
	panel:ClearAllPoints()
	if pos then panel:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else panel:SetPoint("LEFT", 40, 60) end
end

-- Panel ----------------------------------------------------------------

local function text(template, wrap)
	local fs = panel:CreateFontString(nil, "OVERLAY", template)
	fs:SetJustifyH("LEFT")
	fs:SetWidth(WIDTH - PAD * 2)
	fs:SetWordWrap(wrap ~= false)
	return fs
end

local function button(label, width, onClick)
	local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	b:SetSize(width, 20)
	b:SetText(label)
	b:SetScript("OnClick", onClick)
	return b
end

local function build()
	panel = CreateFrame("Frame", "MatBrokerGuide", UIParent, "BasicFrameTemplateWithInset")
	panel:SetSize(WIDTH, 300)
	panel:SetMovable(true)
	panel:EnableMouse(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetClampedToScreen(true)
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if dock() then return end -- docked: it goes back to its corner
		local point, _, rel, x, y = self:GetPoint()
		ns.db.guidePos = { point, rel, x, y }
	end)
	undock()
	panel:SetScript("OnHide", function()
		if not hiding and profWindow() then dismissed = guideKey end
	end)
	tinsert(UISpecialFrames, "MatBrokerGuide")
	ns.FixClose(panel)

	panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	panel.title:SetPoint("TOP", 0, -5)
	panel.title:SetText("MatBroker guide")

	panel.header = text("GameFontNormalLarge", false)
	panel.switch = button("", 160, function(self)
		guideKey = self.key
		ns.RefreshGuide()
	end)

	panel.bar = CreateFrame("StatusBar", nil, panel)
	panel.bar:SetSize(WIDTH - PAD * 2, 10)
	panel.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	panel.bar:SetStatusBarColor(0.25, 0.75, 0.25)
	panel.bar.bg = panel.bar:CreateTexture(nil, "BACKGROUND")
	panel.bar.bg:SetAllPoints()
	panel.bar.bg:SetColorTexture(0, 0, 0, 0.5)

	panel.train = text("GameFontHighlightSmall")
	panel.step = text("GameFontNormal")
	panel.crafts = text("GameFontHighlightSmall")
	panel.mats = text("GameFontHighlightSmall")
	panel.mats:SetSpacing(3)
	panel.note = text("GameFontHighlightSmall")
	panel.route = text("GameFontHighlightSmall")
	panel.routeBtn = button("", 150, function(self) ns.SetPath(self.choice .. " " .. self.option) end)
	panel.select = button("Select recipe", 110, function(self) selectRecipe(self.recipe) end)
	panel.make = button("", 110, function(self) craftRecipe(self.recipe, self.count) end)
	panel.next = text("GameFontHighlightSmall")
	panel.next:SetSpacing(2)
end

local function place(widget, y, gap)
	widget:ClearAllPoints()
	widget:SetPoint("TOPLEFT", PAD, y)
	local h = widget.GetStringHeight and widget:GetStringHeight() or widget:GetHeight()
	return y - h - (gap or 6)
end

local function hideAll()
	for _, w in ipairs({ panel.switch, panel.train, panel.crafts, panel.mats, panel.note, panel.route,
		panel.routeBtn, panel.select, panel.make, panel.next }) do
		w:Hide()
	end
end

-- A button to step to this character's next guide when it has several, then size the panel.
local function finish(list, guide, y)
	if #list > 1 and not profWindow() then
		local other = list[1]
		for i, g in ipairs(list) do
			if g == guide then other = list[i + 1] or list[1] break end
		end
		panel.switch.key = other.key
		panel.switch:SetText("Show " .. other.name)
		panel.switch:Show()
		y = place(panel.switch, y - 4)
	end
	panel:SetHeight(-y + 10)
	dock()
end

function ns.RefreshGuide()
	if not (panel and panel:IsShown()) or not ns.db then return end
	hideAll()
	local list, c = myGuides()
	-- With the profession window up, the guide is that profession's.
	local open, isOpen, openSkill, openMax = openGuide()
	if open then guideKey = open.key end
	local guide = open or (not isOpen and currentGuide()) or nil
	local y = -32

	if not guide then
		panel.header:SetText(GREY .. (isOpen and "No guide for this profession yet.|r" or "No guided profession on this character.|r"))
		y = place(panel.header, y)
		panel.step:SetText("")
		panel.bar:Hide()
		panel:SetHeight(-y + 10)
		dock()
		return
	end
	guideKey = guide.key

	local skill = open and openSkill or c.profs[guide.skillLine] or 0
	local max = open and openSkill and openMax or (c.profMax and c.profMax[guide.skillLine])
	panel.header:SetText(string.format("%s %s%d / %d|r", guide.name, "|cffffffff", skill, guide.top))
	y = place(panel.header, y, 4)

	panel.bar:SetMinMaxValues(0, guide.top)
	panel.bar:SetValue(math.min(skill, guide.top))
	panel.bar:Show()
	y = place(panel.bar, y, 8)

	local rank = trainingDue(guide, skill, max)
	if rank then
		local faction = UnitFactionGroup("player") or "Horde"
		local lines = { ORANGE .. "Train " .. rank.name .. " " .. guide.name .. "|r" .. GREY
			.. string.format(" (needs skill %d%s%s)", rank.skill, rank.level and (", level " .. rank.level) or "",
				rank.cost and (", " .. rank.cost) or "") .. "|r" }
		if rank.level and UnitLevel("player") < rank.level then
			table.insert(lines, RED .. "You're level " .. UnitLevel("player") .. ", train at " .. rank.level .. ".|r")
		end
		table.insert(lines, rank.trainers[faction] or "")
		panel.train:SetText(table.concat(lines, "\n"))
		panel.train:Show()
		y = place(panel.train, y, 10)
	elseif max and skill >= max and skill < guide.top then
		panel.train:SetText(RED .. "You're at your cap (" .. max .. "). Visit a trainer.|r")
		panel.train:Show()
		y = place(panel.train, y, 10)
	end

	local steps, at = ns.GuideSteps(guide, skill)
	local s = at and steps[at]
	if not s then
		panel.step:SetText(GREEN .. "Guide done to " .. guide.top .. ".|r")
		y = place(panel.step, y)
		panel.note:SetText(GREY .. "The rest isn't published yet. The weekly check will add it when it is.|r")
		panel.note:Show()
		y = place(panel.note, y)
		finish(list, guide, y)
		return
	end

	panel.step:SetText(string.format("%s%d-%d|r  %s", GREY, s.lo, s.hi, s.recipe))
	y = place(panel.step, y, 2)

	local left = stepLeft(s, skill)
	local crafts = 0
	if s.zones then
		local faction = UnitFactionGroup("player") or "Horde"
		panel.crafts:SetText(GOLD .. "Where:|r " .. (s.zones[faction] or s.zones.Horde or ""))
	else
		crafts = math.max(1, math.ceil((s.crafts or 0) * left))
		panel.crafts:SetText(string.format("About %d more craft%s to %d", crafts, crafts == 1 and "" or "s", s.hi))
	end
	panel.crafts:Show()
	y = place(panel.crafts, y, 6)

	local mats = {}
	for id, n in pairs(s.uses or {}) do table.insert(mats, { id = id, need = math.ceil(n * left) }) end
	table.sort(mats, function(a, b) return ns.MatName(a.id) < ns.MatName(b.id) end)
	local lines = {}
	for _, m in ipairs(mats) do
		local got = have(c, m.id)
		local color = got >= m.need and GREEN or RED
		local where = ""
		if got >= m.need and (c.bags[m.id] or 0) < m.need then where = GREY .. " (bank/mail)|r" end
		table.insert(lines, string.format("|T%s:14|t %s  %s%d / %d|r%s", ns.MatIcon(m.id), ns.MatName(m.id), color, got, m.need, where))
	end
	if #lines > 0 then
		panel.mats:SetText(table.concat(lines, "\n"))
		panel.mats:Show()
		y = place(panel.mats, y, 8)
	end

	local note = s.note
	if type(note) == "table" then note = note[UnitFactionGroup("player") or "Horde"] or note.Horde end
	if note then
		panel.note:SetText(GREY .. note .. "|r")
		panel.note:Show()
		y = place(panel.note, y, 8)
	end

	if s.choice then
		local options = guide.choices[s.choice]
		local current = ns.Option(guide, s.choice)
		-- Cycle to the next option in the list.
		local other = options[1]
		for i, o in ipairs(options) do
			if o == current then other = options[i + 1] or options[1] break end
		end
		panel.route:SetText(GREY .. "Route " .. options.label .. ": " .. current .. "|r")
		panel.route:Show()
		y = place(panel.route, y, 2)
		panel.routeBtn.choice, panel.routeBtn.option = s.choice, other
		panel.routeBtn:SetText("Switch to " .. other)
		panel.routeBtn:Show()
		y = place(panel.routeBtn, y, 8)
	end

	if not s.zones and open == guide then
		local found = findRecipe(s.recipe)
		if found then
			panel.select.recipe = found
			panel.select:Show()
			place(panel.select, y)
			local count = math.min(found.available, crafts)
			panel.make.recipe, panel.make.count = found, count
			panel.make:SetText(count > 0 and ("Make " .. count) or "Missing mats")
			panel.make:SetEnabled(count > 0)
			panel.make:ClearAllPoints()
			panel.make:SetPoint("LEFT", panel.select, "RIGHT", 6, 0)
			panel.make:Show()
			y = y - 28
		else
			panel.route:SetText(RED .. "You don't know " .. s.recipe .. " yet. Learn it from the trainer.|r")
			panel.route:Show()
			y = place(panel.route, y, 8)
		end
	end

	local upcoming = {}
	for i = at + 1, math.min(at + NEXT_STEPS, #steps) do
		local n = steps[i]
		table.insert(upcoming, string.format("%s%d-%d|r  %s%s", GREY, n.lo, n.hi, n.recipe, n.crafts and (" x" .. n.crafts) or ""))
	end
	if #upcoming > 0 then
		panel.next:SetText(GOLD .. "Next|r\n" .. table.concat(upcoming, "\n"))
		panel.next:Show()
		y = place(panel.next, y, 6)
	end

	finish(list, guide, y)
end

function ns.ShowGuide(key)
	if not panel then build() end
	if key then guideKey = key end
	panel:Show()
	ns.RefreshGuide()
end

function ns.ToggleGuide()
	if panel and panel:IsShown() then panel:Hide() else dismissed = nil ns.ShowGuide() end
end

-- Open on login for crafter alts that still have guide left to do.
ns.On("PLAYER_LOGIN", function()
	C_Timer.After(3, function()
		if not ns.db.guideAuto then return end
		-- Crafting guides only: Cooking and First Aid don't pop up on every character.
		local c = ns.Me()
		for _, g in ipairs(ns.GUIDES) do
			local skill = c.profs[g.skillLine]
			if skill and skill < g.top then ns.ShowGuide(g.key) return end
		end
	end)
end)

-- Follow the profession window: show the guide for the profession it has
-- up, docked to its corner; no guide for that profession, no panel.
local hooked = {}
local windowUp, wasShown = false, false -- wasShown: the panel was already up when the window opened

local function hidePanel()
	hiding = true
	panel:Hide()
	hiding = false
end

local function follow()
	local frame = profWindow()
	if not frame then
		if windowUp and panel then
			undock()
			if wasShown and not dismissed then
				panel:Show()
				ns.RefreshGuide()
			else
				hidePanel()
			end
		end
		windowUp, dismissed = false, nil
		return
	end
	if not windowUp then
		windowUp, wasShown = true, (panel and panel:IsShown()) or false
	end
	if not hooked[frame] then
		hooked[frame] = true
		frame:HookScript("OnHide", function() C_Timer.After(0, follow) end)
	end
	local guide, isOpen = openGuide()
	if guide then
		-- Closed with the X: it stays closed until you change profession.
		if dismissed ~= guide.key then
			dismissed = nil
			ns.ShowGuide(guide.key)
		end
	elseif isOpen and panel and panel:IsShown() then
		hidePanel()
	end
end

local function followSoon() C_Timer.After(0.1, follow) end

ns.On("TRADE_SKILL_SHOW", followSoon)
ns.On("TRADE_SKILL_CLOSE", followSoon)
-- Switching profession tabs, and skill-ups, come through these (not every
-- client has all of them).
for _, event in ipairs({ "TRADE_SKILL_UPDATE", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED",
	"TRADE_SKILL_DATA_SOURCE_CHANGING" }) do
	pcall(ns.On, event, followSoon)
end
