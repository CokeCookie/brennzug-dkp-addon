local Util = DKBLootLoader:RegisterModule("Util")
local DB = DKBLootLoader:UseModule("DB")

local RAID_NAMES = {
  [DB.RAID_MC] = "Molten Core",
  [DB.RAID_ZG] = "Zul Gurub",
  [DB.RAID_BWL] = "Blackwing Lair",
}

function Util:TableShallowCopy(table)
  local copy = {}
 
  for key, value in pairs(table) do
    copy[key] = value
  end

  return copy
end

function Util:TablePull(table, key)
  local value = table[key]

  table[key] = nil

  return value
end

function Util:GetGuildMemberInfo(player)
  local totalGuildMembers = GetNumGuildMembers()

  for i = 1, totalGuildMembers do
    local nameWithServerName, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
    local name = nameWithServerName:match("(.*)-")

    if name == player then
      return name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID
    end
  end

  return nil
end

function Util:IsInMyGuild(player)
  local totalGuildMembers = GetNumGuildMembers()

  for i = 1, totalGuildMembers do
    local nameWithServerName = GetGuildRosterInfo(i)
    local name = nameWithServerName:match("(.*)-")

    if name == player then
      return true
    end
  end

  return false
end

function Util:GetRaidName(raid)
  return RAID_NAMES[raid]
end

function Util:GetItemIdFromItemLink(itemLink)
  return itemLink:match("|[0123456789abcdef]*|Hitem:(%d+):")
end

function Util:IsEmpty(value)
  return value == nil or value == ''
end