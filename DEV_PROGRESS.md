# Development Progress

## Current
- Branch: `dev`
- Dev version: `0.1.30-dev`.
- Stable release: `0.1.28` on `main` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.
- User-tested runtime source: `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`; the stable release uses the exact same `pfUI_VendorTweaks.lua` blob (`d4011262f648fe98bcf78be37640cbce249d6e6b`) with stable TOC metadata and dev-only material removed.
- Release-facing P3 runtime commit: `50efdff8f24001010b087abdf817da86a669646a`.
- P2 runtime commit: `63a75ebdda85bec16dc074f48622fd1bcdd38576`.
- P1 runtime commits: `a1c9b6daec6fd06b644a804b19d6490cb89babab` and `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Feature-pass baseline: `f9143abb659481007ac497ec00d5451a6800a4e6`.
- Pre-redesign head: `3fc2aee6626aceaf18964de96a0a1071cfa79286`; this was the prior handoff plus the repository-wide rulebook versioning clarification only.
- Current pre-handoff dev head: `83091ddabeb814c5a2ee43b0fb8199c765754c4f`.
- Lua-validated `0.1.30-dev` tree: `e89d7cdbafe3328c2f7f6350fcc9b3888952d7f1`; current `pfUI_VendorTweaks.lua` is the exact validated blob `203aa3a77661ce97e0288ecb2372681151c3c93d`, and the only later runtime-tree change removed the temporary checker workflow.
- Mode: runtime-validation gate for the streamlined `0.1.30-dev` options/list-semantics pass.
- Current scope: user-test the redesigned options layout, unconditional grey-sell takeover, list-driven Auto-Sell/Auto-Delete/Auto-Buy, Buy chat feedback, and the inherited Auto-Buy/burn backend before any promotion.

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
- The addon version comes from the TOC. Current development is `0.1.30-dev`; it inherits the accepted `0.1.28` runtime baseline plus the untested `0.1.29-dev` Auto-Buy/burn backend, and adds the documented streamlined options/list-semantics delta.
- The approved production Auto-Delete feedback remains the existing single 8-frame strip `artwork/pfUI_VendorTweaks_Burn.tga`, with `BIN_FRAME_COUNT = 8` and approximately 1.0 second default runtime.
- Debug controls may tune/preview the existing animation but must not become a stable runtime dependency.
- Do not introduce heuristic buyback matching: stock 1.12 buyback API does not expose an exact item link/ID suitable for a reliable Auto-Delete exemption.
- Performance optimizations must preserve fail-closed delete safety, merchant behaviour, user-configured lists, and current visual/chat settings.
- Do not optimize only for raids. The target is lower background cost in all gameplay; raids are simply where compounded addon overhead is most visible.

### Protocol / Data Model
- No external protocol is involved.
- Existing item lists and metadata remain compatible. `0.1.30-dev` intentionally retires the old takeover/Auto-Vendor/Auto-Delete/Auto-Buy enable flags: list membership is now the feature opt-in, while Sell/Delete/Buy chat preferences remain persistent SavedVariables.
- Vendor/delete list membership remains item-ID keyed. Auto-Buy is item-ID keyed with the configured desired bag count as its value; cached name/icon/stack metadata remains presentation/defaulting data rather than behavioural authority.

### Active Decisions
- The completed `0.1.28` performance pass remains the accepted runtime baseline; `0.1.30-dev` contains the still-unvalidated `0.1.29-dev` Auto-Buy/burn work plus the approved options/list-semantics redesign.
- The performance audit should prioritize removing recurring idle/background work over micro-optimizing one-shot configuration or merchant operations.
- Preserve event-driven ownership: temporary workers may run while a real operation is active, but they should become fully dormant when no work is pending.
- The longer/higher-frame/two-part Fire/Ash burn replacement remains shelved; the restored 8-frame implementation is the approved production state.
- Current branding remains `pfUI VendorTweaks`. The old feature-enable and animation-enable checkbox layout is superseded by the user-approved streamlined controls in this pass.

## Active Feature Pass — 0.1.30-dev

### Requested behaviour
- Installing VendorTweaks means VendorTweaks owns pfUI grey auto-selling; there is no separate takeover checkbox.
- Auto-Vendor, Auto-Delete and Auto-Buy require no enable checkboxes. Putting an item in the corresponding list is the explicit opt-in; an empty list means no configured work for that feature.
- Sell delay is user-configurable from `0.00` to `0.20` seconds.
- The approved 8-frame Auto-Delete burn animation remains production behaviour and gets an `Animation Duration` slider from `0.20` to `1.00` seconds.
- Chat feedback is independently configurable for Sell, Delete and Buy.
- Auto-Buy maintains a configured actual item count in bags `0`–`4` when a merchant selling that item is opened.
- Auto-Buy configuration is item-ID keyed. Each entry stores its desired bag count; cached name/icon/stack metadata remains presentation/defaulting data.
- Dropping a new Auto-Buy item defaults its desired amount to one normal item stack when `GetItemInfo` supplies a stack size, otherwise `1`. The amount remains directly editable.
- Merchant matching is by exact item ID. Merchant sale quantity/batch size from `GetMerchantItemInfo` must be respected so a purchase does not leave the requested target short merely because the merchant sells in lots.
- Auto-Buy counts bags only, not bank contents.
- Auto-Vendor, Auto-Delete and Auto-Buy membership are mutually exclusive for the same item because simultaneous buy/sell/delete ownership would create contradictory merchant behaviour.
- Do not add speculative buy throttling, confirmation systems, bank counting, restock categories, or unrelated vendor features in this pass.

### UI direction
- Header controls: `Sell Delay` slider on the left (`0.00`–`0.20s`) and `Animation Duration` slider on the right (`0.20`–`1.00s`).
- One compact `Chat Messages` row below them: `Sell [x]`, `Delete [x]`, `Buy [x]`.
- Auto-Buy comes next at full width: one drop target followed by compact horizontal item-icon + maintain-quantity controls; entries may wrap when needed. Do not spend permanent row space on item names or stack-size labels.
- Auto-Sell and Auto-Delete remain the lower two-column section, each with its drop target and scrollable item list.
- Preserve pfUI styling, existing drop animation behaviour and the small editable Auto-Buy maximum/maintain quantity box.

### Validation gates
- Real Lua 5.0.2 compile/static check before runtime handoff.
- Runtime: existing Auto-Vendor and Auto-Delete regression sanity.
- Runtime: burn animation at default plus at least one shorter and one longer configured duration.
- Runtime: Auto-Buy with an item sold singly and an item sold in a merchant batch; test below-target, exactly-at-target, and above-target bag counts.
- Runtime: verify a configured Auto-Buy item at one normal stack default can be edited to an arbitrary count and persists across reload.
- Runtime: confirm list exclusivity when moving the same item between Auto-Vendor, Auto-Delete and Auto-Buy.

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
- Auto-Buy maintain-stock remains item-ID keyed by desired actual bag count, counts bags 0-4 only, matches exact merchant item ID, and defaults a new item target from its normal item stack size when available.
- Merchant batch handling is unchanged from `0.1.29-dev`: deficits are rounded up to the merchant-reported sale batch before `BuyMerchantItem`; this still requires target-client verification because historical 1.12-era quantity semantics are inconsistent.
- Merchant ordering remains sales first, then Auto-Buy, so selling can free bag space before restocking.
- Auto-Sell, Auto-Delete and Auto-Buy ownership remains mutually exclusive per item; Auto-Buy ownership prevents both grey and explicit Auto-Sell of that item.
- Options layout now matches the approved design: two header sliders, compact Chat Messages row, full-width Auto-Buy drop area with compact icon + quantity entries, then lower two-column Auto-Sell/Auto-Delete lists. Item names are available by hover instead of consuming Auto-Buy row width.
- New user-facing strings are present in `enUS`; other locales continue to use the existing enUS fallback for the new keys.

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
- `0.1.30-dev` validation run `36075563299` passed the real Lua 5.0.2 checker self-test and compiled all 10 addon Lua files. The validated runtime Lua blob is `203aa3a77661ce97e0288ecb2372681151c3c93d` and is unchanged on current `dev`.

## Current Issues
- No current static or compiler regression is known.
- The entire `0.1.30-dev` runtime delta remains untested in-game; the inherited Auto-Buy/burn work from `0.1.29-dev` was also never runtime-tested before this redesign.
- Batched merchant purchasing remains the highest-priority runtime check: `GetMerchantItemInfo` exposes a batch quantity, while historical 1.12-era documentation for `BuyMerchantItem(index, quantity)` is inconsistent about stack-vs-unit semantics. Do not promote until an actual batched reagent is verified.
- The redesigned option spacing/clickability, compact Auto-Buy icon/quantity rows, tooltip/remove control, and both sliders require target-client validation.
- Buy chat currently reports the amount requested from `BuyMerchantItem`; runtime batch validation will determine whether that message corresponds cleanly to actual units received on the target client.
- Historical validation note: the occupied-cursor P1 edge case was not deliberately reproduced because the 0.20-second timing window is impractical to hit manually; no related regression was observed during natural play.

## Testing

### Last Runtime Test
- Version/runtime source: `0.1.28-dev` runtime tree at `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`.
- Result: user reports the addon appears to be working as expected during natural play.
- No Lua errors, missed/unintended actions, visual regressions, stuck workers, or performance symptoms were reported.
- The stable `0.1.28` release at `9df26d5606bcfecae59d22227219fe6d939bfe94` inherits this runtime validation because its runtime Lua blob is byte-identical to the tested source; promotion changed only stable TOC metadata and removed dev-only material.

### Next Runtime Test
Use the exact current `0.1.30-dev` handoff build and verify:
1. Addon loads with no Lua errors; open VendorTweaks options and confirm the new layout is aligned, readable and fully clickable: Sell Delay + Animation Duration, one Chat Messages row, compact Auto-Buy, then Auto-Sell/Auto-Delete columns.
2. Grey selling: with VendorTweaks installed, open a merchant with grey items and confirm VendorTweaks performs the grey sale without any takeover checkbox. Also confirm an explicit Auto-Sell-list item sells in the same visit.
3. Sell Delay: test near both ends (`0.00` and `0.20`) and confirm the visible selling cadence changes and the selected value persists after reload.
4. Auto-Delete: drag an item into Auto-Delete, self-loot it, confirm deletion still occurs, and verify Animation Duration at `0.20`, a middle value, and `1.00`; reload and confirm persistence.
5. Chat Messages: independently toggle Sell, Delete and Buy and confirm only the corresponding message is suppressed/restored.
6. Auto-Buy single-unit merchant item: drag it into Auto-Buy, confirm the compact icon + small quantity box appears, hover identifies the item, the default target matches one normal item stack when metadata is available, and an arbitrary edited target persists.
7. For that single-unit item, test below-target, exactly-at-target and above-target bag counts; only below-target should purchase.
8. Auto-Buy batched reagent/vendor item: verify the resulting actual bag count reaches at least the configured maintain target without multiplying the purchase incorrectly, and compare the Buy chat amount with the actual units received.
9. Move the same item Auto-Buy -> Auto-Sell -> Auto-Delete (or equivalent) and confirm only the newest list retains it; confirm the compact Auto-Buy remove control also removes an entry.
10. With selling and Auto-Buy configured at the same merchant, confirm selling finishes before restocking and an Auto-Buy-owned item is never sold.

## Planned / Next Work
- Stop code changes at the `0.1.30-dev` runtime-validation gate.
- Use user runtime results to correct only demonstrated issues in the new delta.
- Do not promote, translate additional locales, or broaden merchant behavior before the streamlined UI and Auto-Buy/batch behavior are user-accepted.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.
- Do not redesign features merely to optimize raid-only behaviour; changes should reduce general background cost while preserving functionality.
- Do not add ClassicAPI or another DLL dependency solely for this performance pass unless a concrete measured limitation of the native 1.12.1 API requires it and the dependency is explicitly reconsidered.
- Translating the new `0.1.30` strings into non-English locale files is deferred; functional fallback remains enUS.

## Release / Promotion Notes
- Current stable release is `0.1.28` on `main` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.
- Stable TOC metadata is `VendorTweaks` / `0.1.28`.
- Stable runtime Lua blob is exactly `d4011262f648fe98bcf78be37640cbce249d6e6b`, matching the user-tested dev runtime.
- Stable release excludes `DEV_PROGRESS.md`, `dev_rulebook.md`, `Debug.lua`, and development-only loader entries.
- Release validation: corrected stable-file-set Lua 5.0.2 run `36035354158` passed.
- Accepted validation debt: the occupied-cursor 0.20-second edge case was not deliberately reproduced; natural play showed no related regression.
- External/runtime prerequisites remain World of Warcraft 1.12.1 and pfUI; no optional DLL/client extension is required.

## Exact Next Step
User runtime-test the exact `0.1.30-dev` handoff build using the "Next Runtime Test" sequence above. First priority is options/load sanity and the compact Auto-Buy controls; highest-risk behavior remains batched merchant purchasing. Do not promote or broaden scope before those results.
