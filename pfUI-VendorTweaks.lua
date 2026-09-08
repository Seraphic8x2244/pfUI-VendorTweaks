-- pfUI-VendorTweaks v0.1.21
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
  -- v0.1.20: takeoverGreys is also the Auto-Sell ON switch; retire the old split flag.
  DB.autoSellGreys = nil
  if DB.autoVendor == nil then DB.autoVendor = "1" end
  if DB.autoDelete == nil then DB.autoDelete = "1" end
  if type(DB.vendorList) ~= "table" then DB.vendorList = {} end
  if type(DB.deleteList) ~= "table" then DB.deleteList = {} end
  if type(DB.items) ~= "table" then DB.items = {} end

  -- v0.1.21: list membership is ID-only. Migrate the old saved item-name values
  -- into one shared metadata cache used by both Auto-Vendor and Auto-Delete.
  local function MigrateList(list)
    local normalized = {}
    for id, value in pairs(list) do
      local itemID = tonumber(id)
      if itemID then
        normalized[itemID] = true
        if type(value) == "string" then
          local item = DB.items[itemID]
          if type(item) ~= "table" then item = {} end
          if not item.name then item.name = value end
          DB.items[itemID] = item
        end
      end
    end
    return normalized
  end

  DB.vendorList = MigrateList(DB.vendorList)
  DB.deleteList = MigrateList(DB.deleteList)
end

local function GetInterval()
  local n = DB and tonumber(DB.interval) or 0.35
  if n < 0.05 then n = 0.05 end
  if n > 0.50 then n = 0.50 end
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

local function CacheItemInfo(id, name, texture)
  if not DB or not id then return end
  if type(DB.items) ~= "table" then DB.items = {} end

  local item = DB.items[id]
  if type(item) ~= "table" then item = {} end
  if name then item.name = name end
  if texture then item.icon = texture end
  DB.items[id] = item
end

