-- pfUI-VendorTweaks v0.1.8
-- Vanilla WoW 1.12.1 / pfUI (Shagu + brues-code)
-- Component-only external addon.

if not pfUI then return end

local ADDON_NAME = "pfUI-VendorTweaks"
local DB = nil

-- -----------------------------------------------------------------------------
-- SavedVariables: bind only after the addon SavedVariables have been restored.
-- -----------------------------------------------------------------------------
local function InitDB()
  if type(pfUI_VendorTweaks) ~= "table" then
    pfUI_VendorTweaks = {}
  end

  DB = pfUI_VendorTweaks

  if DB.interval == nil then DB.interval = "0.35" end
  if DB.takeoverGreys == nil then DB.takeoverGreys = "0" end
  if DB.autoSellGreys == nil then DB.autoSellGreys = "0" end
  if DB.autoVendor == nil then DB.autoVendor = "1" end
  if DB.autoDelete == nil then DB.autoDelete = "1" end
  if type(DB.vendorList) ~= "table" then DB.vendorList = {} end
  if type(DB.deleteList) ~= "table" then DB.deleteList = {} end
end

local function GetInterval()
  local n = DB and tonumber(DB.interval) or 0.35
  if n < 0.05 then n = 0.05 end
  if n > 1.50 then n = 1.50 end
  return n
end

local function Enabled(key)
  return DB and DB[key] == "1"
end

local function GetIDFromLink(link)
  if not link then return nil end
  local _, _, id = string.find(link, "item:(%d+)")
  return id and tonumber(id) or nil
end

-- -----------------------------------------------------------------------------
-- Localized self-loot matching
-- -----------------------------------------------------------------------------
local selfLootPatterns = {}

