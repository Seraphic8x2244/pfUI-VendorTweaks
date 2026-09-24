-- pfUI VendorTweaks development controls
-- Dev branch only. Remove this file and its TOC entry for stable releases.

if not pfUI then return end

local bin = getglobal("pfUI_VendorTweaks_Bin")
if not bin
  or not bin.GetTuningOffsets
  or not bin.SetTuningOffsets
  or not bin.PlayPreview
  or not bin.GetDebugFireFrameCount
  or not bin.GetDebugDefaultDurationMs
  or not bin.SetDebugFireTimeline then
  return
end

local function D_(key)
  if pfUI.env and pfUI.env.T and pfUI.env.T[key] then
    return pfUI.env.T[key]
  end
  if pfUI_translation and pfUI_translation.enUS and pfUI_translation.enUS[key] then
    return pfUI_translation.enUS[key]
  end
  return key
end

local function ApplyBackdrop(target)
  target:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  target:SetBackdropColor(0, 0, 0, .9)
end

local function MakeButton(parent, text, width, x, y, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(22)
  button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  button:SetText(text)
  button:SetScript("OnClick", onClick)
  return button
end

-- ---------------------------------------------------------------------------
-- Shared authoring state
-- ---------------------------------------------------------------------------
local TIMELINE_MS = 2000
local RULER_WIDTH = 570
local snapOptions = { 10, 15, 20, 25, 30, 35, 40, 45, 50 }
local snapMs = 25
local frameCount = bin:GetDebugFireFrameCount()
local defaultDurationMs = bin:GetDebugDefaultDurationMs()
local markerTimes = {}
local endTimeMs = defaultDurationMs
local markers = {}
local endMarker = nil
local selectedMarker = 1
local activeMarker = nil

local function BuildDefaultTimeline()
  markerTimes = {}
  for i = 1, frameCount do
    markerTimes[i] = math.floor((((i - 1) * defaultDurationMs) / frameCount) + .5)
  end
  endTimeMs = defaultDurationMs
end

local function ApplyTimeline()
  return bin:SetDebugFireTimeline(markerTimes, endTimeMs)
end

local function TimelineString()
  local parts = {}
  for i = 1, frameCount do
    table.insert(parts, "F" .. i .. "=" .. markerTimes[i])
  end
  table.insert(parts, D_("VT_DEBUG_END") .. "=" .. endTimeMs)
  return table.concat(parts, " ")
end

-- ---------------------------------------------------------------------------
-- Position controls window
-- ---------------------------------------------------------------------------
local frame = CreateFrame("Frame", "pfUI_VendorTweaks_Debug", UIParent)
frame:SetWidth(350)
frame:SetHeight(205)
frame:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
frame:SetFrameStrata("DIALOG")
ApplyBackdrop(frame)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText(D_("VT_DEBUG_TITLE"))

local closeMain = MakeButton(frame, "x", 20, 324, -5, function()
  frame:Hide()
end)

local controls = {}

local function GetOffsets()
  return bin:GetTuningOffsets()
end

local function SetOffset(index, value)
  local ix, iy, fx, fy = GetOffsets()
  if index == 1 then ix = value
  elseif index == 2 then iy = value
  elseif index == 3 then fx = value
  else fy = value end
  bin:SetTuningOffsets(ix, iy, fx, fy)
end

local function RefreshOffsets()
  local ix, iy, fx, fy = GetOffsets()
  local values = { ix, iy, fx, fy }
  for i = 1, 4 do
    if controls[i] and controls[i].edit then
      controls[i].edit:SetText(tostring(values[i]))
    end
  end
end

local function MakeOffsetRow(index, labelText, y)
  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetWidth(55)
  label:SetJustifyH("LEFT")
  label:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, y)
  label:SetText(labelText)

  local minus = MakeButton(frame, "-", 24, 72, y + 4, function()
    local ix, iy, fx, fy = GetOffsets()
    local values = { ix, iy, fx, fy }
    SetOffset(index, values[index] - 1)
    RefreshOffsets()
  end)

  local edit = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  edit:SetWidth(58)
  edit:SetHeight(20)
  edit:SetPoint("LEFT", minus, "RIGHT", 8, 0)
  edit:SetAutoFocus(false)
  edit:SetJustifyH("CENTER")
  edit:SetScript("OnEnterPressed", function()
    local value = tonumber(this:GetText())
    if value then SetOffset(index, value) end
    this:ClearFocus()
    RefreshOffsets()
  end)
  edit:SetScript("OnEscapePressed", function()
    this:ClearFocus()
    RefreshOffsets()
  end)

  local plus = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  plus:SetWidth(24)
  plus:SetHeight(22)
  plus:SetPoint("LEFT", edit, "RIGHT", 8, 0)
  plus:SetText("+")
  plus:SetScript("OnClick", function()
    local ix, iy, fx, fy = GetOffsets()
    local values = { ix, iy, fx, fy }
    SetOffset(index, values[index] + 1)
    RefreshOffsets()
  end)

  controls[index] = { edit = edit }
