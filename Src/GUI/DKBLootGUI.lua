local AceGUI = LibStub("AceGUI-3.0")
local LibJSON = LibStub("LibJSON-1.0")
local DB = DKBLootLoader:UseModule("DB")
local GUI = DKBLootLoader:RegisterModule("GUI")
local Util = DKBLootLoader:UseModule("Util")
local COLOR_RAID_ACTIVE = { ["r"] = 0.0, ["g"] = 1.0, ["b"] = 0.0, ["a"] = 1.0 }
local COLOR_RAID_FINISHED = { ["r"] = 1.0, ["g"] = 1.0, ["b"] = 1.0, ["a"] = 1.0 }

local TAB_1, TAB_2 = "tab1", "tab2"
local RAID_MC, RAID_ZG, RAID_BWL = "MOLTEN_CORE", "ZUL_GURUB", "BLACKWING_LAIR"
local mainFrame = nil
local mainFrameStatusTexts = {
  "Der Kreuzende Brennzug w\195\188nscht allzeit guten Loot!",
  "Dank geht raus an Cokecookie, Megumìn, Lothia, Ragnarrwall und Siedler!",
}
local mainFrameStatusTextIndex = 1
-- Tab 1
local importFrame = nil
-- Tab 2
local addRaidFrame = nil
local raidParticipantsFrame = nil
local addRaidParticipantFrame = nil
local raidEvaluationFrame = nil
local lootTableItemTooltip = CreateFrame("GameTooltip", "DKBLootGUI-LootTableTooltip", UIParent, "GameTooltipTemplate")
-- Generic
local confirmBoxFrame = nil

local classesMap = {
  {
    className = "Druide",
    classFile = "DRUID",
  },
  {
    className = "Hexenmeister",
    classFile = "WARLOCK",
  },
  {
    className = "J\195\164ger",
    classFile = "HUNTER",
  },
  {
    className = "Krieger",
    classFile = "WARRIOR",
  },
  {
    className = "Magier",
    classFile = "MAGE",
  },
  {
    className = "Paladin",
    classFile = "PALADIN",
  },
  {
    className = "Priester",
    classFile = "PRIEST",
  },
  {
    className = "Schamane",
    classFile = "SHAMAN",
  },
  {
    className = "Schurke",
    classFile = "ROGUE",
  },
}

local function CloseConfirmBox()
  if confirmBoxFrame then
    AceGUI:Release(confirmBoxFrame)
    confirmBoxFrame = nil
  end
end

local function ShowConfirmBox(title, text, confirmHandler)
  CloseConfirmBox()

  local frame = AceGUI:Create("CustomFrame")
  local label = AceGUI:Create("Label")

  frame:SetTitle(title)
  frame:SetLayout("Fill")
  frame:EnableResize(false)
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(260, 60)
  frame:SetCallback("OnOk", function ()
    confirmHandler()
    frame:Hide()
  end)
  frame:SetCallback("OnCancel", function () frame:Hide() end)
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
    confirmBoxFrame = nil
  end)

  label:SetText(text)
  frame:AddChild(label)
  frame:SetHeight(label.label:GetNumLines() + label.label:GetStringHeight() + 70)

  confirmBoxFrame = frame

  return frame
end

local function RenderImportDKPWindow(options)
  local frame = AceGUI:Create("CustomFrame")
  local editBox = AceGUI:Create("CustomMultiLineEditBox")
  local function handleSubmit()
    local success, err = pcall(function ()
      local lua = LibJSON.Deserialize(editBox:GetText())

      if not lua.brennzug then
        error("Komisches Format.")
      end

      DB:ImportDKPList(lua.brennzug)
    end)

    if not success then
      UIErrorsFrame:AddMessage("Fehler beim Laden der DKP-Liste.", 1.0, 0.0, 0.0, 1, 5)

      return false
    end

    frame:Hide()
  end

  frame:SetTitle("DKP-Liste importieren")
  frame:SetLayout("Fill")
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(560, 380)
  frame.frame:SetMaxResize(560, 380)
  frame:SetCallback("OnOk", handleSubmit)
  frame:SetCallback("OnCancel", function() frame:Hide() end)
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
    
    if options.onClose then
      options.onClose()
    end
  end)

  editBox:SetLabel("DKP-Liste")
  editBox:SetFocus()
  editBox.editbox:SetScript("OnEnterPressed", handleSubmit)
  frame:AddChild(editBox)

  return frame
