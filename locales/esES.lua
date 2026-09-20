-- pfUI-VendorTweaks localisation: esES
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["esES"] = pfUI_translation["esES"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "Regular venta automática de pfUI",
    ["VT_AUTO_VENDOR"] = "Venta automática",
    ["VT_AUTO_DELETE"] = "Borrado automático",
    ["VT_DROP_VENDOR"] = "Suelta aquí para vender",
    ["VT_DROP_DELETE"] = "Suelta aquí para borrar",
    ["VT_ITEM_FALLBACK"] = "Objeto #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "Mostrar mensaje de borrado en el chat",
    ["VT_SHOW_SELL_ANIMATION"] = "Mostrar animación de venta",
    ["VT_SHOW_SELL_CHAT"] = "Mostrar mensaje de venta en el chat",
    ["VT_SOLD"] = "Vendido: %s",
    ["VT_SHOW_DELETE_ANIMATION"] = "Mostrar animación de borrado",
    ["VT_DELETED"] = "Eliminado: %s",
    ["VT_BIN"] = "VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["esES"][key] = value
end
