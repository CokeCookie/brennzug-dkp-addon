local EventQueue = DKBLootLoader:RegisterModule("EventQueue")

function EmitUpdateDebounced(self)
  if self.debounceTimer and not self.debounceTimer:IsCancelled() then
    self.debounceTimer:Cancel()
  end

  self.debounceTimer = C_Timer.NewTimer(self.debounce, function ()
    self.debounceTimer = nil

    for i, callback in pairs(self.listeners) do
      callback(self)
    end
  end)
end

function EventQueue:Create()
  local instance = {
    items = {},
    debounce = 0.5,
    debounceTimer = nil,
    listeners = {},
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function EventQueue:Push(event, ...)
  tinsert(self.items, {
    name = event,
    args = { ... },
  })

  EmitUpdateDebounced(self)
end

function EventQueue:GetItems()
  return self.items
end

function EventQueue:Length()
  return #self.items
end

function EventQueue:GetItem(index)
  return self.items[index]
end

function EventQueue:HasItems()
  return self:Length() > 0
end

function EventQueue:Remove(index)
  tremove(self.items, index)
end

function EventQueue:Consume(pattern)
  if #pattern > self:Length() then
    return nil
  end

  for i = 1, #pattern do
    if self.items[i].name ~= pattern[i] then
      return nil
    end
  end

  -- We've passed the first #pattern elements and they matched
  local events = {}

  for i = 1, #pattern do
    tinsert(events, tremove(self.items, 1))
  end

  return events
end

function EventQueue:OnUpdate(callback)
  tinsert(self.listeners, callback)
end

function EventQueue:ResetListeners()
  self.listeners = {}
end