# VendorTweaks Development Progress

## Current
- Branch: `dev`
- Version: `0.1.27-dev`
- Goal: Finish verification of the balanced Auto-Vendor feedback controls, then begin the revised Auto-Delete animation rework.
- Workflow: Migrated to the canonical `VanillaTemplate` development contract.

## Recent Commits
- `bc95b18a59534c0c308fc18754a7658dcec2c82d` — Migrate VendorTweaks to canonical workflow.
- `8abdce0230b11c776528add6d8916cc3b8c889d1` — Adopt canonical addon development guide.
- `247262b65211368c9484b13753788c312d23bf35` — Record VendorTweaks migration handoff.
- `0d2ee5634a45e4031aa70d267f6b8bfba8c646dd` — Bump VendorTweaks dev10 test version.
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
  - localization split into `locales/<locale>.lua` files with stable VendorTweaks keys and an enUS fallback.
  - burn artwork moved to `artwork/` and its texture path updated.
- `Show sell animation` placeholder should remain visible, greyed out and non-functional.
- `Show sell message in chat` should default ON and control only VendorTweaks sell-chat output.
- Localized `Sold: %s` output covers custom Auto-Vendor and grey-item takeover sales.
- Sell-chat ON/OFF behavior has been confirmed working in game.
- Static migration checks passed: every locale defines all 15 VendorTweaks keys; the TOC loads all locale files; the Lua file has no hardcoded dev10 version; and the moved burn TGA retains the exact original blob SHA.
- The migrated addon load/localization/artwork path still needs an in-game smoke test.

## Current Issues
- None known.

## Testing

### Last Test
- Version/commit: pre-migration `0.1.27-dev10` / `0d2ee5634a45e4031aa70d267f6b8bfba8c646dd`
- Passed: Auto-Vendor feedback options are visible; layout confirmed perfect.
- Failed: None reported.
- Passed: sell-chat ON/OFF behavior.

### Next Test
- Install current `dev` (`0.1.27-dev`).
- Confirm the addon loads and the VendorTweaks pfUI panel opens normally.
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
Rename the addon’s user-facing branding to `pfUI VendorTweaks` everywhere while preserving the technical addon identifier/path where required by WoW, then smoke-test the renamed UI.
