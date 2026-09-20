-- pfUI VendorTweaks
-- Vanilla WoW 1.12.1 / pfUI (Shagu + brues-code)
-- Component-only external addon.

if not pfUI then return end

local ADDON_NAME = "pfUI_VendorTweaks"
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
local DB = nil
local missingIconIDs = {}
local iconRepairInitialized = false

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
  if DB.showSellChat == nil then DB.showSellChat = "1" end
  if DB.autoDelete == nil then DB.autoDelete = "1" end
  if DB.showDeleteAnimation == nil then DB.showDeleteAnimation = "1" end
  if DB.showDeleteChat == nil then DB.showDeleteChat = "1" end
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
  if pfUI_translation and pfUI_translation.enUS and pfUI_translation.enUS[key] then
    return pfUI_translation.enUS[key]
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

-- -----------------------------------------------------------------------------
-- On-demand icon repair
-- Dormant when every listed item already has cached artwork.
-- -----------------------------------------------------------------------------
local iconRepairFrame = CreateFrame("Frame")
local iconRepairListening = false

local function UpdateIconRepairListener()
  local shouldListen = next(missingIconIDs) ~= nil

  if shouldListen and not iconRepairListening then
    iconRepairFrame:RegisterEvent("BAG_UPDATE")
    iconRepairListening = true
  elseif not shouldListen and iconRepairListening then
    iconRepairFrame:UnregisterEvent("BAG_UPDATE")
    iconRepairListening = false
  end
end

local function TryResolveItemIcon(id)
  if not DB or not id then return false end

  local item = DB.items and DB.items[id]
  if type(item) == "table" and item.icon then
    missingIconIDs[id] = nil
    return true
  end

  local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(id)
  if name or texture then
    CacheItemInfo(id, name, texture)
  end

  item = DB.items and DB.items[id]
  if type(item) == "table" and item.icon then
    missingIconIDs[id] = nil
    return true
  end

  missingIconIDs[id] = true
  return false
end

local function ScanBagForMissingIcons(bag)
  if not DB or not next(missingIconIDs) then return end
  if bag == nil or bag < 0 or bag > 4 then return end

  local size = GetContainerNumSlots(bag) or 0
  for slot = 1, size do
    local link = GetContainerItemLink(bag, slot)
    local id = GetIDFromLink(link)
    if id and missingIconIDs[id] then
      local texture = GetContainerItemInfo(bag, slot)
      if texture then
        local name = GetItemInfo(link or id)
        CacheItemInfo(id, name, texture)
        missingIconIDs[id] = nil
      end
    end
  end
end

local function ScanAllBagsForMissingIcons()
  if not next(missingIconIDs) then return end
  for bag = 0, 4 do
    ScanBagForMissingIcons(bag)
    if not next(missingIconIDs) then break end
  end
end

local function RebuildMissingIconIDs()
  missingIconIDs = {}
  if not DB then return end

  local checked = {}
  local function CheckList(list)
    for id in pairs(list) do
      local itemID = tonumber(id)
      if itemID and not checked[itemID] then
        checked[itemID] = true
        TryResolveItemIcon(itemID)
      end
    end
  end

  CheckList(DB.vendorList)
  CheckList(DB.deleteList)
end

local function InitializeIconRepair()
  -- PLAYER_ENTERING_WORLD also fires after zoning; the initial full scan is
  -- intentionally once per session. After this, BAG_UPDATE scans only the bag
  -- that actually changed and only while unresolved icons still exist.
  if iconRepairInitialized then return end
  iconRepairInitialized = true

  RebuildMissingIconIDs()
  if next(missingIconIDs) then
    ScanAllBagsForMissingIcons()
  end
  UpdateIconRepairListener()
end

iconRepairFrame:SetScript("OnEvent", function()
  if event ~= "BAG_UPDATE" or not DB or not next(missingIconIDs) then return end

  local bag = tonumber(arg1)
  if bag and bag >= 0 and bag <= 4 then
    ScanBagForMissingIcons(bag)
  end

  UpdateIconRepairListener()
end)

