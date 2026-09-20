-- pfUI-VendorTweaks localisation
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
    ["Show delete message in chat"] = "Show delete message in chat",
    ["Show sell animation"] = "Show sell animation",
    ["Show sell message in chat"] = "Show sell message in chat",
    ["Sold: %s"] = "Sold: %s",
    ["Show delete animation"] = "Show delete animation",
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
    ["Show delete message in chat"] = "Löschmeldung im Chat anzeigen",
    ["Show sell animation"] = "Verkaufsanimation anzeigen",
    ["Show sell message in chat"] = "Verkaufsmeldung im Chat anzeigen",
    ["Sold: %s"] = "Verkauft: %s",
    ["Show delete animation"] = "Löschanimation anzeigen",
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
    ["Show delete message in chat"] = "Mostrar mensaje de borrado en el chat",
    ["Show sell animation"] = "Mostrar animación de venta",
    ["Show sell message in chat"] = "Mostrar mensaje de venta en el chat",
    ["Sold: %s"] = "Vendido: %s",
    ["Show delete animation"] = "Mostrar animación de borrado",
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
    ["Show delete message in chat"] = "Afficher le message de suppression dans le chat",
    ["Show sell animation"] = "Afficher l’animation de vente",
    ["Show sell message in chat"] = "Afficher le message de vente dans le chat",
    ["Sold: %s"] = "Vendu : %s",
    ["Show delete animation"] = "Afficher l’animation de suppression",
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
    ["Show delete message in chat"] = "채팅에 삭제 메시지 표시",
    ["Show sell animation"] = "판매 애니메이션 표시",
    ["Show sell message in chat"] = "채팅에 판매 메시지 표시",
    ["Sold: %s"] = "판매됨: %s",
    ["Show delete animation"] = "삭제 애니메이션 표시",
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
    ["Show delete message in chat"] = "Показывать сообщение об удалении в чате",
    ["Show sell animation"] = "Показывать анимацию продажи",
    ["Show sell message in chat"] = "Показывать сообщение о продаже в чате",
    ["Sold: %s"] = "Продано: %s",
    ["Show delete animation"] = "Показывать анимацию удаления",
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
    ["Show delete message in chat"] = "在聊天中显示删除消息",
    ["Show sell animation"] = "显示出售动画",
    ["Show sell message in chat"] = "在聊天中显示出售消息",
    ["Sold: %s"] = "已出售：%s",
    ["Show delete animation"] = "显示删除动画",
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
    ["Show delete message in chat"] = "在聊天中顯示刪除訊息",
    ["Show sell animation"] = "顯示出售動畫",
    ["Show sell message in chat"] = "在聊天中顯示出售訊息",
    ["Sold: %s"] = "已出售：%s",
    ["Show delete animation"] = "顯示刪除動畫",
    ["Deleted: %s"] = "已刪除：%s",
  },
}

for locale, entries in pairs(translations) do
  pfUI_translation[locale] = pfUI_translation[locale] or {}
  for key, value in pairs(entries) do
    pfUI_translation[locale][key] = value
  end
end
