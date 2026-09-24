# Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Verified pre-handoff development head: `3db6fea316d8684223dc9bd6ca745784dd831765`.
- Handoff: the documentation-only performance-audit commit immediately following that verified head; use the current remote `dev` head as the exact handoff commit.
- Stable baseline: `0.1.27` on `main` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Goal: perform a focused runtime-performance maintenance pass that removes avoidable background polling/event work without changing user-visible behaviour.
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
- The addon version comes from the TOC. This documentation-only audit leaves it at `0.1.27-dev`; the implementation pass should advance to the next development version before runtime changes.
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

### P1 — remove background icon-repair listening
Current behaviour:
- Missing configured-item icons populate `missingIconIDs`.
- While any unresolved icon remains, `iconRepairFrame` registers `BAG_UPDATE`.
- Each changed bag is scanned slot-by-slot looking for unresolved IDs.
- An item whose icon cannot be resolved can therefore keep this listener armed for the whole session.

Why this matters:
- Icon data is configuration/presentation metadata, not runtime vendor/delete correctness.
- Permanent `BAG_UPDATE` work is exactly the kind of individually-small background cost that compounds across many addons.

Intended direction:
- Remove the session-long background icon-repair listener.
- Resolve cached icons on demand when the VendorTweaks configuration panel is opened/refreshed and when an item is added.
- A one-shot bag scan at those explicit UI actions is acceptable.
- If an icon still cannot be resolved, display the existing question-mark fallback and stop; do not keep gameplay listeners active waiting for it.
- Preserve existing item-ID membership and metadata caching semantics.

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
- Handoff commit: current remote `dev` head containing this performance-audit report.
- `3db6fea316d8684223dc9bd6ca745784dd831765` — Migrate development workflow; verified pre-audit head.
- `1f1b8e573151b9c694038bcd65c4889ee3eeff78` — Mark VendorTweaks feature-complete.
- `8d4075a77b324b127a14f2ab163ae744740fcebd` — Record 0.1.27 release.
- `d3b272050cf75665895ce3113771946f280bef8b` — Record 0.1.27 stable approval.
- `435bc1873bc6de201798855c1edfe84d0e9bfa99` — Record restored 8-frame burn test state.
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
- None. The performance audit/report is documentation-only; no runtime optimization has been implemented yet.

## Static / Automated Checks
- Audit confirmed `pfUI_VendorTweaks.lua` on `dev` at `3db6fea316d8684223dc9bd6ca745784dd831765` was byte-identical to stable `main` `0.1.27`.
- Static inspection identified runtime `OnUpdate` handlers for the sell worker, bin animation, delete worker, configuration drop animations, and dev-only debug timeline, with the normal visibility/lifetime characteristics documented above.
- Static inspection identified permanent main event registrations including `CHAT_MSG_LOOT` and `BAG_UPDATE`, plus the conditional icon-repair `BAG_UPDATE` listener.
- No runtime code changed during the audit, so no new Lua compiler/runtime validation was required for this documentation handoff.
- Existing stable checks remain: stable TOC metadata is `0.1.27`, `Debug.lua` is absent from stable, stable runtime/artwork match the approved build, and no speculative Fire/Ash replacement is present.

## Current Issues
- Background icon-repair `BAG_UPDATE` can remain active indefinitely for an unresolved configured-item icon and scan changed bag slots throughout gameplay.
- Auto-Delete's main event frame receives every `BAG_UPDATE` even when no deletion is pending.
- Auto-Delete self-loot filtering does avoidable localized pattern work before confirming the looted item is configured for deletion.
- The delete worker can remain shown and poll every frame indefinitely if its delete step becomes due while the player holds an item on the cursor.

## Testing

### Last Runtime Test
- Version/commit: `0.1.27-dev`, restored 8-frame state recorded at `435bc1873bc6de201798855c1edfe84d0e9bfa99`; later approval/release tracking preserved that runtime and it was promoted to `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Passed: restored 8-frame Auto-Delete feedback; Auto-Delete control placement/clickability; Auto-Vendor feedback layout; sell-chat ON/OFF behaviour; current branding/technical naming; dev debug controls/timeline with the 8-frame animation.
- Failed: None recorded.
- Not tested: the proposed performance changes do not exist yet.

### Next Runtime Test
After the performance implementation is complete, test the exact new `dev` commit for:
- normal login/reload and zoning;
- opening VendorTweaks config with fully cached items and with an intentionally unresolved/missing icon;
- adding/removing Auto-Vendor and Auto-Delete list entries and verifying labels/icons/fallbacks;
- Auto-Delete of a configured self-looted item;
- multiple rapid configured loot events to exercise debounce/settling behaviour;
- cursor-occupied edge case when a configured deletion becomes due, confirming no wrong deletion and no stuck worker;
- non-configured/self/other-player loot traffic remaining inert;
- merchant purchases of delete-listed items still respecting the existing purchase exemption;
- Auto-Vendor/custom sales, grey takeover, throttle interval and sell-chat behaviour;
- Auto-Delete animation/chat toggles and the approved 8-frame visual;
- confirmation that no relevant `BAG_UPDATE` or `CHAT_MSG_LOOT` listeners/workers remain active outside the states that actually require them.

## Planned / Next Work
1. Begin a new performance maintenance version (next dev version after `0.1.27-dev`) before runtime edits.
2. Implement P1 icon-repair removal first: make icon resolution configuration-driven and delete the background icon-repair `BAG_UPDATE` subsystem.
3. Redesign the occupied-cursor delete-worker path so it cannot spin every frame indefinitely while preserving fail-closed deletion safety.
4. Make Auto-Delete `BAG_UPDATE` registration demand-driven around actual pending deletions.
5. Reorder/limit `CHAT_MSG_LOOT` handling so irrelevant raid/group loot exits as cheaply as safely possible.
6. Re-audit all runtime `OnUpdate` and event registrations after the rewrite; only then consider the P3 micro-optimizations.
7. Run the real Lua 5.0 compatibility/compiler checks available in the development environment plus static diff review.
8. User runtime-test the exact resulting `dev` commit before any promotion.

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
Start the performance build from the current remote `dev` handoff. First bump the TOC to the next development version, then remove the background icon-repair `BAG_UPDATE` subsystem and replace it with on-demand icon resolution during configuration refresh/item addition only. Preserve question-mark fallback behaviour and all vendor/delete list semantics. Do not begin the later Auto-Delete worker/event rewrite until that first change has passed static review and the real Lua 5.0 compiler/compatibility checks.
