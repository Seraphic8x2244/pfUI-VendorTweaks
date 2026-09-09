from pathlib import Path

p = Path('pfUI-VendorTweaks.lua')
s = p.read_text()

def replace_once(old, new, label):
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    s = s.replace(old, new, 1)

replace_once('-- pfUI-VendorTweaks v0.1.21', '-- pfUI-VendorTweaks v0.1.22', 'version header')

old = '''  local function DisplayInfo(id)
    local liveName, _, _, _, _, _, _, _, _, liveTexture = GetItemInfo(id)
    if liveName or liveTexture then
      CacheItemInfo(id, liveName, liveTexture)
    end

    local item = DB.items and DB.items[id]
    local name = liveName or (type(item) == "table" and item.name)
    local texture = liveTexture or (type(item) == "table" and item.icon)

    return name or string.format(T_("ID: %d"), id), texture
  end

  local function Refresh()
    if not DB then return end

    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))
    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))
    SetCheckboxChecked(autoDelete, Enabled("autoDelete"))

    local interval = GetInterval()
    slider:SetValue(interval)
    if sliderText then sliderText:SetText(string.format("%.2fs", interval)) end

    for _, row in ipairs(vendorPool) do row:Hide() end
    for _, row in ipairs(deletePool) do row:Hide() end

    local i = 0
    for id in pairs(DB.vendorList) do
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
    vendorChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    vendorScroll:SetVerticalScroll(math.min(vendorScroll:GetVerticalScroll(), math.max(0, vendorChild:GetHeight() - vendorScroll:GetHeight())))

    i = 0
    for id in pairs(DB.deleteList) do
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
    deleteChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    deleteScroll:SetVerticalScroll(math.min(deleteScroll:GetVerticalScroll(), math.max(0, deleteChild:GetHeight() - deleteScroll:GetHeight())))
  end
'''

new = '''  local function DisplayInfo(id)
    local item = DB.items and DB.items[id]
    local name = type(item) == "table" and item.name or nil
    local texture = type(item) == "table" and item.icon or nil
    return name or string.format(T_("ID: %d"), id), texture
  end

  local function Refresh()
    if not DB then return end

    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))
    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))
    SetCheckboxChecked(autoDelete, Enabled("autoDelete"))

    local interval = GetInterval()
    slider:SetValue(interval)
    if sliderText then sliderText:SetText(string.format("%.2fs", interval)) end

    for _, row in ipairs(vendorPool) do row:Hide() end
    for _, row in ipairs(deletePool) do row:Hide() end

    -- Resolve list artwork cheaply. Known VendorTweaks metadata wins immediately;
    -- only incomplete entries query WoW's item cache. Anything still missing is
    -- collected for one shared bag scan rather than scanning bags once per item.
    local unresolved = {}
    local checked = {}

    local function ResolveListMetadata(list)
      for id in pairs(list) do
        local itemID = tonumber(id) or id
        if not checked[itemID] then
          checked[itemID] = true
          local item = DB.items and DB.items[itemID]
          local hasIcon = type(item) == "table" and item.icon

          if not hasIcon then
            local liveName, _, _, _, _, _, _, _, _, liveTexture = GetItemInfo(itemID)
            if liveName or liveTexture then
              CacheItemInfo(itemID, liveName, liveTexture)
            end

            item = DB.items and DB.items[itemID]
            if not (type(item) == "table" and item.icon) then
              unresolved[itemID] = true
            end
          end
        end
      end
    end

    ResolveListMetadata(DB.vendorList)
    ResolveListMetadata(DB.deleteList)

    if next(unresolved) then
      for bag = 0, 4 do
        local size = GetContainerNumSlots(bag) or 0
        for slot = 1, size do
          local bagLink = GetContainerItemLink(bag, slot)
          local itemID = GetIDFromLink(bagLink)
          if itemID and unresolved[itemID] then
            local bagTexture = GetContainerItemInfo(bag, slot)
            if bagTexture then
              local bagName = GetItemInfo(bagLink or itemID)
              CacheItemInfo(itemID, bagName, bagTexture)
              unresolved[itemID] = nil
            end
          end
        end
      end
    end

    local i = 0
    for id in pairs(DB.vendorList) do
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
    vendorChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    vendorScroll:SetVerticalScroll(math.min(vendorScroll:GetVerticalScroll(), math.max(0, vendorChild:GetHeight() - vendorScroll:GetHeight())))

    i = 0
    for id in pairs(DB.deleteList) do
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
    deleteChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    deleteScroll:SetVerticalScroll(math.min(deleteScroll:GetVerticalScroll(), math.max(0, deleteChild:GetHeight() - deleteScroll:GetHeight())))
  end
'''

replace_once(old, new, 'refresh metadata resolution')
p.write_text(s)

toc = Path('pfUI-VendorTweaks.toc')
ts = toc.read_text()
if ts.count('## Version: 0.1.21') != 1:
    raise SystemExit('TOC version: expected 0.1.21 once')
toc.write_text(ts.replace('## Version: 0.1.21', '## Version: 0.1.22', 1))
