local Trade = DKBLootLoader:RegisterModule("Trade")
local TradeStateMachine = DKBLootLoader:UseModule("TradeStateMachine")
local EventQueue = DKBLootLoader:UseModule("EventQueue")
local DB = DKBLootLoader:UseModule("DB")

local QUEUE_EVENTS = {
  "TRADE_SHOW",
  "TRADE_CLOSED",
  "TRADE_REQUEST_CANCEL",
  "TRADE_ACCEPT_UPDATE",
  "TRADE_PLAYER_ITEM_CHANGED",
}

local eventFrame = CreateFrame("Frame")
local eventQueue = EventQueue:Create()

local function HandleEvent(self, event, ...)
  if tContains(QUEUE_EVENTS, event) then
    eventQueue:Push(event, ...)
  end
end

function Trade:Initialize()
  local tradeStateMachine = TradeStateMachine:Create(eventQueue)

  eventFrame:RegisterEvent("TRADE_SHOW")
  eventFrame:RegisterEvent("TRADE_CLOSED")
  eventFrame:RegisterEvent("TRADE_REQUEST_CANCEL")
  eventFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
  eventFrame:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
  eventFrame:SetScript("OnEvent", HandleEvent)

  tradeStateMachine:Start()
end
