# Development Progress

## Current
- Branch: `dev`
- Dev version: `0.1.34-dev`.
- Stable release: `0.1.28` on `main` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.
- User-tested runtime source: `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`; the stable release uses the exact same `pfUI_VendorTweaks.lua` blob (`d4011262f648fe98bcf78be37640cbce249d6e6b`) with stable TOC metadata and dev-only material removed.
- Release-facing P3 runtime commit: `50efdff8f24001010b087abdf817da86a669646a`.
- P2 runtime commit: `63a75ebdda85bec16dc074f48622fd1bcdd38576`.
- P1 runtime commits: `a1c9b6daec6fd06b644a804b19d6490cb89babab` and `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Feature-pass baseline: `f9143abb659481007ac497ec00d5451a6800a4e6`.
- Pre-redesign head: `3fc2aee6626aceaf18964de96a0a1071cfa79286`; this was the prior handoff plus the repository-wide rulebook versioning clarification only.
- `0.1.30-dev` runtime-validation handoff: `932a35632eca5def6983b211db881ebfa6ecf4d9`; later commits before the user's test changed development documentation only.
- `0.1.31-dev` runtime commit: `38453ab5567e37e6b2b8224c5b9f98aa4f9eb81d`; its staged input worked in-game but the inventory-stack model and batched purchase call were rejected by runtime testing.
- `0.1.32-dev` runtime commit: `83f2f5cb9ad241de850c81f43e78e764673e779e`; handoff head `437594b661f395ea8545b283973651b60a352721`; runtime Lua blob `719628956e859747cc9473e57d6013b8a6dfdb94`. User explicitly reported the corrected Auto-Buy behaviour works.
- `0.1.33-dev` runtime commit: `3816e1a0800e638f22b71e92df7f658a09bbea4f`; handoff head `15064000fa0811a4c6975b411b946ef08ed18c69`; runtime Lua blob `c1d4d11e901389490199145b19ab2ffbcf7dcfc1`. User reported all tested behaviour works and the layout feels good.
- `0.1.34-dev` runtime commit: `716bb6940c35cc75fcaeb530915a7cb6741290b1`.
- Lua-validated `0.1.34-dev` tree: `ae3aed92a4097a32ac1a3f150f63b501be1dbe53`; Actions run `36165705057` passed the canonical Lua 5.0.2 checker/self-test and all addon Lua files. Current runtime Lua is the exact validated blob `25f2dc0025ad56ed4c9a41c58ea94a6226d9920b`.
- Current pre-handoff dev head: `47ca7cea444519e2b55356bb9a9469768491f6e1`; the only post-validation change removed the temporary checker workflow.
- Mode: runtime-validation gate for the focused `0.1.34-dev` settings visual-hierarchy refinement.
- Current scope: user-test only the new header/label/rule styling. All accepted `0.1.33` behaviour remains unchanged. Do not promote or broaden scope.

## Current Design / Development Contract

### Architecture / Ownership
- `pfUI_VendorTweaks` is a component-only external addon for pfUI and declares pfUI as a dependency.
- Runtime code remains centered in `pfUI_VendorTweaks.lua`; locale files under `locales/` load before it.
- `Debug.lua` is development-only tooling on `dev` and is not required for normal addon operation.
- Per-character addon state is owned by the `pfUI_VendorTweaks` SavedVariables table.
- The Auto-Delete bin uses pfUI's movable-frame system for placement/scale/reset ownership.
- Performance work should prefer dormant/event-driven execution over permanent `OnUpdate` or permanently registered high-frequency events when equivalent behaviour can be preserved.

### Invariants
- Technical addon/folder/metadata identity is `pfUI_VendorTweaks`; stale hyphenated `pfUI-VendorTweaks.toc/.lua` files from older installs must not be used.
- The addon version comes from the TOC. Current development is `0.1.34-dev`; it inherits the accepted `0.1.28` runtime baseline plus the user-accepted `0.1.33-dev` Auto-Buy behaviour/layout and changes only settings-panel visual hierarchy.
- The approved production Auto-Delete feedback remains the existing single 8-frame strip `artwork/pfUI_VendorTweaks_Burn.tga`, with `BIN_FRAME_COUNT = 8` and approximately 1.0 second default runtime.
- Debug controls may tune/preview the existing animation but must not become a stable runtime dependency.
- Do not introduce heuristic buyback matching: stock 1.12 buyback API does not expose an exact item link/ID suitable for a reliable Auto-Delete exemption.
- Performance optimizations must preserve fail-closed delete safety, merchant behaviour, user-configured lists, and current visual/chat settings.
- Do not optimize only for raids. The target is lower background cost in all gameplay; raids are simply where compounded addon overhead is most visible.

### Protocol / Data Model
- No external protocol is involved.
- Existing item lists and metadata remain compatible. `0.1.30-dev` intentionally retires the old takeover/Auto-Vendor/Auto-Delete/Auto-Buy enable flags: list membership is now the feature opt-in, while Sell/Delete/Buy chat preferences remain persistent SavedVariables.
- Vendor/delete list membership remains item-ID keyed. Auto-Buy is item-ID keyed with a hard maximum actual item count as its value.
- `DB.buyListUnit = "max_count"` marks the current Auto-Buy representation; `0.1.33` does not change SavedVariables semantics.
- The short-lived `0.1.31` `inventory_stacks` representation is intentionally cleared once during initialization instead of being guessed into counts: the user's tests showed the same stored number could reflect either intended item count or intended inventory stacks, so automatic reinterpretation could trigger an unexpectedly large purchase.
- Cached name/icon/stack metadata remains presentation/defaulting data only; purchase arithmetic no longer depends on inventory maximum stack size.

### Active Decisions
- The completed `0.1.28` performance pass remains the accepted runtime baseline. The `0.1.30-dev` options layout was partially exercised and judged basically fine, but its inline Auto-Buy quantity EditBox focused/blinked without accepting typed input.
- The staged Auto-Buy flow introduced in `0.1.31-dev` is retained because its standalone text input accepted typing in-game. Its label/meaning is changed from `Inventory stacks` to `No more than`, meaning an actual item-count ceiling.
- The `0.1.31` empty numeric field lacked a visible rectangle until it contained text; `0.1.32` put the EditBox inside a permanently backdropped holder so the input target is visible before staging an item.
- User runtime feedback accepts the `0.1.32` hard actual-count ceiling and vendor-batch purchase behaviour as working. `0.1.33` must not alter that purchase engine.
- `0.1.33` deliberately never auto-populates the `No more than` field. The player supplies the number. Empty input keeps `Add` disabled/grey; a non-empty invalid string turns red and also leaves `Add` disabled; a valid positive integer plus a staged item enables `Add`.
- The saved Auto-Buy area is now one icon-high full-width strip below the configuration row. Entries never wrap vertically; overflow scrolls horizontally with the mouse wheel.
- User runtime feedback accepts the complete `0.1.33` Auto-Buy interaction/layout as working and visually good.
- `0.1.34` adds visual hierarchy without adding vertical height: AUTO-BUY/AUTO-SELL/AUTO-DELETE use pfUI's native teal header colour, each has a subtle 1px teal rule extending right, and Sell/Delete/Buy checkbox labels are neutral silver while Chat Messages remains gold.
- AUTO-SELL and AUTO-DELETE rules are independently constrained to their own 195px columns; the left rule must not run into the right column.
- Runtime evidence distinguishes vendor batch size from inventory stack size. Auto-Buy therefore uses `GetMerchantItemInfo` batch quantity for purchasing and does not use inventory max stack size to determine the user's ceiling.
- The performance audit should prioritize removing recurring idle/background work over micro-optimizing one-shot configuration or merchant operations.
- Preserve event-driven ownership: temporary workers may run while a real operation is active, but they should become fully dormant when no work is pending.
- The longer/higher-frame/two-part Fire/Ash burn replacement remains shelved; the restored 8-frame implementation is the approved production state.
- Current branding remains `pfUI VendorTweaks`. The old feature-enable and animation-enable checkbox layout is superseded by the user-approved streamlined controls in this pass.

## Active Feature Pass — 0.1.34-dev

### Requested behaviour
- Installing VendorTweaks means VendorTweaks owns pfUI grey auto-selling; there is no separate takeover checkbox.
- Auto-Vendor, Auto-Delete and Auto-Buy require no enable checkboxes. Putting an item in the corresponding list is the explicit opt-in; an empty list means no configured work for that feature.
- Sell delay is user-configurable from `0.00` to `0.20` seconds.
- The approved 8-frame Auto-Delete burn animation remains production behaviour and gets an `Animation Duration` slider from `0.20` to `1.00` seconds.
- Chat feedback is independently configurable for Sell, Delete and Buy.
- Auto-Buy maintains a user-configured hard maximum actual item count across bags `0`–`4` when a merchant selling that item is opened.
- Auto-Buy configuration is item-ID keyed. Each entry stores its `No more than` count directly.
- Dropping an item into Auto-Buy stages it without changing list ownership. The standalone `No more than` field is never auto-filled; the player must type the desired hard item-count ceiling. Pressing enabled `Add` commits the entry and mutual-exclusion ownership change.
- Merchant matching remains exact item ID. `GetMerchantItemInfo` quantity is treated as vendor batch size, and Auto-Buy buys only whole batches that fit without exceeding the configured maximum.
- For singly sold goods (`batchSize == 1`), the quantity argument is used directly. For batched goods, the accepted `0.1.32` engine deliberately avoids the historically ambiguous second argument to `BuyMerchantItem` and issues one no-quantity call per required vendor batch; `0.1.34` leaves this logic unchanged.
- Buy chat reports the requested number of actual item units, not the number of vendor-batch API calls.
- Auto-Buy counts bags only, not bank contents.
- Auto-Vendor, Auto-Delete and Auto-Buy membership are mutually exclusive for the same item because simultaneous buy/sell/delete ownership would create contradictory merchant behaviour.
- Do not add speculative buy throttling, confirmation systems, bank counting, restock categories, or unrelated vendor features in this pass.

### UI direction
- Header controls: `Sell Delay` slider on the left (`0.00`–`0.20s`) and `Animation Duration` slider on the right (`0.20`–`1.00s`).
- One compact `Chat Messages` row below them: `Sell [x]`, `Delete [x]`, `Buy [x]`.
- Auto-Buy top row is: drop target + `Drop item here to auto-buy` on the left, then `No more than [ ] [Add]` on the same row.
- The `No more than` EditBox is always visibly outlined but starts empty and is never programmatically populated. Empty input is neutral; non-empty invalid input is red.
- `Add` is disabled with grey text unless both a staged item and a valid positive integer are present; valid input restores the normal active Add appearance.
- Saved Auto-Buy entries occupy one full-width box immediately below that row, exactly one icon row high. Entries are compact icon tiles with the configured maximum count attached; they never wrap vertically, and overflow scrolls horizontally with the mouse wheel.
- Auto-Sell and Auto-Delete remain the lower two-column section, each with its drop target and scrollable item list.
- AUTO-BUY, AUTO-SELL and AUTO-DELETE headings use pfUI native header teal (`.2, 1, .8`) rather than gold.
- Each teal heading has a subtle 1px teal rule beginning 7px after the text. AUTO-BUY's rule stays inside the 415px full-width section; AUTO-SELL and AUTO-DELETE each stay inside their own 195px column.
- The Sell/Delete/Buy chat checkbox labels are silver/neutral (`.75, .75, .75`); the Chat Messages heading remains gold.
- Do not add the optional dynamic current/max label (for example `146/200`) yet; it remains a possible later presentation refinement after this gate.

### Validation gates
- Real Lua 5.0.2 compile/static check before runtime handoff.
- Runtime: existing Auto-Vendor and Auto-Delete regression sanity.
- Runtime: burn animation at default plus at least one shorter and one longer configured duration.
- Runtime: confirm AUTO-BUY/AUTO-SELL/AUTO-DELETE headings render in pfUI teal and are visually distinct from the gold page/control headings.
- Runtime: confirm each heading has a subtle 1px rule extending right with a small text gap.
- Runtime: AUTO-BUY rule should terminate at the full-width section edge; AUTO-SELL's rule must stop inside the left column and never extend into AUTO-DELETE; AUTO-DELETE has its own independent right-column rule.
- Runtime: confirm Sell/Delete/Buy checkbox labels are silver/neutral while Chat Messages remains gold.
- Runtime: no vertical growth, overlap or regression in the accepted `0.1.33` layout/behaviour.

## Performance Audit Findings

The audit was performed against `dev` at `3db6fea316d8684223dc9bd6ca745784dd831765`. At that point `pfUI_VendorTweaks.lua` was byte-identical to stable `main` `0.1.27`, so the findings apply to the released runtime as well.

### Baseline conclusion
- There is no normal permanently executing sell/delete `OnUpdate` loop during ordinary gameplay.
- The sell worker and delete worker are hidden when inactive, so their `OnUpdate` handlers do not execute while hidden.
- The bin animation frame is also hidden when idle; its `OnUpdate` runs only while the animation/pfUI unlock visibility keeps the frame shown.
- The strongest opportunities are therefore demand-driven event registration and edge cases that can leave temporary work active longer than intended.

### P1 — background icon-repair listening removed in `0.1.28-dev`
Implemented at `a1c9b6daec6fd06b644a804b19d6490cb89babab`:
- Deleted the session-persistent `missingIconIDs` state, `iconRepairFrame`, `BAG_UPDATE` registration/re-registration logic, and zoning-time icon-repair initialization.
- Configuration `Refresh()` now resolves incomplete listed-item metadata on demand with `ResolveListedItemIcons()`.
- The refresh path first asks `GetItemInfo`, then performs at most one explicit bag pass for still-missing listed IDs.
- Item addition preserves the existing direct cursor-link/cache lookup and exact item-ID bag fallback, then refreshes the configuration list.
- If an icon still cannot be resolved, the existing question-mark texture remains the display fallback and no gameplay listener is armed.
- Item-ID list membership, shared `DB.items` metadata cache, SavedVariables shape, vendor behaviour, delete behaviour, and the main Auto-Delete `BAG_UPDATE` path were not changed.

Status:
- Static diff review passed.
- Real Lua 5.0.2 checker/self-test passed.
- User runtime validation: basic load/reload/zoning, config/list/icon behaviour, ordinary bag activity, and Auto-Vendor sanity passed on the combined P1 checkpoint. Normal configured Auto-Delete was deferred for later observation.

### P1 — occupied-cursor delete-worker spin eliminated in `0.1.28-dev`
Implemented at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`:
- When a delete step becomes due and `CursorHasItem()` is true, `ExecuteSafeDeleteStep()` now calls `StopDeleteWorker(false)` and returns.
- This clears the due timer and hides the worker immediately, so an occupied cursor can no longer leave the frame executing every update.
- `pendingDeleteIDs` is intentionally retained; the existing main `BAG_UPDATE` path can re-arm the same 0.20-second debounce on the next legitimate bag transition.
- The redundant cursor check was removed from the worker `OnUpdate`; the safety check remains inside `ExecuteSafeDeleteStep()`, immediately before any bag scan/deletion.
- Fail-closed behaviour is preserved: no deletion is attempted while the cursor is occupied, and no cursor item is guessed or manipulated.
- The main Auto-Delete `BAG_UPDATE` registration, `CHAT_MSG_LOOT` filtering order, SavedVariables/list semantics, feedback, and delete timing constants were not changed.