end

local function RenderRaidEvaluationWindow(options)
  local frame = AceGUI:Create("CustomFrame")
  local editBox = AceGUI:Create("CustomMultiLineEditBox")

  frame:SetTitle("DKP-Ausertung")
  frame:SetLayout("Fill")
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(560, 380)
  frame.frame:SetMaxResize(560, 380)
  frame:SetCallback("OnOk", function ()
    ShowConfirmBox(
      "Wirklich abschlie\195\159en?",
      "Wenn du die Auswertung abschlie\195\159t, kannst du nachtr\195\164glich nix mehr \195\164ndern.",
      function ()
        DB:MarkRaidAsEvaluated(options.raidId)
      end
    )
  end)
  frame:SetCallback("OnCancel", function () frame:Hide() end)
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
    
    if options.onClose then
      options.onClose()
    end
  end)
  frame:SetOkButtonText("Raid endg\195\188ltig abschlie\195\159en")

  editBox:SetLabel("JSON-Code")
  editBox:SetText(options.json)
  editBox:SetFocus()
  editBox:HighlightText(0, #options.json)
  frame:AddChild(editBox)

  return frame
end

local function RenderAddRaidWindow(options)
  local frame = AceGUI:Create("CustomFrame")
  local dropdown = AceGUI:Create("Dropdown")
  local function handleSubmit()
    if DB:HasActiveRaid() then
      UIErrorsFrame:AddMessage("Es ist bereits eine andere Aufzeichnung aktiv.", 1.0, 0.0, 0.0, 1, 5)
      return
    end

    local raid = DB:AddRaid(dropdown:GetValue())

    DB:SetActiveRaid(raid.id)

    frame:Hide()

    if options.onSubmit then
      options.onSubmit()
    end
  end

  frame:SetTitle("Neue Aufzeichnung")
  frame:SetLayout("Fill")
  frame:EnableResize(false)
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(260, 120)
  frame:SetCallback("OnOk", handleSubmit)
  frame:SetCallback("OnCancel", function() frame:Hide() end)
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
    
    if options.onClose then
      options.onClose()
    end
  end)

  dropdown:SetLabel("Raid")
  dropdown:SetList({
    [DB.RAID_MC] = Util:GetRaidName(DB.RAID_MC),
    [DB.RAID_ZG] = Util:GetRaidName(DB.RAID_ZG),
    [DB.RAID_BWL] = Util:GetRaidName(DB.RAID_BWL),
  }, { DB.RAID_MC, DB.RAID_ZG, DB.RAID_BWL })
  dropdown:SetCallback("OnOpened", function ()
    dropdown.pullout:ClearAllPoints()
    dropdown.pullout:SetPoint("TOPLEFT", dropdown.frame, "BOTTOMLEFT", 0, 16)
  end)
  frame:AddChild(dropdown)

  local instanceId = select(8, GetInstanceInfo())
  local instanceIdValueMap = {
    [409] = DB.RAID_MC,
    [469] = DB.RAID_BWL,
    [309] = DB.RAID_ZG,
  }

  if instanceIdValueMap[instanceId] then
    dropdown:SetValue(instanceIdValueMap[instanceId])
  end

  return frame
end

local function RenderAddRaidParticipantWindow(options)
  local frame = AceGUI:Create("CustomFrame")
  local playerEditBox = AceGUI:Create("CustomEditBox")
  local groupEditBox = AceGUI:Create("CustomEditBox")
  local classDropdown = AceGUI:Create("Dropdown")
  local function handleSubmit()
    local player = playerEditBox:GetText()
    local group = groupEditBox:GetText()
    local classIndex = classDropdown:GetValue()

    if not player or not group or not classIndex then
      UIErrorsFrame:AddMessage("Bitte f\195\188lle alle Felder aus.", 1.0, 0.0, 0.0, 1, 5)

      return false
    end

    local classInfo = classesMap[classIndex]

    if not classInfo then
      UIErrorsFrame:AddMessage("Ung\195\188ltige Klasse.", 1.0, 0.0, 0.0, 1, 5)

      return false
    end

    DB:AddRaidParticipant(options.raid.id, {
      player = player,
      group = group,
      class = classInfo.className,
      classFile = classInfo.classFile,
    })
  end

  frame:SetTitle("Teilnehmer hinzuf\195\188gen")
  frame:SetLayout("Flex")
  frame:EnableResize(false)
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(260, 200)
  frame:SetCallback("OnOk", handleSubmit)
  frame:SetCallback("OnCancel", function() frame:Hide() end)
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
    
    if options.onClose then
      options.onClose()
    end
  end)

  playerEditBox:SetLabel("Spielername")
  playerEditBox:SetUserData("flexAutoWidth", true)
  playerEditBox.editbox:SetScript("OnEnterPressed", handleSubmit)
  frame:AddChild(playerEditBox)

  groupEditBox:SetLabel("Raidgruppe")
  groupEditBox:SetUserData("flexAutoWidth", true)
  groupEditBox.editbox:SetScript("OnEnterPressed", handleSubmit)
  frame:AddChild(groupEditBox)

  local classes = {}

  for i, classInfo in pairs(classesMap) do
    classes[i] = classInfo.className
  end

  classDropdown:SetLabel("Klasse")
  classDropdown:SetUserData("flexAutoWidth", true)
  classDropdown:SetList(classes)
  frame:AddChild(classDropdown)

  return frame
