# Development Progress

## Current
- Branch: `dev`
- Version: `0.1.28-dev`
- Stage-1 icon-resolution runtime commit: `a1c9b6daec6fd06b644a804b19d6490cb89babab` — removed the background icon-repair listener and bumped the TOC from `0.1.27-dev`.
- Occupied-cursor worker runtime commit: `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` — stops the due Auto-Delete worker immediately when the cursor is occupied while retaining pending IDs for the next legitimate `BAG_UPDATE` re-arm.
- Runtime head validated in this checkpoint: `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Handoff: the current remote `dev` head containing this status update; its runtime tree is the validated `e5e8e96...` tree plus documentation only.
- Stable baseline: `0.1.27` on `main` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Goal: continue the focused runtime-performance maintenance pass that removes avoidable background polling/event work without changing user-visible behaviour.
- Current stage: both P1 runtime changes are implemented and checked: the background icon-repair listener removal and the occupied-cursor Auto-Delete worker fix. Neither P1 change has yet been user runtime-tested. The P2 main `BAG_UPDATE` registration rewrite and `CHAT_MSG_LOOT` optimization have not begun.
- Current scope boundary: performance-focused maintenance only. Do not reopen shelved visual/features work, change SavedVariables semantics, or alter accepted vendor/delete behaviour unless required by a proven performance fix.

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
- The addon version comes from the TOC. The current performance build is `0.1.28-dev`; its runtime delta is the checked P1 icon-resolution rewrite plus the checked occupied-cursor delete-worker fix.
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
- User runtime validation: pending.

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
- User runtime validation: pending.

### P2 — make main Auto-Delete `BAG_UPDATE` registration demand-driven
Current behaviour:
- The main event frame permanently registers `BAG_UPDATE`.
- Most bag updates do nothing except check whether `pendingDeleteIDs` contains anything.
- A relevant self-loot message is what actually creates delete work.

Intended direction:
- Register the Auto-Delete `BAG_UPDATE` path only when a relevant configured loot item has armed `pendingDeleteIDs`.
- Unregister it again when pending work is cleared/completed/aborted.
- Keep icon-repair handling separate; after P1 it should no longer require a background `BAG_UPDATE` listener.

### P2 — reduce `CHAT_MSG_LOOT` work
Current behaviour:
- Every loot message received while Auto-Delete is enabled is tested against the localized self-loot patterns before the item ID is checked against `DB.deleteList`.
- In busy group/raid loot traffic this means repeated string-pattern work for irrelevant items/messages.

Intended direction:
- Use the cheapest safe rejection order available: extract the item ID first where possible, reject IDs not in `DB.deleteList`, then perform self-loot validation only for potentially relevant IDs.
- Consider registering `CHAT_MSG_LOOT` only while Auto-Delete is enabled and the delete list is non-empty, provided configuration changes can update registration reliably.
- Preserve localization correctness and the vendor-purchase exemption path.

### P3 — merchant/config/debug micro-costs
These are secondary and should not distract from P1/P2:
- Sell worker: while actively selling, `GetInterval()` reparses the saved string each frame and `table.remove(sellQueue, 1)` shifts the queue. Cache the interval/use a queue index only if doing so remains simple and behaviourally identical.
- Bin animation: active for approximately one second per deletion and performs texture/position work each frame. Leave unchanged unless focused profiling shows it matters after P1/P2.
- Configuration drop animations: have `OnUpdate` handlers, but they are configuration-UI-only and visually short-lived.
- Dev `Debug.lua` timeline: has an `OnUpdate` that returns immediately unless a marker is being dragged. It is absent from `main`; optional cleanup can attach/detach the handler around active dragging, but this is not a release-performance priority.

## Recent Relevant Commits
- Handoff commit: current remote `dev` head containing this status update; runtime tree validated at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` — Stop delete worker when cursor is occupied; second checked P1 runtime change.
- `56c92a05147c4cb5114316ebecb979f4a5611e52` — Pre-worker-fix handoff/status checkpoint.
- `a209d43607508f2b33552cdf6e3da98bc8ca60e1` — Fix temporary Lua 5.0 checker plumbing; CI/tooling only.
- `a1c9b6daec6fd06b644a804b19d6490cb89babab` — Remove background icon repair polling; stage-1 runtime implementation and `0.1.28-dev` version bump.
- `c8c55f9af9cd1dfad08d1577a8f02a4f32072eae` — Record performance audit handoff.
- `3db6fea316d8684223dc9bd6ca745784dd831765` — Migrate development workflow; verified pre-audit head.
- `1f1b8e573151b9c694038bcd65c4889ee3eeff78` — Mark VendorTweaks feature-complete.
- Stable `main`: `b2a90beb03464494b2cd5c699f10a0a2bd82f26b` — Release 0.1.27.