local function PruneItemInfo(id)
  if not DB or not DB.items or not id then return end
  if not DB.vendorList[id] and not DB.deleteList[id] then
    DB.items[id] = nil
    missingIconIDs[id] = nil
    UpdateIconRepairListener()
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
local worker = CreateFrame("Frame", "pfUI_VendorTweaks_Worker", UIParent)
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
    if Enabled("showSellChat") then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ff33[pfUI VendorTweaks]|r " .. string.format(T_("VT_SOLD"), currentLink))
    end
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

local function pfUI_VendorTweaks_GreyButtonClick()
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
  if hookedVendorButton == button and current == pfUI_VendorTweaks_GreyButtonClick then
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
  button:SetScript("OnClick", pfUI_VendorTweaks_GreyButtonClick)
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

-- -----------------------------------------------------------------------------
-- Vendor-purchase Auto-Delete exemption
-- Normal merchant purchases can emit the same self-acquisition loot messages
-- that arm Auto-Delete. Track exact merchant item IDs at the purchase call and
-- consume one short-lived exemption in CHAT_MSG_LOOT. This deliberately does
-- not change the existing delete worker or its BAG_UPDATE safety path.
-- -----------------------------------------------------------------------------
local vendorPurchaseExemptions = {}
local VENDOR_PURCHASE_EXEMPTION_TTL = 2.0
local merchantPurchaseHooksInstalled = false
local originalBuyMerchantItem = nil
local originalPickupMerchantItem = nil

local function MarkVendorPurchase(index)
  if not DB or not Enabled("autoDelete") or not index then return end

  local link = GetMerchantItemLink(index)
  local id = GetIDFromLink(link)
  if not id or not DB.deleteList[id] then return end

  local now = GetTime()
  local entry = vendorPurchaseExemptions[id]
  if not entry or not entry.expires or entry.expires < now then
    entry = { count = 0, expires = 0 }
  end

  entry.count = (entry.count or 0) + 1
  entry.expires = now + VENDOR_PURCHASE_EXEMPTION_TTL
  vendorPurchaseExemptions[id] = entry
end

local function ConsumeVendorPurchaseExemption(id)
  local entry = id and vendorPurchaseExemptions[id]
  if not entry then return false end

  if not entry.expires or entry.expires < GetTime() then
    vendorPurchaseExemptions[id] = nil
    return false
  end

  local count = entry.count or 0
  if count <= 0 then
    vendorPurchaseExemptions[id] = nil
    return false
  end

  count = count - 1
  if count > 0 then
    entry.count = count
  else
    vendorPurchaseExemptions[id] = nil
  end
  return true
end

local function InstallMerchantPurchaseHooks()
  if merchantPurchaseHooksInstalled then return end
  merchantPurchaseHooksInstalled = true

  if type(BuyMerchantItem) == "function" then
    originalBuyMerchantItem = BuyMerchantItem
    BuyMerchantItem = function(index, quantity)
      MarkVendorPurchase(index)
      if quantity ~= nil then
        return originalBuyMerchantItem(index, quantity)
      end
      return originalBuyMerchantItem(index)
    end
  end

  if type(PickupMerchantItem) == "function" then
    originalPickupMerchantItem = PickupMerchantItem
    PickupMerchantItem = function(index)
      -- With an occupied cursor this API is a sell path, not a purchase path.
      if not CursorHasItem() then
        MarkVendorPurchase(index)
      end
      return originalPickupMerchantItem(index)
    end
  end
end

-- -----------------------------------------------------------------------------
-- pfUI VendorTweaks Bin
-- A tiny visual acknowledgement for successful Auto-Delete actions. The frame
-- is registered with pfUI's movable system, so pfUI Unlock Mode owns position,
-- scale and reset behaviour exactly like native pfUI movable frames.
-- -----------------------------------------------------------------------------
local BIN_ICON_DEFAULT_X = 0
local BIN_ICON_DEFAULT_Y = -12
local BIN_BURN_DEFAULT_X = 0
local BIN_BURN_DEFAULT_Y = 0

