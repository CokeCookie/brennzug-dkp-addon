--[[-----------------------------------------------------------------------------
ScrollingTable
A scrollable table with content.
-------------------------------------------------------------------------------]]
local Type, Version = "DKBLootGUI-ScrollingTable", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local AceHook = LibStub and LibStub("AceHook-3.0", true)
local ScrollingTable = LibStub("ScrollingTable")
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[
   xpcall safecall implementation
]]
local xpcall = xpcall

local function errorhandler(err)
  return geterrorhandler()(err)
end

local function safecall(func, ...)
  if func then
    return xpcall(func, errorhandler, ...)
  end
end

AceGUI:RegisterLayout("FillScrollingTable", function(content, children)
  if children[1] then
    local width = content:GetWidth()

    children[1].frame:Show()

    safecall(content.obj.st.LayoutFinished, content.obj.st, width)
    safecall(content.obj.LayoutFinished, content.obj, nil, nil)
  end
end)

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function tpull(table, key)
  local value = table[key]

  table[key] = nil

  return value
end

local function shallowcopy(t)
  local copy = {}

  for key, value in pairs(t) do
    copy[key] = value
  end

  return copy
end

local function UpdateScrollingTable(self, width)
  if self.resizing then return end
  if self.table == nil then return end

  local columns = {}
  local availableWidth = (width or self.container.frame:GetWidth()) - 33
  local percentageWidth = availableWidth
  local remainingWidth = availableWidth

  for index = 1, #self.columns do
    local column = self.columns[index]

    if column.width then
      percentageWidth = percentageWidth - column.width
    end
  end

  for index, column in pairs(self.columns) do
    local options = shallowcopy(column)
    local width = tpull(options, "width")
    local percentage = tpull(options, "percentage")
    local minWidth = tpull(options, "minWidth")

    if index == #self.columns and remainingWidth > 0 then
      width = remainingWidth
    elseif percentage then
      width = percentageWidth * percentage
    end

    if column.minWidth and width < column.minWidth then
      width = column.minWidth
    end

    remainingWidth = remainingWidth - width

    columns[index] = {
      width = width,
    }

    for key, value in pairs(column) do
      columns[index][key] = value
    end
  end

  self.resizing = true
  self.table:SetDisplayCols(columns)
  self.resizing = nil
end

local tableId = 1

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    local table = ScrollingTable:CreateST({}, nil, nil, nil, self.frame)
    table.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    table.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -16)
    table.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 3)

    local realself = self
    AceHook:Hook(table, "SetSelection", function (self, realrow)
      if self.fSelect and realself.selectionHandler then
        realself.selectionHandler(realrow)
      end
    end)

    local tableWidget = AceGUI:RegisterAsWidget({
      frame = table.frame,
      type  = "ScrollingTable_" .. tableId
    })
    tableId = tableId + 1

    self.table = table
    self.container:AddChild(tableWidget)
  end,

  ["OnRelease"] = function(self)
    if self.table then
      self.table:Hide()
    end

    self.container:ReleaseChildren()
    self.columns = {}
    self.table = nil
  end,

  ["OnHeightSet"] = function(self, height)
    local tableHeight = height - 19
    local rowHeight = self.table.rowHeight
    local numberOfRows = floor((tableHeight - 10) / rowHeight)

    if numberOfRows > 0 then
      self.table:SetDisplayRows(numberOfRows, rowHeight)
    end
  end,

  ["SetColumns"] = function(self, columns)
    self.columns = columns

    UpdateScrollingTable(self)
  end,

  ["SetRowHeight"] = function(self, rowHeight)
    local tableHeight = self.frame:GetHeight() - 19
    local numberOfRows = floor((tableHeight - 10) / rowHeight)

    if numberOfRows <= 0 then
      numberOfRows = self.table.displayRows
    end

    for i = 1, #self.table.rows do
      local row = self.table.rows[i]

      row:Hide()

      for j = 1, #row.cols do
        local col = row.cols[j]
        
        col:Hide()
      end
    end

    self.table.rows = nil
    self.table:SetDisplayRows(numberOfRows, rowHeight)
  end,

  ["SetData"] = function (self, data, isMinimalDataformat)
    self.table:SetData(data, isMinimalDataformat)
  end,

  ["LayoutFinished"] = function(self, width)
    if self.table == nil then
      return
    end

    local height = self.table.frame:GetHeight()
    local numberOfRows = floor((height - 10) / self.table.rowHeight)

    if numberOfRows > 0 then
      self.table:SetDisplayRows(numberOfRows, self.table.rowHeight)
    end

    UpdateScrollingTable(self, width, height)
  end,

  ["SetSelectionHandler"] = function(self, handler)
    self.selectionHandler = handler
  end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local container = AceGUI:Create('SimpleGroup')

  local widget = {
    frame     = container.frame,
    container = container,
    columns   = {},
    type      = Type
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  container.st = widget
  container:SetLayout("FillScrollingTable")

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)