end

local function RenderRaidParticipantsWindow(options)
  local participantsSubscription = DB:Subscribe(DB.EVENT_PARTICIPANTS)

  local frame = AceGUI:Create("Frame")
  local participantsTableWrapper = AceGUI:Create("SimpleGroup")
  local participantsTable = AceGUI:Create("DKBLootGUI-ScrollingTable")
  local controlsContainer = AceGUI:Create("SimpleGroup")
  local addCurrentRaidButton = AceGUI:Create("Button")
  local addParticipantButton = AceGUI:Create("Button")
  local controlsSpacer = AceGUI:Create("SimpleGroup")
  local deleteParticipantButton = AceGUI:Create("Button")

  local raid = options.raid
  local title = format(
    "Teilnehmerliste - %s am %s",
    Util:GetRaidName(raid.raid),
    date("%d.%m.%Y", raid.timestamp)
  )

  local function UpdateParticipatsTable()
    local participants = DB:GetRaidParticipants(raid.id)
    local tableData = {}

    for i, participant in pairs(participants) do
      local playerDKP, hasPlayerDKP, hasLoot = DB:ComputeCurrentPlayerDKP(raid.id, participant.player)
      local playerColor = { r = 1, g = 1, b = 1 }
      local dkpColor = { r = 1, g = 1, b = 1 }

      if not hasPlayerDKP then
        playerColor = { r = 0, g = 1, b = 1 }
      end

      if playerDKP < 0 then
        dkpColor = { r = 1, g = 0, b = 0 }
      elseif hasLoot then
        dkpColor = { r = 1, g = 1, b = 0 }
      end

      tinsert(tableData, {
        cols = {
          { value = i, },
          { value = participant.player, color = playerColor },
          { value = participant.class, color = RAID_CLASS_COLORS[participant.classFile] },
          { value = participant.group },
          { value = playerDKP, color = dkpColor },
        }
      })
    end

    participantsTable:SetData(tableData)
  end

  frame:SetTitle(title)
  frame:SetLayout("Flex")
  frame:EnableResize(false)
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(500, 400)
  frame:SetCallback("OnClose", function (widget)
    participantsSubscription:Cancel()
    AceGUI:Release(widget)
    
    if options.onClose then
      options.onClose()
    end
  end)

  participantsTableWrapper:SetLayout("Fill")
  participantsTableWrapper:SetUserData("flex", "grow")
  frame:AddChild(participantsTableWrapper)

  participantsTable:SetColumns({
    { name = "#", width = 20 },
    { name = "Spieler", percentage = 0.6, minWidth = 80 },
    { name = "Klasse", percentage = 0.4 },
    { name = "Gruppe", width = 50 },
    { name = "DKP", width = 30 },
  })
  participantsTable.table:EnableSelection(true)
  participantsTable:SetSelectionHandler(function (realrow)
    deleteParticipantButton:SetDisabled(realrow == nil)
  end)
  participantsSubscription:OnData(UpdateParticipatsTable)
  participantsTableWrapper:AddChild(participantsTable)

  controlsContainer:SetLayout("Flex")
  controlsContainer:SetUserData("flexDirection", "row")
  controlsContainer:SetAutoAdjustHeight(false)
  controlsContainer:SetHeight(30)
  frame:AddChild(controlsContainer)

  addCurrentRaidButton:SetText("Aktuellen Raid erfassen")
  addCurrentRaidButton:SetAutoWidth(true)
  addCurrentRaidButton:SetCallback("OnClick", function ()
    DB:RegisterAllRaidMembersAsParticipants(raid.id)
  end)
  controlsContainer:AddChild(addCurrentRaidButton)

  addParticipantButton:SetText("Teilnehnmer hinzuf\195\188gen")
  addParticipantButton:SetAutoWidth(true)
  addParticipantButton:SetCallback("OnClick", function ()
    if addRaidParticipantFrame then
      return
    end

    addRaidParticipantFrame = RenderAddRaidParticipantWindow({
      raid = raid,
      onClose = function ()
        addRaidParticipantFrame = nil
      end,
    })
  end)
  controlsContainer:AddChild(addParticipantButton)

  controlsSpacer:SetUserData("flex", "grow")
  controlsContainer:AddChild(controlsSpacer)

  deleteParticipantButton:SetText("L\195\182schen")
  deleteParticipantButton:SetAutoWidth(true)
  deleteParticipantButton:SetDisabled(true)
  deleteParticipantButton:SetCallback("OnClick", function ()
    local participantsIndex = participantsTable.table and participantsTable.table:GetSelection() or nil

    if not participantsIndex then
      return
    end

    local participant = DB:GetRaidParticipantByIndex(raid.id, participantsIndex)

    ShowConfirmBox(
      "Spieler wirklich l\195\182schen?",
      "Willst du " .. participant.player .. " wirklich l\195\182schen?",
      function ()
        DB:DeleteRaidParticipantByIndex(raid.id, participantsIndex)
      end
    )
  end)
  controlsContainer:AddChild(deleteParticipantButton)

  UpdateParticipatsTable()

  return frame
