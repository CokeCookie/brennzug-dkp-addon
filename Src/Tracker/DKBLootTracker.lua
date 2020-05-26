local Tracker = DKBLootLoader:RegisterModule("Tracker")
local DB = DKBLootLoader:UseModule("DB")
local Util = DKBLootLoader:UseModule("Util")

local ITEM_BLACKLIST = {
  -- Zul Gurub Bijous
  19707, 19708, 19709, 19710, 19711, 19712, 19713, 19714, 19715,
}

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
      local quality = C_Item.GetItemQualityByID(itemId)

      if not tContains(ITEM_BLACKLIST, itemId) then
        if 3 <= quality and quality <= 5 then
          DB:AddLootItem(lootSourceGuid, lootSourceName, itemId)
        end
      end
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