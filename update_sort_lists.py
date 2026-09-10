from pathlib import Path

source_path = Path("pfUI-VendorTweaks.lua")
toc_path = Path("pfUI-VendorTweaks.toc")
source = source_path.read_text(encoding="utf-8")
toc = toc_path.read_text(encoding="utf-8")

source = source.replace("-- pfUI-VendorTweaks v0.1.24", "-- pfUI-VendorTweaks v0.1.25", 1)
toc = toc.replace("## Version: 0.1.24", "## Version: 0.1.25", 1)

needle = '''    UpdateIconRepairListener()\n\n    local i = 0\n    for id in pairs(DB.vendorList) do\n      i = i + 1\n      local idKey = tonumber(id) or id\n      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)\n      local display, texture = DisplayInfo(idKey)\n'''
replacement = '''    UpdateIconRepairListener()\n\n    -- List membership stays as an ID-keyed map. Build a temporary display array\n    -- only when the panel refreshes so both columns are deterministic and\n    -- alphabetically sorted without adding any persistent ordering state.\n    local function BuildSortedRows(list)\n      local rows = {}\n      for id in pairs(list) do\n        local itemID = tonumber(id) or id\n        local display, texture = DisplayInfo(itemID)\n        table.insert(rows, {\n          id = itemID,\n          display = display,\n          texture = texture,\n          sortKey = string.lower(display or ""),\n        })\n      end\n\n      table.sort(rows, function(a, b)\n        if a.sortKey == b.sortKey then\n          return a.id < b.id\n        end\n        return a.sortKey < b.sortKey\n      end)\n\n      return rows\n    end\n\n    local vendorRows = BuildSortedRows(DB.vendorList)\n    local i = 0\n    for _, entry in ipairs(vendorRows) do\n      i = i + 1\n      local idKey = entry.id\n      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)\n      local display, texture = entry.display, entry.texture\n'''
if needle not in source:
    raise SystemExit("vendor loop anchor not found")
source = source.replace(needle, replacement, 1)

needle = '''    i = 0\n    for id in pairs(DB.deleteList) do\n      i = i + 1\n      local idKey = tonumber(id) or id\n      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)\n      local display, texture = DisplayInfo(idKey)\n'''
replacement = '''    local deleteRows = BuildSortedRows(DB.deleteList)\n    i = 0\n    for _, entry in ipairs(deleteRows) do\n      i = i + 1\n      local idKey = entry.id\n      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)\n      local display, texture = entry.display, entry.texture\n'''
if needle not in source:
    raise SystemExit("delete loop anchor not found")
source = source.replace(needle, replacement, 1)

source_path.write_text(source, encoding="utf-8")
toc_path.write_text(toc, encoding="utf-8")
