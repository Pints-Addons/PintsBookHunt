-- Pint's Book Hunt: a checklist of the 40 books for "Friend of the Library" (WoW Forever), where each one is, an arrow
-- or map pin to it, and what the 10- and 20-book rewards are. Books count per character.
-- A book is ticked by itself when you read it, loot it or have it in your bags; you can also tick it by hand.
local ADDON, NS = ...
local B = {}
_G.PintsBookHunt = B

local BOOKS, TIERS, TURNIN = NS.BOOKS, NS.TIERS, NS.TURNIN
local char, acct                      -- PintsBookHuntChar (this character), PintsBookHuntDB (all characters)
local GOLD = "|cffd4a017"
local function Say(m) print(GOLD .. "Pint's Book Hunt:|r " .. m) end
local function Secret(v) return type(issecretvalue) == "function" and issecretvalue(v) end

-- book name -> entry (lower case, so "Ka-Boom!" and "ka-boom!" both match)
local byName = {}
for _, b in ipairs(BOOKS) do byName[b[2]:lower()] = b end
local function Find(name)
	if type(name) ~= "string" or Secret(name) then return end
	return byName[name:lower()] or byName[(name:gsub("^%s+", ""):gsub("%s+$", "")):lower()]
end

---------------------------------------------------------------- what this character has
local function Count()
	local n = 0
	for _, b in ipairs(BOOKS) do if char and char.got[b[1]] then n = n + 1 end end
	return n
