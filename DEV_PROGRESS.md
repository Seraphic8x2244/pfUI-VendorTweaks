# pfUI VendorTweaks Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Repository/addon technical name: `pfUI_VendorTweaks`
- User-facing name: `pfUI VendorTweaks`
- Goal: Promote the user-approved restored 8-frame build to stable `main` using `DEV_GUIDE.md`.
- Workflow: Canonical `VanillaTemplate` development contract; `DEV_GUIDE.md` is authoritative.

## Recent Commits
- `435bc1873bc6de201798855c1edfe84d0e9bfa99` — Record restored 8-frame burn test state.
- `07ea0eb4e57a89c9893566d6eb328b79ffad5ec2` — Record debug timing ruler test state.
- `070a39ffbef0063c96bd04be2963fc73946b6796` — Add draggable 2.0s burn timing ruler.

## Stable Candidate
- User tested current restored `dev` and explicitly approved it for promotion to `main`.
- Production Auto-Delete feedback uses the existing single 8-frame burn strip:
  - `artwork/pfUI_VendorTweaks_Burn.tga`
  - `BIN_FRAME_COUNT = 8`
  - approximately 1.0 second default runtime.
- The speculative 16-frame fire + 12-frame ash/two-part replacement is not present.
- No `pfUI_VendorTweaks_Fire.tga` or `pfUI_VendorTweaks_Ash.tga` exists on current `dev`.

## Completed / User Verified
- Current restored 8-frame build approved for stable release.
- Auto-Delete feedback checkbox placement and clickability.
- Auto-Vendor feedback layout.
- Sell-chat ON/OFF behaviour.
- User-facing branding: `pfUI VendorTweaks`.
- Technical identifiers normalized to `pfUI_VendorTweaks`.
- Dev debug controls/timeline framework works with the existing 8-frame animation.

## Dev-only Tooling
- `Debug.lua` is loaded only on `dev`.
- `/vtdebug`, `/vtdebug timeline`, and `/vtdebug all` expose the 8-frame timing/position authoring tools.
- The ruler exposes 8 burn frames plus `END`.
- Debug functionality is not required for normal addon operation.

## Deferred
- Longer/higher-frame/two-part burn replacement is shelved.
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so avoid heuristic matching.

## Stable Promotion
For `main`, preserve the approved functional runtime and perform only the documented cleanup:
- TOC Title: remove `-dev`.
- TOC Version: `0.1.27-dev` -> `0.1.27`.
- Remove `DEV_GUIDE.md`.
- Remove `DEV_PROGRESS.md`.
- Remove `Debug.lua` and its TOC entry.
- Do not include speculative work or unrelated refactors.

## Exact Next Step
Create the stable `main` tree from this approved `dev` state with only the documented dev-only cleanup, then verify `main` is directly installable and contains the same runtime code/assets as approved `dev`.
