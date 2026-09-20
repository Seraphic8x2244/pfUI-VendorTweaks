# pfUI VendorTweaks Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Repository/addon technical name: `pfUI_VendorTweaks`
- User-facing name: `pfUI VendorTweaks`
- Stable release: `main` is now `0.1.27` at `b2a90beb03464494b2cd5c699f10a0a2bd82f26b`.
- Workflow: Canonical `VanillaTemplate` development contract; `DEV_GUIDE.md` is authoritative.

## Recent Commits
- `d3b272050cf75665895ce3113771946f280bef8b` — Record 0.1.27 stable approval.
- `435bc1873bc6de201798855c1edfe84d0e9bfa99` — Record restored 8-frame burn test state.
- `07ea0eb4e57a89c9893566d6eb328b79ffad5ec2` — Record debug timing ruler test state.
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

## Deferred
- Longer/higher-frame/two-part burn replacement is shelved.
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so avoid heuristic matching.

## Exact Next Step
No immediate release work. Future development starts from `dev` at `0.1.27-dev`; keep `main` at the known-good `0.1.27` release until a later dev state is explicitly user-approved for promotion.