end
local function Faction() return UnitFactionGroup("player") == "Alliance" and "Alliance" or "Horde" end
local function CharKey() return (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?") end
local function SaveSummary()
	if not (acct and char) then return end
	local _, cls = UnitClass("player")
	acct.chars[CharKey()] = { count = Count(), class = cls, faction = Faction(), turned = { char.turned[1] and true or nil, char.turned[2] and true or nil } }
end

local Refresh                           -- (the window)
local function Mark(b, how)
	if not char or char.got[b[1]] then return end
	char.got[b[1]] = time()
	SaveSummary()
	local n = Count()
	Say(("|cffffffff%s|r collected (%s) - %d of %d."):format(b[2], how or "found", n, #BOOKS))
	for _, t in ipairs(TIERS) do
		if n == t.need then
			local ti = TURNIN[Faction()]
			Say(("%d books: hand them to |cffffffff%s|r (%s) for |cffffffff%s|r."):format(t.need, ti.npc, ti.where, t.title))
		end
	end
	if Refresh then Refresh() end
	if B.RefreshMap then B.RefreshMap() end
end
B.Mark = Mark

---------------------------------------------------------------- noticing a book
-- reading it (books in the world open the reading window with their title)
local function OnItemText()
	local title = ItemTextGetItem and ItemTextGetItem()
	local b = Find(title)
	if b then Mark(b, "read") end
end
-- looting it: "You receive loot: [Ka-Boom!]."
local selfPrefixes = {}
for _, g in ipairs({ "LOOT_ITEM_SELF", "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF" }) do
	local f = _G[g]
	if type(f) == "string" then local p = f:match("^(.-)%%") ; if p and p ~= "" then selfPrefixes[#selfPrefixes + 1] = p end end
end
local function OnLoot(msg)
	if type(msg) ~= "string" or Secret(msg) then return end
	local mine = false
	for _, p in ipairs(selfPrefixes) do if msg:sub(1, #p) == p then mine = true; break end end
	if not mine then return end
	for name in msg:gmatch("%[(.-)%]") do local b = Find(name); if b then Mark(b, "looted") end end
end
-- in your bags
local function ScanBags()
	if not char then return end
	local num = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
	local link = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
	if not (num and link) then return end
	for bag = 0, NUM_BAG_SLOTS or 4 do
		for slot = 1, num(bag) or 0 do
			local l = link(bag, slot)
			if type(l) == "string" and not Secret(l) then
				local b = Find(l:match("%[(.-)%]"))
				if b then Mark(b, "in your bags") end
			end
		end
	end
end
-- handing them in: the quest's title as the reward window opens, then whether it was handed in
local pendingTitle
local function OnQuestComplete() local t = GetTitleText and GetTitleText(); pendingTitle = (type(t) == "string" and not Secret(t)) and t or nil end
local function OnTurnedIn()
	if not (char and pendingTitle) then return end
	for i, t in ipairs(TIERS) do
		if pendingTitle == t.title then
			char.turned[i] = time(); SaveSummary(); Say(("|cffffffff%s|r handed in."):format(t.title))
		end
	end
	pendingTitle = nil
	if Refresh then Refresh() end
end

---------------------------------------------------------------- pointing the way
local function OpenMap(mapID)
	if InCombatLockdown() or not WorldMapFrame then return end
	if not WorldMapFrame:IsShown() then ToggleWorldMap() end
	if WorldMapFrame.SetMapID then WorldMapFrame:SetMapID(mapID) end
end
-- Pint's Quest Book's arrow if you have it, else TomTom, else the game's own map pin, else the map opened there
function B.Waypoint(mapID, x, y, title, sub)
	local where = ("%s %.1f, %.1f"):format(sub or "", x, y)
	local QB = _G.PintsQuestBook
	if QB and QB.MapToWorld and QB.ArrowTo then
		local cont, wx, wy = QB.MapToWorld(mapID, x, y)
		if cont then QB.ArrowTo(cont, wx, wy, title, where); return end
	end
	if TomTom and TomTom.AddWaypoint then
		TomTom:AddWaypoint(mapID, x / 100, y / 100, { title = title, persistent = false, minimap = true, world = true })
		Say(("arrow set: %s (%s)."):format(title, where)); return
	end
	if C_Map and C_Map.SetUserWaypoint and UiMapPoint and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(mapID)) then
		local ok = pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100))
		if ok then
			if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true) end
			Say(("map pin set: %s (%s)."):format(title, where)); return
		end
	end
	OpenMap(mapID)
	Say(("%s is at %s."):format(title, where))
end
local function WayTo(b) B.Waypoint(b[4], b[5], b[6], b[2], b[3]) end

---------------------------------------------------------------- copying a link (the game can't open web pages)
StaticPopupDialogs["PINTSBOOKHUNT_LINK"] = {
	text = "%s\n\nPress Ctrl-C to copy the link:",
	button1 = OKAY or "OK",
	hasEditBox = true, editBoxWidth = 320,
	OnShow = function(self, data)
		local eb = self.editBox or self.EditBox
		if eb then eb:SetText(data or ""); eb:HighlightText(); eb:SetFocus() end
	end,
	EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	EditBoxOnTextChanged = function(self, data) if self:GetText() ~= data then self:SetText(data or ""); self:HighlightText() end end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
local function CopyLink(title, url) StaticPopup_Show("PINTSBOOKHUNT_LINK", title, nil, url) end

---------------------------------------------------------------- reward items: a real tooltip once the game knows them
local function ItemTip(owner, name)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	local _, link = GetItemInfo(name)
	if link then GameTooltip:SetHyperlink(link)
	else GameTooltip:AddLine(name, 0, 0.44, 0.87); GameTooltip:AddLine("(the full tooltip shows once you've seen the item)", 0.6, 0.6, 0.6, true) end
	GameTooltip:Show()
end

---------------------------------------------------------------- the window
local W, ROW_H = 800, 22
local COL = { chk = 4, num = 28, name = 56, zone = 350, xy = 476, note = 544, way = 656, video = 702 }
local win, rows, list = nil, {}, {}

local function Button(parent, text, w, h)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w, h or 20); b:SetText(text)
	local fs = b:GetFontString(); if fs then fs:SetFontObject("GameFontNormalSmall") end
	return b
end
local function NoteColor(note)
	local n = note:lower()
	if n:find("hard") then return "|cffff6040" end
	if n:find("group") then return "|cffffa040" end
	if n:find("depends") then return "|cffd0d060" end
	if n:find("no video") then return "|cff909090" end
	return "|cff80d080"
end

local function Row(i)
	local r = rows[i]
	if r then return r end
	r = CreateFrame("Button", nil, list.child)
	r:SetSize(W - 52, ROW_H)
	r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
	r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints(); r.bg:SetColorTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0)
	local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0, 0.08)
	r.chk = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate"); r.chk:SetSize(22, 22); r.chk:SetPoint("LEFT", COL.chk, 0)
	r.chk:SetScript("OnClick", function(self)
		local b = r.b
		if self:GetChecked() then char.got[b[1]] = time() else char.got[b[1]] = nil end
		SaveSummary(); Refresh(); if B.RefreshMap then B.RefreshMap() end
	end)
	local function FS(x, w, just)
		local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetPoint("LEFT", x, 0); fs:SetWidth(w); fs:SetJustifyH(just or "LEFT"); fs:SetWordWrap(false)
		return fs
	end
	r.num = FS(COL.num, 22, "RIGHT"); r.name = FS(COL.name, 288); r.zone = FS(COL.zone, 122); r.xy = FS(COL.xy, 64)
	r.note = FS(COL.note, 108)
	r.way = Button(r, "Way", 42, 18); r.way:SetPoint("LEFT", COL.way, 0)
	r.way:SetScript("OnClick", function() WayTo(r.b) end)
	r.video = Button(r, "Video", 46, 18); r.video:SetPoint("LEFT", COL.video, 0)
	r.video:SetScript("OnClick", function() CopyLink(r.b[2], r.b[8]) end)
	r:SetScript("OnEnter", function(self)
		local b = self.b
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(b[2], 1, 0.82, 0)
		GameTooltip:AddLine(("%s  %.1f, %.1f"):format(b[3], b[5], b[6]), 1, 1, 1)
		GameTooltip:AddLine(b[7], 0.8, 0.8, 0.8)
		if char.got[b[1]] then GameTooltip:AddLine("Collected " .. date("%d %b %Y", char.got[b[1]]), 0.4, 1, 0.4) end
		GameTooltip:AddLine("Click: point the way   (Way does the same; Video copies a link to a guide)", 0.5, 0.5, 0.5, true)
		GameTooltip:Show()
	end)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	r:SetScript("OnClick", function(self) WayTo(self.b) end)
	rows[i] = r
	return r
