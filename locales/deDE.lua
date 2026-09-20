-- pfUI VendorTweaks localisation: deDE
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["deDE"] = pfUI_translation["deDE"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "pfUI-Autoverkauf drosseln",
    ["VT_AUTO_VENDOR"] = "Auto-Verkauf",
    ["VT_AUTO_DELETE"] = "Auto-Löschen",
    ["VT_DROP_VENDOR"] = "Hier zum Verkauf ablegen",
    ["VT_DROP_DELETE"] = "Hier zum Löschen ablegen",
    ["VT_ITEM_FALLBACK"] = "Gegenstand #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "Löschmeldung im Chat anzeigen",
    ["VT_SHOW_SELL_ANIMATION"] = "Verkaufsanimation anzeigen",
    ["VT_SHOW_SELL_CHAT"] = "Verkaufsmeldung im Chat anzeigen",
    ["VT_SOLD"] = "Verkauft: %s",
    ["VT_SHOW_DELETE_ANIMATION"] = "Löschanimation anzeigen",
    ["VT_DELETED"] = "Gelöscht: %s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["deDE"][key] = value
end
