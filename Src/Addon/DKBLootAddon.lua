DKBLoot = LibStub("AceAddon-3.0"):NewAddon("DKBLoot", "AceConsole-3.0", "AceEvent-3.0")

local DB = DKBLootLoader:UseModule("DB")
local GUI = DKBLootLoader:UseModule("GUI")
local LootMaster = DKBLootLoader:UseModule("LootMaster")
local Tracker = DKBLootLoader:UseModule("Tracker")
local Trade = DKBLootLoader:UseModule("Trade")
local Whisper = DKBLootLoader:UseModule("Whisper")

function DKBLoot:OnInitialize()
  DKBLoot:RegisterChatCommand("dkb", "HandleSlashCommand")
  
  DB:Initialize()
  LootMaster:Initialize()
  Tracker:Initialize()
  Trade:Initialize()
  Whisper:Initialize()
end

function DKBLoot:HandleSlashCommand(command)
  if GUI:IsVisible() then
    GUI:Hide()
  else
    GUI:Show()
  end
end