end

local function Sorted()
	local out = {}
	local f = char.filter or "all"
	for _, b in ipairs(BOOKS) do
		if not (char.hideDone and char.got[b[1]]) and (f == "all" or b[9] == f) then out[#out + 1] = b end
	end
	if char.sort == "zone" then
		table.sort(out, function(a, c) if a[3] ~= c[3] then return a[3] < c[3] end return a[1] < c[1] end)
	end
	return out
end

local function TierText(i)
	local t, n = TIERS[i], Count()
	if char.turned[i] then return ("|cff40ff40Done|r - handed in %s"):format(date("%d %b", char.turned[i])) end
	if n >= t.need then return "|cffffd100Ready - hand in your books|r" end
	return ("|cffb0b0b0%d more to go|r"):format(t.need - n)
end

function Refresh()
	if not (win and win:IsShown() and char) then return end
	local n = Count()
	win.progress:SetMinMaxValues(0, #BOOKS); win.progress:SetValue(n)
	win.count:SetText(("%d / %d books collected"):format(n, #BOOKS))
	local shown = Sorted()
	for i, b in ipairs(shown) do
		local r = Row(i)
		r.b = b
		local got = char.got[b[1]] and true or false
		r.chk:SetChecked(got)
		local dim = got and "|cff707070" or ""
		r.num:SetText(dim .. b[1]); r.name:SetText((got and "|cff707070" or "|cffffffff") .. b[2])
		r.zone:SetText(dim .. b[3]); r.xy:SetText(("%s%.1f, %.1f"):format(dim, b[5], b[6]))
		r.note:SetText((got and "|cff707070" or NoteColor(b[7])) .. b[7])
		r:Show()
	end
	for i = #shown + 1, #rows do rows[i]:Hide() end
	list.child:SetHeight(math.max(1, #shown * ROW_H))
	win.empty:SetShown(#shown == 0)
	-- rewards
	for i, blk in ipairs(win.tiers) do blk.status:SetText(TierText(i)) end
	local ti = TURNIN[Faction()]
	win.turnin:SetText(("Hand in to |cffffffff%s|r, %s."):format(ti.npc, ti.where))
	-- your other characters
	local others = {}
	for key, c in pairs(acct.chars) do
		if key ~= CharKey() then
			local cc = c.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[c.class]
			local hex = cc and ("|cff%02x%02x%02x"):format(cc.r * 255, cc.g * 255, cc.b * 255) or "|cffffffff"
			others[#others + 1] = hex .. key:match("^(.-) %- ") .. "|r " .. (c.count or 0)
		end
	end
	table.sort(others)
	win.alts:SetText(#others > 0 and ("Your other characters: " .. table.concat(others, ",  ")) or "")
	-- buttons that show a choice
	win.sortB:SetText(char.sort == "zone" and "Sort: zone" or "Sort: number")
	local f = char.filter or "all"
	win.filterB:SetText(f == "all" and "Both continents" or f)
	win.hide:SetChecked(char.hideDone and true or false)
	win.pins:SetChecked(acct.mapPins ~= false)
end
B.Refresh = function() if Refresh then Refresh() end end

local function Build()
	win = CreateFrame("Frame", "PintsBookHuntFrame", UIParent, "BackdropTemplate")
	win:SetSize(W, 600); win:SetPoint("CENTER")
	win:SetFrameStrata("HIGH"); win:SetClampedToScreen(true); win:SetMovable(true); win:EnableMouse(true)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", win.StartMoving)
	win:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local p, _, rp, x, y = self:GetPoint(); acct.pos = { p, rp, x, y }
	end)
	if acct.pos then win:ClearAllPoints(); win:SetPoint(acct.pos[1], UIParent, acct.pos[2], acct.pos[3], acct.pos[4]) end
	win:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 26, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
	tinsert(UISpecialFrames, "PintsBookHuntFrame")
	win:SetScript("OnShow", function() Refresh() end)

	local close = CreateFrame("Button", nil, win, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -4, -4)
	local icon = win:CreateTexture(nil, "ARTWORK"); icon:SetSize(30, 30); icon:SetPoint("TOPLEFT", 16, -14)
	icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
	title:SetText("Pint's Book Hunt")
	local sub = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	sub:SetText("Friend of the Library - books count for each character on their own")

	win.progress = CreateFrame("StatusBar", nil, win); win.progress:SetSize(220, 14); win.progress:SetPoint("TOPRIGHT", -44, -20)
	win.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); win.progress:SetStatusBarColor(0.83, 0.63, 0.1)
	local pbg = win.progress:CreateTexture(nil, "BACKGROUND"); pbg:SetAllPoints(); pbg:SetColorTexture(0, 0, 0, 0.6)
	-- marks at 10 and 20
	for _, t in ipairs(TIERS) do
		local m = win.progress:CreateTexture(nil, "OVERLAY"); m:SetColorTexture(1, 1, 1, 0.8); m:SetSize(2, 14)
		m:SetPoint("LEFT", 220 * t.need / #BOOKS - 1, 0)
	end
	win.count = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); win.count:SetPoint("TOP", win.progress, "BOTTOM", 0, -3)

	-- controls
	local y = -62
	win.hide = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate"); win.hide:SetSize(22, 22); win.hide:SetPoint("TOPLEFT", 16, y)
	local hl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); hl:SetPoint("LEFT", win.hide, "RIGHT", 2, 0); hl:SetText("Hide collected")
	win.hide:SetScript("OnClick", function(self) char.hideDone = self:GetChecked() and true or nil; Refresh() end)
	win.pins = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate"); win.pins:SetSize(22, 22); win.pins:SetPoint("TOPLEFT", 140, y)
	local pl = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); pl:SetPoint("LEFT", win.pins, "RIGHT", 2, 0); pl:SetText("Books on the map")
	win.pins:SetScript("OnClick", function(self) acct.mapPins = self:GetChecked() and true or false; if B.RefreshMap then B.RefreshMap() end end)
	win.filterB = Button(win, "Both continents", 130); win.filterB:SetPoint("TOPLEFT", 280, y - 1)
	win.filterB:SetScript("OnClick", function()
		local f = char.filter or "all"
		char.filter = (f == "all" and "Kalimdor") or (f == "Kalimdor" and "Eastern Kingdoms") or "all"
		Refresh()
	end)
	win.sortB = Button(win, "Sort: number", 110); win.sortB:SetPoint("LEFT", win.filterB, "RIGHT", 6, 0)
	win.sortB:SetScript("OnClick", function() char.sort = (char.sort == "zone") and nil or "zone"; Refresh() end)
	local route = Button(win, "All 40: shortest route (video)", 200); route:SetPoint("LEFT", win.sortB, "RIGHT", 6, 0)
	route:SetScript("OnClick", function() CopyLink("All 40 books in one video, by the shortest path", NS.ROUTE_VIDEO) end)

	-- column headings
	local hy = y - 28
	local function Head(x, w, text, just)
		local fs = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); fs:SetPoint("TOPLEFT", 20 + x, hy); fs:SetWidth(w); fs:SetJustifyH(just or "LEFT")
		fs:SetText(text)
	end
	Head(COL.num, 22, "#", "RIGHT"); Head(COL.name, 200, "Book"); Head(COL.zone, 120, "Zone"); Head(COL.xy, 64, "Location")
	Head(COL.note, 108, "Notes")

	-- the list
	list = CreateFrame("ScrollFrame", "PintsBookHuntList", win, "UIPanelScrollFrameTemplate")
	list:SetPoint("TOPLEFT", 20, hy - 16); list:SetPoint("BOTTOMRIGHT", -34, 178)
	list.child = CreateFrame("Frame", nil, list); list.child:SetSize(W - 52, 1)
	list:SetScrollChild(list.child)
	win.empty = win:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge"); win.empty:SetPoint("CENTER", list, "CENTER")
	win.empty:SetText("Nothing to show - every book here is collected.")

	-- rewards
	local line = win:CreateTexture(nil, "ARTWORK"); line:SetColorTexture(0.83, 0.63, 0.1, 0.5); line:SetHeight(1)
	line:SetPoint("BOTTOMLEFT", 20, 168); line:SetPoint("BOTTOMRIGHT", -20, 168)
	local rh = win:CreateFontString(nil, "OVERLAY", "GameFontNormal"); rh:SetPoint("BOTTOMLEFT", 20, 146); rh:SetText("Rewards")
	win.turnin = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); win.turnin:SetPoint("LEFT", rh, "RIGHT", 12, 0)
	local tmap = Button(win, "Map", 50, 18); tmap:SetPoint("LEFT", win.turnin, "RIGHT", 8, 0)
	tmap:SetScript("OnClick", function() OpenMap(TURNIN[Faction()].map) end)
	tmap:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:AddLine("Open the map of the city where you hand in")
		local o = TURNIN[Faction() == "Alliance" and "Horde" or "Alliance"]
		GameTooltip:AddLine(("(the other side hands in to %s, %s)"):format(o.npc, o.where), 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
	end)
	tmap:SetScript("OnLeave", function() GameTooltip:Hide() end)
	win.tiers = {}
	for i, t in ipairs(TIERS) do
		local x = 20 + (i - 1) * 380
		local blk = {}
		local h = win:CreateFontString(nil, "OVERLAY", "GameFontNormal"); h:SetPoint("BOTTOMLEFT", x, 122)
		h:SetText(("%d books - |cffffffff%s|r"):format(t.need, t.title))
		blk.status = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); blk.status:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -3)
		local ch = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); ch:SetPoint("TOPLEFT", blk.status, "BOTTOMLEFT", 0, -6)
		ch:SetText("Choose one:")
		local prev = ch
		for _, name in ipairs(t.rewards) do
			local rb = CreateFrame("Button", nil, win); rb:SetSize(300, 18)
			rb:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", prev == ch and 10 or 0, -3)
			local ic = rb:CreateTexture(nil, "ARTWORK"); ic:SetSize(16, 16); ic:SetPoint("LEFT")
			ic:SetTexture((GetItemIcon and GetItemIcon(name)) or "Interface\\Icons\\INV_Misc_QuestionMark")
			local fs = rb:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); fs:SetPoint("LEFT", ic, "RIGHT", 4, 0)
			fs:SetText("|cff0070dd" .. name .. "|r")
			rb:SetScript("OnEnter", function(self) ItemTip(self, name) end)
			rb:SetScript("OnLeave", function() GameTooltip:Hide() end)
			rb.icon = ic; rb.itemName = name
			blk[#blk + 1] = rb
			prev = rb
		end
		win.tiers[i] = blk
	end
	win.alts = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); win.alts:SetPoint("BOTTOMLEFT", 20, 14)
	win.alts:SetPoint("BOTTOMRIGHT", -20, 14); win.alts:SetJustifyH("LEFT")
	win:Hide()
