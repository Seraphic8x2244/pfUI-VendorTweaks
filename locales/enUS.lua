-- pfUI VendorTweaks localisation: enUS
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["enUS"] = pfUI_translation["enUS"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "Throttle pfUI auto-sell",
    ["VT_AUTO_VENDOR"] = "Auto-Vendor",
    ["VT_AUTO_DELETE"] = "Auto-Delete",
    ["VT_DROP_VENDOR"] = "Drop item here to vendor",
    ["VT_DROP_DELETE"] = "Drop item here to delete",
    ["VT_ITEM_FALLBACK"] = "Item #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "Show delete message in chat",
    ["VT_SHOW_SELL_ANIMATION"] = "Show sell animation",
    ["VT_SHOW_SELL_CHAT"] = "Show sell message in chat",
    ["VT_SOLD"] = "Sold: %s",
    ["VT_SHOW_DELETE_ANIMATION"] = "Show delete animation",
    ["VT_DELETED"] = "Deleted: %s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
    ["VT_DEBUG_TITLE"] = "pfUI VendorTweaks Burn Debug",
    ["VT_DEBUG_PLAY"] = "Play Burn",
    ["VT_DEBUG_PRINT"] = "Print Values",
    ["VT_DEBUG_RESET"] = "Reset",
    ["VT_DEBUG_ITEM_X"] = "Item X",
    ["VT_DEBUG_ITEM_Y"] = "Item Y",
    ["VT_DEBUG_FIRE_X"] = "Fire X",
    ["VT_DEBUG_FIRE_Y"] = "Fire Y",
    ["VT_DEBUG_HINT"] = "Enter = exact value   +/- = 1 UI unit",
    ["VT_DEBUG_PREFIX"] = "pfUI VendorTweaks Debug",
    ["VT_DEBUG_VALUES"] = "item=(%d, %d) fire=(%d, %d)",
}

for key, value in pairs(entries) do
  pfUI_translation["enUS"][key] = value
end
