-- API compatibility shims for WoW 7.3.5 (Legion)
local _, MDT = ...

if C_AddOns then return end

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
    if not name then return end
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
  local btn = CreateFrame("Button", "MDTMaximizeButton", parent)
  btn:SetSize(24, 24)
  btn:SetPoint("RIGHT", closeButton, "LEFT", 0, 0)
  btn:SetFrameLevel(4)
  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetSize(16, 16)
  btn.icon:SetPoint("CENTER")
  btn.isMaximized = false

  function btn:Minimize()
    self.isMaximized = false
    self.icon:SetTexture("Interface\\Buttons\\UI-Panel-MaximizeButton-Up")
  end

  function btn:Maximize()
    self.isMaximized = true
    self.icon:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  end

  function btn:SetOnMaximizedCallback(fn)
    self.onMaximize = fn
  end

  function btn:SetOnMinimizedCallback(fn)
    self.onMinimize = fn
  end

  btn:SetScript("OnClick", function(self)
    if self.isMaximized then
      if self.onMinimize then self.onMinimize() end
      self:Minimize()
    else
      if self.onMaximize then self.onMaximize() end
      self:Maximize()
    end
  end)

  return btn
end
