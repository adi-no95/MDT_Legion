-- API compatibility shims for WoW 7.3.5 (Legion)
local _, MDT = ...

-- WeakAurasLegionCompat owns the complete C_AddOns/C_Spell/C_Map shims. If MDT
-- installs incomplete stubs first, WeakAuras skips its copies and errors
-- (C_AddOns.EnableAddOn is nil, Init.lua never defines WeakAuras.IsLibsOK).
if not IsAddOnLoaded("WeakAurasLegionCompat") then
	local _, _, _, compatEnabled = GetAddOnInfo("WeakAurasLegionCompat")
	local _, _, _, waEnabled = GetAddOnInfo("WeakAuras")
	if compatEnabled or waEnabled then
		LoadAddOn("WeakAurasLegionCompat")
	end
end

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

-- Only fill missing mixin methods. WeakAurasLegionCompat ships a full BackdropTemplateMixin
-- and overwriting it makes WeakAuras frames recurse or lose nine-slice backdrops.
do
	local nativeFrame = CreateFrame("Frame")
	local nativeSetBackdrop = nativeFrame.SetBackdrop
	local nativeSetBackdropColor = nativeFrame.SetBackdropColor
	local nativeSetBackdropBorderColor = nativeFrame.SetBackdropBorderColor

	if not BackdropTemplateMixin.SetBackdrop then
		function BackdropTemplateMixin:SetBackdrop(backdrop)
			if nativeSetBackdrop then
				nativeSetBackdrop(self, backdrop)
			end
		end
	end

	if not BackdropTemplateMixin.SetBackdropColor then
		function BackdropTemplateMixin:SetBackdropColor(r, g, b, a)
			if nativeSetBackdropColor then
				nativeSetBackdropColor(self, r, g, b, a)
			end
		end
	end

	if not BackdropTemplateMixin.SetBackdropBorderColor then
		function BackdropTemplateMixin:SetBackdropBorderColor(r, g, b, a)
			if nativeSetBackdropBorderColor then
				nativeSetBackdropBorderColor(self, r, g, b, a)
			end
		end
	end

	if not BackdropTemplateMixin.ClearBackdrop then
		function BackdropTemplateMixin:ClearBackdrop()
			if nativeSetBackdrop then
				nativeSetBackdrop(self, nil)
			end
		end
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

-- On 7.3.5 SetPortraitTexture takes a creature display ID as well as a unit token;
-- that is what the default world map uses to draw its Encounter Journal boss icons.
if not SetPortraitTextureFromCreatureDisplayID then
	function SetPortraitTextureFromCreatureDisplayID(texture, creatureDisplayID)
		if not texture then
			return
		end
		SetPortraitTexture(texture, tonumber(creatureDisplayID) or 39490)
	end
end

local DEFAULT_DISPLAY_ID = 39490
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local QUESTION_MARK_FILE_ID = 134400

-- Used when a display id cannot be resolved by the client. Only vanilla era icons,
-- they are guaranteed to exist on 7.3.5.
MDT.creatureTypeIcons = {
	["Humanoid"] = "Interface\\Icons\\INV_Misc_Head_Human_01",
	["Beast"] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
	["Undead"] = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
	["Demon"] = "Interface\\Icons\\Spell_Shadow_SummonInfernal",
	["Elemental"] = "Interface\\Icons\\Spell_Fire_Elemental_Totem",
	["Aberration"] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
	["Mechanical"] = "Interface\\Icons\\Trade_Engineering",
	["Giant"] = "Interface\\Icons\\INV_Misc_MonsterHorn_01",
	["Dragonkin"] = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
	["Critter"] = "Interface\\Icons\\INV_Misc_MonsterClaw_04",
}

-- npcId -> icon path or spellId, for hand tuning individual enemies
MDT.enemyIconOverrides = {}

local fallbackIconCache = {}
-- texture -> { data, icon }, for textures whose creature portrait has not loaded yet
local pendingPortraits = {}

