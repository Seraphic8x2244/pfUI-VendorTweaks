# pfUI VendorTweaks Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Repository/addon technical name: `pfUI_VendorTweaks`
- User-facing name: `pfUI VendorTweaks`
- Goal: User-test the restored 8-frame Auto-Delete burn and its dev-only timing/position authoring tools, then promote this approved functional state to stable `main` using `DEV_GUIDE.md`.
- Workflow: Canonical `VanillaTemplate` development contract; `DEV_GUIDE.md` is authoritative.

## Current Code State
- `dev` was restored to the functional state at `07ea0eb4e57a89c9893566d6eb328b79ffad5ec2`.
- Production Auto-Delete feedback uses the existing single 8-frame burn strip:
  - `artwork/pfUI_VendorTweaks_Burn.tga`
  - `BIN_FRAME_COUNT = 8`
  - approximately 1.0 second default runtime.
- The speculative 16-frame fire + 12-frame ash/two-part replacement is not present.
- No `pfUI_VendorTweaks_Fire.tga` or `pfUI_VendorTweaks_Ash.tga` exists on current `dev`.

## Debug Authoring Tool
- `Debug.lua` is dev-only and loaded after the main addon.
- `/vtdebug` toggles the main controls.
- `/vtdebug timeline` toggles the 2.0-second timing ruler.
- `/vtdebug all` opens both.
- The ruler exposes the existing 8 burn frames plus `END`.
- Snap choices: 10/15/20/25/30/35/40/45/50 ms.
- `Play Burn` previews the authored 8-frame timing.
- `Print Values` reports placement offsets and frame timestamps.
- `Reset` restores the default timing and offsets.
- Main runtime exposes only the narrow debug methods needed by `Debug.lua`; normal addon behaviour does not depend on `Debug.lua`.

## Completed / User Verified
- Auto-Delete feedback checkbox placement and clickability.
- Auto-Vendor feedback layout.
- Sell-chat ON/OFF behaviour.
- User-facing branding: `pfUI VendorTweaks`.
- Technical identifiers normalized to `pfUI_VendorTweaks`.
- Existing vendor queue, Auto-Delete safety logic, vendor-purchase exemption and pfUI integration were not intentionally refactored during the workflow migration.
- Dev debug controls/timeline UX was previously tested sufficiently to establish that the authoring framework works.

## Implemented / Awaiting Current In-Game Test
- Restored current `dev` after shelving the unfinished longer/two-part burn replacement.
- Current repository checks confirm:
  - `BIN_FRAME_COUNT = 8`;
  - single `pfUI_VendorTweaks_Burn.tga` asset;
  - 8-frame debug timeline API;
  - no ash runtime/debug API;
  - no Fire/Ash replacement assets.
- This restored branch state still needs the user's final in-game test before stable approval.

## Stable Promotion Rules
After the user explicitly approves this exact dev state as stable:
- Promote the same approved functional code to `main`.
- Change TOC Title to remove `-dev`.
- Change TOC Version from `0.1.27-dev` to `0.1.27`.
- Remove `DEV_GUIDE.md`.
- Remove `DEV_PROGRESS.md`.
- Remove `Debug.lua` and its TOC entry.
- Do not include knowingly untested/speculative work.
- Do not invent another version, redesign the release, or perform unrelated refactors during promotion.
- The TOC remains the single version source.

## Deferred
- Longer/higher-frame/two-part burn replacement, including separate fire and burned/ash artwork, is shelved.
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so avoid heuristic matching.

## Exact Next Step
User installs current `dev` and tests the restored 8-frame burn plus the debug controls/timing ruler. If the user explicitly approves this exact state as stable, perform the documented `dev` -> `main` cleanup/promotion without changing functional runtime behaviour.
