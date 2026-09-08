from pathlib import Path

p = Path("pfUI-VendorTweaks.lua")
s = p.read_text()


def replace_once(old, new, label):
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 match, found {count}")
    s = s.replace(old, new, 1)


replace_once("-- pfUI-VendorTweaks v0.1.20", "-- pfUI-VendorTweaks v0.1.21", "version header")

old_init = '''  if DB.autoVendor == nil then DB.autoVendor = "1" end
  if DB.autoDelete == nil then DB.autoDelete = "1" end
  if type(DB.vendorList) ~= "table" then DB.vendorList = {} end
  if type(DB.deleteList) ~= "table" then DB.deleteList = {} end
end
'''
new_init = '''  if DB.autoVendor == nil then DB.autoVendor = "1" end
  if DB.autoDelete == nil then DB.autoDelete = "1" end
  if type(DB.vendorList) ~= "table" then DB.vendorList = {} end
  if type(DB.deleteList) ~= "table" then DB.deleteList = {} end
  if type(DB.items) ~= "table" then DB.items = {} end

  -- v0.1.21: list membership is ID-only. Migrate the old saved item-name values
  -- into one shared metadata cache used by both Auto-Vendor and Auto-Delete.
  local function MigrateList(list)
    local normalized = {}
    for id, value in pairs(list) do
      local itemID = tonumber(id)
      if itemID then
        normalized[itemID] = true
        if type(value) == "string" then
          local item = DB.items[itemID]
          if type(item) ~= "table" then item = {} end
          if not item.name then item.name = value end
          DB.items[itemID] = item
        end
      end
    end
    return normalized
  end

  DB.vendorList = MigrateList(DB.vendorList)
  DB.deleteList = MigrateList(DB.deleteList)
end
'''
replace_once(old_init, new_init, "InitDB item cache migration")

marker = '''local function T_(key)
  if pfUI.env and pfUI.env.T and pfUI.env.T[key] then
    return pfUI.env.T[key]
  end
  return key
end
'''
replacement = marker + '''
local function CacheItemInfo(id, name, texture)
  if not DB or not id then return end
  if type(DB.items) ~= "table" then DB.items = {} end

  local item = DB.items[id]
  if type(item) ~= "table" then item = {} end
  if name then item.name = name end
  if texture then item.icon = texture end
  DB.items[id] = item
end

local function PruneItemInfo(id)
  if not DB or not DB.items or not id then return end
  if not DB.vendorList[id] and not DB.deleteList[id] then
    DB.items[id] = nil
  end
end
'''
replace_once(marker, replacement, "item cache helpers")

replace_once(
    '  slider:SetPoint("LEFT", takeover.label, "RIGHT", 18, 0)\n',
    '  -- Align the slider to the right edge of the two list columns.\n  slider:SetPoint("RIGHT", takeover, "LEFT", 415, 0)\n',
    "right-align slider",
)

old_display = '''  local function DisplayInfo(id, savedName)
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
new_display = '''  local function DisplayInfo(id)
    local liveName, _, _, _, _, _, _, _, _, liveTexture = GetItemInfo(id)
    if liveName or liveTexture then
      CacheItemInfo(id, liveName, liveTexture)
    end

    local item = DB.items and DB.items[id]
    local name = liveName or (type(item) == "table" and item.name)
    local texture = liveTexture or (type(item) == "table" and item.icon)

    return name or string.format(T_("ID: %d"), id), texture
  end
'''
replace_once(old_display, new_display, "DisplayInfo shared cache")

old_vendor = '''    for id, name in pairs(DB.vendorList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)
      local display, texture = DisplayInfo(idKey, name)
      if display and display ~= name then DB.vendorList[id] = display end
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", vendorChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.icon:SetTexture(texture or "Interface\\\\Icons\\\\INV_Misc_QuestionMark")
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.vendorList[idKey] = nil
        DB.vendorList[tostring(idKey)] = nil
        Refresh()
      end)
      row:Show()
    end
