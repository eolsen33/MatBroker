local _, ns = ...

local GREY, GREEN, RED, PURPLE, YELLOW = "|cff9d9d9d", "|cff40ff40", "|cffff5555", "|cff9d7cff", "|cffffff60"

-- Herbs and skins: which alt they go to.
local function addRouteLines(tooltip, id)
	local r = ns.Route(id)
	if not r then return end
	local surplus = r.surplusTo and ("send to " .. ns.MailName(r.surplusTo)) or "sell on the AH"
	if r.extra then
		tooltip:AddDoubleLine(PURPLE .. "MatBroker|r", YELLOW .. "Not in a guide: " .. surplus .. "|r")
	elseif not r.crafter then
		tooltip:AddDoubleLine(PURPLE .. "MatBroker|r", GREY .. "Log in your " .. r.guide.name .. " alt once|r")
	elseif r.need > 0 then
		local _, myName = ns.Me()
		local who = r.crafter == myName and "Keep" or ("Send to " .. ns.MailName(r.crafter))
		tooltip:AddDoubleLine(PURPLE .. "MatBroker|r " .. GREEN .. who .. "|r",
			GREEN .. string.format("%d more for %s %d", r.need, r.guide.name, r.skill) .. "|r")
	else
		tooltip:AddDoubleLine(PURPLE .. "MatBroker|r " .. YELLOW .. "Surplus|r",
			YELLOW .. surplus .. "|r" .. GREY .. " (" .. r.crafter .. " has enough)|r")
	end
	local to = r.crafter or r.surplusTo
	local mailed = ns.Mailed(to, id)
	if mailed > 0 then
		tooltip:AddDoubleLine(GREY .. "Mailed to " .. to .. " so far|r", GREY .. mailed .. "|r")
	end
end

local function addMatLines(tooltip, id)
	local price, source, t = ns.Price(id)
	tooltip:AddDoubleLine(PURPLE .. "MatBroker|r", price and (ns.Money(price) .. GREY .. " (" .. source .. (t and (", " .. ns.Age(t)) or "") .. ")|r") or (GREY .. "no price yet|r"))
end

local function addItemLines(tooltip, link)
	local info, bracket, value, maxBuy, rows, missing = ns.EvaluateItem(link)
	if not bracket then return end

	tooltip:AddLine(" ")
	tooltip:AddLine(PURPLE .. "Disenchants into:|r")
	for _, r in ipairs(rows) do
		local qty = r.lo == r.hi and tostring(r.lo) or (r.lo .. "-" .. r.hi)
		local left = string.format("  %s%g%%|r %s x%s", GREY, r.chance * 100, ns.MatName(r.id), qty)
		tooltip:AddDoubleLine(left, r.price and ns.Money(r.price) or (GREY .. "no price|r"), 1, 1, 1, 1, 1, 1)
	end

	if value then
		tooltip:AddDoubleLine("DE value (after AH cut)", ns.Money(value), 1, 1, 1, 1, 1, 1)
		tooltip:AddDoubleLine(GREEN .. string.format("Buy for up to (%g%% profit)", ns.db.margin * 100) .. "|r", ns.Money(maxBuy), 1, 1, 1, 1, 1, 1)
		if info.sellPrice > value then
			tooltip:AddLine(GREY .. "Vendor price " .. ns.Money(info.sellPrice) .. GREY .. " beats disenchanting.|r")
		end
	else
		tooltip:AddLine(GREY .. "Missing prices for " .. #missing .. " mat(s). Scan the AH with /mb scan.|r")
	end

	local need, have = ns.SkillFor(info.ilvl), ns.EnchantingSkill()
	if have and need and have < need then
		tooltip:AddLine(RED .. string.format("Needs Enchanting %d to disenchant (you have %d).", need, have) .. "|r")
	end
end

local function onItem(tooltip, data)
	if not ns.db or not ns.db.tooltip then return end
	if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
	local link
	if tooltip.GetItem then link = select(2, tooltip:GetItem()) end
	if not link and data and data.id then link = data.id end
	if not link then return end

	local id = tonumber(tostring(link):match("item:(%d+)")) or tonumber(link)
	if id and ns.TRACKED[id] then addRouteLines(tooltip, id) end
	if id and ns.IS_MAT[id] then
		addMatLines(tooltip, id)
	else
		addItemLines(tooltip, link)
	end
end

if TooltipDataProcessor and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItem)
else
	GameTooltip:HookScript("OnTooltipSetItem", function(tt) onItem(tt) end)
	ItemRefTooltip:HookScript("OnTooltipSetItem", function(tt) onItem(tt) end)
end
