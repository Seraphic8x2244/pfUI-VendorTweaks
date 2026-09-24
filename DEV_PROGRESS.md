# Development Progress

## Current
- Branch: `dev`
- Version: `0.1.28-dev`
- Stage-1 runtime implementation commit: `a1c9b6daec6fd06b644a804b19d6490cb89babab` — removed the background icon-repair listener and bumped the TOC from `0.1.27-dev`.
- Lua-checker plumbing commit: `a209d43607508f2b33552cdf6e3da98bc8ca60e1` — temporary CI/checker plumbing only; no runtime addon change after `a1c9b6d`.
- Handoff: the current remote `dev` head containing the temporary-workflow cleanup and this status update; use the current remote `dev` head as the exact handoff commit.
- Stable baseline: `0.1.27` on `main` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Goal: continue the focused runtime-performance maintenance pass that removes avoidable background polling/event work without changing user-visible behaviour.
- Current stage: P1 icon-repair removal is implemented, statically reviewed, and accepted by the real Lua 5.0.2 compiler checker. It has not yet been user runtime-tested. The later Auto-Delete worker/event rewrite has not begun.
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
- The addon version comes from the TOC. The current performance build is `0.1.28-dev`; its only runtime delta so far is the checked P1 icon-resolution rewrite.
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

### P1 — eliminate occupied-cursor delete-worker spin
Current behaviour:
- The delete worker is normally short-lived and hidden.
- Once due, its `OnUpdate` checks `GetTime()` and then `CursorHasItem()`.
- If the player is holding an item on the cursor, the worker remains shown and returns every frame until the cursor becomes clear.

Why this matters:
- A rare interaction can convert a temporary worker into an effectively unbounded per-frame poll.

Intended direction:
- Do not leave the worker continuously shown solely waiting for the cursor to clear.
- Preserve fail-closed safety: never delete while the cursor is occupied and never guess which cursor item is safe.
- Prefer an event/demand-driven re-arm or a clean abort that waits for the next legitimate bag/loot transition rather than a permanent frame poll.
- Any chosen design must preserve the current delete debounce/settling semantics where they are genuinely required for correctness.

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
- Handoff commit: current remote `dev` head containing the checker-workflow cleanup and status update.
- `a209d43607508f2b33552cdf6e3da98bc8ca60e1` — Fix temporary Lua 5.0 checker plumbing; CI/tooling only, no runtime addon delta.
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
- The exact runtime code introduced at `a1c9b6daec6fd06b644a804b19d6490cb89babab` is still the current runtime code; `a209d43607508f2b33552cdf6e3da98bc8ca60e1` changed only temporary checker plumbing.
- No occupied-cursor delete-worker, main Auto-Delete event-registration, loot-filtering, or P3 changes have been implemented yet.

## Static / Automated Checks
- Static diff review of `c8c55f9... -> a1c9b6d...` confirmed the runtime scope is limited to `pfUI_VendorTweaks.lua` plus the TOC version bump.
- Static assertions confirmed there are no remaining `missingIconIDs`, `iconRepairFrame`, `InitializeIconRepair`, or `UpdateIconRepairListener` references.
- Exactly one `RegisterEvent("BAG_UPDATE")` remains in runtime code: the pre-existing main Auto-Delete event path, intentionally untouched in this stage.
- The existing question-mark row fallback and drop-animation fallback remain present.
- SavedVariables declaration/migration, item-ID list maps, direct exact-ID item-addition bag lookup, vendor engine, and delete engine were unchanged by this stage.
- Canonical checker source: VanillaTemplate `tools/lua50/` scripts as of `9093fac60f210dedd87d5e2d0f265a97494f999f`.
- The checker run reconstructed those exact scripts and verified the official Lua 5.0.2 source archive checksum `a6c85d85f912e1c321723084389d63dee7660b81b8292452b190ea7190dd73bc`.
- GitHub Actions run `36008345150`: Lua 5.0.2 checker self-test passed and `check_lua50.sh pfUI_VendorTweaks.lua Debug.lua locales` passed all 10 Lua files.
- An earlier temporary run (`36008134817`) stopped before compilation because its job token could not clone the separate VanillaTemplate repository; that tooling-only failure was replaced by the successful checksum-pinned checker run above.

