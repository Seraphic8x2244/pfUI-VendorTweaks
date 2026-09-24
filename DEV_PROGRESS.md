# Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Verified pre-migration development head: `1f1b8e573151b9c694038bcd65c4889ee3eeff78`
- Handoff: the single documentation-migration commit immediately following that verified head; use the current remote `dev` head as the exact handoff commit.
- Stable baseline: `0.1.27` on `main` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Goal: Keep the released feature set stable and maintain the addon only when a concrete fix is needed.
- Current scope boundary: Feature-complete/maintenance-only unless the user explicitly reopens feature development. This workflow migration changes documentation only.

## Current Design / Development Contract

### Architecture / Ownership
- `pfUI_VendorTweaks` is a component-only external addon for pfUI and declares pfUI as a dependency.
- Runtime code remains centered in `pfUI_VendorTweaks.lua`; locale files under `locales/` load before it.
- `Debug.lua` is development-only tooling on `dev` and is not required for normal addon operation.
- Per-character addon state is owned by the `pfUI_VendorTweaks` SavedVariables table.
- The Auto-Delete bin uses pfUI's movable-frame system for placement/scale/reset ownership.

### Invariants
- Technical addon/folder/metadata identity is `pfUI_VendorTweaks`; stale hyphenated `pfUI-VendorTweaks.toc/.lua` files from older installs must not be used.
- The addon version comes from the TOC. Development metadata stays at `0.1.27-dev` until new work deliberately changes it.
- The approved production Auto-Delete feedback remains the existing single 8-frame strip `artwork/pfUI_VendorTweaks_Burn.tga`, with `BIN_FRAME_COUNT = 8` and approximately 1.0 second default runtime.
- Debug controls may tune/preview the existing animation but must not become a stable runtime dependency.
- Do not introduce heuristic buyback matching: stock 1.12 buyback API does not expose an exact item link/ID suitable for a reliable Auto-Delete exemption.

### Protocol / Data Model
- No external protocol is involved.
- Existing SavedVariables/config semantics are the compatibility contract; this migration does not change or reinterpret them.

### Active Decisions
- The addon is feature-complete for now and should be treated as maintenance-only.
- The longer/higher-frame/two-part Fire/Ash burn replacement is shelved; the restored 8-frame implementation is the approved production state.
- Sell-chat ON/OFF behaviour, Auto-Vendor feedback layout, Auto-Delete feedback controls, and the current pfUI-facing branding are accepted behaviour.

## Recent Relevant Commits
- `1f1b8e573151b9c694038bcd65c4889ee3eeff78` — Mark VendorTweaks feature-complete; verified pre-migration `dev` head.
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
- None for the released `0.1.27` runtime state.

## Static / Automated Checks
- Stable `main` TOC title has no `-dev` suffix and version is `0.1.27`.
- `DEV_PROGRESS.md`, the legacy `DEV_GUIDE.md`, and `Debug.lua` are absent from the verified stable baseline.
- `Debug.lua` is absent from the stable TOC.
- Stable `pfUI_VendorTweaks.lua` was verified byte-identical to the approved dev runtime at release.
- Stable artwork was verified byte-identical to approved dev and contains only `pfUI_VendorTweaks_Burn.tga`.
- No speculative Fire/Ash two-part replacement is present in `main`.

## Current Issues
- None currently open.

## Testing

### Last Runtime Test
- Version/commit: `0.1.27-dev`, restored 8-frame state recorded at `435bc1873bc6de201798855c1edfe84d0e9bfa99`; later approval/release tracking preserved that runtime and it was promoted to `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Passed: restored 8-frame Auto-Delete feedback; Auto-Delete control placement/clickability; Auto-Vendor feedback layout; sell-chat ON/OFF behaviour; current branding/technical naming; dev debug controls/timeline with the 8-frame animation.
- Failed: None recorded.
- Not tested: None pending for the released 0.1.27 runtime state.

### Next Runtime Test
- None scheduled. Any future maintenance delta must be tested against its exact new dev commit before promotion.

## Planned / Next Work
- No active feature work.
- For a future maintenance fix, start from the current `dev` head, keep the existing architecture/invariants, and scope the change narrowly to the reported issue.

## Deferred / Out of Scope
- Longer/higher-frame/two-part burn replacement remains shelved.
- Buyback-specific Auto-Delete exemption remains deferred because stock 1.12 buyback API lacks an exact item link/ID; do not substitute heuristic matching.

## Release / Promotion Notes
- Stable baseline to preserve is `main` `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Preserve stable TOC Title/Version metadata and exclude development-only status/debug material from release builds.
- `main` and `dev` currently diverge in Git history; future promotion must compare the branches and preserve the intended stable/release tree rather than assuming a blind fast-forward or replacement.
- Main-only or release-only content to preserve: stable TOC metadata and the absence of dev-only `DEV_PROGRESS.md`/`Debug.lua`; no unique main-only runtime feature is currently documented.
- Known validation debt accepted for release: None.
- External/runtime prerequisites: World of Warcraft 1.12.1 and pfUI. No optional DLL/client extension is required for the documented feature set.

## Exact Next Step
No immediate development work. Leave `main` at known-good `0.1.27` and `dev` at `0.1.27-dev`. Only resume development for a concrete maintenance fix or when the user explicitly reopens feature work; before editing, verify the current remote `dev` head against this handoff.
