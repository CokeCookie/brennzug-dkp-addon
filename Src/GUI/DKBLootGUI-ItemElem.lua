--[[-----------------------------------------------------------------------------
ItemElem Widget
Displays an item icon and name.
-------------------------------------------------------------------------------]]
local Type, Version = "ItemElem", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local max, select, pairs = math.max, select, pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: GameFontHighlightSmall

local function ReleaseTooltip(tooltip)
  tooltip:Hide()
  tooltip = nil
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
  ["OnAcquire"] = function(self)
    self.frame:SetHeight(30)

    self.textureFrame:SetPoint("LEFT", self.frame, "LEFT")
    self.textureFrame:SetWidth(30)
    self.textureFrame:SetHeight(30)

    self.texture:SetTexCoord(0, 1, 0, 1)
    self.texture:SetPoint("TOP", self.textureFrame, "TOP")
    self.texture:SetPoint("BOTTOM", self.textureFrame, "BOTTOM")
    self.texture:SetPoint("LEFT", self.textureFrame, "LEFT")
    self.texture:SetPoint("RIGHT", self.textureFrame, "RIGHT")
    self.texture:Show()
  
    self.label:SetJustifyH("LEFT")
    self.label:SetPoint("TOP", self.frame, "TOP")
    self.label:SetPoint("BOTTOM", self.frame, "BOTTOM")
    self.label:SetPoint("LEFT", self.frame, "LEFT", 35, 0)
    self.label:SetPoint("RIGHT", self.frame, "RIGHT")

    self:SetItem(nil)
  end,

  ["OnRelease"] = function(self)
  end,

  ["SetItem"] = function(self, itemLink)
    if self.tooltip then
      ReleaseTooltip(self.tooltip)
    end

    local itemTexture = GetItemIcon(itemLink)

    self.label:SetText(itemLink)
    self.texture:SetTexture(itemTexture)

    if itemLink then
      local realself = self

      self.textureFrame:SetScript("OnEnter", function ()
        realself.tooltip:SetOwner(self.textureFrame, "ANCHOR_CURSOR")
        realself.tooltip:SetHyperlink(itemLink)
        realself.tooltip:Show()
      end)
      self.textureFrame:SetScript("OnLeave", function ()
        realself.tooltip:Hide()
        realself.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
      end)
    end
  end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
  local num = AceGUI:GetNextWidgetNum(Type)
  local frame = CreateFrame("Frame", nil, UIParent)
  local textureFrame = CreateFrame("Frame", nil, frame)
  local texture = frame:CreateTexture(nil, "BACKGROUND")
  local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
  local tooltip = CreateFrame("GameTooltip", "DKBLootGUI-ItemElemTooltip" .. num, UIParent, "GameTooltipTemplate")

  -- create widget
  local widget = {
    label = label,
    textureFrame = textureFrame,
    texture = texture,
    frame = frame,
    tooltip = tooltip,
    type  = Type,
  }
  for method, func in pairs(methods) do
    widget[method] = func
  end

  return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