## Current Issues
- The delete worker can remain shown and poll every frame indefinitely if its delete step becomes due while the player holds an item on the cursor.
- Auto-Delete's main event frame still receives every `BAG_UPDATE` even when no deletion is pending.
- Auto-Delete self-loot filtering still does avoidable localized pattern work before confirming the looted item is configured for deletion.
- Stage-1 `0.1.28-dev` icon-resolution behaviour is checked but has not yet been exercised in the target client.

## Testing

### Last Runtime Test
- Version/commit: `0.1.27-dev`, restored 8-frame state recorded at `435bc1873bc6de201798855c1edfe84d0e9bfa99`; later approval/release tracking preserved that runtime and it was promoted to `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Passed: restored 8-frame Auto-Delete feedback; Auto-Delete control placement/clickability; Auto-Vendor feedback layout; sell-chat ON/OFF behaviour; current branding/technical naming; dev debug controls/timeline with the 8-frame animation.
- Failed: None recorded.
- Not tested: the proposed performance changes do not exist yet.

### Next Runtime Test
Stage 1 is not yet user runtime-tested. At the next runtime checkpoint, exercise the exact current `0.1.28-dev` handoff for:
- normal login/reload and zoning with no Lua errors;
- opening VendorTweaks config with fully cached list entries;
- opening/refreshing with an intentionally unresolved/missing icon and confirming the existing question-mark fallback;
- adding Auto-Vendor and Auto-Delete entries from the cursor and confirming names/icons resolve immediately when available;
- removing entries and confirming shared metadata pruning semantics remain correct;
- ordinary bag activity after closing the config, confirming no new icon-related behaviour or errors occur in gameplay;
- sanity checks that Auto-Vendor/custom sales and configured Auto-Delete still behave as before.

The final complete performance delta must still receive the broader runtime test documented by the remaining performance stages before any promotion to `main`.

## Planned / Next Work
1. P1 icon-repair removal — implemented and checked in `0.1.28-dev`.
2. Redesign the occupied-cursor delete-worker path so it cannot spin every frame indefinitely while preserving fail-closed deletion safety.
3. Make Auto-Delete `BAG_UPDATE` registration demand-driven around actual pending deletions.
4. Reorder/limit `CHAT_MSG_LOOT` handling so irrelevant raid/group loot exits as cheaply as safely possible.
5. Re-audit all runtime `OnUpdate` and event registrations after the rewrite; only then consider the P3 micro-optimizations.
6. Run the real Lua 5.0 compatibility/compiler checks plus static diff review after each coherent runtime stage.
7. User runtime-test the exact resulting full performance `dev` commit before any promotion.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.
- Do not redesign features merely to optimize raid-only behaviour; changes should reduce general background cost while preserving functionality.
- Do not add ClassicAPI or another DLL dependency solely for this performance pass unless a concrete measured limitation of the native 1.12.1 API requires it and the dependency is explicitly reconsidered.
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
Begin the next performance stage from the current remote `dev` handoff: redesign the occupied-cursor Auto-Delete worker path so a due deletion cannot leave a visible worker polling every frame while the cursor is occupied. Preserve fail-closed safety, the existing delete debounce/settling semantics that are required for correctness, and all current list/SavedVariables/feedback behaviour. Do not yet change the main Auto-Delete `BAG_UPDATE` registration or `CHAT_MSG_LOOT` filtering as part of that worker-only step. Run static review and the real Lua 5.0.2 checker again before proceeding to the subsequent event-registration stage. Do not promote to `main` until the complete performance runtime delta is user-tested and accepted.