'''
new_vendor = '''    for id in pairs(DB.vendorList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)
      local display, texture = DisplayInfo(idKey)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", vendorChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.icon:SetTexture(texture or "Interface\\\\Icons\\\\INV_Misc_QuestionMark")
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.vendorList[idKey] = nil
        PruneItemInfo(idKey)
        Refresh()
      end)
      row:Show()
    end
'''
replace_once(old_vendor, new_vendor, "vendor list cache usage")

old_delete = '''    for id, name in pairs(DB.deleteList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)
      local display, texture = DisplayInfo(idKey, name)
      if display and display ~= name then DB.deleteList[id] = display end
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", deleteChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.icon:SetTexture(texture or "Interface\\\\Icons\\\\INV_Misc_QuestionMark")
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.deleteList[idKey] = nil
        DB.deleteList[tostring(idKey)] = nil
        Refresh()
      end)
      row:Show()
    end
'''
new_delete = '''    for id in pairs(DB.deleteList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)
      local display, texture = DisplayInfo(idKey)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", deleteChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.icon:SetTexture(texture or "Interface\\\\Icons\\\\INV_Misc_QuestionMark")
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.deleteList[idKey] = nil
        PruneItemInfo(idKey)
        Refresh()
      end)
      row:Show()
    end
'''
replace_once(old_delete, new_delete, "delete list cache usage")

old_drop_membership = '''    if mode == "vendor" then
      DB.vendorList[itemID] = name or string.format(T_("Item #%d"), itemID)
      DB.deleteList[itemID] = nil
      DB.deleteList[tostring(itemID)] = nil
      SetDropHighlight(vendorDrop, false)
    else
      DB.deleteList[itemID] = name or string.format(T_("Item #%d"), itemID)
      DB.vendorList[itemID] = nil
      DB.vendorList[tostring(itemID)] = nil
      SetDropHighlight(deleteDrop, false)
    end
'''
new_drop_membership = '''    if mode == "vendor" then
      DB.vendorList[itemID] = true
      DB.deleteList[itemID] = nil
      SetDropHighlight(vendorDrop, false)
    else
      DB.deleteList[itemID] = true
      DB.vendorList[itemID] = nil
      SetDropHighlight(deleteDrop, false)
    end
'''
replace_once(old_drop_membership, new_drop_membership, "ID-only list membership")

old_after_scan = '''    if not texture then
      for bag = 0, 4 do
        local size = GetContainerNumSlots(bag) or 0
        for slot = 1, size do
          local bagLink = GetContainerItemLink(bag, slot)
          if bagLink and GetIDFromLink(bagLink) == itemID then
            local bagTexture = GetContainerItemInfo(bag, slot)
            if bagTexture then
              texture = bagTexture
              break
            end
          end
        end
        if texture then break end
      end
    end

    Refresh()
'''
new_after_scan = '''    if not texture then
      for bag = 0, 4 do
        local size = GetContainerNumSlots(bag) or 0
        for slot = 1, size do
          local bagLink = GetContainerItemLink(bag, slot)
          if bagLink and GetIDFromLink(bagLink) == itemID then
            local bagTexture = GetContainerItemInfo(bag, slot)
            if bagTexture then
              texture = bagTexture
              break
            end
          end
        end
        if texture then break end
      end
    end

    CacheItemInfo(itemID, name or string.format(T_("Item #%d"), itemID), texture)
    Refresh()
'''
replace_once(old_after_scan, new_after_scan, "cache dropped item metadata")

p.write_text(s)

tp = Path("pfUI-VendorTweaks.toc")
ts = tp.read_text()
if ts.count("## Version: 0.1.20") != 1:
    raise SystemExit("TOC version: expected 0.1.20 once")
ts = ts.replace("## Version: 0.1.20", "## Version: 0.1.21", 1)
tp.write_text(ts)