## Completed / User-Verified
- The restored 8-frame Auto-Delete feedback build was user tested and explicitly approved for stable release.
- Auto-Delete feedback checkbox placement and clickability are verified.
- Auto-Vendor feedback layout is verified.
- Sell-chat ON/OFF behaviour is verified.
- User-facing branding is `pfUI VendorTweaks`.
- Technical identifiers are normalized to `pfUI_VendorTweaks`.
- Dev debug controls/timeline framework works with the existing 8-frame animation.
- Stable install naming is normalized to `pfUI_VendorTweaks`; obsolete hyphenated runtime filenames are not part of the supported install.

## Implemented / Awaiting Runtime Test
- `0.1.28-dev` P1 icon-resolution rewrite: the background icon-repair `BAG_UPDATE` subsystem is gone and icon repair is now configuration/item-addition demand only.
- `0.1.28-dev` occupied-cursor delete-worker fix at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`: a due worker stops/hides if the cursor is occupied, retains pending IDs, and relies on the existing next `BAG_UPDATE` to re-arm the debounce.
- The combined P1 runtime tree at `e5e8e96...` is statically checked but not yet user runtime-tested.
- No main Auto-Delete event-registration rewrite, loot-filtering optimization, or P3 change has been implemented.

## Static / Automated Checks
- Static diff review of `c8c55f9... -> a1c9b6d...` confirmed the runtime scope is limited to `pfUI_VendorTweaks.lua` plus the TOC version bump.
- Static assertions confirmed there are no remaining `missingIconIDs`, `iconRepairFrame`, `InitializeIconRepair`, or `UpdateIconRepairListener` references.
- Exactly one `RegisterEvent("BAG_UPDATE")` remains in runtime code: the pre-existing main Auto-Delete event path, intentionally untouched in this stage.
- The existing question-mark row fallback and drop-animation fallback remain present.
- SavedVariables declaration/migration, item-ID list maps, direct exact-ID item-addition bag lookup, vendor engine, and delete engine were unchanged by this stage.
- Canonical checker source remains VanillaTemplate `tools/lua50/`.
- Exact `56c92a05147c4cb5114316ebecb979f4a5611e52 -> e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` comparison is one runtime commit modifying only `pfUI_VendorTweaks.lua`: 8 additions, 3 deletions.
- Static review confirmed the worker change only moves occupied-cursor handling into `ExecuteSafeDeleteStep()`, calls `StopDeleteWorker(false)`, and removes the redundant per-frame cursor return.
- The main Auto-Delete `eventFrame:RegisterEvent("BAG_UPDATE")` line is unchanged across that diff; exactly one runtime `BAG_UPDATE` registration remains.
- The existing `CHAT_MSG_LOOT` path is also unchanged: it still performs `IsSelfLootMessage(arg1)` before extracting/checking the item ID. The planned P2 filtering optimization therefore has not begun.
- GitHub Actions run `36025914487` reconstructed the current canonical VanillaTemplate checker scripts (blob SHAs `0478ee7...`, `0fe4c45...`, `2eaaa5c...`), verified the official Lua 5.0.2 archive checksum `a6c85d85f912e1c321723084389d63dee7660b81b8292452b190ea7190dd73bc`, passed the checker self-test, and passed `check_lua50.sh pfUI_VendorTweaks.lua Debug.lua locales` for all 10 Lua files.
- The temporary validation branch was reset back to `e5e8e96...` after the successful run; it introduced no change to `dev`.
- Earlier checker run `36008345150` remains the passing compiler check for the icon-resolution-only checkpoint.

## Current Issues
- Auto-Delete's main event frame still receives every `BAG_UPDATE` even when no deletion is pending; the P2 registration rewrite is deliberately deferred until the current P1 runtime checkpoint is tested.
- Auto-Delete self-loot filtering still does avoidable localized pattern work before confirming the looted item is configured for deletion; the P2 filtering optimization is likewise deferred.
- The combined `0.1.28-dev` P1 icon-resolution and occupied-cursor worker behaviour is checked but has not yet been exercised in the target client.

## Testing

### Last Runtime Test
- Version/commit: `0.1.27-dev`, restored 8-frame state recorded at `435bc1873bc6de201798855c1edfe84d0e9bfa99`; later approval/release tracking preserved that runtime and it was promoted to `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Passed: restored 8-frame Auto-Delete feedback; Auto-Delete control placement/clickability; Auto-Vendor feedback layout; sell-chat ON/OFF behaviour; current branding/technical naming; dev debug controls/timeline with the 8-frame animation.
- Failed: None recorded.
- Not tested: the current `0.1.28-dev` performance delta at runtime head `e5e8e96...`.

