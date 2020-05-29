local Tracker = DKBLootLoader:RegisterModule("Tracker")
local DB = DKBLootLoader:UseModule("DB")
local Util = DKBLootLoader:UseModule("Util")

local eventFrame = CreateFrame("Frame")

local function HandleLootOpened(...)
  local lootMethod = GetLootMethod()

  if lootMethod ~= "master" then
    return
  end

  local activeRaid = DB:GetActiveRaid()

  if not activeRaid then
    return
  end

  local lootableItemsCount = GetNumLootItems()

  if lootableItemsCount == 0 then
    return
  end

  local lootSourceGuid = GetLootSourceInfo(1)

  if lootSourceGuid == nil then
    -- Loot source is nil
    -- Why???
    return
  end

  if DB:IsLootSourceAlreadyKnown(activeRaid.id, lootSourceGuid) then
    return
  end

  local type, zero, serverId, instanceId, zoneUid, npcId, spawnUid = strsplit("-", lootSourceGuid)
  local lootSourceName = type == "Creature" and UnitName("target") or nil

  for slot = 1, lootableItemsCount do
    if GetLootSlotType(slot) == LOOT_SLOT_ITEM then
      local itemLink = GetLootSlotLink(slot)
      local itemId = Util:GetItemIdFromItemLink(itemLink)

      DB:AddLootItem(lootSourceGuid, lootSourceName, itemId)
    end
  end
end

local function HandleEvent(self, event, ...)
  if event == "LOOT_OPENED" then
    HandleLootOpened(...)
  end
end

function Tracker:Initialize()
  eventFrame:RegisterEvent("LOOT_OPENED")
  eventFrame:SetScript("OnEvent", HandleEvent)
end