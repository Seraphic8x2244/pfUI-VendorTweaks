from pathlib import Path

src_path = Path("pfUI-VendorTweaks.lua")
toc_path = Path("pfUI-VendorTweaks.toc")
src = src_path.read_text(encoding="utf-8")

src = src.replace("-- pfUI-VendorTweaks v0.1.23", "-- pfUI-VendorTweaks v0.1.24", 1)

src = src.replace(
    'local ADDON_NAME = "pfUI-VendorTweaks"\nlocal DB = nil\n',
    'local ADDON_NAME = "pfUI-VendorTweaks"\nlocal DB = nil\nlocal missingIconIDs = {}\nlocal iconRepairInitialized = false\n',
    1,
)

old = '''local function PruneItemInfo(id)
  if not DB or not DB.items or not id then return end
  if not DB.vendorList[id] and not DB.deleteList[id] then
    DB.items[id] = nil
  end
end
'''
new = '''-- -----------------------------------------------------------------------------
-- On-demand icon repair
-- Dormant when every listed item already has cached artwork.
-- -----------------------------------------------------------------------------
local iconRepairFrame = CreateFrame("Frame")
local iconRepairListening = false

local function UpdateIconRepairListener()
  local shouldListen = next(missingIconIDs) ~= nil

  if shouldListen and not iconRepairListening then
    iconRepairFrame:RegisterEvent("BAG_UPDATE")
    iconRepairListening = true
  elseif not shouldListen and iconRepairListening then
    iconRepairFrame:UnregisterEvent("BAG_UPDATE")
    iconRepairListening = false
  end
end

local function TryResolveItemIcon(id)
  if not DB or not id then return false end

  local item = DB.items and DB.items[id]
  if type(item) == "table" and item.icon then
    missingIconIDs[id] = nil
    return true
  end

  local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
  if name or texture then
    CacheItemInfo(id, name, texture)
  end

  item = DB.items and DB.items[id]
  if type(item) == "table" and item.icon then
    missingIconIDs[id] = nil
    return true
  end

  missingIconIDs[id] = true
  return false
end

local function ScanBagForMissingIcons(bag)
  if not DB or not next(missingIconIDs) then return end
  if bag == nil or bag < 0 or bag > 4 then return end

  local size = GetContainerNumSlots(bag) or 0
  for slot = 1, size do
    local link = GetContainerItemLink(bag, slot)
    local id = GetIDFromLink(link)
    if id and missingIconIDs[id] then
      local texture = GetContainerItemInfo(bag, slot)
      if texture then
        local name = GetItemInfo(link or id)
        CacheItemInfo(id, name, texture)
        missingIconIDs[id] = nil
      end
    end
  end
end

local function ScanAllBagsForMissingIcons()
  if not next(missingIconIDs) then return end
  for bag = 0, 4 do
    ScanBagForMissingIcons(bag)
    if not next(missingIconIDs) then break end
  end
end

local function RebuildMissingIconIDs()
  missingIconIDs = {}
  if not DB then return end

  local checked = {}
  local function CheckList(list)
    for id in pairs(list) do
      local itemID = tonumber(id)
      if itemID and not checked[itemID] then
        checked[itemID] = true
        TryResolveItemIcon(itemID)
      end
    end
  end

  CheckList(DB.vendorList)
  CheckList(DB.deleteList)
end

local function InitializeIconRepair()
  -- PLAYER_ENTERING_WORLD also fires after zoning; the initial full scan is
  -- intentionally once per session. After this, BAG_UPDATE scans only the bag
  -- that actually changed and only while unresolved icons still exist.
  if iconRepairInitialized then return end
  iconRepairInitialized = true

  RebuildMissingIconIDs()
  if next(missingIconIDs) then
    ScanAllBagsForMissingIcons()
  end
  UpdateIconRepairListener()
end

iconRepairFrame:SetScript("OnEvent", function()
  if event ~= "BAG_UPDATE" or not DB or not next(missingIconIDs) then return end

  local bag = tonumber(arg1)
  if bag and bag >= 0 and bag <= 4 then
    ScanBagForMissingIcons(bag)
  end

  UpdateIconRepairListener()
end)

local function PruneItemInfo(id)
  if not DB or not DB.items or not id then return end
  if not DB.vendorList[id] and not DB.deleteList[id] then
    DB.items[id] = nil
    missingIconIDs[id] = nil
    UpdateIconRepairListener()
  end
end
'''
if old not in src:
    raise SystemExit("PruneItemInfo block not found")
src = src.replace(old, new, 1)

start_marker = "    -- Resolve list artwork cheaply. Known VendorTweaks metadata wins immediately;\n"
end_marker = "    local i = 0\n"
start = src.find(start_marker)
if start < 0:
    raise SystemExit("Refresh metadata block start not found")
end = src.find(end_marker, start)
if end < 0:
    raise SystemExit("Refresh metadata block end not found")

replacement = '''    -- Known VendorTweaks metadata wins immediately. Only incomplete entries
    -- query WoW's item cache. If Refresh discovers a previously-untracked
    -- missing icon, perform one shared bag scan; already-tracked misses rely on
    -- the on-demand BAG_UPDATE repair listener instead of rescanning all bags.
    local checked = {}
    local discoveredMissing = false

    local function ResolveListMetadata(list)
      for id in pairs(list) do
        local itemID = tonumber(id) or id
        if not checked[itemID] then
          checked[itemID] = true
          local item = DB.items and DB.items[itemID]
          local hasIcon = type(item) == "table" and item.icon

          if hasIcon then
            missingIconIDs[itemID] = nil
          else
            local wasMissing = missingIconIDs[itemID]
            if not TryResolveItemIcon(itemID) and not wasMissing then
              discoveredMissing = true
            end
          end
        end
      end
    end

    ResolveListMetadata(DB.vendorList)
    ResolveListMetadata(DB.deleteList)

    if discoveredMissing and next(missingIconIDs) then
      ScanAllBagsForMissingIcons()
    end
    UpdateIconRepairListener()

'''
src = src[:start] + replacement + src[end:]

old_drop = '''    CacheItemInfo(itemID, name or string.format(T_("Item #%d"), itemID), texture)
    Refresh()
'''
new_drop = '''    CacheItemInfo(itemID, name or string.format(T_("Item #%d"), itemID), texture)
    if texture then
      missingIconIDs[itemID] = nil
    else
      missingIconIDs[itemID] = true
    end
    UpdateIconRepairListener()
    Refresh()
'''
if old_drop not in src:
    raise SystemExit("HandleDrop cache block not found")
src = src.replace(old_drop, new_drop, 1)

old_world = '''  elseif event == "PLAYER_ENTERING_WORLD" then
    if not DB then InitDB() end
    ApplyGreyTakeover()
'''
new_world = '''  elseif event == "PLAYER_ENTERING_WORLD" then
    if not DB then InitDB() end
    ApplyGreyTakeover()
    InitializeIconRepair()
'''
if old_world not in src:
    raise SystemExit("PLAYER_ENTERING_WORLD block not found")
src = src.replace(old_world, new_world, 1)

src_path.write_text(src, encoding="utf-8")

toc = toc_path.read_text(encoding="utf-8")
if "## Version: 0.1.23" not in toc:
    raise SystemExit("TOC version not found")
toc = toc.replace("## Version: 0.1.23", "## Version: 0.1.24", 1)
toc_path.write_text(toc, encoding="utf-8")
