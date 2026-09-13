---@class MDT_Legacy
local addon = select(2, ...)
local MDT = MDT

if not addon:GenericVersionCheck("MythicDungeonTools", "5.0.0") then
  return
end

function addon:OnInitialize()
end

MDT:RegisterModule("MDT Legacy", addon)
