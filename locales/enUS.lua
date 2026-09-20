-- pfUI-VendorTweaks localisation: enUS
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["enUS"] = pfUI_translation["enUS"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "VendorTweaks",
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
    ["VT_BIN"] = "VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["enUS"][key] = value
end
