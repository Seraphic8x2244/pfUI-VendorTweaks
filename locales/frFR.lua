-- pfUI VendorTweaks localisation: frFR
-- Keep format specifiers unchanged: %d %s

if not pfUI_translation then return end

pfUI_translation["frFR"] = pfUI_translation["frFR"] or {}
local entries = {
    ["VT_VENDOR_TWEAKS"] = "pfUI VendorTweaks",
    ["VT_THROTTLE_AUTOSELL"] = "Régler la vente auto pfUI",
    ["VT_AUTO_VENDOR"] = "Vente auto",
    ["VT_AUTO_DELETE"] = "Suppression auto",
    ["VT_DROP_VENDOR"] = "Déposer ici pour vendre",
    ["VT_DROP_DELETE"] = "Déposer ici pour supprimer",
    ["VT_ITEM_FALLBACK"] = "Objet n°%d",
    ["VT_ID"] = "ID : %d",
    ["VT_SHOW_DELETE_CHAT"] = "Afficher le message de suppression dans le chat",
    ["VT_SHOW_SELL_ANIMATION"] = "Afficher l’animation de vente",
    ["VT_SHOW_SELL_CHAT"] = "Afficher le message de vente dans le chat",
    ["VT_SOLD"] = "Vendu : %s",
    ["VT_SHOW_DELETE_ANIMATION"] = "Afficher l’animation de suppression",
    ["VT_DELETED"] = "Supprimé : %s",
    ["VT_BIN"] = "pfUI VendorTweaks Bin",
}

for key, value in pairs(entries) do
  pfUI_translation["frFR"][key] = value
end