end

-- ---------------------------------------------------------------------------
-- Timeline window
-- ---------------------------------------------------------------------------
local timeline = CreateFrame("Frame", "pfUI_VendorTweaks_DebugTimeline", UIParent)
timeline:SetWidth(650)
timeline:SetHeight(190)
timeline:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
timeline:SetFrameStrata("DIALOG")
ApplyBackdrop(timeline)
timeline:EnableMouse(true)
timeline:SetMovable(true)
timeline:RegisterForDrag("LeftButton")
timeline:SetScript("OnDragStart", function() this:StartMoving() end)
timeline:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

local timelineTitle = timeline:CreateFontString(nil, "OVERLAY", "GameFontNormal")
timelineTitle:SetPoint("TOP", timeline, "TOP", 0, -10)
timelineTitle:SetText(D_("VT_DEBUG_TIMELINE_TITLE"))

local closeTimeline = MakeButton(timeline, "x", 20, 624, -5, function()
  timeline:Hide()
end)

local snapLabel = timeline:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
snapLabel:SetPoint("TOPLEFT", timeline, "TOPLEFT", 12, -38)
snapLabel:SetText(D_("VT_DEBUG_SNAP") .. ":")

local selectedText = timeline:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
selectedText:SetPoint("TOPRIGHT", timeline, "TOPRIGHT", -74, -38)
selectedText:SetJustifyH("RIGHT")

local snapButtons = {}

local function RefreshSnapButtons()
  for i = 1, table.getn(snapButtons) do
    local button = snapButtons[i]
    if button.snapValue == snapMs then
      button:SetText("[" .. button.snapValue .. "]")
    else
      button:SetText(tostring(button.snapValue))
    end
  end
end

for i = 1, table.getn(snapOptions) do
  local value = snapOptions[i]
  local button = MakeButton(timeline, tostring(value), 34, 50 + ((i - 1) * 36), -31, function()
    snapMs = this.snapValue
    RefreshSnapButtons()
  end)
  button.snapValue = value
  table.insert(snapButtons, button)
end

local ruler = CreateFrame("Frame", nil, timeline)
ruler:SetWidth(RULER_WIDTH)
ruler:SetHeight(68)
ruler:SetPoint("TOPLEFT", timeline, "TOPLEFT", 40, -82)

local baseline = ruler:CreateTexture(nil, "ARTWORK")
baseline:SetWidth(RULER_WIDTH)
baseline:SetHeight(1)
baseline:SetPoint("CENTER", ruler, "CENTER", 0, 0)
baseline:SetTexture(.65, .65, .65, 1)