Status:
- Static review of the exact `56c92a0... -> e5e8e96...` runtime diff passed.
- Real Lua 5.0.2 checker/self-test passed in GitHub Actions run `36025914487`; all 10 addon Lua files compiled.
- User runtime validation: the occupied-cursor timing case was not reproduced because the 0.20-second window is impractical to hit manually. The user explicitly accepted that remaining gap and authorized advancing to P2 while watching runtime behaviour.

### P2 — demand-driven Auto-Delete `BAG_UPDATE` registration
Implemented at `63a75ebdda85bec16dc074f48622fd1bcdd38576`:
- The main event frame no longer registers `BAG_UPDATE` permanently.
- A relevant configured self-loot arms `pendingDeleteIDs` and registers `BAG_UPDATE` only for the active delete operation.
- `StopDeleteWorker(true)` clears pending IDs and unregisters `BAG_UPDATE` when work completes or aborts.
- `StopDeleteWorker(false)` intentionally leaves the listener armed for the occupied-cursor case because pending IDs are retained and the next legitimate bag transition must re-arm the debounce.
- The existing 0.20-second bag-settling/debounce semantics remain intact while deletion work is pending.

### P2 — reduced `CHAT_MSG_LOOT` work
Implemented at `63a75ebdda85bec16dc074f48622fd1bcdd38576`:
- `CHAT_MSG_LOOT` is registered only while Auto-Delete is enabled and `DB.deleteList` is non-empty.
- Initialization, the Auto-Delete toggle, and delete-list add/remove paths all refresh that registration.
- Loot handling now extracts the item ID first, rejects IDs absent from `DB.deleteList`, and only then runs the localized self-loot pattern matcher.
- Vendor-purchase exemption handling remains after positive item-ID/self-loot validation.
- No chat filtering or chat-window mutation was introduced.

