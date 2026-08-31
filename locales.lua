-- pfUI-VendorTweaks localization keys
-- VendorTweaks extends pfUI's translation table so the component follows
-- pfUI's selected language. Missing translations intentionally fall back to
-- the English key through pfUI.env.T.

if not pfUI_translation then return end

local keys = {
  "Vendor Tweaks",
  "Take over pfUI grey selling (throttled)",
  "Auto-sell greys when merchant opens",
  "Vendor sell delay: %.2f seconds",
  "Auto-Vendor",
  "Auto-Delete",
  "Drop item here to vendor",
  "Drop item here to delete",
  "Item #%d",
  "ID: %d",
  "Deleted: %s",
}

pfUI_translation["enUS"] = pfUI_translation["enUS"] or {}
for _, key in ipairs(keys) do
  if pfUI_translation["enUS"][key] == nil then
    pfUI_translation["enUS"][key] = key
  end
end

-- Supported pfUI locales. These tables are deliberately not populated with
-- guessed translations; adding translated values here (or in a separate locale
-- contribution) will make VendorTweaks use them automatically.
local locales = { "deDE", "esES", "frFR", "koKR", "ruRU", "zhCN" }
for _, locale in ipairs(locales) do
  pfUI_translation[locale] = pfUI_translation[locale] or {}
end
