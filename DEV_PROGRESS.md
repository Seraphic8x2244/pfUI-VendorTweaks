# Development Progress

## Current
- Branch: `dev`
- Version: `0.1.28-dev`
- Current runtime head: `63a75ebdda85bec16dc074f48622fd1bcdd38576` — P2 demand-driven Auto-Delete event registration plus cheap item-ID-first loot rejection.
- P1 icon-resolution runtime commit: `a1c9b6daec6fd06b644a804b19d6490cb89babab`.
- P1 occupied-cursor worker runtime commit: `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf`.
- Stable baseline: `0.1.27` on `main` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Goal: continue the focused runtime-performance maintenance pass that removes avoidable background polling/event work without changing user-visible behaviour.
- Current stage: P1 received partial user runtime validation and the user explicitly authorized advancing despite the two remaining Auto-Delete edge checks. P2 is now implemented, statically reviewed, and accepted by the real Lua 5.0.2 compiler checker. The combined P1+P2 runtime tree is awaiting user observation/runtime validation tonight.
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
- The addon version comes from the TOC. The current performance build is `0.1.28-dev`; its runtime delta is the P1 icon-resolution rewrite, the occupied-cursor delete-worker fix, and the checked P2 demand-driven Auto-Delete event rewrite.
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
These are secondary and should not distract from P1/P2:
- Sell worker: while actively selling, `GetInterval()` reparses the saved string each frame and `table.remove(sellQueue, 1)` shifts the queue. Cache the interval/use a queue index only if doing so remains simple and behaviourally identical.
- Bin animation: active for approximately one second per deletion and performs texture/position work each frame. Leave unchanged unless focused profiling shows it matters after P1/P2.
- Configuration drop animations: have `OnUpdate` handlers, but they are configuration-UI-only and visually short-lived.
- Dev `Debug.lua` timeline: has an `OnUpdate` that returns immediately unless a marker is being dragged. It is absent from `main`; optional cleanup can attach/detach the handler around active dragging, but this is not a release-performance priority.

## Recent Relevant Commits
- `63a75ebdda85bec16dc074f48622fd1bcdd38576` — Make Auto-Delete events demand-driven; current runtime head and P2 implementation.
- `524700cede1c4d4b3c0472ae1727607081315207` — Document occupied-cursor P1 checkpoint.
- `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` — Stop delete worker when cursor is occupied; second P1 runtime change.
- `a1c9b6daec6fd06b644a804b19d6490cb89babab` — Remove background icon repair polling; first P1 runtime change and `0.1.28-dev` version bump.
- `c8c55f9af9cd1dfad08d1577a8f02a4f32072eae` — Record performance audit handoff.
- `3db6fea316d8684223dc9bd6ca745784dd831765` — Migrate development workflow.
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
- P1 icon-resolution rewrite at `a1c9b6d...`: background icon-repair `BAG_UPDATE` subsystem removed.
- P1 occupied-cursor worker fix at `e5e8e96...`: due worker stops instead of polling every frame while the cursor is occupied.
- P2 at `63a75ebd...`: `CHAT_MSG_LOOT` is demand-registered only when Auto-Delete is usable, irrelevant loot is rejected by item ID before localized matching, and `BAG_UPDATE` is registered only while delete work is pending.
- Combined P1+P2 runtime behaviour is awaiting user observation.
- Remaining P1 validation gaps: normal configured Auto-Delete was not separately completed before P2, and the occupied-cursor timing case was not reproducible manually. These are development validation debt only; no release has been authorized with them outstanding.

