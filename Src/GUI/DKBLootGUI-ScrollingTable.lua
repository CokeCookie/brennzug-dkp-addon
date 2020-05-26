--[[-----------------------------------------------------------------------------
DKBLootGUI-ScrollingTable
A scrollable table with content.
-------------------------------------------------------------------------------]]
local Type, Version = "DKBLootGUI-ScrollingTable", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
local AceHook = LibStub and LibStub("AceHook-3.0", true)
local ScrollingTable = LibStub("ScrollingTable")
local Util = DKBLootLoader:UseModule("Util")
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function UpdateScrollingTable(self, width)
  local columns = {}
  local availableWidth = (width or self.frame:GetWidth()) - 33
  local percentageWidth = availableWidth
  local remainingWidth = availableWidth

  for index, column in pairs(self.columns) do
    if column.width then
      percentageWidth = percentageWidth - column.width
    end
  end

  for index, column in pairs(self.columns) do
    local options = Util:TableShallowCopy(column)
    local width = Util:TablePull(options, "width")
    local percentage = Util:TablePull(options, "percentage")
    local minWidth = Util:TablePull(options, "minWidth")

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

  self.table:SetDisplayCols(columns)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function (self)
    self.table = ScrollingTable:CreateST({}, nil, nil, nil, self.frame)
    self.columns = {}

    self.table.frame:SetParent(self.frame)
    self.table.head:SetHeight(15)
    self.table.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -16)
    self.table.frame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, 3)

    local realself = self
    AceHook:Hook(self.table, "SetSelection", function (self, realrow)
      if self.fSelect and realself.selectionHandler then
        realself.selectionHandler(realrow)
      end
    end)
  end,

  ["OnRelease"] = function (self)
    self.table:Hide()
    self.table = nil
    self.columns = nil
  end,

  ["OnWidthSet"] = function (self, width)
    UpdateScrollingTable(self, width)
  end,

  ["OnHeightSet"] = function(self, height)
    local tableHeight = height - 19
    local rowHeight = self.table.rowHeight
    local numberOfRows = floor((tableHeight - 10) / rowHeight)

    if numberOfRows > 0 then
      self.table:SetDisplayRows(numberOfRows, rowHeight)
    end
  end,

  -- ["SetParent"] = function (self, parent)
  --   print("TEST")
  -- end,

  ["SetColumns"] = function (self, columns)
    self.columns = columns

    UpdateScrollingTable(self)
  end,

  ["SetData"] = function (self, data, isMinimalDataformat)
    self.table:SetData(data, isMinimalDataformat)
  end,

  ["SetSelectionHandler"] = function(self, handler)
    self.selectionHandler = handler
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
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local frame = CreateFrame("Frame", nil, UIParent)

  local widget = {
    frame = frame,
    table = nil,
    columns = {},
    type = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