end

function B.Toggle()
	if not char then return end
	if not win then Build() end
	if win:IsShown() then win:Hide() else win:Show() end
	-- reward icons fill in once the game has looked the items up
	for _, blk in ipairs(win.tiers) do
		for _, rb in ipairs(blk) do local ic = GetItemIcon and GetItemIcon(rb.itemName); if ic then rb.icon:SetTexture(ic) end end
	end
end

---------------------------------------------------------------- start up
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "ITEM_TEXT_BEGIN", "CHAT_MSG_LOOT", "BAG_UPDATE_DELAYED", "QUEST_COMPLETE", "QUEST_TURNED_IN" }) do
	pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, a1)
	if e == "PLAYER_LOGIN" then
		PintsBookHuntDB = PintsBookHuntDB or {}
		acct = PintsBookHuntDB
		acct.chars = acct.chars or {}
		PintsBookHuntChar = PintsBookHuntChar or {}
		char = PintsBookHuntChar
		char.got = char.got or {}
		char.turned = char.turned or {}
		SaveSummary()
		C_Timer.After(5, ScanBags)
		if B.MakeMapPins then B.MakeMapPins() end
		return
	end
	if not char then return end
	if e == "ITEM_TEXT_BEGIN" then C_Timer.After(0.1, OnItemText)
	elseif e == "CHAT_MSG_LOOT" then OnLoot(a1)
	elseif e == "BAG_UPDATE_DELAYED" then ScanBags()
	elseif e == "QUEST_COMPLETE" then OnQuestComplete()
	elseif e == "QUEST_TURNED_IN" then OnTurnedIn() end
