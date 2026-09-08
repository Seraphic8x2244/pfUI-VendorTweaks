-- pfUI-VendorTweaks localisation
--
-- VendorTweaks extends pfUI's own translation tables so its interface follows
-- the language selected in pfUI. English keys are the source strings and also
-- the fallback when a translation is missing.
--
-- When adding translations, keep format specifiers unchanged:
--   %.2f   %d   %s

if not pfUI_translation then return end

local keys = {
  "Vendor Tweaks",
  "Throttle pfUI auto-sell",
  "Auto-Vendor",
  "Auto-Delete",
  "Drop item here to vendor",
  "Drop item here to delete",
  "Item #%d",
  "ID: %d",
  "Deleted: %s",
}

-- Match the translation locales shipped by pfUI (Shagu and brues-code).
local locales = {
  "enUS",
  "deDE",
  "esES",
  "frFR",
  "koKR",
  "ruRU",
  "zhCN",
  "zhTW",
}

for _, locale in ipairs(locales) do
  pfUI_translation[locale] = pfUI_translation[locale] or {}
end

-- Keep the English source strings explicit. pfUI will fall back to the key for
-- missing translations, but populating enUS makes this file self-contained and
-- gives future translations one authoritative source-string list to follow.
for _, key in ipairs(keys) do
  if pfUI_translation["enUS"][key] == nil then
    pfUI_translation["enUS"][key] = key
  end
end

-- Non-English translations can be added directly to the tables above, e.g.
-- pfUI_translation["deDE"]["Vendor Tweaks"] = "..."