### P3 — merchant/config/debug micro-costs
Implemented in the final optimization burst:
- Sell worker (`50efdff8...`): caches the active sell interval instead of reparsing `DB.interval` every frame; slider changes still update the cached value immediately.
- Sell worker (`50efdff8...`): replaces `table.remove(sellQueue, 1)` with an indexed queue, avoiding repeated array shifts while preserving item order and fail-closed slot/ID verification.
- Sell worker now hides immediately after the final queued sale instead of waiting for one additional throttle interval.
- Bin animation (`50efdff8...`): relies on `PlayBinAnimation()` for the unchanged pre-burn icon state, switches the wipe anchor once at burn start, and stops repeating unchanged alpha/texture/height/position assignments before the burn.
- Configuration drop animations (`50efdff8...`): their `OnUpdate` is attached only while the short flourish is active and removed at completion; no idle config animation handler remains.
- Dev `Debug.lua` (`c47b9c59...`): the timeline `OnUpdate` is attached only while a marker is actively dragged and removed on mouse-up, release detection, or timeline hide.

Post-P3 re-audit:
- Runtime `OnUpdate` handlers that remain are the sell worker, bin animation/unlock frame, and delete worker. Sell/delete workers are hidden while idle; the bin frame is hidden during ordinary gameplay except for its short animation or pfUI unlock visibility.
- `CHAT_MSG_LOOT` and `BAG_UPDATE` remain demand-driven from P2.
- Remaining permanent events are low-frequency lifecycle/merchant events: `ADDON_LOADED`, `VARIABLES_LOADED`, `PLAYER_ENTERING_WORLD`, `PLAYER_LOGOUT`, `MERCHANT_SHOW`, and `MERCHANT_CLOSED`.
- No further obvious recurring runtime cost is currently worth another optimization stage before user validation.

