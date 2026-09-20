-- pfUI VendorTweaks localisation: koKR
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["koKR"] = pfUI_translation["koKR"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "pfUI 자동 판매 속도 조절",
    ["VT_AUTO_VENDOR"] = "자동 판매",
    ["VT_AUTO_DELETE"] = "자동 삭제",
    ["VT_DROP_VENDOR"] = "판매할 아이템 놓기",
    ["VT_DROP_DELETE"] = "삭제할 아이템 놓기",
    ["VT_ITEM_FALLBACK"] = "아이템 #%d",
    ["VT_ID"] = "ID: %d",
    ["VT_SHOW_DELETE_CHAT"] = "채팅에 삭제 메시지 표시",
    ["VT_SHOW_SELL_ANIMATION"] = "판매 애니메이션 표시",
    ["VT_SHOW_SELL_CHAT"] = "채팅에 판매 메시지 표시",
    ["VT_SOLD"] = "판매됨: %s",
    ["VT_SHOW_DELETE_ANIMATION"] = "삭제 애니메이션 표시",
    ["VT_DELETED"] = "삭제됨: %s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["koKR"][key] = value
end
