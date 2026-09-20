# pfUI VendorTweaks Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Repository/addon technical name: `pfUI_VendorTweaks`
- User-facing name: `pfUI VendorTweaks`
- Stable release: `main` is `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Status: Feature-complete for now. Treat as maintenance-only unless the user explicitly reopens feature development.
- Workflow: Canonical `VanillaTemplate` development contract; `DEV_GUIDE.md` is authoritative.

## Recent Commits
- `8d4075a77b324b127a14f2ab163ae744740fcebd` — Record 0.1.27 release.
- `d3b272050cf75665895ce3113771946f280bef8b` — Record 0.1.27 stable approval.
- `435bc1873bc6de201798855c1edfe84d0e9bfa99` — Record restored 8-frame burn test state.
- Stable `main`: `b2a90beb03464494b2cd5c699f10a0a2bd82f26b` — Release 0.1.27.

## Released / User Verified
- Current restored 8-frame build was user tested and explicitly approved for stable release.
- Production Auto-Delete feedback uses the existing single 8-frame burn strip:
  - `artwork/pfUI_VendorTweaks_Burn.tga`
  - `BIN_FRAME_COUNT = 8`
  - approximately 1.0 second default runtime.
- Auto-Delete feedback checkbox placement and clickability.
- Auto-Vendor feedback layout.
- Sell-chat ON/OFF behaviour.
- User-facing branding: `pfUI VendorTweaks`.
- Technical identifiers normalized to `pfUI_VendorTweaks`.
- Dev debug controls/timeline framework works with the existing 8-frame animation.
- Stable install naming is normalized to `pfUI_VendorTweaks`; stale hyphenated `pfUI-VendorTweaks.toc/.lua` files from older installs must not be used.

## Stable 0.1.27 Verification
- `main` TOC title has no `-dev`.
- `main` TOC version is `0.1.27`.
- `DEV_GUIDE.md`, `DEV_PROGRESS.md`, and `Debug.lua` are absent from `main`.
- `Debug.lua` is absent from the stable TOC.
- Stable `pfUI_VendorTweaks.lua` is byte-identical to the approved dev runtime.
- Stable artwork is byte-identical to approved dev and contains only `pfUI_VendorTweaks_Burn.tga`.
- No speculative Fire/Ash two-part replacement is present in `main`.

## Dev-only Tooling
- `Debug.lua` remains on `dev` only.
- `/vtdebug`, `/vtdebug timeline`, and `/vtdebug all` expose the 8-frame timing/position authoring tools.
- The ruler exposes 8 burn frames plus `END`.
- Debug functionality is not required for normal addon operation.

## Untested Work
- None pending for the released `0.1.27` state.

## Deferred / Shelved
- Longer/higher-frame/two-part burn replacement is shelved.
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so avoid heuristic matching.

## Exact Next Step
No immediate development work. Leave `main` at known-good `0.1.27` and `dev` at `0.1.27-dev`. Only resume development for maintenance fixes or when the user explicitly reopens feature work.