## Recent Relevant Commits
- `35ddeab61d1dd141a33c4a2edd112b828c162e50` — Remove the temporary Lua 5.0 checker after successful `0.1.33-dev` validation.
- `0a7cc06b5a0aa428d39bed7e3abece6d8274bc4e` — Temporary validation workflow commit; Actions run `36160817841` passed the canonical Lua 5.0.2 checker/self-test and all addon Lua files.
- `3816e1a0800e638f22b71e92df7f658a09bbea4f` — Refine Auto-Buy input state and saved-items layout; bump to `0.1.33-dev`.
- `62f7f72a93bc3524cdbc09af458af5b6225d0c39` — Remove the temporary Lua 5.0 checker after successful `0.1.32-dev` validation.
- `b6df4ef2fddd62d84858070a0f0a29833275c1ab` — Temporary validation workflow commit; Actions run `36157287265` passed the canonical Lua 5.0.2 checker/self-test and all addon Lua files.
- `83f2f5cb9ad241de850c81f43e78e764673e779e` — Fix Auto-Buy count ceiling, batched merchant execution and permanently visible empty input; bump to `0.1.32-dev`.
- `f4854e17fe96b96c32e97ce7b5ff386743f2bfcb` — Remove the temporary Lua 5.0 checker after successful `0.1.31-dev` validation.
- `336fd25e1ea2411c3a062360776c5cc919fabf25` — Temporary validation workflow commit; Actions run `36147804790` passed the canonical Lua 5.0.2 checker/self-test and all addon Lua files.
- `38453ab5567e37e6b2b8224c5b9f98aa4f9eb81d` — Revise Auto-Buy around staged input and inventory-stack caps; bump to `0.1.31-dev`.
- `83091ddabeb814c5a2ee43b0fb8199c765754c4f` — Remove the temporary Lua 5.0 checker after successful `0.1.30-dev` validation.
- `e89d7cdbafe3328c2f7f6350fcc9b3888952d7f1` — Temporary validation workflow commit; Actions run `36075563299` passed the real Lua 5.0.2 checker/self-test and all 10 Lua files.
- `d0e9ee613c2896d0ddc71268c77ff8737238e91e` — Bump the completed redesign build to `0.1.30-dev` and update TOC notes.
- `788249f7446c2c2079826f519d3738cb7b4429a7` — Add streamlined option labels and Buy chat text.
- `41e1b86891578af469b8225d38ef85d2694fb7cb` — Tighten compact Auto-Buy rows and tooltip capture.
- `833f3c18a096d57f9a2884cc1610e933b42dbe2c` — Implement streamlined options, list-driven semantics, unconditional pfUI grey-sell takeover, and Buy chat feedback.
- `70925d8f80605feaa02fd02b93d300345fea11e3` — Document the user-approved options redesign before implementation.
- `6bff5c194649b4a0af079bdf3147880faef82488` — Update development TOC notes to include Auto-Buy; no runtime Lua change.
- `0c0b4403a4858f2400a09dc05efedefb91be345f` — Remove temporary Lua 5.0 validation workflow after successful validation.
- `164ec4bf1e86d6cb3f3c2e459cef87c97f7ee848` — Refactor Auto-Buy configuration refresh to stay within Lua 5.0's 32-upvalue function limit; this is the Lua-validated feature runtime.
- `a0bcedb892a31aa311f255a9f30bfab8744a80ea` — Temporary validation workflow commit; first 0.1.29 compile exposed the 32-upvalue limit.
- `5b695ff4e09025465e3da4bfd9deac090fe19e69` — Add Auto-Buy and burn-duration English UI labels.
- `544cc430fd48d4cbc808bd2aeba432770462fe50` — Implement burn-duration control, Auto-Buy maintain-stock runtime and options re-layout.
- `1a67fc8057d3c0a1c5b202e3c3cfddf2a4fd3cb1` — Begin `0.1.29-dev`.
- `4c7e8acefeaa597bfebd87232886837c1e21a794` — Establish the 0.1.29 feature contract before code changes.
- `9df26d5606bcfecae59d22227219fe6d939bfe94` on `main` — Release 0.1.28; current stable release.
- `e3326556fa0158fdadd7dc16c9da700116625d80` on `dev` — Record accepted performance runtime before promotion.
- `c47b9c59e60607f539a3d2fc47d6862a7cb596eb` — Final user-tested dev runtime tree; dev-only timeline cleanup on top of release-facing P3 runtime.
- `50efdff8f24001010b087abdf817da86a669646a` — Optimize remaining release-facing runtime micro-costs.
- `63a75ebdda85bec16dc074f48622fd1bcdd38576` — Make Auto-Delete events demand-driven.
- `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` — Stop delete worker when cursor is occupied.
- `a1c9b6daec6fd06b644a804b19d6490cb89babab` — Remove background icon-repair polling and begin 0.1.28-dev performance pass.

