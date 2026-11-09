-- Pint's Book Hunt: a book icon on the world map (zones and continents) for every book this character still needs.
-- A plain click on an icon goes straight to the map (zoom in / out): icons only take clicks while Ctrl is held, and
-- Ctrl-click points the way to that book. (Moving the map from add-on code would "taint" it and get the game's own
-- quest icons blocked in a fight.)
local ADDON, NS = ...
local B = _G.PintsBookHunt
local BOOKS = NS.BOOKS
local ICON = "Interface\\Icons\\INV_Misc_Book_09"

PintsBookHuntPinMixin = CreateFromMixins and MapCanvasPinMixin and CreateFromMixins(MapCanvasPinMixin) or {}
-- (add-on pins may not pass mouse buttons through in a fight on the modern client: say yes and do nothing)
function PintsBookHuntPinMixin:SetPassThroughButtons() end
function PintsBookHuntPinMixin:SetPropagateMouseClicks() end
function PintsBookHuntPinMixin:OnLoad()
	if self.UseFrameLevelType then pcall(self.UseFrameLevelType, self, "PIN_FRAME_LEVEL_AREA_POI") end
	if self.SetScalingLimits then pcall(self.SetScalingLimits, self, 1, 0.9, 1.2) end
end
function PintsBookHuntPinMixin:OnAcquired(b, x, y, small)
	self.b = b
	self:SetPosition(x, y)
	local s = small and 14 or 18
	self:SetSize(s, s)
	if not self.icon then
		self.edge = self:CreateTexture(nil, "BACKGROUND"); self.edge:SetPoint("TOPLEFT", -1, 1); self.edge:SetPoint("BOTTOMRIGHT", 1, -1)
		self.edge:SetColorTexture(0.83, 0.63, 0.1, 1)
		self.icon = self:CreateTexture(nil, "ARTWORK"); self.icon:SetAllPoints(); self.icon:SetTexture(ICON); self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
	self:SetScript("OnEnter", self.OnMouseEnter); self:SetScript("OnLeave", self.OnMouseLeave)
	self:SetScript("OnMouseUp", function(pin, button) pin:OnClick(button) end)
	if self.SetMouseClickEnabled then self:SetMouseMotionEnabled(true); self:SetMouseClickEnabled(IsControlKeyDown() and true or false) end
end
function PintsBookHuntPinMixin:OnMouseEnter()
	local b = self.b
	if not b then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(b[2], 1, 0.82, 0)
	GameTooltip:AddLine(("%s  %.1f, %.1f"):format(b[3], b[5], b[6]), 1, 1, 1)
	GameTooltip:AddLine(b[7], 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Ctrl-click: point the way", 0.5, 0.5, 0.5)
	GameTooltip:Show()
end
function PintsBookHuntPinMixin:OnMouseLeave() GameTooltip:Hide() end
function PintsBookHuntPinMixin:OnClick(button)
	if IsControlKeyDown() then
		if self.b then B.Waypoint(self.b[4], self.b[5], self.b[6], self.b[2], self.b[3]) end
		return
	end
end

local rects = {}
local function RectOn(zone, top)
	local key = zone .. ">" .. top
	if rects[key] == nil then
		rects[key] = false
		if C_Map and C_Map.GetMapRectOnMap then
			local ok, a, b, c, d = pcall(C_Map.GetMapRectOnMap, zone, top)
			if ok and a and b and c and d and b > a and d > c then rects[key] = { a, b, c, d } end
		end
	end
	return rects[key] or nil
end

local Provider
function B.MakeMapPins()
	if Provider or not (MapCanvasDataProviderMixin and WorldMapFrame and WorldMapFrame.AddDataProvider) then return end
	Provider = CreateFromMixins(MapCanvasDataProviderMixin)
	function Provider:RemoveAllData() self:GetMap():RemoveAllPinsByTemplate("PintsBookHuntPinTemplate") end
	function Provider:RefreshAllData()
		self:RemoveAllData()
		local db, ch = PintsBookHuntDB, PintsBookHuntChar
		if not (db and ch and ch.got) or db.mapPins == false then return end
		local map = self:GetMap()
		local mapID = map:GetMapID()
		local info = mapID and C_Map.GetMapInfo(mapID)
		if not info then return end
		for _, b in ipairs(BOOKS) do
			if not ch.got[b[1]] then
				if b[4] == mapID then
					map:AcquirePin("PintsBookHuntPinTemplate", b, b[5] / 100, b[6] / 100)
				else
					-- the zone it's in, shown on this bigger map (continent, world) or a city on its zone
					local r = RectOn(b[4], mapID)
					if r then
						local x, y = r[1] + (r[2] - r[1]) * b[5] / 100, r[3] + (r[4] - r[3]) * b[6] / 100
						if x >= 0 and x <= 1 and y >= 0 and y <= 1 then map:AcquirePin("PintsBookHuntPinTemplate", b, x, y, (info.mapType or 3) <= 2) end
					end
				end
			end
		end
	end
	WorldMapFrame:AddDataProvider(Provider)
end
function B.RefreshMap() if Provider and WorldMapFrame and WorldMapFrame:IsShown() then Provider:RefreshAllData() end end
-- pressing or letting go of Ctrl: the book icons start or stop taking clicks
local cf = CreateFrame("Frame")
cf:RegisterEvent("MODIFIER_STATE_CHANGED")
cf:SetScript("OnEvent", function(_, _, key)
	if key ~= "LCTRL" and key ~= "RCTRL" then return end
	if not (WorldMapFrame and WorldMapFrame:IsShown() and WorldMapFrame.EnumeratePinsByTemplate) then return end
	local on = IsControlKeyDown() and true or false
	for pin in WorldMapFrame:EnumeratePinsByTemplate("PintsBookHuntPinTemplate") do
		if pin.SetMouseClickEnabled then pin:SetMouseClickEnabled(on) end
	end
end)
