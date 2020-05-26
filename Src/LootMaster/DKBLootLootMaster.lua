local LootMaster = DKBLootLoader:RegisterModule("LootMaster")
local DB = DKBLootLoader:UseModule("DB")
local GUI = DKBLootLoader:UseModule("GUI")
local Util = DKBLootLoader:UseModule("Util")

local eventFrame = CreateFrame("Frame")


local function CreatePattern(pattern, maximize)
  pattern = string.gsub(pattern, "[%(%)%-%+%[%]]", "%%%1")

  if not maximize then 
    pattern = string.gsub(pattern, "%%s", "(.-)")
  else
    pattern = string.gsub(pattern, "%%s", "(.+)")
  end

  pattern = string.gsub(pattern, "%%d", "%(%%d-%)")

  if not maximize then 
    pattern = string.gsub(pattern, "%%%d%$s", "(.-)")
  else
    pattern = string.gsub(pattern, "%%%d%$s", "(.+)")
  end

  pattern = string.gsub(pattern, "%%%d$d", "%(%%d-%)")

  return pattern
end

local patternLoot = CreatePattern(LOOT_ITEM, true)
local patternLootOwn = CreatePattern(LOOT_ITEM_SELF, true)
local patternCreateOwn = CreatePattern(LOOT_ITEM_CREATED_SELF, true)

local function HandleLootChatMessage(text)
  if string.match(text, patternCreateOwn) then
    return
  end

  if not IsMasterLooter() then
    return
  end

  local activeRaid = DB:GetActiveRaid()

  if not activeRaid then
    return
  end

  local playerName, itemLink = string.match(text, patternLoot)

  if not playerName or not itemLink then
    playerName = GetUnitName("player")
    itemLink = string.match(text, patternLootOwn)

    if itemLink and lootMethod == "group" then
      DB:AddLootItem("UNKNOWN", "N/A", Util:GetItemIdFromItemLink(itemLink))
    end
  end

  if itemLink then
    local itemId = Util:GetItemIdFromItemLink(itemLink)
    local unassignedItem = DB:FindFirstUnassignedLootByItemId(activeRaid.id, itemId)

    if not unassignedItem then
      -- An unassigned item with the given item link could not be found
      -- so it's probably not part of the boss loot
      return
    end

    GUI:ShowAssignItemWindow(activeRaid.id, itemId, playerName)
  end
end

local function HandleEvent(self, event, ...)
  if event == "CHAT_MSG_LOOT" then
    HandleLootChatMessage(...)
  end
end

function LootMaster:Initialize()
  eventFrame:RegisterEvent("CHAT_MSG_LOOT")
  eventFrame:SetScript("OnEvent", HandleEvent)
end