local _, ns = ...

-- Minimap button: left-click opens the window, right-click the leveling guide.
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
		if mouse == "RightButton" then ns.ToggleGuide() else ns.ToggleWindow() end
	end)
	button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", followCursor) end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("MatBroker")
		GameTooltip:AddLine(GREY .. "Left-click:|r mat prices, deals, alt mats", 1, 1, 1)
		GameTooltip:AddLine(GREY .. "Right-click:|r leveling guide", 1, 1, 1)
		GameTooltip:AddLine(GREY .. "Drag:|r move this button", 1, 1, 1)
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
