# VendorTweaks Dev Status

## Current state
- Branch: `dev`
- Test version: `0.1.27-dev1`
- Base main version: `0.1.26`
- Branched from: `e9b8c1a0fa6a5fffd0f23a21321f4945b0938024` — Exempt vendor purchases from Auto-Delete
- Current dev HEAD before this status update: `d6bd35b163588aebfc134b4dd7888f342d42454c`

## Latest dev commits
- `d6bd35b163588aebfc134b4dd7888f342d42454c` — Remove temporary TGA compatibility workflow
- `749b370128eeaa8441c9e647cc3d342ba0518da7` — Update VendorTweaks animation test handoff
- `efa3fcec9a9faecc8c25d87820177f5edadd0e89` — Bump VendorTweaks dev test version
- `431f2b84b2ff7ea1e3e3b96552b7582cddb2d81e` — Localise delete chat toggle
- `13465e4122a0daccf2e9497c3478774020ffc477` — Add first VendorTweaks Bin animation
- `38de111cb727a0e2a6e4545e01e196692e579a9f` — Add first VendorTweaks burn sprite
- `03005cb53a32cb97e75338b153b2430e643d7b9e` — Add VendorTweaks dev handoff

## Completed on dev
- Existing Auto-Delete chat message preserved.
- Added per-character `Show delete message in chat` option, default ON.
- Added translations for the new chat option to all supported VendorTweaks/pfUI locales.
- Added `pfVendorTweaksBin` as a 64x64 pfUI movable; pfUI Unlock Mode controls move/scale/reset and the drag label is presented as `VendorTweaks Bin`.
- Added an 8-frame transparent burn-to-ash TGA sprite strip. Source frames are 32x32 and render in the 64x64 Bin for the first visual test.
- Added a 0.24-second OnUpdate animation: 32x32 item icon underneath, burn sprite above, icon darkens/collapses as it burns.
- Successful Auto-Delete starts/restarts the Bin animation with the deleted item's slot texture, then falls back through the shared item cache to the question-mark icon.
- Added stock Vanilla `igQuestLogAbandonQuest` sound at animation start.
- Rapid deletes replace/restart the active visual instead of queueing animation notifications.
- Existing Auto-Delete acquisition, BAG_UPDATE debounce, cursor verification, deletion safety and vendor-purchase exemption logic are otherwise unchanged.

## In-game test findings
- `0.1.27-dev1`: `VendorTweaks Bin` does not appear in pfUI Unlock Mode at its default anchor. Default code position is UIParent CENTER, x=0, y=-120, size 64x64, so this is being treated as a movable visibility/registration compatibility failure rather than an off-screen-position issue.

## Untested in game
- TGA render/alpha and sprite texture coordinates on the actual Vanilla 1.12.1 client. The strip is 32-bit RGBA RLE TGA, 256x32; legacy WoW API documentation states RLE TGA is supported, but the actual client test remains authoritative.
- Whether scaling 32px source frames to a 64px display is crisp enough; if soft, rebuild as native 64px frames.
- Bin anchor registration/drag/scale/reset in both brues-code and Shagu pfUI.
- 0.24-second timing and whether 8 frames look smooth enough.
- Sound choice/volume.
- Repeated rapid deletion visual behaviour.
- New checkbox layout at all supported localisation widths.

## Deferred
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so no heuristic matching.
- Additional/interpolated burn frames unless this 8-frame test proves too jumpy.
- Polished/custom burn sound unless the stock Vanilla sound is unsatisfactory.

## Exact next step
Fix the failed `0.1.27-dev1` Unlock Mode test by keeping the Bin anchor frame shown-but-empty outside animation, so pfUI forks do not need to resurrect a hidden movable. Bump the dev test version, then retest `VendorTweaks Bin` visibility/move/scale/reset/persistence before testing the deletion animation.