end

local function RenderDKPSummaryTab(container)
  local subscription = DB:Subscribe(DB.EVENT_GUILD_DKP)

  local innerContainer = AceGUI:Create("SimpleGroup")
  local dkpTableWrapper = AceGUI:Create("SimpleGroup")
  local dkpTable = AceGUI:Create("DKBLootGUI-ScrollingTable")
  local controlsContainer = AceGUI:Create("SimpleGroup")
  local dkpImportButton = AceGUI:Create("Button")

  local function UpdateDKPTable()
    local activeRaid = DB:GetActiveRaid()
    local activeRaidName = activeRaid and activeRaid.raid or nil
    local guildDkp = DB:GetDKPList()
    local tableData = {}

    for i, entry in pairs(guildDkp) do
      local playerName, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline = Util:GetGuildMemberInfo(entry.player)
      local status
      local statusColor

      if not playerName then
        status = "Nicht gefunden"
        statusColor = { r = 1, g = 0, b = 0 }
      elseif UnitInRaid(playerName) then
        status = "In deinem Raid"
        statusColor = { r = 0, g = 1, b = 1 }
      elseif not isOnline and not UnitIsConnected(playerName) then
        status = "Offline"
        statusColor = { r = 0.5, g = 0.5, b = 0.5 }
      else
        status = "Online"
        statusColor = { r = 0, g = 1, b = 0 }
      end

      tableData[i] = {
        cols = {
          {
            value = entry.player,
            color = GetUnitName("player") == playerName and { r = 0, g = 1, b = 0 } or nil,
          },
          {
            value = status,
            color = statusColor,
          },
          {
            value = entry.dkp[DB.RAID_MC],
            color = activeRaidName == DB.RAID_MC and COLOR_RAID_ACTIVE or nil,
          },
          {
            value = entry.dkp[DB.RAID_BWL],
            color = activeRaidName == DB.RAID_BWL and COLOR_RAID_ACTIVE or nil,
          },
          {
            value = entry.dkp[DB.RAID_ZG],
            color = activeRaidName == DB.RAID_ZG and COLOR_RAID_ACTIVE or nil,
          },
        },
      }
    end

    dkpTable:SetData(tableData)
  end

  local function HandleEvent(event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
      UpdateDKPTable()
    end
  end

  container.frame:RegisterEvent("GUILD_ROSTER_UPDATE")
  container.frame:SetScript("OnEvent", HandleEvent)

  innerContainer:SetLayout("Flex")
  innerContainer.frame:SetScript("OnHide", function ()
    subscription:Cancel()
  end)
  container:AddChild(innerContainer)

  dkpTableWrapper:SetLayout("Fill")
  dkpTableWrapper:SetUserData("flex", "grow")
  innerContainer:AddChild(dkpTableWrapper)

  dkpTable:SetColumns({
    { name = "Spieler", percentage = 1, minWidth = 80 },
    { name = "Status", width = 100 },
    { name = "MC", width = 30 },
    { name = "BWL", width = 30 },
    { name = "ZG", width = 30 },
  })
  subscription:OnData(UpdateDKPTable)
  dkpTableWrapper:AddChild(dkpTable)

  controlsContainer:SetAutoAdjustHeight(false)
  controlsContainer:SetHeight(30)
  controlsContainer:SetLayout("Flow")
  innerContainer:AddChild(controlsContainer)

  dkpImportButton:SetText("Importieren")
  dkpImportButton:SetAutoWidth(true)
  dkpImportButton:SetCallback("OnClick", function ()
    if importFrame then
      return
    end

    importFrame = RenderImportDKPWindow({
      onClose = function ()
        importFrame = nil
      end,
    })
  end)
  controlsContainer:AddChild(dkpImportButton)

  UpdateDKPTable()
end

local function RenderRaidTab(container)
  local raidsSubscription = DB:Subscribe(DB.EVENT_RAIDS)
  local lootSubscription = DB:Subscribe(DB.EVENT_LOOT)

  local innerContainer = AceGUI:Create("SimpleGroup")

  local raidsColumn = AceGUI:Create("SimpleGroup")
  local raidsTableWrapper = AceGUI:Create("SimpleGroup")
  local raidsTable = AceGUI:Create("DKBLootGUI-ScrollingTable")
  local raidControls = AceGUI:Create("SimpleGroup")
  local addRaidButton = AceGUI:Create("Button")
  local raidControlsSpacer = AceGUI:Create("SimpleGroup")
  local deleteRaidButton = AceGUI:Create("Button")

  local columnSpacer = AceGUI:Create("SimpleGroup")

  local lootColumn = AceGUI:Create("SimpleGroup")
  local lootTableWrapper = AceGUI:Create("SimpleGroup")
  local lootTable = AceGUI:Create("DKBLootGUI-ScrollingTable")
  local lootControls = AceGUI:Create("SimpleGroup")

  local function UpdateFinishOrEvaluateRaidButton(row)
    local raid = DB:GetRaidByIndex(row)

    lootControls:ReleaseChildren()

    if not raid or raid.evaluated then
      return
    end

    local participantsButton = AceGUI:Create("Button")
    local lootControlsSpacer = AceGUI:Create("SimpleGroup")
    local finishOrEvaluateRaidButton = AceGUI:Create("Button")

    participantsButton:SetText("Teilnehmer")
    participantsButton:SetCallback("OnClick", function ()
      local x, y

      if raidParticipantsFrame then
        raidParticipantsFrame:Hide()
        raidParticipantsFrame = nil
      end

      if not raidsTable.table then
        return
      end

      local raid = DB:GetRaidByIndex(raidsTable.table:GetSelection())

      if not raid then
        return
      end

      raidParticipantsFrame = RenderRaidParticipantsWindow({
        raid = raid,
      })
    end)
    participantsButton:SetAutoWidth(true)
    lootControls:AddChild(participantsButton)

    lootControlsSpacer:SetUserData("flex", "grow")
    lootControls:AddChild(lootControlsSpacer)

    if DB:IsActiveRaidId(raid.id) then
      finishOrEvaluateRaidButton:SetText("Aufzeichnung beenden")
      finishOrEvaluateRaidButton:SetCallback("OnClick", function ()
        local selection = raidsTable.table:GetSelection()

        if not selection then
          return
        end

        ShowConfirmBox(
          "Aufzeichnung wirklich beenden?",
          "Wenn die Aufzeichnung beendet wurde, kann die Lootliste nachtr\195\164glich nicht mehr ge\195\164ndert werden.",
          function ()
            DB:StopActiveRaid()
          end
        )
      end)
    else
      finishOrEvaluateRaidButton:SetText("DKP-Auswertung")
      finishOrEvaluateRaidButton:SetCallback("OnClick", function ()
        if raidEvaluationFrame then
          return
        end

        local raid = DB:GetRaidByIndex(raidsTable.table:GetSelection())

        if not raid then
          return
        end

        local json = DB:EvaluateRaidById(raid.id)

        raidEvaluationFrame = RenderRaidEvaluationWindow({
          raidId = raid.id,
          json = json,
          onClose = function ()
            raidEvaluationFrame = nil
          end,
        })
      end)
    end

    finishOrEvaluateRaidButton:SetAutoWidth(true)
    lootControls:AddChild(finishOrEvaluateRaidButton)
  end

  local function UpdateRaidsTable()
    local raids = DB:GetRaids()
    local tableData = {}

    for i, raid in pairs(raids) do
      local color = DB:IsActiveRaidId(raid.id) and COLOR_RAID_ACTIVE or COLOR_RAID_FINISHED
      local name = Util:GetRaidName(raid.raid)

      tableData[i] = {
        cols = {
          {
            value = date("%d.%m.%Y", raid.timestamp),
          },
          {
            value = name,
          },
        },
        color = color,
      }
    end

    raidsTable:SetData(tableData)

    if #raids > 0 then
      if not raidsTable.table:GetSelection() then
        raidsTable.table:SetSelection(1)
      end
    else
      raidsTable.table:ClearSelection()
      UpdateFinishOrEvaluateRaidButton(raidsTable.table:GetSelection())
    end
  end

  local function UpdateLootTable(row)
    local raidIndex = row
    local raid = DB:GetRaidByIndex(raidIndex)

    if not raid then
      lootTable:SetData({}, true)
      return
    end

    local tableData = {}

    for i, entry in pairs(raid.loot) do
      local itemName, itemLink = GetItemInfo(entry.itemId)

      tableData[i] = {
        entry.itemId,
        itemLink,
        entry.sourceName or entry.sourceGUID,
        entry.givenTo and entry.givenTo.player or "",
        entry.givenTo and entry.givenTo.dkp or "",
      }
    end

    lootTable:SetData(tableData, true)
  end

  innerContainer:SetLayout("Flex")
  innerContainer:SetUserData("flexDirection", "row")
  innerContainer.frame:SetScript("OnHide", function ()
    raidsSubscription:Cancel()
    lootSubscription:Cancel()
  end)
  container:AddChild(innerContainer)

  -- 1st Column
  raidsColumn:SetLayout("Flex")
  raidsColumn:SetWidth(180)
  innerContainer:AddChild(raidsColumn)

  raidsTableWrapper:SetLayout("Fill")
  raidsTableWrapper:SetUserData("flex", "grow")
  raidsColumn:AddChild(raidsTableWrapper)

  raidsTable:SetColumns({
    { name = "Datum", width = 64 },
    { name = "Raid", percentage = 1, minWidth = 80 },
  })
  raidsTable.table:EnableSelection(true)
  raidsTable:SetSelectionHandler(function (realrow)
    UpdateLootTable(realrow)
    UpdateFinishOrEvaluateRaidButton(realrow)

    deleteRaidButton:SetDisabled(realrow == nil)
  end)
  raidsSubscription:OnData(UpdateRaidsTable)
  raidsTableWrapper:AddChild(raidsTable)

  raidControls:SetLayout("Flex")
  raidControls:SetUserData("flexDirection", "row")
  raidControls:SetAutoAdjustHeight(false)
  raidControls:SetHeight(30)
  raidsColumn:AddChild(raidControls)

  addRaidButton:SetText("Neu")
  addRaidButton:SetAutoWidth(true)
  addRaidButton:SetCallback("OnClick", function ()
    if addRaidFrame then
      return
    end

    addRaidFrame = RenderAddRaidWindow({
      onSubmit = function ()
        raidsTable.table:SetSelection(1)
      end,
      onClose = function ()
        addRaidFrame = nil
      end,
    })
  end)
  raidControls:AddChild(addRaidButton)

  raidControlsSpacer:SetUserData("flex", "grow")
  raidControls:AddChild(raidControlsSpacer)

  deleteRaidButton:SetText("L\195\182schen")
  deleteRaidButton:SetAutoWidth(true)
  deleteRaidButton:SetDisabled(true)
  deleteRaidButton:SetCallback("OnClick", function ()
    local selection = raidsTable.table:GetSelection()

    if not selection then
      return
    end

    ShowConfirmBox(
      "Aufzeichnung wirklich l\195\182schen?",
      "Diese Aktion kann nicht r\195\188ckg\195\164ngig gemacht werden.",
      function ()
        raidsTable.table:ClearSelection()
        DB:DeleteRaidByIndex(selection)
      end
    )
  end)
  raidControls:AddChild(deleteRaidButton)

  -- Spacer
  columnSpacer:SetWidth(10)
  innerContainer:AddChild(columnSpacer)

  -- 2nd Column
  lootColumn:SetLayout("Flex")
  lootColumn:SetUserData("flex", "grow")
  innerContainer:AddChild(lootColumn)

  lootTableWrapper:SetLayout("Fill")
  lootTableWrapper:SetUserData("flex", "grow")
  lootColumn:AddChild(lootTableWrapper)

  lootTable:SetColumns({
    {
      name = "Item",
      width = 32,
      DoCellUpdate = function (rowFrame, cellFrame, data, cols, row, realrow, column, fShow, self, ...)
        local itemId = self:GetCell(realrow, column)
        local itemName, itemLink = GetItemInfo(itemId)

        if fShow then
          local itemTexture = GetItemIcon(itemId)

          if not cellFrame.cellItemTexture then
            cellFrame.cellItemTexture = cellFrame:CreateTexture()
          end

          cellFrame.cellItemTexture:SetTexture(itemTexture)
          cellFrame.cellItemTexture:SetTexCoord(0, 1, 0, 1)
          cellFrame.cellItemTexture:Show()
          cellFrame.cellItemTexture:SetPoint("LEFT", cellFrame.cellItemTexture:GetParent(), "LEFT")
          cellFrame.cellItemTexture:SetWidth(30)
          cellFrame.cellItemTexture:SetHeight(30)
        end

        if itemLink then
          cellFrame:SetScript("OnEnter", function()
            lootTableItemTooltip:SetOwner(cellFrame, "ANCHOR_CURSOR")
            lootTableItemTooltip:SetHyperlink(itemLink)
            lootTableItemTooltip:Show()
          end)
          cellFrame:SetScript("OnLeave", function()
             lootTableItemTooltip:Hide()
             lootTableItemTooltip:SetOwner(UIParent, "ANCHOR_NONE")
           end)
        end
      end,
    },
    { name = "", percentage = 0.6 },
    { name = "Gepl\195\188ndert von", percentage = 0.4 },
    { name = "Spieler", width = 80 },
    { name = "DKP", width = 30 },
  })
  lootTable:SetRowHeight(30)
  lootTable.table:RegisterEvents({
    ["OnDoubleClick"] = function (rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
      if column == 4 or column == 5 then
        local selectedRaidIndex = raidsTable.table:GetSelection()
        local raid = DB:GetRaidByIndex(selectedRaidIndex)
        local entry = DB:GetRaidLootByIndex(raid.id, realrow)

        if not entry then
          return
        end
        
        GUI:ShowAssignItemWindow(
          raid.id,
          entry.itemId,
          entry.givenTo and entry.givenTo.player or nil,
          entry.givenTo and entry.givenTo.dkp or nil,
          realrow,
          column
        )
      end
    end,
  })
  lootSubscription:OnData(function () UpdateLootTable(raidsTable.table:GetSelection()) end)
  container.frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  container:SetCallback("OnClose", function ()
    container.frame:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
  end)
  container.frame:SetScript("OnEvent", function ()
    if raidsTable and raidsTable.table then
      UpdateLootTable(raidsTable.table:GetSelection())
    end
  end)
  lootTableWrapper:AddChild(lootTable)

  lootControls:SetLayout("Flex")
  lootControls:SetUserData("flexDirection", "row")
  lootControls:SetAutoAdjustHeight(false)
  lootControls:SetHeight(30)
  lootColumn:AddChild(lootControls)

  UpdateRaidsTable()
  UpdateLootTable(raidsTable.table:GetSelection())
end

function GUI:ShowAssignItemWindow(raidId, itemId, playerName, dkp, itemIndex, column)
  local frame = AceGUI:Create("CustomFrame")
  local itemLabel = AceGUI:Create("Label")
  local itemContainer = AceGUI:Create("SimpleGroup")
  local itemElem = AceGUI:Create("ItemElem")
  local inputContainer = AceGUI:Create("SimpleGroup")
  local playerInput = AceGUI:Create("CustomEditBox")
  local dkpInput = AceGUI:Create("CustomEditBox")
  local itemName, itemLink = GetItemInfo(itemId)
  local function handleSubmit()
    local dkp = dkpInput:GetText()

    if not dkp:match("%d*") then
      UIErrorsFrame:AddMessage("Bitte gib eine Zahl ein.", 1.0, 0.0, 0.0, 1, 5)
      dkpInput:HighlightText(0, #dkp)
      return
    end

    DB:RegisterPlayerItemDKP(raidId, itemId, playerInput:GetText(), dkp, itemIndex)

    frame:Hide()
  end

  frame:SetTitle("DKP Eingabe")
  frame:SetLayout("Flow")
  frame:EnableResize(false)
  frame.frame:SetFrameStrata("HIGH")
  frame.frame:SetSize(300, 160)
  frame:SetCallback("OnOk", handleSubmit)
  frame:SetCallback("OnCancel", function() frame:Hide() end)
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
  end)

  itemLabel:SetText("Item")
  itemLabel:SetColor(1, 0.82, 0)
  frame:AddChild(itemLabel)

  itemContainer:SetLayout("Fill")
  itemContainer:SetHeight(30)
  itemContainer:SetAutoAdjustHeight(false)
  frame:AddChild(itemContainer)

  itemElem:SetItem(itemLink)
  itemContainer:AddChild(itemElem)

  inputContainer:SetLayout("Flex")
  inputContainer:SetHeight(40)
  inputContainer:SetAutoAdjustHeight(false)
  inputContainer:SetUserData("flexDirection", "row")
  frame:AddChild(inputContainer)

  local playerList = {}

  for i, participant in pairs(DB:GetRaidParticipants(raidId)) do
    playerList[#playerList + 1] = participant.player
  end

  playerInput:SetLabel("Spieler")
  playerInput:SetSuggestions(playerList)
  playerInput:SetUserData("flex", "grow")
  playerInput:SetText(playerName)
  playerInput.editbox:SetScript("OnTabPressed", function () dkpInput:SetFocus() end)
  playerInput.editbox:SetScript("OnEnterPressed", handleSubmit)
  inputContainer:AddChild(playerInput)

  dkpInput:SetLabel("DKP")
  dkpInput:SetWidth(80)
  dkpInput:SetText(dkp)
  dkpInput.editbox:SetScript("OnTabPressed", function () playerInput:SetFocus() end)
  dkpInput.editbox:SetScript("OnEnterPressed", handleSubmit)
  inputContainer:AddChild(dkpInput)

  if not IsPlayerMoving() then
    if column == nil or column == 4 then
      playerInput:SetFocus()
      playerInput:HighlightText(0, #playerInput:GetText())
    elseif column == 5 then
      dkpInput:SetFocus()
      dkpInput:HighlightText(0, #dkpInput:GetText())
    end
  end

  return frame
end

function GUI:Show(self)
  if mainFrame then
    mainFrame:Hide()
    mainFrame = nil
    return
  end

  local frame = AceGUI:Create("Frame")
  local tab = AceGUI:Create("TabGroup")

  frame:SetTitle("Der Kreuzende Brennzug - Loot")
  frame:SetStatusText(mainFrameStatusTexts[mainFrameStatusTextIndex])
  frame:SetCallback("OnClose", function (widget)
    AceGUI:Release(widget)
    mainFrame = nil
  end)
  frame:SetLayout("Fill")
  frame.frame:SetSize(700, 503) -- Measured to fit 11 items in the item table
  frame.frame:SetFrameStrata("MEDIUM")
  frame.frame:SetMinResize(600, 400)

  tab:SetLayout("Fill")
  tab:SetTabs({
    { text = "DKP-\195\156bersicht", value = TAB_1 },
    { text = "Raids", value = TAB_2 },
  })
  tab:SetCallback("OnGroupSelected", function (container, event, group)
   container:ReleaseChildren()

    if confirmBoxFrame then
      confirmBoxFrame:Hide()
    end

   if group == TAB_1 then
      if addRaidFrame then
        addRaidFrame:Hide()
      end
      if raidParticipantsFrame then
        raidParticipantsFrame:Hide()
      end
      if addRaidParticipantFrame then
        addRaidParticipantFrame:Hide()
      end
      if raidEvaluationFrame then
        raidEvaluationFrame:Hide()
      end

      RenderDKPSummaryTab(container)
   elseif group == TAB_2 then
      if importFrame then
        importFrame:Hide()
      end

      RenderRaidTab(container)
   end
  end)
  tab:SelectTab(TAB_1)

  frame:AddChild(tab)

  mainFrame = frame
  mainFrameStatusTextIndex = (mainFrameStatusTextIndex % #mainFrameStatusTexts) + 1
end
