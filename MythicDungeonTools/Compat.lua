-- API compatibility shims for WoW 7.3.5 (Legion)
local _, MDT = ...

if not Mixin then
	function Mixin(object, mixin)
		for key, value in pairs(mixin) do
			object[key] = value
		end
	end
end

if not BackdropTemplateMixin then
	BackdropTemplateMixin = {}
end

function BackdropTemplateMixin:SetBackdrop(backdrop)
	if self.SetBackdrop then
		self:SetBackdrop(backdrop)
	end
end

function BackdropTemplateMixin:SetBackdropColor(r, g, b, a)
	if self.SetBackdropColor then
		self:SetBackdropColor(r, g, b, a)
	end
end

function BackdropTemplateMixin:SetBackdropBorderColor(r, g, b, a)
	if self.SetBackdropBorderColor then
		self:SetBackdropBorderColor(r, g, b, a)
	end
end

function BackdropTemplateMixin:ClearBackdrop()
	if self.SetBackdrop then
		self:SetBackdrop(nil)
	end
end

function MDT.CreateProgressBar(parent)
	local progressBar = CreateFrame("Frame", nil, parent)
	progressBar:SetSize(200, 20)
	progressBar.Bar = CreateFrame("StatusBar", nil, progressBar)
	progressBar.Bar:SetAllPoints(progressBar)
	progressBar.Bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	progressBar.Bar:SetMinMaxValues(0, 100)
	progressBar.Bar.Label = progressBar.Bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	progressBar.Bar.Label:SetPoint("CENTER")
	progressBar.AnimValue = 0
	return progressBar
end

local frameNameCounter = 0
function MDT.CreateFrameWithTemplate(frameType, name, parent, template)
	frameNameCounter = frameNameCounter + 1
	name = name or ("MDTAnonFrame" .. frameNameCounter)
	parent = parent or UIParent
	if not frameType or frameType == "" then
		frameType = "Frame"
	elseif frameType:lower() == "frame" then
		frameType = "Frame"
	end
	if template then
		local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
		if ok and frame then
			return frame
		end
	end
	local ok, frame = pcall(CreateFrame, frameType, name, parent)
	return ok and frame or nil
end

local poiAtlasFallbacks = {
	QuestNormal = "Interface\\Minimap\\Tracking\\QuestBlob",
	QuestObjective = "Interface\\Minimap\\Tracking\\QuestBlob",
	["TaxiNode_Continent_Horde"] = "Interface\\Minimap\\Tracking\\TaxiNode_Neutral",
	["map-icon-SuramarDoor.tga"] = "Interface\\Minimap\\Tracking\\Door",
	Dungeon = "Interface\\Minimap\\Tracking\\Dungeon",
	["bags-innerglow"] = "Interface\\Buttons\\UI-ActionButton-Border",
	["bags-glow-artifact"] = "Interface\\Buttons\\UI-ActionButton-Border",
}

function MDT.SetTextureAtlas(texture, atlas)
	if not texture then
		return
	end
	if texture.SetAtlas then
		local ok = pcall(texture.SetAtlas, texture, atlas)
		if ok then
			return
		end
	end
	local path = poiAtlasFallbacks[atlas]
	if path then
		texture:SetTexture(path)
	elseif type(atlas) == "string" and (atlas:find("\\") or atlas:find("%.")) then
		texture:SetTexture(atlas)
	else
		texture:SetTexture("Interface\\Minimap\\Tracking\\None")
	end
end

local function ensurePinTextureMethods(texture)
	if not texture then
		return
	end
	if not texture.SetAtlas then
		texture.SetAtlas = function(self, atlas)
			MDT.SetTextureAtlas(self, atlas)
		end
	end
	if not texture.SetDesaturated then
		texture.SetDesaturated = function() end
	end
end