-- TODO: Make the code below work instead of the code above
-- Note: When using the code below, the table loses its anchor (sometimes) when shown for the second time
-- --[[-----------------------------------------------------------------------------
-- DKBLootGUI-ScrollingTable
-- A scrollable table with content.
-- -------------------------------------------------------------------------------]]
-- local Type, Version = "DKBLootGUI-ScrollingTable", 1
-- local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
-- local AceHook = LibStub and LibStub("AceHook-3.0", true)
-- local ScrollingTable = LibStub("ScrollingTable")
-- local Util = DKBLootLoader:UseModule("Util")
-- if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- --[[-----------------------------------------------------------------------------
-- Support functions
-- -------------------------------------------------------------------------------]]
-- local function UpdateScrollingTable(self, width)
--   local columns = {}
--   local availableWidth = (width or self.frame:GetWidth()) - 33
--   local percentageWidth = availableWidth
--   local remainingWidth = availableWidth

--   for index, column in pairs(self.columns) do
--     if column.width then
--       percentageWidth = percentageWidth - column.width
--     end
--   end

--   for index, column in pairs(self.columns) do
--     local options = Util:TableShallowCopy(column)
--     local width = Util:TablePull(options, "width")
--     local percentage = Util:TablePull(options, "percentage")
--     local minWidth = Util:TablePull(options, "minWidth")

--     if index == #self.columns and remainingWidth > 0 then
--       width = remainingWidth
--     elseif percentage then
--       width = percentageWidth * percentage
--     end

--     if column.minWidth and width < column.minWidth then
--       width = column.minWidth
--     end

--     remainingWidth = remainingWidth - width

--     columns[index] = {
--       width = width,
--     }

--     for key, value in pairs(column) do
--       columns[index][key] = value
--     end
--   end

--   self.table:SetDisplayCols(columns)
-- end

-- --[[-----------------------------------------------------------------------------
-- Methods
-- -------------------------------------------------------------------------------]]
-- local methods = {
--   ["OnAcquire"] = function (self)
--     local table = ScrollingTable:CreateST({}, nil, nil, nil, self.frame)

--     table.frame:SetParent(self.frame)
--     table.head:SetHeight(15)
--     table.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -16)
--     table.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 3)


--     local realself = self
--     AceHook:Hook(table, "SetSelection", function (self, realrow)
--       if self.fSelect and realself.selectionHandler then
--         realself.selectionHandler(realrow)
--       end
--     end)

--     self.table = table
--     self.columns = {}
--   end,

--   ["OnRelease"] = function (self)
--     self.table:Hide()
--     self.table = nil
--     self.columns = nil
--   end,

--   ["OnHeightSet"] = function(self, height)
--     local tableHeight = height - 19
--     local rowHeight = self.table.rowHeight
--     local numberOfRows = floor((tableHeight - 10) / rowHeight)

--     if numberOfRows > 0 then
--       self.table:SetDisplayRows(numberOfRows, rowHeight)
--     end
--   end,

--   ["SetWidth"] = function (self, width)
--     UpdateScrollingTable(self, width)
--   end,

--   ["SetColumns"] = function (self, columns)
--     self.columns = columns

--     UpdateScrollingTable(self)
--   end,

--   ["SetData"] = function (self, data, isMinimalDataformat)
--     self.table:SetData(data, isMinimalDataformat)
--   end,

--   ["SetSelectionHandler"] = function(self, handler)
--     self.selectionHandler = handler
--   end,

--   ["SetRowHeight"] = function(self, rowHeight)
--     local tableHeight = self.frame:GetHeight() - 19
--     local numberOfRows = floor((tableHeight - 10) / rowHeight)

--     if numberOfRows <= 0 then
--       numberOfRows = self.table.displayRows
--     end

--     for i = 1, #self.table.rows do
--       local row = self.table.rows[i]

--       row:Hide()

--       for j = 1, #row.cols do
--         local col = row.cols[j]
        
--         col:Hide()
--       end
--     end

--     self.table.rows = nil
--     self.table:SetDisplayRows(numberOfRows, rowHeight)
--   end,
-- }

-- --[[-----------------------------------------------------------------------------
-- Constructor
-- -------------------------------------------------------------------------------]]
-- local function Constructor()
--   local frame = CreateFrame("Frame", nil, UIParent)

--   local widget = {
--     frame = frame,
--     columns = {},
--     type = Type,
--   }
--   for method, func in pairs(methods) do
--     widget[method] = func
--   end

--   return AceGUI:RegisterAsWidget(widget)
-- end

-- AceGUI:RegisterWidgetType(Type, Constructor, Version)
