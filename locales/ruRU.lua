-- pfUI VendorTweaks localisation: ruRU
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["ruRU"] = pfUI_translation["ruRU"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "Регулировать автопродажу pfUI",
    ["VT_AUTO_VENDOR"] = "Автопродажа",
    ["VT_AUTO_DELETE"] = "Автоудаление",
    ["VT_DROP_VENDOR"] = "Сюда для продажи",
    ["VT_DROP_DELETE"] = "Сюда для удаления",
    ["VT_ITEM_FALLBACK"] = "Предмет #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "Показывать сообщение об удалении в чате",
    ["VT_SHOW_SELL_ANIMATION"] = "Показывать анимацию продажи",
    ["VT_SHOW_SELL_CHAT"] = "Показывать сообщение о продаже в чате",
    ["VT_SOLD"] = "Продано: %s",
    ["VT_SHOW_DELETE_ANIMATION"] = "Показывать анимацию удаления",
    ["VT_DELETED"] = "Удалено: %s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["ruRU"][key] = value
end
