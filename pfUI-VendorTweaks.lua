-- pfUI-VendorTweaks v0.1.12
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

local function T_(key)
  if pfUI.env and pfUI.env.T and pfUI.env.T[key] then
    return pfUI.env.T[key]
  end
  return key
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

local function VendorTweaksGreyButtonClick()
  StartSellQueue(true, false)
end

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

  local current = button:GetScript("OnClick")
  if hookedVendorButton == button and current == VendorTweaksGreyButtonClick then
    return
  end

  if hookedVendorButton and hookedVendorButton ~= button then
    RestorePfUIVendorButton()
  end

  -- If another addon/fork replaced the handler after our first hook, preserve
  -- that newest handler as the one to restore when takeover is disabled.
  hookedVendorButton = button
  originalVendorButtonOnClick = current

  -- Preserve pfUI's button and tooltip; only replace the action.
  button:SetScript("OnClick", VendorTweaksGreyButtonClick)
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
-- CHAT_MSG_LOOT arms IDs, BAG_UPDATE activity is debounced for 0.20s, then the
-- worker deletes one matching stack per step. Any lock/cursor verification
-- failure aborts the pending cleanup (fail closed; no retry loop).
-- -----------------------------------------------------------------------------
local pendingDeleteIDs = {}
local deletePendingAt = nil
local DELETE_DEBOUNCE = 0.20
local DELETE_STEP_DELAY = 0.10
local deleteWorker = CreateFrame("Frame", "pfVendorTweaksDeleteWorker", UIParent)
deleteWorker:Hide()

local function StopDeleteWorker(clearPending)
  if clearPending then pendingDeleteIDs = {} end
  deletePendingAt = nil
  deleteWorker:Hide()
end

local function ExecuteSafeDeleteStep()
  if not DB or not Enabled("autoDelete") then
    StopDeleteWorker(true)
    return
  end

  -- Never interfere with an item already held by the player.
  if CursorHasItem() then return end

  for bag = 0, 4 do
    local size = GetContainerNumSlots(bag) or 0
    for slot = 1, size do
      local link = GetContainerItemLink(bag, slot)
      local id = GetIDFromLink(link)

      if id and pendingDeleteIDs[id] and DB.deleteList[id] then
        local _, _, locked = GetContainerItemInfo(bag, slot)
        if locked then
          StopDeleteWorker(true)
          return
        end

        PickupContainerItem(bag, slot)

        local cursorType, cursorID = GetCursorInfo()
        if cursorType ~= "item" or tonumber(cursorID) ~= id then
          if CursorHasItem() then ClearCursor() end
          StopDeleteWorker(true)
          return
        end

        DeleteCursorItem()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[VendorTweaks]|r " .. string.format(T_("Deleted: %s"), link))

        -- Let the server settle this deletion before looking for another stack.
        deletePendingAt = GetTime() + DELETE_STEP_DELAY
        deleteWorker:Show()
        return
      end
    end
  end

  -- No matching pending items remain in the bags.
  StopDeleteWorker(true)
end

deleteWorker:SetScript("OnUpdate", function()
  if not deletePendingAt or GetTime() < deletePendingAt then return end
  if CursorHasItem() then return end
  ExecuteSafeDeleteStep()
end)