## Static / Automated Checks
- P1 icon-resolution and occupied-cursor diffs passed their documented static reviews and Lua 5.0.2 checks.
- Exact P2 comparison `524700c... -> 63a75eb...` is one runtime commit modifying only `pfUI_VendorTweaks.lua`: 36 additions, 11 deletions.
- Static review confirms there is exactly one `RegisterEvent("CHAT_MSG_LOOT")` site and one matching unregister site; there is no unconditional startup registration.
- Static review confirms there is exactly one `RegisterEvent("BAG_UPDATE")` site, reached only after a relevant configured self-loot arms pending deletion, and one unregister site reached when pending work is cleared.
- The old expensive ordering `IsSelfLootMessage -> GetIDFromLink/delete-list check` is gone; current ordering is `GetIDFromLink -> DB.deleteList -> IsSelfLootMessage`.
- SavedVariables shape, delete timing constants, item-ID list semantics, vendor engine, feedback settings, localization matcher, and vendor-purchase exemption semantics were not intentionally changed.
- GitHub Actions run `36028964709` on the temporary validation branch passed: workflow setup, canonical Lua 5.0.2 checker reconstruction, checker self-test, and `check_lua50.sh pfUI_VendorTweaks.lua Debug.lua locales`.
- The temporary validation branch was reset back to `63a75ebdda85bec16dc074f48622fd1bcdd38576` after the successful run; no validation workflow or trigger file remains in the runtime tree.

## Current Issues
- The combined P1+P2 performance tree has not yet had an end-to-end Auto-Delete runtime observation after the P2 event-registration rewrite.
- Normal configured Auto-Delete still needs to be observed in ordinary play.
- The occupied-cursor P1 edge case remains unproven at runtime because the 0.20-second timing window was not practical to reproduce manually.
- No current static/compiler failure is known.

## Testing

### Last Runtime Test
- Version/runtime commit: `0.1.28-dev` P1 runtime tree at `e5e8e96a779a8bee01d73ed9772cf7afdde29ddf` (with later documentation-only head `524700c...`).
- Passed: login, reload, zoning; config/list/icon presentation; adding/removing Auto-Vendor and Auto-Delete entries; ordinary bag activity; Auto-Vendor behaviour.
- Deferred: normal configured Auto-Delete was left for later observation.
- Not reproduced: occupied-cursor Auto-Delete edge case because the worker timing window was too short to hit reliably by hand.
- Decision: user explicitly authorized advancing to P2 with those two validation gaps and will watch addon behaviour during normal play.

### Next Runtime Test
Exercise the exact combined P1+P2 runtime tree at `63a75ebdda85bec16dc074f48622fd1bcdd38576`:
- normal login/reload/zoning with no Lua errors;
- normal configured Auto-Delete with a clear cursor;
- add and remove Auto-Delete entries while the config is open, including removing the final entry and adding it back;
- toggle Auto-Delete OFF/ON and confirm behaviour resumes correctly;
- loot unrelated items, including group/raid loot traffic where practical, and confirm no visible behavioural regression;
- buy a configured Auto-Delete item from a merchant and confirm the existing vendor-purchase exemption still prevents deletion;
- confirm Auto-Vendor/custom sales remain unchanged;
- opportunistically watch for occupied-cursor Auto-Delete behaviour, but do not require a reflex-based reproduction unless a real symptom appears.

This runtime observation is the gate before any further performance rewrite or release promotion.

## Planned / Next Work
1. P1 icon-repair removal — implemented, checked, and partially runtime validated.
2. P1 occupied-cursor worker fix — implemented and checked; edge case remains runtime-unproven.
3. P2 demand-driven `BAG_UPDATE` registration — implemented and checked at `63a75ebd...`.
4. P2 `CHAT_MSG_LOOT` registration/filter-order optimization — implemented and checked at `63a75ebd...`.
5. User observe/runtime-test the exact combined P1+P2 tree during normal play.
6. After that result, re-audit remaining runtime `OnUpdate` and event registrations.
7. Only consider P3 merchant/config/debug micro-optimizations if the re-audit shows worthwhile remaining cost.
8. Do not promote until the complete performance runtime delta is accepted.

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
Runtime-test/observe the exact current `0.1.28-dev` combined P1+P2 runtime tree at `63a75ebdda85bec16dc074f48622fd1bcdd38576` during normal play. Prioritize normal Auto-Delete, Auto-Delete OFF/ON and list add/remove behaviour, vendor-purchase exemption, and ordinary/group loot traffic. Record any Lua errors, missed deletes, unintended deletes, or behavioural differences. Do not begin P3 or promote to `main` until this checkpoint has a clear user result.