### Next Runtime Test
The combined P1 checkpoint is not yet user runtime-tested. At the next runtime checkpoint, exercise the exact `0.1.28-dev` runtime tree at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` for:
- normal login/reload and zoning with no Lua errors;
- opening VendorTweaks config with fully cached list entries;
- opening/refreshing with an intentionally unresolved/missing icon and confirming the existing question-mark fallback;
- adding Auto-Vendor and Auto-Delete entries from the cursor and confirming names/icons resolve immediately when available;
- removing entries and confirming shared metadata pruning semantics remain correct;
- ordinary bag activity after closing the config, confirming no new icon-related behaviour or errors occur in gameplay;
- sanity checks that Auto-Vendor/custom sales and configured Auto-Delete still behave as before;
- occupied-cursor Auto-Delete safety: arm a configured delete, keep an item on the cursor when the delete step becomes due, and confirm nothing is deleted and no per-frame worker remains active;
- after clearing the cursor, cause the next legitimate bag transition and confirm the retained pending delete re-arms through the existing debounce and completes normally;
- normal configured Auto-Delete with a clear cursor, confirming the worker still completes without regression.

Do not begin either P2 optimization until this exact P1 runtime checkpoint has a clear user result. The final complete performance delta must still receive the broader runtime test documented by the remaining performance stages before any promotion to `main`.

## Planned / Next Work
1. P1 icon-repair removal — implemented and checked in `0.1.28-dev`.
2. P1 occupied-cursor delete-worker fix — implemented and checked at `e5e8e96...`.
3. User runtime-test the exact combined P1 checkpoint before any further runtime optimization.
4. P2, deferred until that test passes: make Auto-Delete `BAG_UPDATE` registration demand-driven around actual pending deletions.
5. P2, deferred until that test passes: reorder/limit `CHAT_MSG_LOOT` handling so irrelevant raid/group loot exits as cheaply as safely possible.
6. Re-audit all runtime `OnUpdate` and event registrations after P2; only then consider the P3 micro-optimizations.
7. Run the real Lua 5.0 compatibility/compiler checks plus static diff review after each coherent runtime stage.
8. User runtime-test the exact resulting full performance `dev` commit before any promotion.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.
- Do not redesign features merely to optimize raid-only behaviour; changes should reduce general background cost while preserving functionality.
- Do not add ClassicAPI or another DLL dependency solely for this performance pass unless a concrete measured limitation of the native 1.12.1 API requires it and the dependency is explicitly reconsidered.
- The P2 main `BAG_UPDATE` registration rewrite and `CHAT_MSG_LOOT` optimization are explicitly deferred until the current P1 runtime checkpoint is user-tested.
- P3 merchant/config/debug micro-optimizations are optional until P1/P2 are complete and re-audited.

## Release / Promotion Notes
- Stable baseline to preserve is `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Do not promote the performance rewrite until the exact runtime delta is user-tested and accepted.
- Preserve stable TOC Title/Version metadata and exclude development-only status/debug material from release builds.
- `main` and `dev` diverge in Git history; future promotion must compare the branches and preserve the intended stable/release tree rather than assuming a blind fast-forward or replacement.
- Main-only or release-only content to preserve: stable TOC metadata and the absence of dev-only `DEV_PROGRESS.md`/`Debug.lua`; no unique main-only runtime feature is currently documented.
- Known validation debt accepted for release: None.
- External/runtime prerequisites: World of Warcraft 1.12.1 and pfUI. No optional DLL/client extension is currently required.

## Exact Next Step
Runtime-test the exact current `0.1.28-dev` P1 runtime tree at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` (the current handoff commit adds documentation only). Exercise the icon-resolution cases plus the occupied-cursor Auto-Delete case documented above, including confirmation that the due worker stops without deleting while the cursor is occupied and that the next legitimate `BAG_UPDATE` re-arms the retained pending delete after the cursor is cleared. Record the result before making any further runtime change. Do not begin the P2 `BAG_UPDATE` registration rewrite or `CHAT_MSG_LOOT` optimization until this checkpoint passes. Do not promote to `main` until the complete performance runtime delta is user-tested and accepted.