## Completed / User-Verified
- `0.1.33-dev` Auto-Buy blank/manual `No more than` input, disabled/grey Add state, invalid red text, one-row saved-items strip and overall layout were reported by the user as working; the layout feels good.
- `0.1.32-dev` Auto-Buy hard actual-count ceiling and corrected vendor-batch purchase behaviour were explicitly reported by the user as working; no further purchase-engine change is requested in `0.1.33`.
- `0.1.31-dev` staged Auto-Buy text input accepted typed numbers in-game. The field was hard to discover while empty because no visible background rectangle was present; this is corrected in `0.1.32-dev`.
- `0.1.31-dev` Symbol of Divinity test: 3 held, user entered 5, addon bought 2, Buy chat reported x2 and final count was 5.
- `0.1.31-dev` Symbol of Kings test: 20 held, user entered 100, Buy chat reported x80 but the purchase filled the bags with Kings. This demonstrated that passing the computed unit amount directly as the second `BuyMerchantItem` argument is unsafe for the target client's batched merchant items.
- Additional target-client observations: shift-right-click on singly sold Symbol of Divinity opens a quantity selector bounded by its normal inventory stack; shift-right-click on Symbol of Kings buys one 20-item vendor batch; Crystal Vial is sold in vendor batches of 5, stacks to 20 in inventory, and its merchant quantity selector offers 1-4. These observations confirm vendor batch and inventory stack are distinct concepts.
- Partial `0.1.30-dev` options checkpoint at the documented handoff runtime: the panel loaded and the overall redesigned layout was judged basically fine. The Auto-Buy inline quantity EditBox was not accepted: it gained focus/blinked but accepted no typed input. No other `0.1.30` runtime paths should be inferred as passed from this result.
- P1 partial runtime checkpoint on `0.1.28-dev`: normal login, reload and zoning passed with no reported Lua errors.
- P1 config/list/icon behaviour passed, including adding/removing Auto-Vendor and Auto-Delete entries and ordinary bag activity.
- Auto-Vendor sanity passed on the P1 checkpoint.
- The restored 8-frame Auto-Delete feedback build was user tested and explicitly approved for stable release.
- Auto-Delete feedback checkbox placement and clickability are verified.
- Auto-Vendor feedback layout is verified.
- Sell-chat ON/OFF behaviour is verified.
- User-facing branding is `pfUI VendorTweaks`.
- Technical identifiers are normalized to `pfUI_VendorTweaks`.
- Dev debug controls/timeline framework works with the existing 8-frame animation.
- Stable install naming is normalized to `pfUI_VendorTweaks`; obsolete hyphenated runtime filenames are not part of the supported install.

