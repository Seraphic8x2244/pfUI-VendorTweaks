# pfUI VendorTweaks Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Goal: In-game test the normalized `pfUI_VendorTweaks` addon and the first dev-only burn-position tuning panel.
- Workflow: Migrated to the canonical `VanillaTemplate` development contract.

## Recent Commits
- `a5ee54a1c75b5770510f2cd04ccd02daa44ed19b` — Restore coloured `pfUI VendorTweaks-dev` TOC title.
- Repository renamed externally to `Seraphic8x2244/pfUI_VendorTweaks`, completing technical identifier normalization.
- `43819d4a49740358d02ddbfc6c81de4e6ea2d148` — Normalize `pfUI_VendorTweaks` burn asset name.
- `5a8c43adc38e25d3a353cbe243fde53e98705342` — Add/localise burn debug controls and corrected TOC paths.
- `e153d1abe3e47a5b9d9f6deddcd03f29be2f869d` — Normalize identifiers and add burn debug controls.
- `63d3a5217861f23cfe02882c62f2487262c4bb1a` — Record identifier and `Debug.lua` work.
- `64dd0f970ecab165a86f116e496c3581c616d391` — Complete `pfUI VendorTweaks` locale branding rename.
- `146a119e901442aa7ee3267f86678788ff329ca9` — Rename addon-list title to `pfUI VendorTweaks-dev`.
- `b9389ea81ef4d3573b1cc28dacb30468f502bb50` — Rename runtime branding and chat prefixes to `pfUI VendorTweaks`.
- `bc95b18a59534c0c308fc18754a7658dcec2c82d` — Migrate pfUI VendorTweaks to canonical workflow.
- `8abdce0230b11c776528add6d8916cc3b8c889d1` — Adopt canonical addon development guide.
- `247262b65211368c9484b13753788c312d23bf35` — Record pfUI VendorTweaks migration handoff.
- `0d2ee5634a45e4031aa70d267f6b8bfba8c646dd` — Bump pfUI VendorTweaks dev10 test version.
- `7ece3f23e04f6614f0370070ba068a2eab69fd58` — Localise sell feedback options.
- `049b82601159f4fffac59ec775356516266ec7f1` — Add balanced sell feedback options.

## Completed / Verified
- Auto-Delete feedback checkbox placement and clickability were verified in game before the workflow migration.
- Latest pre-migration build: Auto-Vendor feedback options appear in the menu and the user confirmed the layout is perfect.
- Existing vendor queue, Auto-Delete safety logic, vendor-purchase exemption and pfUI integration were intentionally not refactored during migration.

## Implemented / Awaiting Test
- Canonical workflow migration:
  - `DEV_GUIDE.md` adopted unchanged from `VanillaTemplate`.
  - development version normalized to `0.1.27-dev`; numbered dev versions are retired.
  - .toc is the sole version source; Lua reads `ADDON_VERSION` with `GetAddOnMetadata`.
  - localization split into `locales/<locale>.lua` files with stable pfUI VendorTweaks keys and an enUS fallback.
  - burn artwork moved to `artwork/` and its texture path updated.
- `Show sell animation` placeholder should remain visible, greyed out and non-functional.
- `Show sell message in chat` should default ON and control only pfUI VendorTweaks sell-chat output.
- Localized `Sold: %s` output covers custom Auto-Vendor and grey-item takeover sales.
- Sell-chat ON/OFF behavior has been confirmed working in game.
- Static migration checks passed: every locale defines all 15 pfUI VendorTweaks keys; the TOC loads all locale files; the Lua file has no hardcoded dev10 version; and the moved burn TGA retains the exact original blob SHA.
- Sell-chat messages are confirmed working on the migrated build.
- User-facing addon branding is `pfUI VendorTweaks`; the dev TOC title now restores the established pfUI colouring (`pf` teal, `UI` white, `VendorTweaks-dev` grey).
- Technical identifiers remain `pfUI-VendorTweaks` / `pfUI_VendorTweaks` where required for addon loading, paths and SavedVariables.
- Technical addon identifiers are now normalized to `pfUI_VendorTweaks`: TOC/Lua basename, `ADDON_NAME`, SavedVariables, named frames/textures, slider global and addon texture path.
- Burn artwork is now `artwork/pfUI_VendorTweaks_Burn.tga`; the image blob is byte-identical to the prior asset.
- Dev-only `Debug.lua` is loaded after the main addon and creates a draggable burn tuning frame.
- Debug controls provide `Play Burn`, direct numeric entry and +/- 1 UI-unit adjustment for Item X/Y and Fire X/Y, plus `Print Values` and `Reset`.
- Main addon exposes only narrow Bin frame methods for preview/offset tuning; normal vendor/delete behavior does not depend on `Debug.lua`.
- Static checks passed: TOC locale paths use one separator, old hyphenated addon Lua/TOC paths are removed, and no old `pfVendorTweaks` / `pfVT_` named globals remain.
- The normalized addon and debug UI still need an in-game test.

## Current Issues
- Root cause found for the reported no-load install: the renamed repository/folder is `pfUI_VendorTweaks`, but stable `main` still contains the old `pfUI-VendorTweaks.toc` / `.lua` basenames. Vanilla requires the addon folder and TOC basename to match, so a default-branch install is not recognized. Current `dev` has matching `pfUI_VendorTweaks.toc` / `.lua` and remains the branch required for `Debug.lua` testing.
- Renaming the Bin frame identifier means any pfUI movable position previously saved under the old frame name will not carry across automatically.

## Testing

### Last Test
- Version/commit: pre-migration `0.1.27-dev10` / `0d2ee5634a45e4031aa70d267f6b8bfba8c646dd`
- Passed: Auto-Vendor feedback options are visible; layout confirmed perfect.
- Failed: None reported.
- Passed: sell-chat ON/OFF behavior.

### Next Test
- Install current `dev` (`0.1.27-dev`) in a folder named exactly `pfUI_VendorTweaks`.
- Confirm the addon loads and the `pfUI VendorTweaks` panel in pfUI opens normally.
- Confirm localized labels resolve rather than showing `VT_...` keys.
- Confirm the existing Bin burn artwork still renders from `artwork/`.
- Confirm `Show sell animation` remains disabled and `Show sell message in chat` remains clickable.
- Sell-chat ON/OFF behavior is already confirmed working.

## Planned / To-do
- After the migration smoke test, implement the revised Auto-Delete animation:
  - live item icon remains readable during ignition.
  - fire rapidly grows to obscure the icon.
  - hide the live icon at peak fire.
  - swap to generic charred remains.
  - collapse remains into ash with a short smoke/ember linger.

## Ideas / Backlog
- Add a polished/custom burn sound if stock Vanilla sounds are unsatisfactory.
- Add/interpolate burn frames only if the revised effect needs them.

## Deferred
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so avoid heuristic matching.

## Exact Next Step
Install/test the `dev` branch specifically in folder `pfUI_VendorTweaks`; it contains the matching `pfUI_VendorTweaks.toc`, `pfUI_VendorTweaks.lua` and `Debug.lua`. Do not promote dev animation work to stable `main`; normalize stable `main` separately only when explicitly approved.