local binIconX = BIN_ICON_DEFAULT_X
local binIconY = BIN_ICON_DEFAULT_Y
local binBurnX = BIN_BURN_DEFAULT_X
local binBurnY = BIN_BURN_DEFAULT_Y
local binIconWiping = false
local binLastTexture = "Interface\\Icons\\INV_Misc_QuestionMark"

local binFrame = CreateFrame("Frame", "pfUI_VendorTweaks_Bin", UIParent)
binFrame:SetWidth(64)
binFrame:SetHeight(64)
binFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
binFrame:SetFrameStrata("HIGH")
binFrame:EnableMouse(false)

local binIcon = binFrame:CreateTexture("pfUI_VendorTweaks_BinIcon", "ARTWORK")
binIcon:SetWidth(32)
binIcon:SetHeight(32)
binIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
binIcon:Hide()

local binBurn = binFrame:CreateTexture("pfUI_VendorTweaks_BinBurn", "OVERLAY")
binBurn:SetWidth(64)
binBurn:SetHeight(64)
binBurn:SetTexture("Interface\\AddOns\\pfUI_VendorTweaks\\artwork\\pfUI_VendorTweaks_Burn.tga")
binBurn:Hide()

local BIN_FRAME_COUNT = 8
local BIN_DURATION = 1.00
local binElapsed = 0
local binRunning = false
local binFrameIndex = 0
local binDebugFrameTimes = nil
local binDebugEndTime = nil

local function BinUnlockVisible()
  return pfUI.unlock and pfUI.unlock.IsShown and pfUI.unlock:IsShown()
end

local function ApplyBinBurnPosition()
  binBurn:ClearAllPoints()
  binBurn:SetPoint("CENTER", binFrame, "CENTER", binBurnX, binBurnY)
end

local function ApplyBinIconPosition()
  binIcon:ClearAllPoints()
  if binIconWiping then
    binIcon:SetPoint("BOTTOM", binFrame, "CENTER", binIconX, binIconY - 16)
  else
    binIcon:SetPoint("CENTER", binFrame, "CENTER", binIconX, binIconY)
  end
end

local function SetBinBurnFrame(index)
  if index < 1 then index = 1 end
  if index > BIN_FRAME_COUNT then index = BIN_FRAME_COUNT end
  local left = (index - 1) / BIN_FRAME_COUNT
  local right = index / BIN_FRAME_COUNT
  binBurn:SetTexCoord(left, right, 0, 1)
  binFrameIndex = index
end

local function ResetBinVisual()
  binRunning = false
  binElapsed = 0
  binFrameIndex = 0
  binIconWiping = false
  binIcon:SetAlpha(1)
  binIcon:SetVertexColor(1, 1, 1, 1)
  binIcon:SetTexCoord(0, 1, 0, 1)
  binIcon:SetWidth(32)
  binIcon:SetHeight(32)
  ApplyBinIconPosition()
  ApplyBinBurnPosition()
  binIcon:Hide()
  binBurn:Hide()
  if not BinUnlockVisible() then
    binFrame:Hide()
  end
end

local function PlayBinAnimation(id, texture)
  local cached = DB and DB.items and id and DB.items[id]
  local cachedTexture = type(cached) == "table" and cached.icon or nil
  local chosenTexture = texture or cachedTexture or binLastTexture or "Interface\\Icons\\INV_Misc_QuestionMark"

  binLastTexture = chosenTexture
  binElapsed = 0
  binRunning = true
  binFrameIndex = 0
  binIconWiping = false

  binIcon:SetTexture(chosenTexture)
  binIcon:SetAlpha(1)
  binIcon:SetVertexColor(1, 1, 1, 1)
  binIcon:SetTexCoord(0, 1, 0, 1)
  binIcon:SetWidth(32)
  binIcon:SetHeight(32)
  ApplyBinIconPosition()
  binIcon:Show()

  ApplyBinBurnPosition()
  SetBinBurnFrame(1)
  if binDebugFrameTimes and binDebugFrameTimes[1] and binDebugFrameTimes[1] > 0 then
    binBurn:Hide()
  else
    binBurn:Show()
  end
  binFrame:Show()