local function PruneItemInfo(id)
  if not DB or not DB.items or not id then return end
  if not DB.vendorList[id] and not DB.deleteList[id] then
    DB.items[id] = nil
  end
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
    cb.label = label

    cb:SetScript("OnClick", function()
      if not DB then return end
      DB[key] = this:GetChecked() and "1" or "0"
      UpdateCheckboxMark(this)
      if onChange then onChange() end
    end)

    return cb
  end

  -- Enabling this is both the takeover switch and the Auto-Sell ON switch.
  -- When disabled, pfUI's own Auto-Sell setting and behaviour are restored intact.
  local takeover = MakeCheckbox(title, -12,
    T_("Throttle pfUI auto-sell"), "takeoverGreys", function()
      CancelSellQueue()
      ApplyGreyTakeover()
    end)

  local slider = CreateFrame("Slider", "pfVT_ComponentSpeedSlider", parent, "OptionsSliderTemplate")
  -- Align the slider to the right edge of the two list columns.
  slider:SetPoint("RIGHT", takeover, "LEFT", 415, 0)
  slider:SetWidth(150)
  slider:SetHeight(16)
  slider:SetMinMaxValues(0.05, 0.50)
  slider:SetValueStep(0.05)
  if pfUI.api and pfUI.api.SkinSlider then pfUI.api.SkinSlider(slider) end
  getglobal(slider:GetName() .. "Low"):SetText("0.05s")
  getglobal(slider:GetName() .. "High"):SetText("0.50s")
  local sliderText = getglobal(slider:GetName() .. "Text")
  slider:SetScript("OnValueChanged", function()
    if not DB then return end
    local val = floor(this:GetValue() * 100 + 0.5) / 100
    DB.interval = tostring(val)
    if sliderText then sliderText:SetText(string.format("%.2fs", val)) end
  end)

  -- The list toggles double as the two side-by-side section subheaders.
  local autoVendor = MakeCheckbox(takeover, -32,
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

  local function SetDropHighlight(frame, shown)
    if not frame or not frame.goldBorder then return end
    for _, tex in ipairs(frame.goldBorder) do
      if shown then tex:Show() else tex:Hide() end
    end
  end

  local function MakeDropSlot(header, text)
    local frame = CreateFrame("Button", nil, parent)
    frame:SetWidth(42)
    frame:SetHeight(42)
    frame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -7)
    if pfUI.api and pfUI.api.CreateBackdrop then pfUI.api.CreateBackdrop(frame, nil, true) end

    -- Gold inset border while an item cursor is hovering over this drop well.
    frame.goldBorder = {}
    local function GoldEdge()
      local tex = frame:CreateTexture(nil, "OVERLAY")
      tex:SetTexture(1, .78, 0)
      tex:SetAlpha(.95)
      tex:Hide()
      table.insert(frame.goldBorder, tex)
      return tex
    end

    local top = GoldEdge()
    top:SetHeight(2)
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)

    local bottom = GoldEdge()
    bottom:SetHeight(2)
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)

    local left = GoldEdge()
    left:SetWidth(2)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)

    local right = GoldEdge()
    right:SetWidth(2)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", frame, "RIGHT", 7, 0)
    label:SetWidth(145)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    frame.label = label

    frame:SetScript("OnEnter", function()
      local cursorType = GetCursorInfo()
      SetDropHighlight(this, cursorType == "item")
    end)
    frame:SetScript("OnLeave", function()
      SetDropHighlight(this, false)
    end)

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

  -- Vanilla 1.12 has no AnimationGroup API. Keep the entire flourish on
  -- the already-working drop button itself: this avoids extra frames, strata,
  -- coordinate conversion, and any chance of the animation intercepting input.
  local function MakeDropAnimator(drop)
    -- Keep input on the proven drop target, but render the transient icon on
    -- a mouse-disabled child frame above pfUI's backdrop frames.
    local visual = CreateFrame("Frame", nil, drop)
    visual:SetWidth(34)
    visual:SetHeight(34)
    visual:SetPoint("CENTER", drop, "CENTER", 0, 0)

    -- pfUI's backdrop is made from child frames, so an arbitrary +N frame
    -- level is not reliable. Mirror the proven checkbox-mark approach and
    -- explicitly sit above whichever backdrop frame is actually highest.
    local visualLevel = drop:GetFrameLevel() + 1
    if drop.backdrop and drop.backdrop.GetFrameLevel and drop.backdrop:GetFrameLevel() >= visualLevel then
      visualLevel = drop.backdrop:GetFrameLevel() + 1
    end
    if drop.backdrop_border and drop.backdrop_border.GetFrameLevel and drop.backdrop_border:GetFrameLevel() >= visualLevel then
      visualLevel = drop.backdrop_border:GetFrameLevel() + 1
    end
    visual:SetFrameLevel(visualLevel)
    visual:EnableMouse(false)
    visual:Hide()

    local icon = visual:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(visual)
    icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local elapsed = 0
    local running = false
    local startX, startY = 0, 0
    local targetX, targetY = -7, -55

    drop:SetScript("OnUpdate", function()
      if not running then return end

      elapsed = elapsed + arg1
      local flashTime = .18
      local slideTime = .42

      if elapsed <= flashTime then
        local pulse = math.abs(math.sin((elapsed / flashTime) * math.pi * 2))
        visual:SetAlpha(.55 + (.45 * pulse))
        return
      end

      local t = (elapsed - flashTime) / slideTime
      if t >= 1 then
        running = false
        visual:Hide()
        visual:SetAlpha(1)
        visual:SetScale(1)
        visual:ClearAllPoints()
        visual:SetPoint("CENTER", drop, "CENTER", 0, 0)
        return
      end

      -- Smoothstep easing keeps the movement continuous at both ends.
      local e = t * t * (3 - (2 * t))
      local x = startX + ((targetX - startX) * e)
      local y = startY + ((targetY - startY) * e)

      visual:ClearAllPoints()
      visual:SetPoint("CENTER", drop, "CENTER", x, y)
      visual:SetScale(1 - (.65 * e))
      visual:SetAlpha(1 - (.35 * e))
    end)

    local animator = {}
    function animator:Play(texture)
      startX, startY = 0, 0
      targetX, targetY = -7, -55

      elapsed = 0
      running = true
      icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      visual:SetAlpha(1)
      visual:SetScale(1)
      visual:ClearAllPoints()
      visual:SetPoint("CENTER", drop, "CENTER", 0, 0)
      visual:Show()
    end

    return animator
  end

  local vendorDropAnim = MakeDropAnimator(vendorDrop)
  local deleteDropAnim = MakeDropAnimator(deleteDrop)

  local vendorPool = {}
  local deletePool = {}

  local function MakeRow(pool, rowParent, greyName)
    local row = CreateFrame("Button", nil, rowParent)
    row:SetWidth(LIST_WIDTH - 4)
    row:SetHeight(18)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(14)
    row.icon:SetHeight(14)
    row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)

    row.del = CreateFrame("Button", nil, row)
    row.del:SetWidth(16)
    row.del:SetHeight(16)
    row.del:SetPoint("RIGHT", row, "RIGHT", -1, 0)
    local x = row.del:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    x:SetPoint("CENTER", row.del, "CENTER", 0, 0)
    x:SetText("|cffff5555x|r")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row.del, "LEFT", -4, 0)
    row.text:SetJustifyH("LEFT")
    if greyName then row.text:SetTextColor(.62, .62, .62) end

    table.insert(pool, row)
    return row
  end

  local function DisplayInfo(id)
    local liveName, _, _, _, _, _, _, _, _, liveTexture = GetItemInfo(id)
    if liveName or liveTexture then
      CacheItemInfo(id, liveName, liveTexture)
    end

    local item = DB.items and DB.items[id]
    local name = liveName or (type(item) == "table" and item.name)
    local texture = liveTexture or (type(item) == "table" and item.icon)

    return name or string.format(T_("ID: %d"), id), texture
  end

  local function Refresh()
    if not DB then return end

    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))
    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))
    SetCheckboxChecked(autoDelete, Enabled("autoDelete"))

    local interval = GetInterval()
    slider:SetValue(interval)
    if sliderText then sliderText:SetText(string.format("%.2fs", interval)) end

    for _, row in ipairs(vendorPool) do row:Hide() end
    for _, row in ipairs(deletePool) do row:Hide() end

    local i = 0
    for id in pairs(DB.vendorList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)
      local display, texture = DisplayInfo(idKey)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", vendorChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.vendorList[idKey] = nil
        PruneItemInfo(idKey)
        Refresh()
      end)
      row:Show()
    end
    vendorChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    vendorScroll:SetVerticalScroll(math.min(vendorScroll:GetVerticalScroll(), math.max(0, vendorChild:GetHeight() - vendorScroll:GetHeight())))

    i = 0
    for id in pairs(DB.deleteList) do
      i = i + 1
      local idKey = tonumber(id) or id
      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)
      local display, texture = DisplayInfo(idKey)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", deleteChild, "TOPLEFT", 2, -2 - ((i - 1) * ROW_HEIGHT))
      row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
      row.text:SetText(display)
      row.del:SetScript("OnClick", function()
        DB.deleteList[idKey] = nil
        PruneItemInfo(idKey)
        Refresh()
      end)
      row:Show()
    end
    deleteChild:SetHeight(math.max(LIST_HEIGHT, 4 + (i * ROW_HEIGHT)))
    deleteScroll:SetVerticalScroll(math.min(deleteScroll:GetVerticalScroll(), math.max(0, deleteChild:GetHeight() - deleteScroll:GetHeight())))
  end

  local function HandleDrop(mode)
    if not DB then return end

    -- Capture the cursor link and texture before ClearCursor(). On Vanilla the
    -- link is already known for a dragged bag item, which makes this more
    -- reliable than asking the item cache by numeric ID alone.
    local cursorType, itemID, itemLink = GetCursorInfo()
    itemID = tonumber(itemID)
    if cursorType ~= "item" or not itemID then return end

    local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemLink or itemID)
    if not name or not texture then
      local fallbackName, _, _, _, _, _, _, _, _, fallbackTexture = GetItemInfo(itemID)
      name = name or fallbackName
      texture = texture or fallbackTexture
    end
    if mode == "vendor" then
      DB.vendorList[itemID] = true
      DB.deleteList[itemID] = nil
      SetDropHighlight(vendorDrop, false)
    else
      DB.deleteList[itemID] = true
      DB.vendorList[itemID] = nil
      SetDropHighlight(deleteDrop, false)
    end

    ClearCursor()

    -- GetItemInfo can return no texture at the exact moment a bag item is
    -- dropped on some Vanilla clients. Once ClearCursor() has returned the
    -- item to its bag slot, resolve the icon from the physical bag contents
    -- instead. Matching stays by item ID, so similarly named items cannot
    -- provide the wrong artwork.
    if not texture then
      for bag = 0, 4 do
        local size = GetContainerNumSlots(bag) or 0
        for slot = 1, size do
          local bagLink = GetContainerItemLink(bag, slot)
          if bagLink and GetIDFromLink(bagLink) == itemID then
            local bagTexture = GetContainerItemInfo(bag, slot)
            if bagTexture then
              texture = bagTexture
              break
            end
          end
        end
        if texture then break end
      end
    end

    CacheItemInfo(itemID, name or string.format(T_("Item #%d"), itemID), texture)
    Refresh()

    if mode == "vendor" then
      vendorDropAnim:Play(texture)
    else
      deleteDropAnim:Play(texture)
    end
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

    local includeGreys = Enabled("takeoverGreys")
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