## Implemented / Awaiting Runtime Test
- `0.1.30-dev` always owns pfUI grey auto-selling while loaded; the old takeover switch is retired, while the original pfUI setting/button handler are still restored on logout.
- Auto-Sell, Auto-Delete and Auto-Buy no longer have enable switches. Item-list membership is the explicit opt-in; legacy enable fields are retired during DB initialization.
- Sell Delay is a `0.00`–`0.20s` slider; the active sell worker still caches the chosen delay for the queue.
- The approved 8-frame Auto-Delete burn is always used for delete feedback and `Animation Duration` is a `0.20`–`1.00s` slider, default `1.00s`.
- Chat Messages are independently controlled by Sell/Delete/Buy checkboxes; Buy chat reports the merchant item and requested purchase amount.
- The accepted `0.1.33-dev` Auto-Buy behaviour/layout is unchanged in `0.1.34`.
- `0.1.34-dev` changes only visual hierarchy: three functional section headings use pfUI teal, each gets a subtle 1px right-extending rule, and the three chat option labels use silver/neutral text.
- AUTO-BUY's rule is bounded to the 415px full-width section; AUTO-SELL and AUTO-DELETE each use separate 195px rule bounds so the left rule cannot cross the centre gutter.
- `0.1.33-dev` never auto-fills the `No more than` field and removes the numeric-only input restriction so invalid strings can be shown explicitly rather than silently blocked.
- Input validation is live: empty remains neutral; non-empty invalid text turns red; valid positive integer text is normal.
- `Add` is a real disabled Button with grey text until a staged item and valid positive integer are both present; it re-enables with normal text only when the configuration is commit-ready.
- Saved Auto-Buy entries remain compact icon tiles with the hard maximum actual item count attached, but are now laid out in one horizontal row inside a 415x38 full-width strip. The child width grows with entries and mouse-wheel input changes horizontal scroll; no vertical wrapping remains.
- Auto-Buy batch calculation is `unitsToBuy = floor((maximum - have) / vendorBatchSize) * vendorBatchSize`, so impossible remainders are intentionally left below the ceiling.
- For `batchSize == 1`, Auto-Buy calls `BuyMerchantItem(index, unitsToBuy)`. For `batchSize > 1`, it issues `unitsToBuy / batchSize` separate `BuyMerchantItem(index)` calls, each representing one vendor batch on the target client; this avoids the demonstrated batched second-argument hazard.
- Buy chat reports `unitsToBuy` actual items even when several no-quantity batch calls are used internally.
- `0.1.31` `inventory_stacks` Auto-Buy entries are cleared once on initialization for safety; no ambiguous automatic conversion is attempted.
- Merchant ordering remains sales first, then Auto-Buy, so selling can free bag space before restocking.
- Auto-Sell, Auto-Delete and Auto-Buy ownership remains mutually exclusive per item after `Add` commits a staged Auto-Buy entry.
- The remaining `0.1.30-dev` options/list/chat/burn work is unchanged and remains awaiting its uncompleted runtime validation.
- New `No more than` and existing `Add` strings are present in `enUS`; other locales continue to use the existing enUS fallback for the new keys.

