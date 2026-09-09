from pathlib import Path

source = Path("pfUI-VendorTweaks.lua")
s = source.read_text(encoding="utf-8")

if s.count("-- pfUI-VendorTweaks v0.1.22") != 1:
    raise SystemExit("Expected v0.1.22 source header exactly once")
s = s.replace("-- pfUI-VendorTweaks v0.1.22", "-- pfUI-VendorTweaks v0.1.23", 1)

count = s.count('T_("Vendor Tweaks")')
if count != 2:
    raise SystemExit(f'Expected 2 Vendor Tweaks UI keys, found {count}')
s = s.replace('T_("Vendor Tweaks")', 'T_("VendorTweaks")')
source.write_text(s, encoding="utf-8")

toc = Path("pfUI-VendorTweaks.toc")
t = toc.read_text(encoding="utf-8")
if t.count("## Version: 0.1.22") != 1:
    raise SystemExit("Expected v0.1.22 TOC version exactly once")
t = t.replace("## Version: 0.1.22", "## Version: 0.1.23", 1)
toc.write_text(t, encoding="utf-8")

locales = r'''-- pfUI-VendorTweaks localisation
--
-- VendorTweaks extends pfUI's own translation tables so its interface follows
-- the language selected in pfUI. VendorTweaks is a proper addon/feature name
-- and remains unchanged in every language.
--
-- Keep format specifiers unchanged:
--   %d   %s

if not pfUI_translation then return end

local translations = {
  enUS = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "Throttle pfUI auto-sell",
    ["Auto-Vendor"] = "Auto-Vendor",
    ["Auto-Delete"] = "Auto-Delete",
    ["Drop item here to vendor"] = "Drop item here to vendor",
    ["Drop item here to delete"] = "Drop item here to delete",
    ["Item #%d"] = "Item #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "Deleted: %s",
  },

  deDE = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "pfUI-Autoverkauf drosseln",
    ["Auto-Vendor"] = "Auto-Verkauf",
    ["Auto-Delete"] = "Auto-Löschen",
    ["Drop item here to vendor"] = "Hier zum Verkauf ablegen",
    ["Drop item here to delete"] = "Hier zum Löschen ablegen",
    ["Item #%d"] = "Gegenstand #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "Gelöscht: %s",
  },

  esES = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "Regular venta automática de pfUI",
    ["Auto-Vendor"] = "Venta automática",
    ["Auto-Delete"] = "Borrado automático",
    ["Drop item here to vendor"] = "Suelta aquí para vender",
    ["Drop item here to delete"] = "Suelta aquí para borrar",
    ["Item #%d"] = "Objeto #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "Eliminado: %s",
  },

  frFR = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "Régler la vente auto pfUI",
    ["Auto-Vendor"] = "Vente auto",
    ["Auto-Delete"] = "Suppression auto",
    ["Drop item here to vendor"] = "Déposer ici pour vendre",
    ["Drop item here to delete"] = "Déposer ici pour supprimer",
    ["Item #%d"] = "Objet n°%d",
    ["ID: %d"] = "ID : %d",
    ["Deleted: %s"] = "Supprimé : %s",
  },

  koKR = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "pfUI 자동 판매 속도 조절",
    ["Auto-Vendor"] = "자동 판매",
    ["Auto-Delete"] = "자동 삭제",
    ["Drop item here to vendor"] = "판매할 아이템 놓기",
    ["Drop item here to delete"] = "삭제할 아이템 놓기",
    ["Item #%d"] = "아이템 #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "삭제됨: %s",
  },

  ruRU = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "Регулировать автопродажу pfUI",
    ["Auto-Vendor"] = "Автопродажа",
    ["Auto-Delete"] = "Автоудаление",
    ["Drop item here to vendor"] = "Сюда для продажи",
    ["Drop item here to delete"] = "Сюда для удаления",
    ["Item #%d"] = "Предмет #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "Удалено: %s",
  },

  zhCN = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "调整 pfUI 自动贩卖速度",
    ["Auto-Vendor"] = "自动贩卖",
    ["Auto-Delete"] = "自动删除",
    ["Drop item here to vendor"] = "拖放物品到此贩卖",
    ["Drop item here to delete"] = "拖放物品到此删除",
    ["Item #%d"] = "物品 #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "已删除：%s",
  },

  zhTW = {
    ["VendorTweaks"] = "VendorTweaks",
    ["Throttle pfUI auto-sell"] = "調整 pfUI 自動販賣速度",
    ["Auto-Vendor"] = "自動販賣",
    ["Auto-Delete"] = "自動刪除",
    ["Drop item here to vendor"] = "拖放物品到此販賣",
    ["Drop item here to delete"] = "拖放物品到此刪除",
    ["Item #%d"] = "物品 #%d",
    ["ID: %d"] = "ID: %d",
    ["Deleted: %s"] = "已刪除：%s",
  },
}

for locale, entries in pairs(translations) do
  pfUI_translation[locale] = pfUI_translation[locale] or {}
  for key, value in pairs(entries) do
    pfUI_translation[locale][key] = value
  end
end
'''

Path("locales.lua").write_text(locales, encoding="utf-8")
