# Development Progress

## Current
- Branch: `dev`
- Version: `0.1.28-dev`
- Current dev runtime head: `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`.
- Release-facing P3 runtime commit: `50efdff8f24001010b087abdf817da86a669646a` — indexed/cached sell worker, reduced bin-animation redundant work, and demand-driven configuration drop-animation updates.
- Dev-only P3 commit: `c47b9c59e60607f539a3d2fc47d6862a7cb596eb` — demand-driven Debug.lua timeline dragging.
- P2 runtime commit: `63a75ebdda85bec16dc074f48622fd1bcdd38576`.
- P1 icon-resolution runtime commit: `a1c9b6daec6fd06b644a804b19d6490cb89babab`.
- P1 occupied-cursor worker runtime commit: `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Stable baseline: `0.1.27` on `main` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Goal: finish the performance-maintenance pass by validating the combined P1+P2+P3 tree through normal play rather than isolated restart-heavy microtests.
- Current stage: all planned P1/P2/P3 performance work is implemented, statically reviewed, and accepted by the real Lua 5.0.2 compiler checker. The remaining gate is user runtime observation of the combined tree.
- Current scope boundary: performance-focused maintenance only. Do not reopen shelved visual/features work, change SavedVariables semantics, or alter accepted vendor/delete behaviour unless required by a proven regression.

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
- The addon version comes from the TOC. The current performance build is `0.1.28-dev`; its runtime delta is the completed P1/P2 performance work plus the P3 sell-worker, burn-animation and configuration-animation micro-optimizations. `Debug.lua` also has a dev-only demand-driven timeline update cleanup.
- The approved production Auto-Delete feedback remains the existing single 8-frame strip `artwork/pfUI_VendorTweaks_Burn.tga`, with `BIN_FRAME_COUNT = 8` and approximately 1.0 second default runtime.
- Debug controls may tune/preview the existing animation but must not become a stable runtime dependency.
- Do not introduce heuristic buyback matching: stock 1.12 buyback API does not expose an exact item link/ID suitable for a reliable Auto-Delete exemption.
- Performance optimizations must preserve fail-closed delete safety, merchant behaviour, user-configured lists, and current visual/chat settings.
- Do not optimize only for raids. The target is lower background cost in all gameplay; raids are simply where compounded addon overhead is most visible.

### Protocol / Data Model
- No external protocol is involved.
- Existing SavedVariables/config semantics are the compatibility contract; the performance pass should not migrate or reinterpret them.
- Vendor/delete list membership remains item-ID keyed; cached names/icons remain presentation metadata rather than behavioural authority.

### Active Decisions
- The addon remains feature-complete; this is an explicitly authorized maintenance pass.
- The performance audit should prioritize removing recurring idle/background work over micro-optimizing one-shot configuration or merchant operations.
- Preserve event-driven ownership: temporary workers may run while a real operation is active, but they should become fully dormant when no work is pending.
- The longer/higher-frame/two-part Fire/Ash burn replacement remains shelved; the restored 8-frame implementation is the approved production state.
- Sell-chat ON/OFF behaviour, Auto-Vendor feedback layout, Auto-Delete feedback controls, and current branding are accepted behaviour.

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
- `c47b9c59e60607f539a3d2fc47d6862a7cb596eb` — Make dev debug timeline update demand-driven; current dev runtime head.
- `50efdff8f24001010b087abdf817da86a669646a` — Optimize remaining release-facing runtime micro-costs.
- `5b2451959e410bd172e7d4ee77a7b49024ab29bf` — Record P2 performance checkpoint.
- `63a75ebdda85bec16dc074f48622fd1bcdd38576` — Make Auto-Delete events demand-driven; P2 implementation.
- `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` — Stop delete worker when cursor is occupied; second P1 runtime change.
- `a1c9b6daec6fd06b644a804b19d6490cb89babab` — Remove background icon repair polling; first P1 runtime change and `0.1.28-dev` version bump.
- Stable `main`: `b2a90beb03464494b2cd5c699f10a0a2bd82f26b` — Release 0.1.27.

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
- P1 icon-resolution rewrite: background icon-repair `BAG_UPDATE` subsystem removed.
- P1 occupied-cursor worker fix: due worker stops instead of polling every frame while the cursor is occupied.
- P2: `CHAT_MSG_LOOT` and `BAG_UPDATE` are demand-driven and irrelevant loot is rejected by item ID before localized matching.
- P3 release-facing runtime optimizations: cached/indexed sell worker, reduced redundant burn-frame work, and demand-driven configuration drop-animation updates.
- P3 dev-only optimization: timeline drag `OnUpdate` is demand-driven.
- The exact combined P1+P2+P3 dev tree at `c47b9c59...` is awaiting natural-play runtime validation.
- Remaining historical P1 validation gap: the occupied-cursor 0.20-second edge case was not reproducible manually. Continue observing it opportunistically rather than requiring reflex testing.

## Static / Automated Checks
- P1 and P2 passed their documented static reviews and Lua 5.0.2 checks.
- Exact P3 comparison `5b24519... -> c47b9c5...` contains two coherent commits modifying only `pfUI_VendorTweaks.lua` and dev-only `Debug.lua`.
- No `table.remove(sellQueue, 1)` remains; sell order is maintained by `sellQueueIndex`.
- Sell interval is cached for active work and updated immediately by the configuration slider.
- Configuration drop-animation `OnUpdate` is attached in `Play()` and explicitly removed at animation completion; there is no permanent idle guard handler.
- The bin animation no longer reapplies unchanged pre-burn visual state every frame and only reapplies the wipe anchor on the transition into wiping.
- Debug timeline has no permanent `timeline:SetScript("OnUpdate", function...)`; it attaches the named update handler only during marker dragging and clears it on all drag termination paths.
- Post-P3 event/OnUpdate inventory found no further high-frequency idle path beyond already-hidden workers and the intentional bin animation/unlock frame.
- GitHub Actions run `36030161209` passed the canonical Lua 5.0.2 checker reconstruction, checker self-test, and compilation of `pfUI_VendorTweaks.lua`, `Debug.lua`, and all locale Lua files.
- Temporary validation branch `validation/lua50-p3` was reset back to `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`; no temporary workflow remains in the runtime tree.

## Current Issues
- The combined P1+P2+P3 performance tree has not yet received an end-to-end natural-play runtime result.
- Normal configured Auto-Delete still needs to be observed after the P2/P3 changes.
- The occupied-cursor P1 edge case remains runtime-unproven because the timing window is impractical to reproduce manually.
- No current static/compiler failure or additional obvious performance hotspot is known.

## Testing

### Last Runtime Test
- Version/runtime commit: `0.1.28-dev` P1 runtime tree at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Passed: login, reload, zoning; config/list/icon presentation; adding/removing Auto-Vendor and Auto-Delete entries; ordinary bag activity; Auto-Vendor behaviour.
- Deferred: normal configured Auto-Delete was left for natural play.
- Not reproduced: occupied-cursor Auto-Delete edge case because the worker timing window was too short to hit reliably by hand.
- Decision: user explicitly chose to combine later optimizations and validate them through natural play instead of repeated restart-heavy microtests.

### Next Runtime Test
Use the exact current `0.1.28-dev` tree at `c47b9c59e60607f539a3d2fc47d6862a7cb596eb` normally. During natural play, watch for:
- login/reload/zoning Lua errors;
- normal Auto-Vendor and grey-selling throughput/order at the configured throttle;
- changing the sell-speed slider and later selling items at the new setting;
- normal Auto-Delete, delete animation and delete chat;
- Auto-Delete OFF/ON and add/remove-list behaviour;
- vendor-purchase Auto-Delete exemption;
- ordinary and group/raid loot traffic;
- configuration drop flourishes when adding list items;
- if using dev controls, timeline marker dragging/preview;
- any missed sales/deletes, unintended deletes, visual regression, stuck worker, or unusual performance behaviour.

A normal play session covering the addon’s ordinary vendor/delete use is preferred over more isolated microtests.

## Planned / Next Work
1. P1/P2/P3 implementation — complete and statically/compiler checked.
2. User runtime-observe the exact combined tree at `c47b9c59...` through normal play.
3. Record the result against that exact commit.
4. If behaviour is accepted, treat the performance pass as complete and prepare the normal release/promotion review against stable `main`.
5. If a real regression appears, fix only that proven regression before promotion.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.
- Do not redesign features merely to optimize raid-only behaviour; changes should reduce general background cost while preserving functionality.
- Do not add ClassicAPI or another DLL dependency solely for this performance pass unless a concrete measured limitation of the native 1.12.1 API requires it and the dependency is explicitly reconsidered.

## Release / Promotion Notes
- Stable baseline to preserve is `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Do not promote the performance rewrite until the exact runtime delta is user-tested and accepted.
- Preserve stable TOC Title/Version metadata and exclude development-only status/debug material from release builds.
- `main` and `dev` diverge in Git history; future promotion must compare the branches and preserve the intended stable/release tree rather than assuming a blind fast-forward or replacement.
- Main-only or release-only content to preserve: stable TOC metadata and the absence of dev-only `DEV_PROGRESS.md`/`Debug.lua`; no unique main-only runtime feature is currently documented.
- Known validation debt accepted for release: None.
- External/runtime prerequisites: World of Warcraft 1.12.1 and pfUI. No optional DLL/client extension is currently required.

## Exact Next Step
Runtime-observe the exact current `0.1.28-dev` combined P1+P2+P3 tree at `c47b9c59e60607f539a3d2fc47d6862a7cb596eb` through normal play. Prioritize ordinary Auto-Vendor/grey sales, normal Auto-Delete, sell-speed changes, delete/config animations, Auto-Delete list/toggle changes, vendor-purchase exemption and group/raid loot. Record any Lua errors, missed or unintended actions, visual differences, stuck workers or performance symptoms. Do not make further speculative performance changes before this natural-play checkpoint; if it passes, move to release/promotion review.