local function AddSelfLootPattern(str)
  if not str then return end

  if pfUI.api and pfUI.api.SanitizePattern then
    table.insert(selfLootPatterns, "^" .. pfUI.api.SanitizePattern(str) .. "$")
  else
    local pattern = string.gsub(str, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    pattern = string.gsub(pattern, "%%%%s", "(.+)")
    pattern = string.gsub(pattern, "%%%%d", "(%%d+)")
    table.insert(selfLootPatterns, "^" .. pattern .. "$")
  end
end

local function InitLootPatterns()
  selfLootPatterns = {}
  AddSelfLootPattern(LOOT_ITEM_SELF)
  AddSelfLootPattern(LOOT_ITEM_SELF_MULTIPLE)
  AddSelfLootPattern(LOOT_ITEM_CREATED_SELF)
  AddSelfLootPattern(LOOT_ITEM_PUSHED_SELF)
  AddSelfLootPattern(LOOT_ITEM_PUSHED_SELF_MULTIPLE)
end

local function IsSelfLootMessage(msg)
  if not msg then return false end
  for _, pattern in ipairs(selfLootPatterns) do
    if string.find(msg, pattern) then return true end
  end
  return false
end

-- -----------------------------------------------------------------------------
-- Cursor tracking for Vanilla drag/drop
-- -----------------------------------------------------------------------------
local cursorItem = { id = nil, name = nil, bag = nil, slot = nil }
local originalPickupContainerItem = PickupContainerItem

PickupContainerItem = function(bag, slot)
  local link = GetContainerItemLink(bag, slot)
  if link then
    local id = GetIDFromLink(link)
    local name = id and GetItemInfo(id) or nil
    cursorItem = { id = id, name = name, bag = bag, slot = slot }
  else
    cursorItem = { id = nil, name = nil, bag = nil, slot = nil }
  end
  return originalPickupContainerItem(bag, slot)
end

-- -----------------------------------------------------------------------------
-- Shared throttled vendor engine
-- Both grey takeover and Auto-Vendor feed this one queue.
-- -----------------------------------------------------------------------------
local sellQueue = {}
local sellTimer = 0
local worker = CreateFrame("Frame", "pfVendorTweaksWorker", UIParent)
worker:Hide()

worker:SetScript("OnUpdate", function()
  sellTimer = sellTimer + arg1
  if sellTimer < GetInterval() then return end
  sellTimer = 0

  if table.getn(sellQueue) == 0 then
    worker:Hide()
    return
  end

  if not MerchantFrame:IsVisible() then
    sellQueue = {}
    worker:Hide()
    return
  end

  local item = table.remove(sellQueue, 1)
  local currentLink = GetContainerItemLink(item.bag, item.slot)
  local currentID = GetIDFromLink(currentLink)

  -- Fail closed if the player moved/replaced an item after queue creation.
  if currentID and currentID == item.id then
    UseContainerItem(item.bag, item.slot)
  end
end)

local function StartSellQueue(includeGreys, includeCustom)
  if not DB then return end

  sellQueue = {}

  for bag = 0, 4 do
    local size = GetContainerNumSlots(bag) or 0
    for slot = 1, size do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local id = GetIDFromLink(link)
        if id then
          local _, _, quality = GetItemInfo(id)
          local shouldSell = false

          if includeGreys and quality == 0 then
            shouldSell = true
          end

          if includeCustom and DB.vendorList[id] then
            shouldSell = true
          end

          if shouldSell then
            table.insert(sellQueue, { bag = bag, slot = slot, id = id })
          end
        end
      end
    end
  end

  if table.getn(sellQueue) > 0 then
    sellTimer = 0
    worker:Show()
  else
    worker:Hide()
  end
end

local function CancelSellQueue()
  sellQueue = {}
  worker:Hide()
end

-- -----------------------------------------------------------------------------
-- pfUI grey-selling takeover
-- Reversible and independent from Auto-Vendor / Auto-Delete.
-- -----------------------------------------------------------------------------
local originalGlobalAutosell = nil
local originalMerchantSellgrays = nil
local capturedGlobalAutosell = false
local capturedMerchantSellgrays = false
local hookedVendorButton = nil
local originalVendorButtonOnClick = nil

local function SuppressPfUIGreyAutosell()
  local C = pfUI_config or {}

  -- Standard Shagu pfUI.
  if C.global and C.global.autosell ~= nil then
    if not capturedGlobalAutosell then
      originalGlobalAutosell = C.global.autosell
      capturedGlobalAutosell = true
    end
    C.global.autosell = "0"
  end

  -- Compatibility with forks/older configs that expose this path.
  if C.merchant and C.merchant.sellgrays ~= nil then
    if not capturedMerchantSellgrays then
      originalMerchantSellgrays = C.merchant.sellgrays
      capturedMerchantSellgrays = true
    end
    C.merchant.sellgrays = "0"
  end
end

local function RestorePfUIGreyAutosell()
  local C = pfUI_config or {}

  if capturedGlobalAutosell and C.global then
    C.global.autosell = originalGlobalAutosell
  end
  if capturedMerchantSellgrays and C.merchant then
    C.merchant.sellgrays = originalMerchantSellgrays
  end

  originalGlobalAutosell = nil
  originalMerchantSellgrays = nil
  capturedGlobalAutosell = false
  capturedMerchantSellgrays = false
end

local function RestorePfUIVendorButton()
  if hookedVendorButton then
    hookedVendorButton:SetScript("OnClick", originalVendorButtonOnClick)
  end
  hookedVendorButton = nil
  originalVendorButtonOnClick = nil
end

local function HookPfUIVendorButton()
  if not Enabled("takeoverGreys") then return end

  local button = getglobal("pfMerchantAutoVendorButton")
  if not button then return end
  if hookedVendorButton == button then return end

  RestorePfUIVendorButton()
  hookedVendorButton = button
  originalVendorButtonOnClick = button:GetScript("OnClick")

  -- Preserve pfUI's button and tooltip; only replace the action.
  button:SetScript("OnClick", function()
    StartSellQueue(true, false)
  end)
end

local function ApplyGreyTakeover()
  if not DB then return end

  if Enabled("takeoverGreys") then
    SuppressPfUIGreyAutosell()
    HookPfUIVendorButton()
  else
    RestorePfUIVendorButton()
    RestorePfUIGreyAutosell()
  end
end

-- -----------------------------------------------------------------------------
-- Loot-only Auto-Delete
-- -----------------------------------------------------------------------------
local pendingDeleteIDs = {}
local deletePendingAt = nil
local DELETE_DEBOUNCE = 0.20
local deleteWorker = CreateFrame("Frame", "pfVendorTweaksDeleteWorker", UIParent)
deleteWorker:Hide()

local function ExecuteSafeDelete()
  if not DB or not Enabled("autoDelete") then
    pendingDeleteIDs = {}
    deletePendingAt = nil
    deleteWorker:Hide()
    return
  end

  if CursorHasItem() then
    deleteWorker:Show()
    return
  end

  for bag = 0, 4 do
    local size = GetContainerNumSlots(bag) or 0
    for slot = 1, size do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local id = GetIDFromLink(link)
        if id and pendingDeleteIDs[id] and DB.deleteList[id] then
          PickupContainerItem(bag, slot)
          DeleteCursorItem()
          DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[VendorTweaks]|r Deleted: " .. link)
        end
      end
    end
  end

  pendingDeleteIDs = {}
  deletePendingAt = nil
  deleteWorker:Hide()
end

deleteWorker:SetScript("OnUpdate", function()
  if not deletePendingAt or GetTime() < deletePendingAt then return end
  if CursorHasItem() then return end
  ExecuteSafeDelete()
end)

-- -----------------------------------------------------------------------------
-- pfUI Components configuration
-- -----------------------------------------------------------------------------
local function T_(key)
  if pfUI.env and pfUI.env.T and pfUI.env.T[key] then
    return pfUI.env.T[key]
  end
  return key
end

local function BuildComponentsPanel(parent)
  if parent.pfVTBuilt then return end
  parent.pfVTBuilt = true
  parent:SetHeight(620)

  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
  title:SetText("Vendor Tweaks")

  local function MakeCheckbox(anchor, y, text, key, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(20)
    cb:SetHeight(20)
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
    if pfUI.api and pfUI.api.SkinCheckbox then pfUI.api.SkinCheckbox(cb) end

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    label:SetText(text)

    cb:SetScript("OnClick", function()
      if not DB then return end
      DB[key] = this:GetChecked() and "1" or "0"
      if onChange then onChange() end
    end)

    return cb
  end

  local takeover = MakeCheckbox(title, -12,
    "Take over pfUI grey selling (throttled)", "takeoverGreys", function()
      CancelSellQueue()
      ApplyGreyTakeover()
    end)

  local autoGreys = MakeCheckbox(takeover, -4,
    "Auto-sell greys when merchant opens", "autoSellGreys")

  local autoVendor = MakeCheckbox(autoGreys, -4,
    "Enable Auto-Vendor list", "autoVendor")

  local autoDelete = MakeCheckbox(autoVendor, -4,
    "Enable Auto-Delete list", "autoDelete", function()
      if not Enabled("autoDelete") then
        pendingDeleteIDs = {}
        deleteWorker:Hide()
      end
    end)

  local delayLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  delayLabel:SetPoint("TOPLEFT", autoDelete, "BOTTOMLEFT", 0, -16)

  local slider = CreateFrame("Slider", "pfVT_ComponentSpeedSlider", parent, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", delayLabel, "BOTTOMLEFT", 0, -8)
  slider:SetWidth(220)
  slider:SetHeight(16)
  slider:SetMinMaxValues(0.05, 1.50)
  slider:SetValueStep(0.05)
  if pfUI.api and pfUI.api.SkinSlider then pfUI.api.SkinSlider(slider) end
  getglobal(slider:GetName() .. "Low"):SetText("0.05s")
  getglobal(slider:GetName() .. "High"):SetText("1.50s")
  slider:SetScript("OnValueChanged", function()
    if not DB then return end
    local val = floor(this:GetValue() * 100 + 0.5) / 100
    DB.interval = tostring(val)
    delayLabel:SetText(string.format("Vendor sell delay: %.2f seconds", val))
  end)

  local vendorHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  vendorHeader:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -30)
  vendorHeader:SetText("Auto-Vendor")

  local deleteHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  deleteHeader:SetPoint("TOPLEFT", vendorHeader, "TOPLEFT", 220, 0)
  deleteHeader:SetText("Auto-Delete")

  local function MakeDropSlot(header, text)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetWidth(195)
    frame:SetHeight(42)
    frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -7)
    if pfUI.api and pfUI.api.CreateBackdrop then pfUI.api.CreateBackdrop(frame, nil, true) end
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", frame, "CENTER", 0, 0)
    label:SetText(text)
    return frame
  end

  local vendorDrop = MakeDropSlot(vendorHeader, "Drop item here to vendor")
  local deleteDrop = MakeDropSlot(deleteHeader, "Drop item here to delete")

  local vendorPool = {}
  local deletePool = {}

  local function MakeRow(pool, red)
    local row = CreateFrame("Button", nil, parent)
    row:SetWidth(195)
    row:SetHeight(18)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row, "LEFT", 2, 0)
    if red then row.text:SetTextColor(1, .4, .4) end
    row.del = CreateFrame("Button", nil, row)
    row.del:SetWidth(16)
    row.del:SetHeight(16)
    row.del:SetPoint("RIGHT", row, "RIGHT", -1, 0)
    local x = row.del:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER", row.del, "CENTER", 0, 0)
    x:SetText("|cffff5555x|r")
    table.insert(pool, row)
    return row
  end

  local function Refresh()
    if not DB then return end

    takeover:SetChecked(Enabled("takeoverGreys"))
    autoGreys:SetChecked(Enabled("autoSellGreys"))
    autoVendor:SetChecked(Enabled("autoVendor"))
    autoDelete:SetChecked(Enabled("autoDelete"))

    local interval = GetInterval()
    slider:SetValue(interval)
    delayLabel:SetText(string.format("Vendor sell delay: %.2f seconds", interval))

    for _, row in ipairs(vendorPool) do row:Hide() end
    for _, row in ipairs(deletePool) do row:Hide() end

    local i = 0
    for id, name in pairs(DB.vendorList) do
      i = i + 1
      local idKey = id
      local row = vendorPool[i] or MakeRow(vendorPool, false)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", vendorDrop, "BOTTOMLEFT", 0, -7 - ((i - 1) * 19))
      row.text:SetText(type(name) == "string" and name or ("ID: " .. idKey))
      row.del:SetScript("OnClick", function()
        DB.vendorList[idKey] = nil
        Refresh()
      end)
      row:Show()
    end

    i = 0
    for id, name in pairs(DB.deleteList) do
      i = i + 1
      local idKey = id
      local row = deletePool[i] or MakeRow(deletePool, true)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", deleteDrop, "BOTTOMLEFT", 0, -7 - ((i - 1) * 19))
      row.text:SetText(type(name) == "string" and name or ("ID: " .. idKey))
      row.del:SetScript("OnClick", function()
        DB.deleteList[idKey] = nil
        Refresh()
      end)
      row:Show()
    end
  end

  local function HandleDrop(mode)
    if not DB or not CursorHasItem() or not cursorItem.id then return end

    if mode == "vendor" then
      DB.vendorList[cursorItem.id] = cursorItem.name or ("Item #" .. cursorItem.id)
      DB.deleteList[cursorItem.id] = nil
    else
      DB.deleteList[cursorItem.id] = cursorItem.name or ("Item #" .. cursorItem.id)
      DB.vendorList[cursorItem.id] = nil
    end

    if cursorItem.bag and cursorItem.slot then
      PickupContainerItem(cursorItem.bag, cursorItem.slot)
    else
      ClearCursor()
    end

    cursorItem = { id = nil, name = nil, bag = nil, slot = nil }
    Refresh()
  end

  vendorDrop:SetScript("OnClick", function() HandleDrop("vendor") end)
  vendorDrop:SetScript("OnReceiveDrag", function() HandleDrop("vendor") end)
  deleteDrop:SetScript("OnClick", function() HandleDrop("delete") end)
  deleteDrop:SetScript("OnReceiveDrag", function() HandleDrop("delete") end)

  parent:SetScript("OnShow", function() Refresh() end)
  Refresh()
