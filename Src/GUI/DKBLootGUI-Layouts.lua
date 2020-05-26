local AceGUI = LibStub and LibStub("AceGUI-3.0", true)

--[[-----------------------------------------------------------------------------
Helper
-------------------------------------------------------------------------------]]
local function errorhandler(err)
  return geterrorhandler()(err)
end

local function safecall(func, ...)
  if func then
    return xpcall(func, errorhandler, ...)
  end
end

--[[-----------------------------------------------------------------------------
Layouts
-------------------------------------------------------------------------------]]
AceGUI:RegisterLayout("Flex", function(content, children)
  if #children == 0 then
    return
  end

  local width = content:GetWidth()
  local height = content:GetHeight()
  local rowDirection = content.obj:GetUserData("flexDirection") == "row"
  local remainingSpace = rowDirection and width or height
  local growingChildren = 0

  for index, child in pairs(children) do
    if child:GetUserData("flex") == "grow" then
      growingChildren = growingChildren + 1
    else
      if child.DoLayout then
        child:DoLayout()
      end

      local childSpace = rowDirection and child.frame:GetWidth() or child.frame:GetHeight()

      remainingSpace = remainingSpace - childSpace
    end
  end

  local remainingSpacePerChild = 0
  local offset = 0

  if growingChildren > 0 then
    remainingSpacePerChild = remainingSpace / growingChildren
  end

  for index, child in pairs(children) do
    if rowDirection then
      if child.type == "SimpleGroup" or child:GetUserData("flexAutoWidth") then
        child:SetHeight(height)
      end
      child.frame:SetPoint("LEFT", content, "LEFT", offset, 0)
    else
      if child.type == "SimpleGroup" or child:GetUserData("flexAutoWidth") then
        child:SetWidth(width)
      end
      child.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -offset)
    end

    if child:GetUserData("flex") == "grow" then
      if rowDirection then
        child:SetWidth(remainingSpacePerChild)
      else
        child:SetHeight(remainingSpacePerChild)
      end
    end
    child.frame:Show()

    local childSpace = rowDirection and child.frame:GetWidth() or child.frame:GetHeight()

    offset = offset + childSpace
  end
  
  if rowDirection then
    safecall(content.obj.LayoutFinished, content.obj, offset, nil)
  else
    safecall(content.obj.LayoutFinished, content.obj, nil, offset)
  end
end)