end

-- Narrow runtime controls used by dev-only Debug.lua. Normal addon behaviour
-- does not depend on these methods.
function binFrame:SetTuningOffsets(iconX, iconY, burnX, burnY)
  if tonumber(iconX) then binIconX = tonumber(iconX) end
  if tonumber(iconY) then binIconY = tonumber(iconY) end
  if tonumber(burnX) then binBurnX = tonumber(burnX) end
  if tonumber(burnY) then binBurnY = tonumber(burnY) end
  ApplyBinIconPosition()
  ApplyBinBurnPosition()
end

function binFrame:GetTuningOffsets()
  return binIconX, binIconY, binBurnX, binBurnY
end

function binFrame:ResetTuningOffsets()
  binIconX = BIN_ICON_DEFAULT_X
  binIconY = BIN_ICON_DEFAULT_Y
  binBurnX = BIN_BURN_DEFAULT_X
  binBurnY = BIN_BURN_DEFAULT_Y
  ApplyBinIconPosition()
  ApplyBinBurnPosition()
end

function binFrame:GetDebugFireFrameCount()
  return BIN_FRAME_COUNT
end

function binFrame:GetDebugDefaultDurationMs()
  return math.floor((BIN_DURATION * 1000) + 0.5)
end

function binFrame:SetDebugFireTimeline(frameTimesMs, endTimeMs)
  if type(frameTimesMs) ~= "table" then return false end

  local times = {}
  local previous = -1
  for i = 1, BIN_FRAME_COUNT do
    local ms = tonumber(frameTimesMs[i])
    if not ms or ms < 0 or ms <= previous then
      return false
    end
    times[i] = ms / 1000
    previous = ms
  end

  local finish = tonumber(endTimeMs)
  if not finish or finish <= previous then
    return false
  end

  binDebugFrameTimes = times
  binDebugEndTime = finish / 1000
  return true
end

function binFrame:ClearDebugFireTimeline()
  binDebugFrameTimes = nil
  binDebugEndTime = nil
end

function binFrame:PlayPreview()
  PlayBinAnimation(nil, binLastTexture)
end

binFrame:SetScript("OnUpdate", function()
  -- pfUI creates the dragger lazily the first time Unlock Mode is opened.
  -- Replace its compact frame-name label with the human-facing anchor name.
  if BinUnlockVisible() and this.drag and this.drag.text then
    this.drag.text:SetText(T_("VT_BIN"))
  end

  if not binRunning then return end

  binElapsed = binElapsed + arg1
  local duration = binDebugEndTime or BIN_DURATION
  local progress = binElapsed / duration
  if progress >= 1 then
    ResetBinVisual()
    return
  end

  local frame = nil
  if binDebugFrameTimes then
    for i = 1, BIN_FRAME_COUNT do
      if binElapsed >= binDebugFrameTimes[i] then
        frame = i
      else
        break
      end
    end

    if frame then
      if frame ~= binFrameIndex then
        SetBinBurnFrame(frame)
      end
      if not binBurn:IsShown() then binBurn:Show() end
    else
      binBurn:Hide()
    end
  else
    frame = math.floor(progress * BIN_FRAME_COUNT) + 1
    if frame ~= binFrameIndex then
      SetBinBurnFrame(frame)
    end
  end

  -- Existing burn test behaviour is preserved while Debug.lua tunes the
  -- relative icon/fire placement. The revised animation will replace this.
  local burnStart = 3 / BIN_FRAME_COUNT
  if progress <= burnStart then
    binIconWiping = false
    binIcon:SetAlpha(1)
    binIcon:SetVertexColor(1, 1, 1, 1)
    binIcon:SetTexCoord(0, 1, 0, 1)
    binIcon:SetHeight(32)
    ApplyBinIconPosition()
  else
    local burn = (progress - burnStart) / (1 - burnStart)
    if burn > 1 then burn = 1 end

    local remain = 1 - burn
    local char = burn * 1.75
    if char > 1 then char = 1 end
    local shade = 1 - char

    binIconWiping = true
    binIcon:SetAlpha(1)
    binIcon:SetVertexColor(shade, shade, shade, 1)
    binIcon:SetTexCoord(0, 1, burn, 1)
    binIcon:SetHeight(math.max(0.5, 32 * remain))
    ApplyBinIconPosition()
  end
end)