## Static / Automated Checks
- P1 and P2 passed their documented static reviews and Lua 5.0.2 checks.
- Exact P3 comparison `5b24519... -> c47b9c5...` contains two coherent commits modifying only `pfUI_VendorTweaks.lua` and dev-only `Debug.lua`.
- No `table.remove(sellQueue, 1)` remains; sell order is maintained by `sellQueueIndex`.
- Sell interval is cached for active work and updated immediately by the configuration slider.
- Configuration drop-animation `OnUpdate` is attached in `Play()` and explicitly removed at animation completion; there is no permanent idle guard handler.
- The bin animation no longer reapplies unchanged pre-burn visual state every frame and only reapplies the wipe anchor on the transition into wiping.
- Debug timeline has no permanent `timeline:SetScript("OnUpdate", function...)`; it attaches the named update handler only during marker dragging and clears it on all drag termination paths.
- Post-P3 event/OnUpdate inventory found no further high-frequency idle path beyond already-hidden workers and the intentional bin animation/unlock frame.
- GitHub Actions run `36030161209` passed the combined dev-tree Lua 5.0.2 checker/self-test and compilation.
- Initial stable-tree validation run `36035277559` failed only because the temporary dev checker command referenced intentionally absent `Debug.lua`; checker self-test itself passed.
- Corrected stable-file-set validation run `36035354158` passed the real Lua 5.0.2 checker/self-test and compiled `pfUI_VendorTweaks.lua` plus all stable locale Lua files.
- Stable release tree `91fef0ebcafcc6a975949a992d23e69dea0be8c1` contains only `README.md`, artwork, locales, `pfUI_VendorTweaks.lua`, stable `pfUI_VendorTweaks.toc`, and `pfui-av.png`; no `DEV_PROGRESS.md`, `dev_rulebook.md`, `Debug.lua`, or temporary validation files are present.
- Initial 0.1.29 validation run `36073383290` correctly failed the feature runtime at line 1521 with Lua 5.0.2's `too many upvalues (limit=32)` error in the enlarged configuration refresh closure; the checker self-test itself passed.
- Commit `164ec4bf1e86d6cb3f3c2e459cef87c97f7ee848` isolated Auto-Buy list refresh into its own narrow closure rather than globalizing state or weakening the checker.
- Follow-up run `36073598287` passed the real Lua 5.0.2 checker self-test and compiled `pfUI_VendorTweaks.lua`, `Debug.lua`, and all locale Lua files.
- The temporary checker workflow was removed immediately afterward; current `dev` contains no validation-only workflow.
- `0.1.30-dev` validation run `36075563299` passed the real Lua 5.0.2 checker self-test and compiled all 10 addon Lua files.
- Exact `0.1.31-dev` runtime diff at `38453ab5567e37e6b2b8224c5b9f98aa4f9eb81d` was reviewed after implementation; it changes only the TOC version, enUS labels, Auto-Buy SavedVariables semantics/migration, Auto-Buy merchant cap calculation, and the Auto-Buy configuration UI.
- `0.1.31-dev` validation run `36147804790` passed the canonical Lua 5.0.2 checker self-test and compiled `pfUI_VendorTweaks.lua`, `Debug.lua`, and all locale Lua files.
- Exact `0.1.32-dev` runtime diff at `83f2f5cb9ad241de850c81f43e78e764673e779e` was reviewed after implementation; it changes only Auto-Buy representation/migration, hard-ceiling batch execution, the staged input presentation/wording, enUS label, and TOC version.
- `0.1.32-dev` validation run `36157287265` passed the canonical Lua 5.0.2 checker self-test and compiled `pfUI_VendorTweaks.lua`, `Debug.lua`, and all locale Lua files. The validated runtime Lua blob is `719628956e859747cc9473e57d6013b8a6dfdb94`.
- Exact `0.1.33-dev` runtime diff at `3816e1a0800e638f22b71e92df7f658a09bbea4f` was reviewed after implementation; it changes only Auto-Buy configuration input state/layout and TOC version. The `0.1.32` merchant purchase engine and SavedVariables representation are unchanged.
- `0.1.33-dev` validation run `36160817841` passed the canonical Lua 5.0.2 checker self-test and compiled `pfUI_VendorTweaks.lua`, `Debug.lua`, and all locale Lua files. The validated runtime Lua blob is `c1d4d11e901389490199145b19ab2ffbcf7dcfc1`.
- Exact `0.1.34-dev` runtime diff at `716bb6940c35cc75fcaeb530915a7cb6741290b1` was reviewed after implementation; it changes only three chat-label colours, section-header colour/rule styling, and TOC version.
- `0.1.34-dev` validation run `36165705057` passed the canonical Lua 5.0.2 checker self-test and compiled `pfUI_VendorTweaks.lua`, `Debug.lua`, and all locale Lua files. The validated runtime Lua blob is `25f2dc0025ad56ed4c9a41c58ea94a6226d9920b`.
- The temporary `0.1.34` checker workflow was removed immediately afterward; current `dev` contains no validation-only workflow and the validated runtime Lua blob is unchanged.

