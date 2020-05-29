local LibJSON = LibStub("LibJSON-1.0")
local DB = DKBLootLoader:RegisterModule("DB")
local Util = DKBLootLoader:RegisterModule("Util")

local ITEM_BLACKLIST = {
  -- Zul Gurub Bijous
  19707, 19708, 19709, 19710, 19711, 19712, 19713, 19714, 19715,
  -- Enchanting materials: Small Brilliant Shard, Large Brilliant Shard, Nexus Crystal
  14343, 14344, 20725,
  -- Onyxia materials: Scale of Onyxia
  15410,
  -- Molten Core materials: Fiery Core, Lava Core
  17010, 17011,
  -- Blackwing Lair materials: Elementium Ore
  18562
}

DB.RAID_MC, DB.RAID_ZG, DB.RAID_BWL = "MOLTEN_CORE", "ZUL_GURUB", "BLACKWING_LAIR"
DB.EVENT_GUILD_DKP, DB.EVENT_RAIDS, DB.EVENT_LOOT, DB.EVENT_PARTICIPANTS = "GUILD_DKP", "RAIDS", "LOOT", "PARTICIPANTS"
local INITIAL_DKP = 10
local db = nil
local defaults = {
  factionrealm = {
    guildDKP = {},
    raids = {},
    activeRaid = nil,
  },
}

local handlers = {}
local nextHandlerId = 1

local function FindPlayerIndex(guildDKP, player)
  for i = 1, #guildDKP do
    if guildDKP[i].player == player then
      return i
    end
  end

  return nil
end

