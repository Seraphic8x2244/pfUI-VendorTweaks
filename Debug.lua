-- pfUI VendorTweaks development controls
-- Dev branch only. Remove this file and its TOC entry for stable releases.

if not pfUI then return end

local bin = getglobal("pfUI_VendorTweaks_Bin")
if not bin or not bin.GetTuningOffsets or not bin.SetTuningOffsets or not bin.PlayPreview then
  return
end

local frame = CreateFrame("Frame", "pfUI_VendorTweaks_Debug", UIParent)
frame:SetWidth(270)
frame:SetHeight(205)
frame:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
frame:SetFrameStrata("DIALOG")
frame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(0, 0, 0, .9)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", frame, "TOP", 0, -10)
title:SetText("pfUI VendorTweaks Burn Debug")

local function MakeButton(text, width, x, y, onClick)
  local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  button:SetWidth(width)
  button:SetHeight(22)
  button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
  button:SetText(text)
  button:SetScript("OnClick", onClick)
  return button
end

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

local function Refresh()
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

  local minus = MakeButton("-", 24, 72, y + 4, function()
    local ix, iy, fx, fy = GetOffsets()
    local values = { ix, iy, fx, fy }
    SetOffset(index, values[index] - 1)
    Refresh()
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
    Refresh()
  end)
  edit:SetScript("OnEscapePressed", function()
    this:ClearFocus()
    Refresh()
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
    Refresh()
  end)

  controls[index] = { edit = edit }
end

MakeButton("Play Burn", 86, 12, -34, function()
  bin:PlayPreview()
end)

MakeButton("Print Values", 86, 104, -34, function()
  local ix, iy, fx, fy = GetOffsets()
  DEFAULT_CHAT_FRAME:AddMessage(string.format(
    "|cff66ccff[pfUI VendorTweaks Debug]|r item=(%d, %d) fire=(%d, %d)",
    ix, iy, fx, fy
  ))
end)

MakeButton("Reset", 60, 196, -34, function()
  bin:ResetTuningOffsets()
  Refresh()
  bin:PlayPreview()
end)

MakeOffsetRow(1, "Item X", -70)
MakeOffsetRow(2, "Item Y", -98)
MakeOffsetRow(3, "Fire X", -126)
MakeOffsetRow(4, "Fire Y", -154)

local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hint:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
hint:SetText("Enter = exact value   +/- = 1 UI unit")

Refresh()