end)

SLASH_PINTSBOOKHUNT1, SLASH_PINTSBOOKHUNT2, SLASH_PINTSBOOKHUNT3 = "/books", "/bookhunt", "/pbh"
SlashCmdList.PINTSBOOKHUNT = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "next" then
		-- a book you still need: in the zone you're in if there is one, else on this continent, else anywhere
		local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
		local info = here and C_Map.GetMapInfo(here)
		local cont
		while info and info.mapType and info.mapType > 2 and info.parentMapID do info = C_Map.GetMapInfo(info.parentMapID) end
		if info then cont = (info.mapID == 1414 and "Kalimdor") or (info.mapID == 1415 and "Eastern Kingdoms") or nil end
		local pick
		for _, b in ipairs(BOOKS) do if not char.got[b[1]] and b[4] == here then pick = b; break end end
		if not pick then for _, b in ipairs(BOOKS) do if not char.got[b[1]] and b[9] == cont then pick = b; break end end end
		if not pick then for _, b in ipairs(BOOKS) do if not char.got[b[1]] then pick = b; break end end end
		if pick then WayTo(pick) else Say("you have every book!") end
	elseif msg == "reset" then
		StaticPopupDialogs.PINTSBOOKHUNT_RESET = StaticPopupDialogs.PINTSBOOKHUNT_RESET or {
			text = "Untick every book for this character?", button1 = YES or "Yes", button2 = NO or "No",
			OnAccept = function() wipe(char.got); wipe(char.turned); SaveSummary(); B.Refresh(); if B.RefreshMap then B.RefreshMap() end end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		StaticPopup_Show("PINTSBOOKHUNT_RESET")
	elseif msg == "help" then
		Say("/books - the checklist.  /books next - point the way to a book you still need.  /books reset - untick them all (this character).")
	else B.Toggle() end
end
