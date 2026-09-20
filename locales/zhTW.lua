-- pfUI VendorTweaks localisation: zhTW
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["zhTW"] = pfUI_translation["zhTW"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "調整 pfUI 自動販賣速度",
    ["VT_AUTO_VENDOR"] = "自動販賣",
    ["VT_AUTO_DELETE"] = "自動刪除",
    ["VT_DROP_VENDOR"] = "拖放物品到此販賣",
    ["VT_DROP_DELETE"] = "拖放物品到此刪除",
    ["VT_ITEM_FALLBACK"] = "物品 #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "在聊天中顯示刪除訊息",
    ["VT_SHOW_SELL_ANIMATION"] = "顯示出售動畫",
    ["VT_SHOW_SELL_CHAT"] = "在聊天中顯示出售訊息",
    ["VT_SOLD"] = "已出售：%s",
    ["VT_SHOW_DELETE_ANIMATION"] = "顯示刪除動畫",
    ["VT_DELETED"] = "已刪除：%s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["zhTW"][key] = value
end
