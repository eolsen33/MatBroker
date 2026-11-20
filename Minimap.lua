local _, ns = ...

-- Minimap button: left-click opens the window, right-click opens a menu
-- (start/stop farming, tracker box, leveling guide).
-- Drag it around the minimap edge; /mb minimap hides or shows it.

local GREY = "|cff9d9d9d"
local button

local function place()
	local angle = math.rad(ns.db.minimapAngle or 200)
	local radius = Minimap:GetWidth() / 2 + 10
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function followCursor()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	ns.db.minimapAngle = math.deg(math.atan2(py / scale - my, px / scale - mx))
	place()
end

-- Right-click menu. Built by hand so it doesn't depend on which dropdown
-- API this client has.
local menu
local ROW = 18

local function menuItems()
	return {
		{ ns.FarmActive() and "|cffff6060Stop farming|r" or "|cff40ff40Start farming|r", ns.FarmToggle },
		{ "Farming tab", function() ns.ShowTab("farm") end },
		{ ns.db.farmBoxHidden and "Show farming tracker box" or "Hide farming tracker box", ns.FarmBoxToggle },
		{ ns.db.fishBoxHidden and "Show fishing tracker box" or "Hide fishing tracker box", function() ns.FishCommand("box") end },
		{ "Leveling guide", ns.ToggleGuide },
		{ "MatBroker window", ns.ToggleWindow },
	}
end

local function showMenu()
	if not menu then
		menu = CreateFrame("Frame", "MatBrokerMinimapMenu", UIParent)
		menu:SetFrameStrata("DIALOG")
		menu:SetClampedToScreen(true)
		menu:EnableMouse(true)
		local bg = menu:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)
		menu.rows = {}
		tinsert(UISpecialFrames, "MatBrokerMinimapMenu") -- Esc closes it
		-- Close a moment after the mouse leaves both the menu and the button.
		menu:SetScript("OnUpdate", function(self, dt)
			if self:IsMouseOver() or button:IsMouseOver() then
				self.away = 0
			else
				self.away = (self.away or 0) + dt
				if self.away > 1.5 then self:Hide() end
			end
		end)
	end
	local items = menuItems()
	for i, item in ipairs(items) do
		local row = menu.rows[i]
		if not row then
			row = CreateFrame("Button", nil, menu)
			row:SetHeight(ROW)
			row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * ROW)
			row:SetPoint("RIGHT", -4, 0)
			local hl = row:CreateTexture(nil, "HIGHLIGHT")
			hl:SetAllPoints()
			hl:SetColorTexture(1, 1, 1, 0.15)
			row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			row.text:SetPoint("LEFT", 6, 0)
			row:SetScript("OnClick", function(self) menu:Hide(); self.run() end)
			menu.rows[i] = row
		end
		row.text:SetText(item[1])
		row.run = item[2]
		row:Show()
	end
	for i = #items + 1, #menu.rows do menu.rows[i]:Hide() end
	menu:SetSize(190, #items * ROW + 8)
	menu:ClearAllPoints()
	menu:SetPoint("TOPRIGHT", button, "BOTTOMLEFT", 6, 6)
	menu.away = 0
	menu:Show()
	GameTooltip:Hide()
end

local function build()
	button = CreateFrame("Button", "MatBrokerMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetSize(20, 20)
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetPoint("TOPLEFT", 7, -5)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetSize(17, 17)
	icon:SetTexture("Interface\\Icons\\INV_Enchant_DustStrange")
	icon:SetPoint("TOPLEFT", 7, -6)
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetSize(53, 53)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT")

	button:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then
			if menu and menu:IsShown() then menu:Hide() else showMenu() end
		else
			ns.ToggleWindow()
		end
	end)
	button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", followCursor) end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("MatBroker")
		GameTooltip:AddLine(GREY .. "Left-click:|r mat prices, deals, alt mats, farming", 1, 1, 1)
		GameTooltip:AddLine(GREY .. "Right-click:|r start or stop farming, tracker box, leveling guide", 1, 1, 1)
		GameTooltip:AddLine(GREY .. "Drag:|r move this button", 1, 1, 1)
		local farming = ns.FarmActive()
		if farming then GameTooltip:AddLine("|cff40ff40Farming:|r " .. ns.FarmLine(farming), 1, 1, 1) end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	place()
end

function ns.ToggleMinimapButton()
	ns.db.minimapHidden = not ns.db.minimapHidden
	if not button then build() end
	button:SetShown(not ns.db.minimapHidden)
	ns.Print("minimap button", ns.db.minimapHidden and "hidden. /mb minimap brings it back." or "shown")
end

ns.On("PLAYER_LOGIN", function()
	build()
	button:SetShown(not ns.db.minimapHidden)
end)