local function UpdatePlayer(guildDKP, player, dkp)
  local index = FindPlayerIndex(guildDKP, player) or (#guildDKP + 1)

  guildDKP[index] = {
    player = player,
    dkp = dkp,
  }
end

local function EmitUpdate(name, ...)
  for key, entry in pairs(handlers) do
    if entry.event == name and entry.subscription.handler then
      entry.subscription.handler(...)
    end
  end
end

local function UpdateGuildDKP(guildDKP)
  db.factionrealm.guildDKP = guildDKP
  EmitUpdate(DB.EVENT_GUILD_DKP, guildDKP)
end

local function UpdateRaids(raids)
  db.factionrealm.raids = raids
  EmitUpdate(DB.EVENT_RAIDS, raids)
end

function DB:GetDKPList()
  return db.factionrealm.guildDKP or {}
end

function DB:GetPlayerDKP(player, raid)
  local guildDKP = DB:GetDKPList()

  for i, entry in pairs(guildDKP) do
    if entry.player == player then
      return raid and entry.dkp[raid] or entry.dkp
    end
  end

  return nil
end

function DB:ImportDKPList(list)
  local guildDKP = DB:GetDKPList()

  for i = 1, #list do
    UpdatePlayer(guildDKP, list[i].player, list[i].dkp)
  end

  UpdateGuildDKP(guildDKP)
end

function DB:GetRaids()
  return db.factionrealm.raids or {}
end

function DB:AddRaid(raid)
  local raids = DB:GetRaids()
  local timestamp = time()
  local id = "Raid:" .. timestamp

  tinsert(raids, 1, {
    id = id,
    raid = raid,
    loot = {},
    lootedNpcs = {},
    participants = {},
    timestamp = timestamp,
  })

  UpdateRaids(raids)

  return raids[1]
end

function DB:GetRaidById(id)
  for i, raid in pairs(DB:GetRaids()) do
    if raid.id == id then
      return raid, i
    end
  end

  return nil, nil
end

function DB:IsActiveRaidId(id)
  return db.factionrealm.activeRaid == id
end

function DB:GetRaidByIndex(index)
  local raids = DB:GetRaids()

  return raids[index]
end

function DB:DeleteRaidByIndex(index)
  local raids = DB:GetRaids()

  tremove(raids, index)

  UpdateRaids(raids)
end

function DB:DeleteRaidById(id)
  local raid, index = DB:GetRaidById(id)

  if raid then
    DB:DeleteRaidByIndex(index)
  end
end

function DB:SetActiveRaid(id)
  if DB:GetRaidById(id) then
    db.factionrealm.activeRaid = id

    UpdateRaids(DB:GetRaids())
  end
end

function DB:StopActiveRaid()
  db.factionrealm.activeRaid = nil

  UpdateRaids(DB:GetRaids())
end

function DB:GetActiveRaid()
  if not db.factionrealm.activeRaid then
    return nil
  end

  return DB:GetRaidById(db.factionrealm.activeRaid)
end

function DB:HasActiveRaid()
  local activeRaid = DB:GetActiveRaid()

  return activeRaid ~= nil
end

function DB:GetRaidLoot(id)
  local raid = DB:GetRaidById(id)

  if not raid then
    return nil
  end

  return raid.loot
end

function DB:GetRaidParticipants(id)
  local raid = DB:GetRaidById(id)

  if not raid then
    return nil
  end

  return raid.participants
end

function DB:IsLootSourceAlreadyKnown(id, guid)
  local raid = DB:GetRaidById(id)

  if not raid then
    return false
  end

  return raid.lootedNpcs[guid] ~= nil
end

function DB:AddLootItem(sourceGUID, sourceName, itemId)
  if tContains(ITEM_BLACKLIST, itemId) then
    return
  end

  local quality = C_Item.GetItemQualityByID(itemId)

  if quality < 3 then
    return
  end

  local activeRaid = DB:GetActiveRaid()

  if not activeRaid then
    return
  end

  tinsert(activeRaid.loot, 1, {
    sourceGUID = sourceGUID,
    sourceName = sourceName,
    itemId = itemId,
  })
  activeRaid.lootedNpcs[sourceGUID] = true

  EmitUpdate(DB.EVENT_LOOT, activeRaid.loot)
end

function DB:GetRaidLootByIndex(id, itemIndex)
  local loot = DB:GetRaidLoot(id)

  if not loot then
    return nil
  end

  return loot[itemIndex]
end

function DB:FindFirstUnassignedLootByItemId(raidId, itemId)
  local loot = DB:GetRaidLoot(raidId)

  if not loot then
    return nil
  end

  for key, entry in pairs(loot) do
    if entry.itemId == itemId then
      if not entry.givenTo then
        return entry
      end
    end
  end

  return nil
end

function DB:RegisterPlayerItemDKP(raidId, itemId, player, dkp, itemIndex)
  local raid = DB:GetRaidById(raidId)

  if not raid then
    return
  end

  local lootEntry

  if itemIndex then
    lootEntry = raid.loot[itemIndex]
  else
    lootEntry = DB:FindFirstUnassignedLootByItemId(raidId, itemId)
  end

  if not lootEntry then
    return
  end

  if not Util:IsEmpty(player) and not Util:IsEmpty(dkp) then
    lootEntry.givenTo = {
      player = player,
      dkp = dkp,
    }
  else
    lootEntry.givenTo = nil
  end

  EmitUpdate(DB.EVENT_LOOT, DB:GetRaidLoot(raidId))
  EmitUpdate(DB.EVENT_PARTICIPANTS)
end

function DB:EvaluateRaidById(raidId)
  local raid = DB:GetRaidById(raidId)

  if not raid then
    return
  end

  local participants = DB:GetRaidParticipants(raidId)
  local exportObj = {
    raid = raid.raid,
    date = date("%d.%m.%Y", raid.timestamp),
    participants = {},
    loot = {},
  }
  local participantsSeen = {}

  for i, participant in pairs(participants) do
    exportObj.participants[i] = {
      player = participant.player,
      dkp = DB:GetPlayerDKP(participant.player, raid.raid),
      group = participant.group,
      class = participant.classFile,
    }
    participantsSeen[participant.player] = true
  end

  for i, entry in pairs(raid.loot) do
    local itemName = GetItemInfo(entry.itemId)

    if entry.givenTo then
      local player = entry.givenTo.player
      local dkp = entry.givenTo.dkp

      if not participantsSeen[player] then
        tinsert(exportObj.participants, {
          player = player,
        })
      end
    end

    exportObj.loot[i] = {
      itemId = entry.itemId,
      itemName = itemName,
      sourceGUID = entry.sourceGUID,
      sourceName = entry.sourceName,
      givenTo = entry.givenTo,
    }
  end

  return LibJSON.Serialize(exportObj)
end

function DB:AddRaidParticipant(raidId, info)
  local raid = DB:GetRaidById(raidId)

  if not raid then
    return
  end

  local existingParticipant = nil

  for i, participant in pairs(raid.participants) do
    if participant.player == info.player then
      existingParticipant = participant
      break
    end
  end

  if existingParticipant then
    return
  end

  tinsert(raid.participants, info)

  EmitUpdate(DB.EVENT_PARTICIPANTS)
end

function DB:DeleteRaidParticipantByIndex(raidId, participantIndex)
  local raid = DB:GetRaidById(raidId)

  if not raid then
    return
  end

  tremove(raid.participants, participantIndex)

  EmitUpdate(DB.EVENT_PARTICIPANTS)
end

function DB:GetRaidParticipantByIndex(raidId, participantIndex)
  local participants = DB:GetRaidParticipants(raidId)

  if not participants then
    return
  end

  return participants[participantIndex]
end

function DB:RegisterAllRaidMembersAsParticipants(raidId)
  local raid = DB:GetRaidById(raidId)

  if not raid then
    return
  end

  for i = 1, GetNumGroupMembers() do
    local player, rank, group, level, class, classFile = GetRaidRosterInfo(i)

    DB:AddRaidParticipant(raidId, {
      player = player,
      group = group,
      class = class,
      classFile = classFile,
    })
  end
end

function DB:ComputeCurrentPlayerDKP(raidId, player)
  local raid = DB:GetRaidById(raidId)

  if not raid then
    return nil
  end

  local playerDKP = DB:GetPlayerDKP(player, raid.raid)
  local currentDKP = playerDKP or INITIAL_DKP
  local raidLoot = DB:GetRaidLoot(raidId)
  local hasPlayerDKP = not not playerDKP
  local hasLoot = false

  for i, entry in pairs(raidLoot) do
    if entry.givenTo and entry.givenTo.player == player then
      currentDKP = currentDKP - entry.givenTo.dkp
      hasLoot = true
    end
  end

  return currentDKP, hasPlayerDKP, hasLoot
end

function DB:Subscribe(event)
  local myHandlerId = nextHandlerId

  local subscription = {
    ["Cancel"] = function (self)
      handlers[myHandlerId] = nil
      self.handler = nil
    end,

    ["OnData"] = function (self, handler)
      self.handler = handler
    end,
  }

  handlers[myHandlerId] = {
    event = event,
    subscription = subscription,
  }
  nextHandlerId = nextHandlerId + 1

  return subscription
end

function DB:Initialize()
  db = LibStub("AceDB-3.0"):New("DKBLootDB", defaults)
end