function MDT.EnsurePinFrameTextures(frame)
	if not frame then
		return
	end
	if not frame.Texture then
		frame.Texture = frame:CreateTexture(nil, "ARTWORK")
		frame.Texture:SetAllPoints(frame)
		ensurePinTextureMethods(frame.Texture)
	end
	if not frame.HighlightTexture then
		frame.HighlightTexture = frame:CreateTexture(nil, "HIGHLIGHT")
		frame.HighlightTexture:SetAllPoints(frame)
		frame.HighlightTexture:SetBlendMode("ADD")
		frame.HighlightTexture:SetAlpha(0.5)
		ensurePinTextureMethods(frame.HighlightTexture)
	end
end

function MDT.EnsureQuestPinFrame(note)
	if not note then
		return
	end

	if note.NormalTexture and note.HighlightTexture and note.Display and note.Display.Icon and note.PushedTexture then
		return note.NormalTexture, note.HighlightTexture, note.Display.Icon, note.PushedTexture
	end

	if note.Texture and note.Number then
		note.Highlight = note.Highlight or note.HighlightTexture
		return note.Texture, note.Highlight, note.Number, note.PushedTexture
	end

	if not note.NormalTexture then
		note.NormalTexture = note:CreateTexture(nil, "ARTWORK")
		note.NormalTexture:SetAllPoints(note)
	end
	if not note.HighlightTexture then
		note.HighlightTexture = note:CreateTexture(nil, "HIGHLIGHT")
		note.HighlightTexture:SetAllPoints(note)
		note.HighlightTexture:SetBlendMode("ADD")
		note.HighlightTexture:SetAlpha(0.5)
	end
	if not note.PushedTexture then
		note.PushedTexture = note:CreateTexture(nil, "OVERLAY")
		note.PushedTexture:SetAllPoints(note)
		note.PushedTexture:Hide()
	end
	if not note.Display then
		note.Display = {}
	end
	if not note.Display.Icon then
		note.Display.Icon = note:CreateTexture(nil, "OVERLAY")
		note.Display.Icon:SetPoint("CENTER")
		note.Display.Icon:SetSize(16, 16)
	end

	return note.NormalTexture, note.HighlightTexture, note.Display.Icon, note.PushedTexture
end

if not SetPortraitTextureFromCreatureDisplayID then
	function SetPortraitTextureFromCreatureDisplayID(texture, creatureDisplayID)
		if not texture then
			return
		end
		creatureDisplayID = tonumber(creatureDisplayID) or 39490
		if SetPortraitToTexture then
			SetPortraitToTexture(texture, "Interface\\Icons\\INV_Misc_Head_Dragon_01")
		else
			texture:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_01")
		end
	end
end