end

if pfUI.gui and pfUI.gui.CreateGUIEntry then
  pfUI.gui.CreateGUIEntry(T_("Components"), "Vendor Tweaks", function()
    BuildComponentsPanel(this)
  end)
end

-- -----------------------------------------------------------------------------
-- Events
-- -----------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("BAG_UPDATE")

eventFrame:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" then
    if arg1 == ADDON_NAME then
      InitDB()
      InitLootPatterns()
      ApplyGreyTakeover()
    end

  elseif event == "VARIABLES_LOADED" then
    -- Fallback for unusual 1.12 loaders/forks.
    if not DB then
      InitDB()
      InitLootPatterns()
      ApplyGreyTakeover()
    end

  elseif event == "PLAYER_ENTERING_WORLD" then
    if not DB then InitDB() end
    ApplyGreyTakeover()

  elseif event == "PLAYER_LOGOUT" then
    RestorePfUIVendorButton()
    RestorePfUIGreyAutosell()

  elseif event == "MERCHANT_SHOW" then
    if not DB then return end

    -- pfUI may create its merchant button lazily; retry the narrow hook here.
    if Enabled("takeoverGreys") then
      SuppressPfUIGreyAutosell()
      HookPfUIVendorButton()
    end

    local includeGreys = Enabled("takeoverGreys") and Enabled("autoSellGreys")
    local includeCustom = Enabled("autoVendor")

    if includeGreys or includeCustom then
      StartSellQueue(includeGreys, includeCustom)
    end

  elseif event == "MERCHANT_CLOSED" then
    CancelSellQueue()

  elseif event == "CHAT_MSG_LOOT" then
    if DB and Enabled("autoDelete") and arg1 and IsSelfLootMessage(arg1) then
      local _, _, link = string.find(arg1, "(item:%d+:%d+:%d+:%d+)")
      if link then
        local id = GetIDFromLink(link)
        if id and DB.deleteList[id] then
          pendingDeleteIDs[id] = true
        end
      end
    end

  elseif event == "BAG_UPDATE" then
    if DB and Enabled("autoDelete") then
      for _ in pairs(pendingDeleteIDs) do
        -- Debounce bag activity: spam-looting may fire several BAG_UPDATEs.
        -- Wait until bags have been quiet for 0.20s, then scan/delete once.
        deletePendingAt = GetTime() + DELETE_DEBOUNCE
        deleteWorker:Show()
        break
      end
    end
  end
end)
