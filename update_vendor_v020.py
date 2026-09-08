from pathlib import Path

p = Path("pfUI-VendorTweaks.lua")
s = p.read_text()

def replace_once(old, new, label):
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 match, found {count}")
    s = s.replace(old, new, 1)

replace_once("-- pfUI-VendorTweaks v0.1.19", "-- pfUI-VendorTweaks v0.1.20", "version header")

replace_once(
    '  if DB.takeoverGreys == nil then DB.takeoverGreys = "0" end\n  if DB.autoSellGreys == nil then DB.autoSellGreys = "0" end\n',
    '  if DB.takeoverGreys == nil then DB.takeoverGreys = "0" end\n  -- v0.1.20: takeoverGreys is also the Auto-Sell ON switch; retire the old split flag.\n  DB.autoSellGreys = nil\n',
    "obsolete autoSellGreys setting",
)

replace_once(
    "  if n > 1.50 then n = 1.50 end",
    "  if n > 0.50 then n = 0.50 end",
    "interval maximum",
)

replace_once(
    '    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)\n    label:SetText(text)\n',
    '    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)\n    label:SetText(text)\n    cb.label = label\n',
    "checkbox label handle",
)

old_ui = '''  local takeover = MakeCheckbox(title, -12,
    T_("Take over pfUI grey selling (throttled)"), "takeoverGreys", function()
      CancelSellQueue()
      ApplyGreyTakeover()
    end)

  local autoGreys = MakeCheckbox(takeover, -4,
    T_("Auto-sell greys when merchant opens"), "autoSellGreys")

  local delayLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  delayLabel:SetPoint("TOPLEFT", autoGreys, "BOTTOMLEFT", 0, -16)

  local slider = CreateFrame("Slider", "pfVT_ComponentSpeedSlider", parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", delayLabel, "BOTTOMLEFT", 0, -8)
  slider:SetWidth(220)
  slider:SetHeight(16)
  slider:SetMinMaxValues(0.05, 1.50)
  slider:SetValueStep(0.05)
  if pfUI.api and pfUI.api.SkinSlider then pfUI.api.SkinSlider(slider) end
  getglobal(slider:GetName() .. "Low"):SetText("0.05s")
  getglobal(slider:GetName() .. "High"):SetText("1.50s")
  slider:SetScript("OnValueChanged", function()
    if not DB then return end
    local val = floor(this:GetValue() * 100 + 0.5) / 100
    DB.interval = tostring(val)
    delayLabel:SetText(string.format(T_("Vendor sell delay: %.2f seconds"), val))
  end)

  -- The list toggles double as the two side-by-side section subheaders.
  local autoVendor = MakeCheckbox(slider, -24,
    T_("Auto-Vendor"), "autoVendor")
'''

new_ui = '''  -- Enabling this is both the takeover switch and the Auto-Sell ON switch.
  -- When disabled, pfUI's own Auto-Sell setting and behaviour are restored intact.
  local takeover = MakeCheckbox(title, -12,
    T_("Throttle pfUI auto-sell"), "takeoverGreys", function()
      CancelSellQueue()
      ApplyGreyTakeover()
    end)

  local slider = CreateFrame("Slider", "pfVT_ComponentSpeedSlider", parent, "OptionsSliderTemplate")
  slider:SetPoint("LEFT", takeover.label, "RIGHT", 18, 0)
  slider:SetWidth(150)
  slider:SetHeight(16)
  slider:SetMinMaxValues(0.05, 0.50)
  slider:SetValueStep(0.05)
  if pfUI.api and pfUI.api.SkinSlider then pfUI.api.SkinSlider(slider) end
  getglobal(slider:GetName() .. "Low"):SetText("0.05s")
  getglobal(slider:GetName() .. "High"):SetText("0.50s")
  local sliderText = getglobal(slider:GetName() .. "Text")
  slider:SetScript("OnValueChanged", function()
    if not DB then return end
    local val = floor(this:GetValue() * 100 + 0.5) / 100
    DB.interval = tostring(val)
    if sliderText then sliderText:SetText(string.format("%.2fs", val)) end
  end)

  -- The list toggles double as the two side-by-side section subheaders.
  local autoVendor = MakeCheckbox(takeover, -32,
    T_("Auto-Vendor"), "autoVendor")
'''
replace_once(old_ui, new_ui, "compact throttle UI")