local npcIdIndex
local function getEnemyDataByNpcId(npcId)
	if not npcId then
		return
	end
	if not npcIdIndex or not npcIdIndex[npcId] then
		npcIdIndex = {}
		for _, enemies in pairs(MDT.dungeonEnemies or {}) do
			for _, enemy in pairs(enemies) do
				if enemy.id then
					npcIdIndex[enemy.id] = enemy
				end
			end
		end
	end
	return npcIdIndex[npcId]
end

-- Picks the lowest spell id that resolves to a real icon on this client. The spells
-- table is keyed, so it has to be sorted to stay stable across reloads.
local function getSpellIcon(spells)
	if type(spells) ~= "table" then
		return
	end
	local spellIds = {}
	for spellId in pairs(spells) do
		if tonumber(spellId) then
			table.insert(spellIds, tonumber(spellId))
		end
	end
	table.sort(spellIds)
	for _, spellId in pairs(spellIds) do
		local icon = C_Spell.GetSpellTexture(spellId)
		if icon and icon ~= QUESTION_MARK_FILE_ID and icon ~= QUESTION_MARK then
			return icon
		end
	end
end

-- Resolves an icon for an enemy that has no usable creature portrait.
function MDT.GetEnemyFallbackIcon(data)
	if not data then
		return QUESTION_MARK
	end
	local npcId = data.id or data.npcId
	local cached = fallbackIconCache[npcId or false]
	if cached then
		return cached
	end

	local icon
	local override = npcId and MDT.enemyIconOverrides[npcId]
	if type(override) == "number" then
		icon = C_Spell.GetSpellTexture(override)
	elseif override then
		icon = override
	end

	-- pull button entries do not carry the spell list, look the enemy up instead
	local spells = data.spells
	if not spells and npcId then
		local enemy = getEnemyDataByNpcId(npcId)
		spells = enemy and enemy.spells
	end
	icon = icon or getSpellIcon(spells)
	icon = icon or MDT.creatureTypeIcons[data.creatureType] or QUESTION_MARK

	if npcId then
		fallbackIconCache[npcId] = icon
	end
	return icon
end

local function setEnemyIcon(texture, icon)
	if SetPortraitToTexture then
		SetPortraitToTexture(texture, icon)
	else
		texture:SetTexture(icon)
	end
end

-- Tries the creature portrait, falling back to an icon if it is not available yet.
-- Returns the fallback that was applied, or nil once the real portrait is showing.
local function applyEnemyPortrait(texture, data)
	-- clear first, otherwise a leftover portrait from a pooled frame looks like a success
	texture:SetTexture(nil)
	SetPortraitTextureFromCreatureDisplayID(texture, data.displayId or DEFAULT_DISPLAY_ID)
	if texture:GetTexture() then
		return
	end
	setEnemyIcon(texture, MDT.GetEnemyFallbackIcon(data))
	return texture:GetTexture()
end

---Sets the creature portrait of an enemy on a texture.
---On 7.3.5 SetPortraitTexture accepts a creature display id, the same way the default
---world map draws its boss icons. Portraits load asynchronously, so anything that does
---not resolve right away gets a fallback icon and is retried on UNIT_PORTRAIT_UPDATE.
function MDT.SetEnemyPortrait(texture, data)
	if not texture or not data then
		return
	end
	pendingPortraits[texture] = nil
	if data.iconTexture then
		setEnemyIcon(texture, data.iconTexture)
		return
	end
	local fallback = applyEnemyPortrait(texture, data)
	if fallback then
		pendingPortraits[texture] = { data = data, icon = fallback }
	end
end

-- Mirrors EncounterJournal_UpdateMapButtonPortraits: retry the portraits that were not
-- cached yet. Keyed by texture, so the list stays bounded by the frame pool size.
local portraitFrame = CreateFrame("Frame")
portraitFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
portraitFrame:SetScript("OnEvent", function()
	for texture, pending in pairs(pendingPortraits) do
		if texture:GetTexture() ~= pending.icon then
			-- something else took this texture over in the meantime, leave it alone
			pendingPortraits[texture] = nil
		else
			local fallback = applyEnemyPortrait(texture, pending.data)
			if fallback then
				pending.icon = fallback
			else
				pendingPortraits[texture] = nil
			end
		end
	end
end)

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

