DKBLootLoader = {}

local modules = {}

local function CreateEmptyModule()
  return {}
end

function DKBLootLoader:RegisterModule(name)
  if not modules then
    modules = {}
  end

  if not modules[name] then
    modules[name] = CreateEmptyModule()
  end

  return modules[name]
end

function DKBLootLoader:UseModule(name)
  if not modules then
    modules = {}
  end

  if not modules[name] then
    modules[name] = CreateEmptyModule()
  end

  return modules[name]
end
