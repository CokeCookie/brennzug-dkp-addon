local TradeStateMachine = DKBLootLoader:RegisterModule("TradeStateMachine")
local DB = DKBLootLoader:UseModule("DB")
local GUI = DKBLootLoader:UseModule("GUI")
local Util = DKBLootLoader:UseModule("Util")

local Machine = {}

function Machine:Create(eventQueue)
  local instance = {
    eventQueue = eventQueue,
    listeners = {},
    tradeTarget = nil,
    playerItems = {},
  }

  setmetatable(instance, self)
  self.__index = self

  eventQueue:OnUpdate(function ()
    instance:ProcessQueue()
  end)

  return instance
end

function Machine:ProcessQueue()
  local handled = false

  for i, listener in pairs(self.listeners) do
    local events = self.eventQueue:Consume(listener.pattern)

    if events then
      listener.callback(unpack(events))

      handled = true
      break
    end
  end

  if handled then
    if self.eventQueue:HasItems() then
      self:ProcessQueue()
    end
  else
    local maxPatternLength = 0

    for i, listener in pairs(self.listeners) do
      if #listener.pattern > maxPatternLength then
        maxPatternLength = #listener.pattern
      end
    end

    if maxPatternLength < self.eventQueue:Length() then
      -- The queue starts with an event which no listener is interested in so we can safely remove it
      self.eventQueue:Remove(1)

      self:ProcessQueue()
    end
  end
end

function Machine:TransitionTo(stateFunction, ...)
  self.listeners = {}

  stateFunction(self, ...)
end

function Machine:OnEvent(pattern, callback)
  tinsert(self.listeners, {
    pattern = pattern,
    callback = callback,
  })
end

function Machine:HandleCancelPatterns(callback)
  self:OnEvent({ "TRADE_CLOSED", "TRADE_CLOSED", "TRADE_REQUEST_CANCEL" }, callback)
  self:OnEvent({ "TRADE_CLOSED", "TRADE_REQUEST_CANCEL" }, callback)
  self:OnEvent({ "TRADE_REQUEST_CANCEL", "TRADE_CLOSED", "TRADE_CLOSED" }, callback)
end

function Machine:HandleTradeCancellation()
  self:HandleCancelPatterns(function ()
    self:Finish(false)
  end)
end

function Machine:HandlePlayerItemChange()
  self:OnEvent({ "TRADE_PLAYER_ITEM_CHANGED" }, function (playerItemEvent)
    local tradeSlotIndex = playerItemEvent.args[1]

    self.playerItems[tradeSlotIndex] = GetTradePlayerItemLink(tradeSlotIndex)
  end)
end

function Machine:Start()
  self.tradeTarget = nil
  self.playerItems = {}

  self:OnEvent({ "TRADE_SHOW" }, function ()
    self.tradeTarget = GetUnitName("npc")

    self:TransitionTo(self.State0)
  end)

  self:OnEvent({ "TRADE_CLOSED" }, function ()
    self:TransitionTo(self.Finish, false)
  end)

  self:HandlePlayerItemChange()
end

function Machine:State0()
  self:HandleTradeCancellation()

  self:OnEvent({ "TRADE_ACCEPT_UPDATE" }, function (acceptEvent)
    local playerAccept, targetAccept = unpack(acceptEvent.args)

    if playerAccept == 1 then
      self:TransitionTo(self.State1)
    elseif targetAccept == 1 then
      self:TransitionTo(self.State2)
    end
  end)

  self:HandlePlayerItemChange()
end

function Machine:State1()
  self:HandleTradeCancellation()

  self:OnEvent({ "TRADE_ACCEPT_UPDATE" }, function (acceptEvent)
    local playerAccept = unpack(acceptEvent.args)

    if playerAccept == 0 then
      self:TransitionTo(self.State0)
    end
  end)

  self:OnEvent({ "TRADE_CLOSED", "TRADE_CLOSED" }, function ()
    self:TransitionTo(self.Finish, true)
  end)

  self:HandlePlayerItemChange()
end

function Machine:State2()
  self:HandleTradeCancellation()

  self:OnEvent({ "TRADE_ACCEPT_UPDATE" }, function (acceptEvent)
    local playerAccept, targetAccept = unpack(acceptEvent.args)

    if targetAccept == 0 then
      self:TransitionTo(self.State0)
    elseif playerAccept == 1 then
      self:TransitionTo(self.State3)
    end
  end)

  self:HandlePlayerItemChange()
end

function Machine:State3()
  self:OnEvent({ "TRADE_CLOSED", "TRADE_CLOSED" }, function ()
    self:TransitionTo(self.Finish, true)
  end)

  self:HandlePlayerItemChange()
end

function Machine:Finish(success)
  if success then
    self:HandleSuccessfulTrade()
  end

  self:TransitionTo(self.Start)
end

function Machine:HandleSuccessfulTrade()
  local activeRaid = DB:GetActiveRaid()

  if not activeRaid then
    return
  end

  for i, itemLink in pairs(self.playerItems) do
    if itemLink then
      local itemId = Util:GetItemIdFromItemLink(itemLink)
      local unassignedItem = DB:FindFirstUnassignedLootByItemId(activeRaid.id, itemId)

      if not unassignedItem then
        -- An unassigned item with the given item link could not be found
        -- so it's probably not part of the boss loot
        return
      end

      GUI:ShowAssignItemWindow(activeRaid.id, itemId, self.tradeTarget)
    end
  end
end

function TradeStateMachine:Create(eventQueue)
  local instance = {
    machine = Machine:Create(eventQueue),
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function TradeStateMachine:Start()
  self.machine:Start()
end