if not WrapTextInColor then
	function WrapTextInColor(text, color)
		if color and color.GenerateHexColor then
			return WrapTextInColorCode(text, color:GenerateHexColor())
		end
		if color and color.r then
			return WrapTextInColorCode(text, format("FF%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255))
		end
		return text
	end
end

if not MenuUtil then
	MenuUtil = {}

	local contextMenuFrame
	local currentMenuItems
	local submenuRegistry = {}
	local submenuCounter = 0

	local function createMenuDescription()
		local desc = { items = {} }

		function desc:CreateTitle(text)
			table.insert(self.items, { isTitle = true, text = text })
		end

		function desc:CreateDivider()
			table.insert(self.items, { isDivider = true })
		end

		function desc:CreateRadio(text, isSelected, setSelected, data)
			table.insert(self.items, {
				isRadio = true,
				text = text,
				isSelected = isSelected,
				setSelected = setSelected,
				data = data,
			})
		end

		function desc:CreateButton(text, callback)
			local submenu = createMenuDescription()
			table.insert(self.items, {
				text = text,
				func = callback,
				submenu = submenu,
			})
			return submenu
		end

		return desc
	end

	local function addMenuItems(items, level)
		if type(items) ~= "table" then
			return
		end
		for _, item in ipairs(items) do
			local info = UIDropDownMenu_CreateInfo()
			if item.isDivider then
				info.text = ""
				info.isTitle = nil
				info.notCheckable = 1
				info.disabled = 1
			elseif item.isTitle then
				info.text = item.text
				info.isTitle = 1
				info.notCheckable = 1
				info.disabled = 1
			elseif item.isRadio then
				info.text = item.text
				info.checked = item.isSelected and item.isSelected(item.data)
				info.func = function()
					if item.setSelected then
						item.setSelected(item.data)
					end
					CloseDropDownMenus()
				end
				info.notCheckable = nil
				info.keepShownOnClick = 1
			elseif item.submenu and #item.submenu.items > 0 then
				info.text = item.text
				info.hasArrow = 1
				info.notCheckable = 1
				submenuCounter = submenuCounter + 1
				local key = "MDTSubmenu" .. submenuCounter
				submenuRegistry[key] = item.submenu.items
				info.value = key
			else
				info.text = item.text
				info.notCheckable = 1
				info.func = function()
					if item.func then
						item.func()
					end
					CloseDropDownMenus()
				end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end

	local function initializeContextMenu(frame, level)
		local items = currentMenuItems
		if level and level > 1 then
			local menuValue = UIDROPDOWNMENU_MENU_VALUE
			if type(menuValue) == "table" then
				items = menuValue
			elseif type(menuValue) == "string" then
				items = submenuRegistry[menuValue]
			end
		end
		addMenuItems(items, level or 1)
	end

	function MenuUtil.CreateContextMenu(owner, builder)
		if not contextMenuFrame then
			contextMenuFrame = CreateFrame("Frame", "MDTCompatContextMenu", UIParent, "UIDropDownMenuTemplate")
		end
		submenuRegistry = {}
		submenuCounter = 0
		local root = createMenuDescription()
		builder(owner, root)
		currentMenuItems = root.items
		UIDropDownMenu_Initialize(contextMenuFrame, initializeContextMenu, "MENU")
		ToggleDropDownMenu(1, nil, contextMenuFrame, "cursor", 0, 0)
	end
end

function MDT.EnsureBackdropMixin(frame)
	if not frame then
		return
	end
	for key, fn in pairs(BackdropTemplateMixin) do
		if type(fn) == "function" and frame[key] == nil then
			frame[key] = fn
		end
	end
end

do
	local backdropShims = {}
	local testFrame = CreateFrame("Frame")
	if testFrame.SetBackdrop and not testFrame.ClearBackdrop then
		backdropShims.ClearBackdrop = function(self)
			self:SetBackdrop(nil)
		end
	end
	if not testFrame.SetBackdropColor then
		backdropShims.SetBackdropColor = function() end
	end
	if not testFrame.SetBackdropBorderColor then
		backdropShims.SetBackdropBorderColor = function() end
	end

	local function applyBackdropShims(obj)
		local meta = getmetatable(obj)
		local index = meta and meta.__index
		if type(index) == "table" then
			for name, fn in pairs(backdropShims) do
				if obj[name] == nil and index[name] == nil then
					index[name] = fn
				end
			end
		elseif type(index) == "function" then
			local origIndex = index
			meta.__index = function(t, k)
				local shim = backdropShims[k]
				if shim and t[k] == nil then
					return shim
				end
				return origIndex(t, k)
			end
		end
	end

	if next(backdropShims) then
		applyBackdropShims(testFrame)
	end
end

-- Legion 7.3.5 cannot load addon PNG textures (added in 10.0.7); use TGA tiles instead.
function MDT.GetCustomMapTilePath(basePath, sublevel, fileSuffix)
	local ext = MDT.IsLegion and MDT:IsLegion() and ".tga" or ".png"
	return basePath .. "\\" .. sublevel .. "_" .. fileSuffix .. ext
end

if C_AddOns then
	return
end

C_AddOns = {}

function C_AddOns.GetAddOnMetadata(nameOrIndex, field)
	if type(nameOrIndex) == "number" then
		nameOrIndex = select(1, GetAddOnInfo(nameOrIndex))
	end
	return GetAddOnMetadata(nameOrIndex, field)
end

function C_AddOns.GetNumAddOns()
	return GetNumAddOns()
end

function C_AddOns.GetAddOnInfo(index)
	return GetAddOnInfo(index)
end

function C_AddOns.IsAddOnLoaded(nameOrIndex)
	return IsAddOnLoaded(nameOrIndex)
end

function C_AddOns.LoadAddOn(name)
	return LoadAddOn(name)
end

if not C_Spell then
	C_Spell = {}
end

if not C_Spell.GetSpellTexture then
	function C_Spell.GetSpellTexture(spellId)
		return select(3, GetSpellInfo(spellId))
	end
end

if not C_Spell.GetSpellLink then
	function C_Spell.GetSpellLink(spellId)
		return GetSpellLink(spellId)
	end
end

if not C_Spell.GetSpellInfo then
	function C_Spell.GetSpellInfo(spellId)
		local name, _, icon = GetSpellInfo(spellId)
		if not name then
			return
		end
		return { name = name, iconID = icon }
	end
end

if not C_Spell.IsSpellDataCached then
	function C_Spell.IsSpellDataCached(spellId)
		return GetSpellInfo(spellId) ~= nil
	end
end

if not C_Spell.RequestLoadSpellData then
	function C_Spell.RequestLoadSpellData(spellId) end
end

if not C_Map then
	C_Map = {}
end

if not C_Map.GetBestMapForUnit then
	function C_Map.GetBestMapForUnit(unit)
		if WorldMapFrame and WorldMapFrame.mapID and WorldMapFrame.mapID > 0 then
			return WorldMapFrame.mapID
		end
		if GetCurrentMapAreaID then
			return GetCurrentMapAreaID()
		end
		return select(8, GetInstanceInfo())
	end
end

if not C_Map.GetMapInfo then
	function C_Map.GetMapInfo(mapID)
		if not mapID or mapID == 0 then
			return { name = GetRealZoneText() or "Unknown", parentMapID = 0 }
		end
		return { name = GetRealZoneText() or "Unknown", parentMapID = mapID }
	end
end

if not C_DateAndTime then
	C_DateAndTime = {}
end

if not C_DateAndTime.GetSecondsUntilWeeklyReset then
	function C_DateAndTime.GetSecondsUntilWeeklyReset()
		local weekday = tonumber(date("%w"))
		local secondsToday = tonumber(date("%H")) * 3600 + tonumber(date("%M")) * 60 + tonumber(date("%S"))
		local daysUntilReset = (2 - weekday) % 7
		if daysUntilReset == 0 and secondsToday > 0 then
			daysUntilReset = 7
		end
		return daysUntilReset * 86400 - secondsToday
	end
end

if not C_MythicPlus then
	C_MythicPlus = {}
end

if not C_MythicPlus.GetCurrentAffixes then
	function C_MythicPlus.GetCurrentAffixes() end
	function C_MythicPlus.RequestCurrentAffixes() end
	function C_MythicPlus.RequestMapInfo() end
	function C_MythicPlus.RequestRewards() end
end

if not C_ChallengeMode then
	C_ChallengeMode = {}
end

-- GetMapUIInfo was added in BfA; Legion uses GetMapInfo with the same return layout.
if not C_ChallengeMode.GetMapUIInfo then
	if C_ChallengeMode.GetMapInfo then
		C_ChallengeMode.GetMapUIInfo = C_ChallengeMode.GetMapInfo
	else
		local legionChallengeTimers = {
			[197] = 1800, -- Eye of Azshara
			[198] = 1800, -- Darkheart Thicket
			[200] = 2100, -- Halls of Valor
			[206] = 1800, -- Neltharion's Lair
			[207] = 1800, -- Vault of the Wardens
			[208] = 1500, -- Maw of Souls
			[209] = 2700, -- The Arcway
			[210] = 1800, -- Court of Stars
			[227] = 2100, -- Return to Karazhan: Lower
			[233] = 1800, -- Cathedral of Eternal Night
			[234] = 2100, -- Return to Karazhan: Upper
			[239] = 1800, -- Seat of the Triumvirate
		}

		function C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
			local timeLimit = legionChallengeTimers[mapChallengeModeID]
			if not timeLimit then
				return
			end
			local name
			if MDT and MDT.mapInfo then
				for _, info in pairs(MDT.mapInfo) do
					if info.mapID == mapChallengeModeID then
						name = info.englishName or info.shortName
						break
					end
				end
			end
			return name or "Unknown", mapChallengeModeID, timeLimit
		end
	end
end

do
	local shims = {}

	local testTex = UIParent:CreateTexture(nil, "BACKGROUND")
	if not testTex.SetColorTexture then
		shims.SetColorTexture = function(self, r, g, b, a)
			self:SetTexture(r or 1, g or 1, b or 1, a or 1)
		end
	end
	testTex:Hide()

	local testFrame = CreateFrame("Frame")
	if not testFrame.SetResizeBounds then
		shims.SetResizeBounds = function(self, minWidth, minHeight, maxWidth, maxHeight)
			self:SetMinResize(minWidth, minHeight)
			self:SetMaxResize(maxWidth, maxHeight)
		end
	end

	local function applyShims(obj)
		local meta = getmetatable(obj)
		local index = meta and meta.__index
		if type(index) == "table" then
			for name, fn in pairs(shims) do
				if obj[name] == nil and not index[name] then
					index[name] = fn
				end
			end
		elseif type(index) == "function" then
			local origIndex = index
			meta.__index = function(t, k)
				local shim = shims[k]
				if shim and t[k] == nil then
					return shim
				end
				return origIndex(t, k)
			end
		end
	end

	if next(shims) then
		applyShims(testTex)
		applyShims(testFrame)
	end
end

if not CreateTextureMarkup then
	function CreateTextureMarkup(file, fileWidth, fileHeight, width, height, left, right, top, bottom)
		if type(file) == "number" then
			return ("|T%d:%d:%d|t"):format(file, width, height)
		end
		return ("|T%s:%d:%d:0:0|t"):format(file, width, height)
	end
end

MDT.SetMouseClickEnabled = function(frame, enabled)
	if frame.SetMouseClickEnabled then
		frame:SetMouseClickEnabled(enabled)
	else
		frame:EnableMouse(enabled)
	end
end

function MDT:CreateMaximizeButton(parent, closeButton)
	-- Legion 7.3.5 has Expand/Minimize panel buttons, not Maximize (added in BfA+).
	local expandTexture = "Interface\\Buttons\\UI-Panel-BiggerButton-Up"
	local collapseTexture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up"
	local expandTexCoord = { 0.1, 0.9, 0.1, 0.9 }

	local btn = CreateFrame("Button", "MDTMaximizeButton", parent)
	btn:SetSize(24, 24)
	btn:SetPoint("RIGHT", closeButton, "LEFT", 0, 0)
	btn:SetFrameLevel(4)
	btn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
	btn:GetHighlightTexture():SetBlendMode("ADD")
	btn.icon = btn:CreateTexture(nil, "ARTWORK")
	btn.icon:SetSize(16, 16)
	btn.icon:SetPoint("CENTER")
	btn.isMaximized = false

	function btn:Minimize()
		self.isMaximized = false
		self.icon:SetTexture(expandTexture)
		self.icon:SetTexCoord(unpack(expandTexCoord))
	end

	function btn:Maximize()
		self.isMaximized = true
		self.icon:SetTexture(collapseTexture)
		self.icon:SetTexCoord(0, 1, 0, 1)
	end

	function btn:SetOnMaximizedCallback(fn)
		self.onMaximize = fn
	end

	function btn:SetOnMinimizedCallback(fn)
		self.onMinimize = fn
	end

	btn:SetScript("OnClick", function(self)
		if self.isMaximized then
			if self.onMinimize then
				self.onMinimize()
			end
			self:Minimize()
		else
			if self.onMaximize then
				self.onMaximize()
			end
			self:Maximize()
		end
	end)

	btn:Minimize()
	return btn
end