## Current Issues
- No current static or compiler regression is known.
- No current Auto-Buy purchase-engine or configuration-layout issue is reported on the tested `0.1.33-dev` runtime; the user explicitly reports all tested behaviour works and the layout feels good.
- `0.1.34-dev` is styling-only and still needs target-client visual validation of teal headers, silver chat-option labels, and correctly bounded 1px rules.
- The temporary `0.1.31` Auto-Buy list is intentionally discarded on first `0.1.32+` load; this is expected, not a persistence regression. Current `max_count` entries remain compatible and are not reset by `0.1.33`.
- Historical validation note: the occupied-cursor P1 edge case was not deliberately reproduced because the 0.20-second timing window is impractical to hit manually; no related regression was observed during natural play.

## Testing

### Last Runtime Test
- Version/runtime source: `0.1.33-dev` handoff at `15064000fa0811a4c6975b411b946ef08ed18c69` (runtime Lua blob `c1d4d11e901389490199145b19ab2ffbcf7dcfc1`).
- Result: user reports all tested behaviour works and the layout feels good.
- Requested follow-up is visual hierarchy only: teal functional section headers, silver Sell/Delete/Buy option labels, and subtle right-extending 1px section rules without adding vertical size.

### Next Runtime Test
Use the exact current `0.1.34-dev` build and verify the styling-only delta:
1. Confirm AUTO-BUY, AUTO-SELL and AUTO-DELETE are pfUI teal.
2. Confirm Sell/Delete/Buy checkbox labels are silver/neutral while Chat Messages stays gold.
3. Confirm each teal heading has a subtle 1px rule beginning just after the text.
4. Confirm AUTO-BUY's rule ends at the full-width section edge; AUTO-SELL's rule stops before the centre gutter; AUTO-DELETE has its own right-column rule.
5. Confirm no extra vertical height, overlap or change to the already accepted `0.1.33` behaviour/layout.

## Planned / Next Work
- Stop code changes at the `0.1.34-dev` runtime-validation gate.
- Use user runtime results to correct only demonstrated issues in the new visual-hierarchy styling.
- Do not alter the accepted `0.1.33` behaviour/layout, promote, translate additional locales, add the optional current/max label, or broaden merchant behavior before this styling delta is user-accepted.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.
- Do not redesign features merely to optimize raid-only behaviour; changes should reduce general background cost while preserving functionality.
- Do not add ClassicAPI or another DLL dependency solely for this performance pass unless a concrete measured limitation of the native 1.12.1 API requires it and the dependency is explicitly reconsidered.
- Translating the current Auto-Buy strings into non-English locale files is deferred; functional fallback remains enUS.
- A dynamic Auto-Buy current/max presentation such as `146/200` beneath saved icons is explicitly deferred until after the current runtime gate; do not add it during validation.

## Release / Promotion Notes
- Current stable release is `0.1.28` on `main` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.
- Stable TOC metadata is `VendorTweaks` / `0.1.28`.
- Stable runtime Lua blob is exactly `d4011262f648fe98bcf78be37640cbce249d6e6b`, matching the user-tested dev runtime.
- Stable release excludes `DEV_PROGRESS.md`, `dev_rulebook.md`, `Debug.lua`, and development-only loader entries.
- Release validation: corrected stable-file-set Lua 5.0.2 run `36035354158` passed.
- Accepted validation debt: the occupied-cursor 0.20-second edge case was not deliberately reproduced; natural play showed no related regression.
- External/runtime prerequisites remain World of Warcraft 1.12.1 and pfUI; no optional DLL/client extension is required.

## Exact Next Step
User runtime-test the exact `0.1.34-dev` build using the "Next Runtime Test" sequence above. This is a styling-only gate: teal functional section headers, silver chat-option labels and correctly bounded 1px rules. The accepted `0.1.33` behaviour/layout is intentionally unchanged. Do not promote or broaden scope before those results.