-- -----------------------------------------------------------------------------
-- pfUI Components configuration
-- -----------------------------------------------------------------------------
local function BuildComponentsPanel(parent)
  if parent.pfVTBuilt then return end
  parent.pfVTBuilt = true
  parent:SetHeight(620)

  local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
  title:SetText(T_("Vendor Tweaks"))

  -- pfUI's modern checkbox skin builds its backdrop from child frames. A texture
  -- on the CheckButton itself can therefore render underneath that backdrop even
  -- on the OVERLAY draw layer. Keep the mark on its own child frame above every
  -- pfUI backdrop frame instead of relying on SetCheckedTexture().
  local function AttachCheckboxMark(cb)
    local mark = CreateFrame("Frame", nil, cb)
    mark:SetAllPoints(cb)

    local level = cb:GetFrameLevel() + 1
    if cb.backdrop and cb.backdrop.GetFrameLevel and cb.backdrop:GetFrameLevel() >= level then
      level = cb.backdrop:GetFrameLevel() + 1
    end
    if cb.backdrop_border and cb.backdrop_border.GetFrameLevel and cb.backdrop_border:GetFrameLevel() >= level then
      level = cb.backdrop_border:GetFrameLevel() + 1
    end
    mark:SetFrameLevel(level)
    mark:EnableMouse(false)

    local check = mark:CreateTexture(nil, "OVERLAY")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetAllPoints(mark)

    cb.pfVTMark = mark
    mark:Hide()
  end

  local function UpdateCheckboxMark(cb)
    if not cb or not cb.pfVTMark then return end
    if cb:GetChecked() then
      cb.pfVTMark:Show()
    else
      cb.pfVTMark:Hide()
    end
  end

  local function SetCheckboxChecked(cb, value)
    cb:SetChecked(value)
    UpdateCheckboxMark(cb)
  end

  local function MakeCheckbox(anchor, y, text, key, onChange)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetWidth(20)
    cb:SetHeight(20)
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
    if pfUI.api and pfUI.api.SkinCheckbox then pfUI.api.SkinCheckbox(cb) end
    AttachCheckboxMark(cb)

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    label:SetText(text)

    cb:SetScript("OnClick", function()
      if not DB then return end
      DB[key] = this:GetChecked() and "1" or "0"
      UpdateCheckboxMark(this)
      if onChange then onChange() end
    end)

    return cb
  end

  local takeover = MakeCheckbox(title, -12,
    T_("Take over pfUI grey selling (throttled)"), "takeoverGreys", function()
      CancelSellQueue()
      ApplyGreyTakeover()
    end)

  local autoGreys = MakeCheckbox(takeover, -4,
    T_("Auto-sell greys when merchant opens"), "autoSellGreys")

  local delayLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  delayLabel:SetPoint("TOPLEFT", autoGreys, "BOTTOMLEFT", 0, -16)

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
    delayLabel:SetText(string.format(T_("Vendor sell delay: %.2f seconds"), val))
  end)

  -- The list toggles double as the two side-by-side section subheaders.
  local autoVendor = MakeCheckbox(slider, -24,
    T_("Auto-Vendor"), "autoVendor")

  local autoDelete = CreateFrame("CheckButton", nil, parent)
  autoDelete:SetWidth(20)
  autoDelete:SetHeight(20)
  autoDelete:SetPoint("TOPLEFT", autoVendor, "TOPLEFT", 220, 0)
  if pfUI.api and pfUI.api.SkinCheckbox then pfUI.api.SkinCheckbox(autoDelete) end
  AttachCheckboxMark(autoDelete)

  local deleteLabel = autoDelete:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  deleteLabel:SetPoint("LEFT", autoDelete, "RIGHT", 5, 0)
  deleteLabel:SetText(T_("Auto-Delete"))

  autoDelete:SetScript("OnClick", function()
    if not DB then return end
    DB.autoDelete = this:GetChecked() and "1" or "0"
    UpdateCheckboxMark(this)
    if not Enabled("autoDelete") then
      pendingDeleteIDs = {}
      deletePendingAt = nil
      deleteWorker:Hide()
    end
  end)

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

  local vendorDrop = MakeDropSlot(autoVendor, T_("Drop item here to vendor"))
  local deleteDrop = MakeDropSlot(autoDelete, T_("Drop item here to delete"))

  local LIST_WIDTH = 195
  local LIST_HEIGHT = 190
  local ROW_HEIGHT = 19

  local function MakeListScroll(drop)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetWidth(LIST_WIDTH)
    scroll:SetHeight(LIST_HEIGHT)
    scroll:SetPoint("TOPLEFT", drop, "BOTTOMLEFT", 0, -7)
    if pfUI.api and pfUI.api.CreateBackdrop then pfUI.api.CreateBackdrop(scroll, nil, true) end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(LIST_WIDTH - 4)
    child:SetHeight(LIST_HEIGHT)
    scroll:SetScrollChild(child)

    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function()
      local maxScroll = math.max(0, child:GetHeight() - scroll:GetHeight())
      local nextScroll = scroll:GetVerticalScroll() - (arg1 * (ROW_HEIGHT * 3))
      if nextScroll < 0 then nextScroll = 0 end
      if nextScroll > maxScroll then nextScroll = maxScroll end
      scroll:SetVerticalScroll(nextScroll)
    end)

    return scroll, child
  end

  local vendorScroll, vendorChild = MakeListScroll(vendorDrop)
  local deleteScroll, deleteChild = MakeListScroll(deleteDrop)

  local vendorPool = {}
  local deletePool = {}

  local function MakeRow(pool, rowParent, red)
    local row = CreateFrame("Button", nil, rowParent)
    row:SetWidth(LIST_WIDTH - 4)
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

  local function DisplayName(id, savedName)
    local liveName = GetItemInfo(id)
    if liveName then
      return liveName
    end
    if type(savedName) == "string" then
      return savedName
    end
    return string.format(T_("ID: %d"), id)
  end

  local function Refresh()
    if not DB then return end

    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))
    SetCheckboxChecked(autoGreys, Enabled("autoSellGreys"))
    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))
    SetCheckboxChecked(autoDelete, Enabled("autoDelete"))

    local interval = GetInterval()
    slider:SetValue(interval)
    delayLabel:SetText(string.format(T_("Vendor sell delay: %.2f seconds"), interval))

    for _, row in ipairs(vendorPool) do row:Hide() end
    for _, row in ipairs(deletePool) do row:Hide() end

    local i = 0
    for id, name in pairs(DB.vendorList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)
      local display = DisplayName(idKey, name)
      if display and display ~= name then DB.vendorList[id] = display end
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", vendorChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.vendorList[idKey] = nil
        DB.vendorList[tostring(idKey)] = nil
        Refresh()
      end)
      row:Show()
    end
    vendorChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    vendorScroll:SetVerticalScroll(math.min(vendorScroll:GetVerticalScroll(), math.max(0, vendorChild:GetHeight() - vendorScroll:GetHeight())))

    i = 0
    for id, name in pairs(DB.deleteList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)
      local display = DisplayName(idKey, name)
      if display and display ~= name then DB.deleteList[id] = display end
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", deleteChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.deleteList[idKey] = nil
        DB.deleteList[tostring(idKey)] = nil
        Refresh()
      end)
      row:Show()
    end
    deleteChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    deleteScroll:SetVerticalScroll(math.min(deleteScroll:GetVerticalScroll(), math.max(0, deleteChild:GetHeight() - deleteScroll:GetHeight())))
  end

  local function HandleDrop(mode)
    if not DB then return end

    local cursorType, itemID = GetCursorInfo()
    itemID = tonumber(itemID)
    if cursorType ~= "item" or not itemID then return end

    local name = GetItemInfo(itemID)
    if mode == "vendor" then
      DB.vendorList[itemID] = name or string.format(T_("Item #%d"), itemID)
      DB.deleteList[itemID] = nil
      DB.deleteList[tostring(itemID)] = nil
    else
      DB.deleteList[itemID] = name or string.format(T_("Item #%d"), itemID)
      DB.vendorList[itemID] = nil
      DB.vendorList[tostring(itemID)] = nil
    end

    ClearCursor()
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
  pfUI.gui.CreateGUIEntry(T_("Thirdparty"), T_("Vendor Tweaks"), function()
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
      local id = GetIDFromLink(arg1)
      if id and DB.deleteList[id] then
        pendingDeleteIDs[id] = true
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
