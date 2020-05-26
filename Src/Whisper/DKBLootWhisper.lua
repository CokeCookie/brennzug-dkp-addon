local Whisper = DKBLootLoader:RegisterModule("Whisper")
local DB = DKBLootLoader:UseModule("DB")
local Util = DKBLootLoader:UseModule("Util")

local DKP_AUTO_RESPONSE = "!dkp"
local RAID_RESPONSES = {
  { name = "Molten Core", raid = DB.RAID_MC },
  { name = "Blackwing Lair", raid = DB.RAID_BWL },
  { name = "Zul Gurub", raid = DB.RAID_ZG },
}

local eventFrame = CreateFrame("Frame")

local function HandleWhisper(text, playerNameWithServer)
  local player = Util:RemoveServerNameFromPlayerName(playerNameWithServer)

  if text == DKP_AUTO_RESPONSE then
    local dkp = DB:GetPlayerDKP(player)

    if not dkp then
      return
    end

    local activeRaid = DB:GetActiveRaid()
    local dkpMessage = "[DKBLoot] "

    for i, entry in pairs(RAID_RESPONSES) do
      local activeString = ""
      local raidDKP = dkp[entry.raid]

      if activeRaid and activeRaid.raid == entry.raid then
        activeString = " (aktuell)"
        raidDKP = DB:ComputeCurrentPlayerDKP(activeRaid.id, player)
      end

      dkpMessage = dkpMessage .. format("%s%s: %d", entry.name, activeString, raidDKP)

      if i ~= #RAID_RESPONSES then
        dkpMessage = dkpMessage .. ", "
      end
    end

    SendChatMessage(dkpMessage, "WHISPER", nil, player)
  end
end

local function HandleEvent(self, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    HandleWhisper(...)
  end
end

function Whisper:Initialize()
  eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
  eventFrame:SetScript("OnEvent", HandleEvent)
end