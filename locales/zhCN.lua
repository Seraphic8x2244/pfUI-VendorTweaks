-- pfUI VendorTweaks localisation: zhCN
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["zhCN"] = pfUI_translation["zhCN"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "调整 pfUI 自动贩卖速度",
    ["VT_AUTO_VENDOR"] = "自动贩卖",
    ["VT_AUTO_DELETE"] = "自动删除",
    ["VT_DROP_VENDOR"] = "拖放物品到此贩卖",
    ["VT_DROP_DELETE"] = "拖放物品到此删除",
    ["VT_ITEM_FALLBACK"] = "物品 #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "在聊天中显示删除消息",
    ["VT_SHOW_SELL_ANIMATION"] = "显示出售动画",
    ["VT_SHOW_SELL_CHAT"] = "在聊天中显示出售消息",
    ["VT_SOLD"] = "已出售：%s",
    ["VT_SHOW_DELETE_ANIMATION"] = "显示删除动画",
    ["VT_DELETED"] = "已删除：%s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["zhCN"][key] = value
end