for ms = 0, TIMELINE_MS, 100 do
  local x = (ms / TIMELINE_MS) * RULER_WIDTH
  local tick = ruler:CreateTexture(nil, "ARTWORK")
  tick:SetWidth(1)
  if math.mod(ms, 500) == 0 then
    tick:SetHeight(20)
  else
    tick:SetHeight(10)
  end
  tick:SetPoint("CENTER", ruler, "LEFT", x, 0)
  tick:SetTexture(.65, .65, .65, 1)

  if math.mod(ms, 500) == 0 then
    local label = ruler:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOP", ruler, "LEFT", x, -12)
    label:SetText(ms .. " ms")
  end
end

local function TimeToX(ms)
  return (ms / TIMELINE_MS) * RULER_WIDTH
end

local function MarkerName(index)
  if index > frameCount then
    return D_("VT_DEBUG_END")
  end
  return "F" .. index
end

local function MarkerTime(index)
  if index > frameCount then
    return endTimeMs
  end
  return markerTimes[index]
end

local function RefreshSelection()
  selectedText:SetText(string.format(D_("VT_DEBUG_SELECTED"), MarkerName(selectedMarker), MarkerTime(selectedMarker)))

  for i = 1, table.getn(markers) do
    if markers[i].highlight then
      if i == selectedMarker then
        markers[i].highlight:Show()
      else
        markers[i].highlight:Hide()
      end
    end
  end

  if endMarker and endMarker.highlight then
    if selectedMarker > frameCount then
      endMarker.highlight:Show()
    else
      endMarker.highlight:Hide()
    end
  end
end

local function RefreshMarkerPositions()
  for i = 1, frameCount do
    local marker = markers[i]
    marker:ClearAllPoints()
    marker:SetPoint("CENTER", ruler, "LEFT", TimeToX(markerTimes[i]), 0)
  end

  if endMarker then
    endMarker:ClearAllPoints()
    endMarker:SetPoint("CENTER", ruler, "LEFT", TimeToX(endTimeMs), 0)
  end

  RefreshSelection()
end

local function SetMarkerTime(index, value)
  if value < 0 then value = 0 end
  if value > TIMELINE_MS then value = TIMELINE_MS end

  if index <= frameCount then
    local previous = -1
    local following = endTimeMs

    if index > 1 then previous = markerTimes[index - 1] end
    if index < frameCount then following = markerTimes[index + 1] end

    if value <= previous or value >= following then
      return false
    end

    if markerTimes[index] == value then return true end
    markerTimes[index] = value
  else
    if value <= markerTimes[frameCount] then
      return false
    end

    if endTimeMs == value then return true end
    endTimeMs = value
  end

  ApplyTimeline()
  RefreshMarkerPositions()
  return true
end

local function SnapTime(value)
  return math.floor((value / snapMs) + .5) * snapMs
end

local TimelineOnUpdate = nil

local function MakeMarker(index, text)
  local marker = CreateFrame("Button", nil, ruler)
  marker:SetWidth(18)
  marker:SetHeight(46)
  marker.markerIndex = index

  local highlight = marker:CreateTexture(nil, "BACKGROUND")
  highlight:SetAllPoints(marker)
  highlight:SetTexture(.25, .25, .25, .7)
  highlight:Hide()
  marker.highlight = highlight

  local line = marker:CreateTexture(nil, "OVERLAY")
  line:SetWidth(2)
  line:SetHeight(34)
  line:SetPoint("CENTER", marker, "CENTER", 0, 0)
  line:SetTexture(1, .72, .2, 1)

  local label = marker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("BOTTOM", marker, "TOP", 0, -5)
  label:SetText(text)

  marker:SetScript("OnMouseDown", function()
    selectedMarker = this.markerIndex
    activeMarker = this.markerIndex
    RefreshSelection()
    timeline:SetScript("OnUpdate", TimelineOnUpdate)
  end)

  marker:SetScript("OnMouseUp", function()
    activeMarker = nil
    timeline:SetScript("OnUpdate", nil)
  end)

  return marker
end

for i = 1, frameCount do
  markers[i] = MakeMarker(i, "F" .. i)