if pfUI.api and pfUI.api.UpdateMovable then
  pfUI.api.UpdateMovable(binFrame)
end
binFrame:Hide()

local deleteWorker = CreateFrame("Frame", "pfUI_VendorTweaks_DeleteWorker", UIParent)
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
        local slotTexture, _, locked = GetContainerItemInfo(bag, slot)
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
        if Enabled("showDeleteAnimation") then
          PlayBinAnimation(id, slotTexture)
        end
        if Enabled("showDeleteChat") then
          DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[pfUI VendorTweaks]|r " .. string.format(T_("VT_DELETED"), link))
        end

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
  title:SetText(T_("VT_VENDOR_TWEAKS"))

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

  local function MakeDisabledCheckbox(anchor, y, text)
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

    cb:SetChecked(false)
    UpdateCheckboxMark(cb)
    cb:Disable()
    cb:SetAlpha(.5)

    return cb
  end

  -- Enabling this is both the takeover switch and the Auto-Sell ON switch.
  -- When disabled, pfUI's own Auto-Sell setting and behaviour are restored intact.
  local takeover = MakeCheckbox(title, -12,
    T_("VT_THROTTLE_AUTOSELL"), "takeoverGreys", function()
      CancelSellQueue()
      ApplyGreyTakeover()
    end)

  local slider = CreateFrame("Slider", "pfUI_VendorTweaks_ComponentSpeedSlider", parent, "OptionsSliderTemplate")
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
    T_("VT_AUTO_VENDOR"), "autoVendor")

  local showSellAnimation = MakeDisabledCheckbox(autoVendor, -2,
    T_("VT_SHOW_SELL_ANIMATION"))

  local showSellChat = MakeCheckbox(showSellAnimation, -2,
    T_("VT_SHOW_SELL_CHAT"), "showSellChat")

  local autoDelete = CreateFrame("CheckButton", nil, parent)
  autoDelete:SetWidth(20)
  autoDelete:SetHeight(20)
  autoDelete:SetPoint("TOPLEFT", autoVendor, "TOPLEFT", 220, 0)
  if pfUI.api and pfUI.api.SkinCheckbox then pfUI.api.SkinCheckbox(autoDelete) end
  AttachCheckboxMark(autoDelete)

  local deleteLabel = autoDelete:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  deleteLabel:SetPoint("LEFT", autoDelete, "RIGHT", 5, 0)
  deleteLabel:SetText(T_("VT_AUTO_DELETE"))

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

  -- Keep Auto-Delete feedback controls between the feature toggle and its
  -- drop target so they sit outside the list scroll frame and remain clickable.
  local showDeleteAnimation = MakeCheckbox(autoDelete, -2,
    T_("VT_SHOW_DELETE_ANIMATION"), "showDeleteAnimation", function()
      if not Enabled("showDeleteAnimation") then ResetBinVisual() end
    end)

  local showDeleteChat = MakeCheckbox(showDeleteAnimation, -2,
    T_("VT_SHOW_DELETE_CHAT"), "showDeleteChat")

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

  local vendorDrop = MakeDropSlot(showSellChat, T_("VT_DROP_VENDOR"))
  local deleteDrop = MakeDropSlot(showDeleteChat, T_("VT_DROP_DELETE"))

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
    local item = DB.items and DB.items[id]
    local name = type(item) == "table" and item.name or nil
    local texture = type(item) == "table" and item.icon or nil
    return name or string.format(T_("VT_ID"), id), texture
  end

  local function Refresh()
    if not DB then return end

    SetCheckboxChecked(takeover, Enabled("takeoverGreys"))
    SetCheckboxChecked(autoVendor, Enabled("autoVendor"))
    SetCheckboxChecked(showSellChat, Enabled("showSellChat"))
    SetCheckboxChecked(autoDelete, Enabled("autoDelete"))
    SetCheckboxChecked(showDeleteAnimation, Enabled("showDeleteAnimation"))
    SetCheckboxChecked(showDeleteChat, Enabled("showDeleteChat"))

    local interval = GetInterval()
    slider:SetValue(interval)
    if sliderText then sliderText:SetText(string.format("%.2fs", interval)) end

    for _, row in ipairs(vendorPool) do row:Hide() end
    for _, row in ipairs(deletePool) do row:Hide() end

    -- Known pfUI VendorTweaks metadata wins immediately. Only incomplete entries
    -- query WoW's item cache. If Refresh discovers a previously-untracked
    -- missing icon, perform one shared bag scan; already-tracked misses rely on
    -- the on-demand BAG_UPDATE repair listener instead of rescanning all bags.
    local checked = {}
    local discoveredMissing = false

    local function ResolveListMetadata(list)
      for id in pairs(list) do
        local itemID = tonumber(id) or id
        if not checked[itemID] then
          checked[itemID] = true
          local item = DB.items and DB.items[itemID]
          local hasIcon = type(item) == "table" and item.icon

          if hasIcon then
            missingIconIDs[itemID] = nil
          else
            local wasMissing = missingIconIDs[itemID]
            if not TryResolveItemIcon(itemID) and not wasMissing then
              discoveredMissing = true
            end
          end
        end
      end
    end

    ResolveListMetadata(DB.vendorList)
    ResolveListMetadata(DB.deleteList)

    if discoveredMissing and next(missingIconIDs) then
      ScanAllBagsForMissingIcons()
    end
    UpdateIconRepairListener()

    -- List membership stays as an ID-keyed map. Build a temporary display array
    -- only when the panel refreshes so both columns are deterministic and
    -- alphabetically sorted without adding any persistent ordering state.
    local function BuildSortedRows(list)
      local rows = {}
      for id in pairs(list) do
        local itemID = tonumber(id) or id
        local display, texture = DisplayInfo(itemID)
        table.insert(rows, {
          id = itemID,
          display = display,
          texture = texture,
          sortKey = string.lower(display or ""),
        })
      end

      table.sort(rows, function(a, b)
        if a.sortKey == b.sortKey then
          return a.id < b.id
        end
        return a.sortKey < b.sortKey
      end)

      return rows
    end

    local vendorRows = BuildSortedRows(DB.vendorList)
    local i = 0
    for _, entry in ipairs(vendorRows) do
      i = i + 1
      local idKey = entry.id
      local row = vendorPool[i] or MakeRow(vendorPool, vendorChild, false)
      local display, texture = entry.display, entry.texture
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

    local deleteRows = BuildSortedRows(DB.deleteList)
    i = 0
    for _, entry in ipairs(deleteRows) do
      i = i + 1
      local idKey = entry.id
      local row = deletePool[i] or MakeRow(deletePool, deleteChild, true)
      local display, texture = entry.display, entry.texture
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

    CacheItemInfo(itemID, name or string.format(T_("VT_ITEM_FALLBACK"), itemID), texture)
    if texture then
      missingIconIDs[itemID] = nil
    else
      missingIconIDs[itemID] = true
    end
    UpdateIconRepairListener()
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
  pfUI.gui.CreateGUIEntry(T_("Thirdparty"), T_("VT_VENDOR_TWEAKS"), function()
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
    InitializeIconRepair()
    InstallMerchantPurchaseHooks()

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
    vendorPurchaseExemptions = {}

  elseif event == "CHAT_MSG_LOOT" then
    if DB and Enabled("autoDelete") and arg1 and IsSelfLootMessage(arg1) then
      local id = GetIDFromLink(arg1)
      if id and DB.deleteList[id] then
        if not ConsumeVendorPurchaseExemption(id) then
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
