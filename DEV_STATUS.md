# VendorTweaks Dev Status

## Current state
- Branch: `dev`
- Test version: `0.1.27-dev10`
- Base main version: `0.1.26`
- Current dev HEAD recorded before migration: `0d2ee5634a45e4031aa70d267f6b8bfba8c646dd`
- Current goal: migrate the repository to the canonical `VanillaTemplate` workflow without changing addon behaviour.

## Latest relevant dev commits
- `0d2ee5634a45e4031aa70d267f6b8bfba8c646dd` — Bump VendorTweaks dev10 test version
- `7ece3f23e04f6614f0370070ba068a2eab69fd58` — Localise sell feedback options
- `049b82601159f4fffac59ec775356516266ec7f1` — Add balanced sell feedback options
- `997b806485d5d98f214ff540a0a800bf8055fbdb` — Move delete feedback toggles above drop target
- `15c8da47ef8e4c8c1fded820a0e74c5ad41781ed` — Localise delete animation toggle

## Completed / user verified
- `0.1.27-dev9`: Auto-Delete feedback checkbox placement and clickability confirmed good.
- `0.1.27-dev10`: Auto-Vendor feedback controls appear in the menu and the layout is confirmed perfect.
- Existing Auto-Delete, vendor queue, vendor-purchase exemption and pfUI integration remain unchanged.

## Implemented / awaiting test
- `Show sell animation` placeholder should be visible, greyed and non-functional.
- `Show sell message in chat` should default ON and control only VendorTweaks sell chat output.
- Localized `Sold: %s` output covers custom Auto-Vendor and grey-item takeover sales.
- Sell-chat ON/OFF behaviour has not yet been tested in game.

## Current issues
- None blocking migration.

## Planned migration
- Add canonical `DEV_GUIDE.md` unchanged from `VanillaTemplate`.
- Replace this file with canonical-style `DEV_PROGRESS.md`.
- Normalize development version to `0.1.27-dev` and stop numbered dev versions.
- Make the .toc the sole version source; remove the hardcoded Lua version header and expose `ADDON_VERSION` from metadata.
- Split `locales.lua` into `locales/<locale>.lua` files and move remaining user-facing strings into localization.
- Move addon artwork under `artwork/` and update texture paths.
- Do not refactor vendor/delete logic.

## Deferred
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID.
- Revised Auto-Delete animation rework until workflow migration is complete.
- Sound choice/volume and any additional/interpolated burn frames.

## Exact next step
Perform the VanillaTemplate workflow migration on `dev`, then smoke-test addon loading, localization, the existing Bin texture path, and retain sell-chat behavior as explicitly untested until the user checks it.