end
endMarker = MakeMarker(frameCount + 1, D_("VT_DEBUG_END"))

local nudgeMinus = MakeButton(timeline, "-", 24, 574, -31, function()
  SetMarkerTime(selectedMarker, MarkerTime(selectedMarker) - snapMs)
end)

local nudgePlus = MakeButton(timeline, "+", 24, 602, -31, function()
  SetMarkerTime(selectedMarker, MarkerTime(selectedMarker) + snapMs)
end)

TimelineOnUpdate = function()
  if not activeMarker then
    timeline:SetScript("OnUpdate", nil)
    return
  end

  if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
    activeMarker = nil
    timeline:SetScript("OnUpdate", nil)
    return
  end

  local cursorX = GetCursorPosition()
  local scale = ruler:GetEffectiveScale()
  local left = ruler:GetLeft()
  if not cursorX or not scale or scale == 0 or not left then return end

  local x = (cursorX / scale) - left
  if x < 0 then x = 0 end
  if x > RULER_WIDTH then x = RULER_WIDTH end

  local value = SnapTime((x / RULER_WIDTH) * TIMELINE_MS)
  SetMarkerTime(activeMarker, value)
end

timeline:SetScript("OnHide", function()
  activeMarker = nil
  timeline:SetScript("OnUpdate", nil)
end)

local function ToggleTimeline()
  if timeline:IsShown() then
    timeline:Hide()
  else
    timeline:Show()
    RefreshMarkerPositions()
  end
end

MakeButton(frame, D_("VT_DEBUG_PLAY"), 72, 10, -34, function()
  ApplyTimeline()
  bin:PlayPreview()
end)

MakeButton(frame, D_("VT_DEBUG_TIMELINE"), 80, 86, -34, function()
  ToggleTimeline()
end)

MakeButton(frame, D_("VT_DEBUG_PRINT"), 80, 170, -34, function()
  local ix, iy, fx, fy = GetOffsets()
  DEFAULT_CHAT_FRAME:AddMessage(string.format(
    "|cff66ccff[" .. D_("VT_DEBUG_PREFIX") .. "]|r " .. D_("VT_DEBUG_VALUES"),
    ix, iy, fx, fy
  ))
  DEFAULT_CHAT_FRAME:AddMessage(string.format(
    "|cff66ccff[" .. D_("VT_DEBUG_PREFIX") .. "]|r " .. D_("VT_DEBUG_TIMELINE_VALUES"),
    snapMs, TimelineString()
  ))
end)

MakeButton(frame, D_("VT_DEBUG_RESET"), 66, 254, -34, function()
  bin:ResetTuningOffsets()
  BuildDefaultTimeline()
  ApplyTimeline()
  RefreshOffsets()
  RefreshMarkerPositions()
  bin:PlayPreview()
end)

MakeOffsetRow(1, D_("VT_DEBUG_ITEM_X"), -70)
MakeOffsetRow(2, D_("VT_DEBUG_ITEM_Y"), -98)
MakeOffsetRow(3, D_("VT_DEBUG_FIRE_X"), -126)
MakeOffsetRow(4, D_("VT_DEBUG_FIRE_Y"), -154)

local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
hint:SetText(D_("VT_DEBUG_HINT"))

BuildDefaultTimeline()
ApplyTimeline()
RefreshOffsets()
RefreshSnapButtons()
RefreshMarkerPositions()

SLASH_PFUI_VENDORTWEAKS_DEBUG1 = "/vtdebug"
SlashCmdList["PFUI_VENDORTWEAKS_DEBUG"] = function(msg)
  if msg == "timeline" then
    ToggleTimeline()
  elseif msg == "all" then
    frame:Show()
    timeline:Show()
    RefreshMarkerPositions()
  else
    if frame:IsShown() then
      frame:Hide()
    else
      frame:Show()
      RefreshOffsets()
    end
  end
end
