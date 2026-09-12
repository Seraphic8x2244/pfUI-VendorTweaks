from pathlib import Path

lua_path = Path('pfUI-VendorTweaks.lua')
toc_path = Path('pfUI-VendorTweaks.toc')

lua = lua_path.read_text()
toc = toc_path.read_text()

lua = lua.replace('-- pfUI-VendorTweaks v0.1.25', '-- pfUI-VendorTweaks v0.1.26', 1)
toc = toc.replace('## Version: 0.1.25', '## Version: 0.1.26', 1)

anchor = '''local pendingDeleteIDs = {}\nlocal deletePendingAt = nil\nlocal DELETE_DEBOUNCE = 0.20\nlocal DELETE_STEP_DELAY = 0.10\n'''
insert = '''local pendingDeleteIDs = {}\nlocal deletePendingAt = nil\nlocal DELETE_DEBOUNCE = 0.20\nlocal DELETE_STEP_DELAY = 0.10\n\n-- -----------------------------------------------------------------------------\n-- Vendor-purchase Auto-Delete exemption\n-- Normal merchant purchases can emit the same self-acquisition loot messages\n-- that arm Auto-Delete. Track exact merchant item IDs at the purchase call and\n-- consume one short-lived exemption in CHAT_MSG_LOOT. This deliberately does\n-- not change the existing delete worker or its BAG_UPDATE safety path.\n-- -----------------------------------------------------------------------------\nlocal vendorPurchaseExemptions = {}\nlocal VENDOR_PURCHASE_EXEMPTION_TTL = 2.0\nlocal merchantPurchaseHooksInstalled = false\nlocal originalBuyMerchantItem = nil\nlocal originalPickupMerchantItem = nil\n\nlocal function MarkVendorPurchase(index)\n  if not DB or not Enabled("autoDelete") or not index then return end\n\n  local link = GetMerchantItemLink(index)\n  local id = GetIDFromLink(link)\n  if not id or not DB.deleteList[id] then return end\n\n  local now = GetTime()\n  local entry = vendorPurchaseExemptions[id]\n  if not entry or not entry.expires or entry.expires < now then\n    entry = { count = 0, expires = 0 }\n  end\n\n  entry.count = (entry.count or 0) + 1\n  entry.expires = now + VENDOR_PURCHASE_EXEMPTION_TTL\n  vendorPurchaseExemptions[id] = entry\nend\n\nlocal function ConsumeVendorPurchaseExemption(id)\n  local entry = id and vendorPurchaseExemptions[id]\n  if not entry then return false end\n\n  if not entry.expires or entry.expires < GetTime() then\n    vendorPurchaseExemptions[id] = nil\n    return false\n  end\n\n  local count = entry.count or 0\n  if count <= 0 then\n    vendorPurchaseExemptions[id] = nil\n    return false\n  end\n\n  count = count - 1\n  if count > 0 then\n    entry.count = count\n  else\n    vendorPurchaseExemptions[id] = nil\n  end\n  return true\nend\n\nlocal function InstallMerchantPurchaseHooks()\n  if merchantPurchaseHooksInstalled then return end\n  merchantPurchaseHooksInstalled = true\n\n  if type(BuyMerchantItem) == "function" then\n    originalBuyMerchantItem = BuyMerchantItem\n    BuyMerchantItem = function(index, quantity)\n      MarkVendorPurchase(index)\n      if quantity ~= nil then\n        return originalBuyMerchantItem(index, quantity)\n      end\n      return originalBuyMerchantItem(index)\n    end\n  end\n\n  if type(PickupMerchantItem) == "function" then\n    originalPickupMerchantItem = PickupMerchantItem\n    PickupMerchantItem = function(index)\n      -- With an occupied cursor this API is a sell path, not a purchase path.\n      if not CursorHasItem() then\n        MarkVendorPurchase(index)\n      end\n      return originalPickupMerchantItem(index)\n    end\n  end\nend\n'''
if anchor not in lua:
    raise SystemExit('delete-worker anchor not found')
lua = lua.replace(anchor, insert, 1)

old_world = '''  elseif event == "PLAYER_ENTERING_WORLD" then\n    if not DB then InitDB() end\n    ApplyGreyTakeover()\n    InitializeIconRepair()\n'''
new_world = '''  elseif event == "PLAYER_ENTERING_WORLD" then\n    if not DB then InitDB() end\n    ApplyGreyTakeover()\n    InitializeIconRepair()\n    InstallMerchantPurchaseHooks()\n'''
if old_world not in lua:
    raise SystemExit('PLAYER_ENTERING_WORLD anchor not found')
lua = lua.replace(old_world, new_world, 1)

old_closed = '''  elseif event == "MERCHANT_CLOSED" then\n    CancelSellQueue()\n\n  elseif event == "CHAT_MSG_LOOT" then\n    if DB and Enabled("autoDelete") and arg1 and IsSelfLootMessage(arg1) then\n      local id = GetIDFromLink(arg1)\n      if id and DB.deleteList[id] then\n        pendingDeleteIDs[id] = true\n      end\n    end\n'''
new_closed = '''  elseif event == "MERCHANT_CLOSED" then\n    CancelSellQueue()\n    vendorPurchaseExemptions = {}\n\n  elseif event == "CHAT_MSG_LOOT" then\n    if DB and Enabled("autoDelete") and arg1 and IsSelfLootMessage(arg1) then\n      local id = GetIDFromLink(arg1)\n      if id and DB.deleteList[id] then\n        if not ConsumeVendorPurchaseExemption(id) then\n          pendingDeleteIDs[id] = true\n        end\n      end\n    end\n'''
if old_closed not in lua:
    raise SystemExit('merchant/chat anchor not found')
lua = lua.replace(old_closed, new_closed, 1)

lua_path.write_text(lua)
toc_path.write_text(toc)
