# Development Progress

## Current
- Branch: `dev`
- Dev version: `0.1.28-dev`
- Stable release: `0.1.28` on `main` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.
- User-tested runtime source: `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`; the stable release uses the exact same `pfUI_VendorTweaks.lua` blob (`d4011262f648fe98bcf78be37640cbce249d6e6b`) with stable TOC metadata and dev-only material removed.
- Release-facing P3 runtime commit: `50efdff8f24001010b087abdf817da86a669646a`.
- P2 runtime commit: `63a75ebdda85bec16dc074f48622fd1bcdd38576`.
- P1 runtime commits: `a1c9b6daec6fd06b644a804b19d6490cb89babab` and `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Mode: maintenance. The performance pass is complete, user-accepted, validated, and promoted. Do not begin speculative optimization or feature work without a new explicit request.
- Current scope: regression fixes, compatibility maintenance, or explicitly requested changes only.

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
- The addon is feature-complete and has returned to maintenance mode after the completed `0.1.28` performance pass.
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
- None. No unreleased runtime work is currently queued.

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

## Current Issues
- No current runtime, static, or compiler regression is known.
- Historical validation note: the occupied-cursor P1 edge case was not deliberately reproduced because the 0.20-second timing window is impractical to hit manually; no related regression was observed during natural play.

## Testing

### Last Runtime Test
- Version/runtime source: `0.1.28-dev` runtime tree at `c47b9c59e60607f539a3d2fc47d6862a7cb596eb`.
- Result: user reports the addon appears to be working as expected during natural play.
- No Lua errors, missed/unintended actions, visual regressions, stuck workers, or performance symptoms were reported.
- The stable `0.1.28` release at `9df26d5606bcfecae59d22227219fe6d939bfe94` inherits this runtime validation because its runtime Lua blob is byte-identical to the tested source; promotion changed only stable TOC metadata and removed dev-only material.

### Next Runtime Test
- None scheduled. Resume runtime testing only when a future maintenance change introduces a new runtime delta.

## Planned / Next Work
- No active development work. Project is in maintenance mode.
- Future work should begin only for a reported regression, compatibility need, or explicit new request.
- Any future runtime edit starts a new tested delta from stable `main` `0.1.28` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.
- Do not redesign features merely to optimize raid-only behaviour; changes should reduce general background cost while preserving functionality.
- Do not add ClassicAPI or another DLL dependency solely for this performance pass unless a concrete measured limitation of the native 1.12.1 API requires it and the dependency is explicitly reconsidered.

## Release / Promotion Notes
- Current stable release is `0.1.28` on `main` at `9df26d5606bcfecae59d22227219fe6d939bfe94`.
- Stable TOC metadata is `VendorTweaks` / `0.1.28`.
- Stable runtime Lua blob is exactly `d4011262f648fe98bcf78be37640cbce249d6e6b`, matching the user-tested dev runtime.
- Stable release excludes `DEV_PROGRESS.md`, `dev_rulebook.md`, `Debug.lua`, and development-only loader entries.
- Release validation: corrected stable-file-set Lua 5.0.2 run `36035354158` passed.
- Accepted validation debt: the occupied-cursor 0.20-second edge case was not deliberately reproduced; natural play showed no related regression.
- External/runtime prerequisites remain World of Warcraft 1.12.1 and pfUI; no optional DLL/client extension is required.

## Exact Next Step
None. The addon is in maintenance mode at stable `0.1.28` (`main` `9df26d5606bcfecae59d22227219fe6d939bfe94`). On the next explicit maintenance request, read this file and `dev_rulebook.md`, verify current branch heads, and start from the stable `0.1.28` baseline unless the request intentionally establishes a new development line.