old_row = '''  local function MakeRow(pool, rowParent, red)
    local row = CreateFrame("Button", nil, rowParent)
    row:SetWidth(LIST_WIDTH - 4)
    row:SetHeight(18)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
    if red then row.text:SetTextColor(1, .4, .4) end
    row.del = CreateFrame("Button", nil, row)
    row.del:SetWidth(16)
    row.del:SetHeight(16)
    row.del:SetPoint("RIGHT", row, "RIGHT", -1, 0)
    local x = row.del:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER", row.del, "CENTER", 0, 0)
    x:SetText("|cffff5555x|r")
    table.insert(pool, row)
    return row
  end

  local function DisplayName(id, savedName)
    local liveName = GetItemInfo(id)
    if liveName then
      return liveName
    end
    if type(savedName) == "string" then
      return savedName
    end
    return string.format(T_("ID: %d"), id)
  end
'''

new_row = '''  local function MakeRow(pool, rowParent, greyName)
    local row = CreateFrame("Button", nil, rowParent)
    row:SetWidth(LIST_WIDTH - 4)
    row:SetHeight(18)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(14)
    row.icon:SetHeight(14)
    row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)

    row.del = CreateFrame("Button", nil, row)
    row.del:SetWidth(16)
    row.del:SetHeight(16)
    row.del:SetPoint("RIGHT", row, "RIGHT", -1, 0)
    local x = row.del:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER", row.del, "CENTER", 0, 0)
    x:SetText("|cffff5555x|r")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row.del, "LEFT", -4, 0)
    row.text:SetJustifyH("LEFT")
    if greyName then row.text:SetTextColor(.62, .62, .62) end

    table.insert(pool, row)
    return row
  end

  local function DisplayInfo(id, savedName)
    local liveName, _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
    if liveName then
      return liveName, texture
    end
    if type(savedName) == "string" then
      return savedName, texture
    end
    return string.format(T_("ID: %d"), id), texture
  end
'''
replace_once(old_row, new_row, "list rows and icons")

replace_once(
    '      local display = DisplayName(idKey, name)\n      if display and display ~= name then DB.vendorList[id] = display end\n      row:ClearAllPoints()\n      row:SetPoint("TOPLEFT", vendorChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))\n      row.text:SetText(display)\n',
    '      local display, texture = DisplayInfo(idKey, name)\n      if display and display ~= name then DB.vendorList[id] = display end\n      row:ClearAllPoints()\n      row:SetPoint("TOPLEFT", vendorChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))\n      row.icon:SetTexture(texture or "Interface\\\\Icons\\\\INV_Misc_QuestionMark")\n      row.text:SetText(display)\n',
    "vendor row icon",
)

replace_once(
    '      local display = DisplayName(idKey, name)\n      if display and display ~= name then DB.deleteList[id] = display end\n      row:ClearAllPoints()\n      row:SetPoint("TOPLEFT", deleteChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))\n      row.text:SetText(display)\n',
    '      local display, texture = DisplayInfo(idKey, name)\n      if display and display ~= name then DB.deleteList[id] = display end\n      row:ClearAllPoints()\n      row:SetPoint("TOPLEFT", deleteChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))\n      row.icon:SetTexture(texture or "Interface\\\\Icons\\\\INV_Misc_QuestionMark")\n      row.text:SetText(display)\n',
    "delete row icon",
)

replace_once(
    '    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))\n    SetCheckboxChecked(autoGreys, Enabled("autoSellGreys"))\n    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))\n',
    '    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))\n    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))\n',
    "refresh obsolete autoGreys",
)

replace_once(
    '    local interval = GetInterval()\n    slider:SetValue(interval)\n    delayLabel:SetText(string.format(T_("Vendor sell delay: %.2f seconds"), interval))\n',
    '    local interval = GetInterval()\n    slider:SetValue(interval)\n    if sliderText then sliderText:SetText(string.format("%.2fs", interval)) end\n',
    "refresh slider value",
)

replace_once(
    '    local includeGreys = Enabled("takeoverGreys") and Enabled("autoSellGreys")\n',
    '    local includeGreys = Enabled("takeoverGreys")\n',
    "takeover implies autosell",
)

p.write_text(s)

lp = Path("locales.lua")
ls = lp.read_text()
old_keys = '''  "Take over pfUI grey selling (throttled)",
  "Auto-sell greys when merchant opens",
  "Vendor sell delay: %.2f seconds",
'''
new_keys = '''  "Throttle pfUI auto-sell",
'''
if ls.count(old_keys) != 1:
    raise SystemExit("locales keys: expected old throttle strings once")
ls = ls.replace(old_keys, new_keys, 1)
lp.write_text(ls)

tp = Path("pfUI-VendorTweaks.toc")
ts = tp.read_text()
if ts.count("## Version: 0.1.19") != 1:
    raise SystemExit("TOC version: expected 0.1.19 once")
ts = ts.replace("## Version: 0.1.19", "## Version: 0.1.20", 1)
tp.write_text(ts)
