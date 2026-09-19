# VendorTweaks Dev Status

## Current state
- Branch: `dev`
- Base version: `0.1.26`
- Branched from: `e9b8c1a0fa6a5fffd0f23a21321f4945b0938024` — Exempt vendor purchases from Auto-Delete

## Completed on main before this branch
- Shared item metadata/icon cache and targeted missing-icon repair.
- Alphabetical Auto-Vendor / Auto-Delete display ordering.
- Localisation tables for supported pfUI locales.
- Vendor-purchase exemption for Auto-Delete.
- Existing Auto-Delete safety path remains fail-closed and loot-message-driven.

## Work in progress on dev
- Add optional chat notification for successful Auto-Delete.
- Add movable `VendorTweaks Bin` anchor integrated with pfUI Unlock Mode.
- Add first-pass 8-frame burn-to-ash deletion animation around a 32x32 item icon.

## Untested
- Bin anchor registration with both brues-code and Shagu pfUI unlock modules.
- Sprite timing and texture coordinates in Vanilla 1.12.1.
- Sound choice/volume in-game.
- Repeated rapid deletes replacing/restarting the active animation.
- Visual scale at different UI scales.

## Deferred
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so no heuristic matching.
- Additional interpolated animation frames unless the 8-frame test proves too jumpy.

## Exact next step
Build the first animation test on `dev`: add the chat-message toggle, movable Bin frame, sprite asset, animation driver, and hook it only after a successful DeleteCursorItem path. Then test in-game before changing frame count or polish.