C_AddOns = C_AddOns or {}

if not C_AddOns.GetAddOnMetadata then
	function C_AddOns.GetAddOnMetadata(nameOrIndex, field)
		if type(nameOrIndex) == "number" then
			nameOrIndex = select(1, GetAddOnInfo(nameOrIndex))
		end
		return GetAddOnMetadata(nameOrIndex, field)
	end
else
	local origGetAddOnMetadata = C_AddOns.GetAddOnMetadata
	function C_AddOns.GetAddOnMetadata(nameOrIndex, field)
		if type(nameOrIndex) == "number" then
			nameOrIndex = select(1, GetAddOnInfo(nameOrIndex))
		end
		return origGetAddOnMetadata(nameOrIndex, field)
	end
end

if not C_AddOns.GetNumAddOns then
	C_AddOns.GetNumAddOns = GetNumAddOns
end

if not C_AddOns.GetAddOnInfo then
	C_AddOns.GetAddOnInfo = GetAddOnInfo
end

if not C_AddOns.IsAddOnLoaded then
	C_AddOns.IsAddOnLoaded = IsAddOnLoaded
end

if not C_AddOns.LoadAddOn then
	C_AddOns.LoadAddOn = LoadAddOn
end

if not C_AddOns.EnableAddOn then
	C_AddOns.EnableAddOn = EnableAddOn
end

if not C_AddOns.DisableAddOn then
	C_AddOns.DisableAddOn = DisableAddOn
end

if not C_AddOns.EnableAllAddOns then
	C_AddOns.EnableAllAddOns = EnableAllAddOns
end

if not C_AddOns.DisableAllAddOns then
	C_AddOns.DisableAllAddOns = DisableAllAddOns
end

if not C_AddOns.DoesAddOnExist then
	C_AddOns.DoesAddOnExist = DoesAddOnExist
end

if not C_AddOns.GetAddOnDependencies then
	C_AddOns.GetAddOnDependencies = GetAddOnDependencies
end

if not C_AddOns.GetAddOnOptionalDependencies then
	C_AddOns.GetAddOnOptionalDependencies = GetAddOnOptionalDependencies
end

if not C_AddOns.IsAddOnLoadOnDemand then
	C_AddOns.IsAddOnLoadOnDemand = IsAddOnLoadOnDemand
end

if not C_AddOns.IsAddOnLoadable then
	C_AddOns.IsAddOnLoadable = IsAddOnLoadable
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

-- CombatLogGetCurrentEventInfo was added in 8.0. On 7.3.5 the payload is the event args.
-- Store them on a frame created at load so later COMBAT_LOG handlers can read the same values.
if not CombatLogGetCurrentEventInfo then
	local cleuArgs, cleuCount = {}, 0
	local cleuFrame = CreateFrame("Frame")
	cleuFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	cleuFrame:SetScript("OnEvent", function(_, _, ...)
		cleuCount = select("#", ...)
		for i = 1, cleuCount do
			cleuArgs[i] = select(i, ...)
		end
	end)
	function CombatLogGetCurrentEventInfo()
		return unpack(cleuArgs, 1, cleuCount)
	end
end

-- GetMapUIInfo was added in BfA; Legion uses GetMapInfo with the same return layout.
if not C_ChallengeMode.GetMapUIInfo then
	if C_ChallengeMode.GetMapInfo then
		C_ChallengeMode.GetMapUIInfo = C_ChallengeMode.GetMapInfo
	else
		local legionChallengeTimers = {
			[199] = 2280, -- Black Rook Hold
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
		-- Retail max size is optional. WeakAuras calls SetResizeBounds(minW, minH) only.
		shims.SetResizeBounds = function(self, minWidth, minHeight, maxWidth, maxHeight)
			if minWidth and minHeight then
				self:SetMinResize(minWidth, minHeight)
			end
			if maxWidth and maxHeight then
				self:SetMaxResize(maxWidth, maxHeight)
			end
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
