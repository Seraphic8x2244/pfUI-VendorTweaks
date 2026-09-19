# VendorTweaks Dev Status

## Current state
- Branch: `dev`
- Test version: `0.1.27-dev9`
- Base main version: `0.1.26`
- Branched from: `e9b8c1a0fa6a5fffd0f23a21321f4945b0938024` — Exempt vendor purchases from Auto-Delete
- Current dev HEAD before this status update: `b7f0d7892bbdb847e48926df6b9ffb4ddb0e10a6`

## Latest dev commits
- `b7f0d7892bbdb847e48926df6b9ffb4ddb0e10a6` — Bump VendorTweaks dev9 test version
- `997b806485d5d98f214ff540a0a800bf8055fbdb` — Move delete feedback toggles above drop target
- `8aa20090351656b9099ee7cb07cc2f15f1f51912` — Bump VendorTweaks dev8 test version
- `15c8da47ef8e4c8c1fded820a0e74c5ad41781ed` — Localise delete animation toggle
- `ea5053917eff6161089873ce426b1abb2d743342` — Replace Bin test button with feedback toggles
- `4896f51bd4f425efaef769a5ac8a315af8a82488` — Bump VendorTweaks dev7 test version
- `ab04297794657be7a8aca783f35226cb30453db3` — Nudge Bin icon up slightly
- `fe18981493b8942f4b5fde76dbfffb3212e417db` — Bump VendorTweaks dev6 test version
- `608186f42474f08bff797661196e76b500dd4cb5` — Lower Bin icon further into flames
- `f59a0008211aa8b7eccd01b817c130957f9df42b` — Bump VendorTweaks dev5 test version
- `5c26deb04691f620879511ec955758ca563c3c68` — Lower Bin icon into burn effect
- `079d06a04415ab30de1a7816879094dbc9345a51` — Bump VendorTweaks dev4 test version
- `24a242daf850429936c9581a2514f36c4cc66172` — Localise Bin animation test button
- `e6f3c25feabc61460da1fa28f7ca4a3c8310eee7` — Add Bin animation test button
- `78b320b4c6eacb71fdbee192cf334e4c3efa363d` — Bump VendorTweaks dev3 test version
- `8ed7b269b4fbe73152753e95356b7e8ae0b28b6d` — Make Bin icon char black with top-down wipe
- `9ee1eecad9011c8c99e88c3de6abc6dba60f1cbd` — Bump VendorTweaks dev test version
- `9032770e9a2adc1c2b1c597de1cf8c8f62ab9beb` — Slow Bin animation and remove quest-failed sound
- `ae842b0024acefd039c58b77259168d10a50caec` — Restore VendorTweaks dev1 test version
- `cb284f86398ee42d00528294e37494adc4b999d4` — Revert false Bin unlock compatibility change
- `d445fe7fbac1c06cab94bdc8d9867f6e5c051b31` — Bump VendorTweaks dev test version
- `165a2df82e17692f668ce8c1aa63b1fc94d385fa` — Keep VendorTweaks Bin movable visible
- `d82673f23e1f3e55b023208b14b8aaf16921eac9` — Record VendorTweaks Bin unlock failure
- `d6bd35b163588aebfc134b4dd7888f342d42454c` — Remove temporary TGA compatibility workflow
- `749b370128eeaa8441c9e647cc3d342ba0518da7` — Update VendorTweaks animation test handoff
- `efa3fcec9a9faecc8c25d87820177f5edadd0e89` — Bump VendorTweaks dev test version
- `431f2b84b2ff7ea1e3e3b96552b7582cddb2d81e` — Localise delete chat toggle
- `13465e4122a0daccf2e9497c3478774020ffc477` — Add first VendorTweaks Bin animation
- `38de111cb727a0e2a6e4545e01e196692e579a9f` — Add first VendorTweaks burn sprite
- `03005cb53a32cb97e75338b153b2430e643d7b9e` — Add VendorTweaks dev handoff

## Completed on dev
- Existing Auto-Delete chat message preserved.
- Added per-character `Show delete animation` and `Show delete message in chat` options, both default ON.
- Added translations for both Auto-Delete feedback options to all supported VendorTweaks/pfUI locales.
- Added `pfVendorTweaksBin` as a 64x64 pfUI movable; pfUI Unlock Mode controls move/scale/reset and the drag label is presented as `VendorTweaks Bin`.
- Added an 8-frame transparent burn-to-ash TGA sprite strip. Source frames are 32x32 and render in the 64x64 Bin for the first visual test.
- Added an OnUpdate animation: 32x32 item icon underneath and burn sprite above. `0.1.27-dev2` lengthens the duration from 0.24s to 1.00s; `0.1.27-dev3` chars the icon to black and wipes it from top to bottom.
- Successful Auto-Delete starts/restarts the Bin animation with the deleted item's slot texture, then falls back through the shared item cache to the question-mark icon.
- `0.1.27-dev1` test showed `igQuestLogAbandonQuest` is the quest-failed sound and unsuitable. `0.1.27-dev2` removes animation audio pending a better choice.
- Rapid deletes replace/restart the active visual instead of queueing animation notifications.
- `0.1.27-dev8` removes the temporary `Test Bin Animation` button and adds a per-character `Show delete animation` toggle, default ON.
- `Show delete animation` and `Show delete message in chat` are stacked together directly below the Auto-Delete list as independent feedback controls.
- Existing Auto-Delete acquisition, BAG_UPDATE debounce, cursor verification, deletion safety and vendor-purchase exemption logic are otherwise unchanged.

## In-game test findings
- `0.1.27-dev8`: both feedback checkboxes rendered but were not clickable; likely overlapped/intercepted by the delete-list scroll frame.
- `0.1.27-dev6`: icon placement was very close; requested a 2-UI-unit upward nudge.
- `0.1.27-dev5`: icon still sits about one previous adjustment too high; requested another ~6 UI units downward.
- `0.1.27-dev4`: screenshot review shows the item icon visually sitting about 8–10 screen pixels too high relative to the flame body; estimated correction is ~6 WoW UI units downward.
- `0.1.27-dev2`: icon did not reach black and disappeared by shrinking vertically toward its centre; desired effect is a top-to-bottom wipe.
- `0.1.27-dev1`: `VendorTweaks Bin` appears correctly in pfUI Unlock Mode on the user's setup. Original movable registration is valid; previous missing-anchor report was caused by testing `main` instead of `dev`.
- `0.1.27-dev1`: burn animation at 0.24s is far too fast.
- `0.1.27-dev1`: `igQuestLogAbandonQuest` plays the quest-failed sound and is the wrong audio cue.

## Untested in game
- TGA render/alpha and sprite texture coordinates on the actual Vanilla 1.12.1 client. The strip is 32-bit RGBA RLE TGA, 256x32; legacy WoW API documentation states RLE TGA is supported, but the actual client test remains authoritative.
- Whether scaling 32px source frames to a 64px display is crisp enough; if soft, rebuild as native 64px frames.
- Bin drag/scale/reset and saved-position persistence on the user's pfUI setup; cross-fork behaviour remains untested.
- `0.1.27-dev7` icon placement after nudging its centre from y=-14 to y=-12 (with wipe bottom anchor adjusted from -30 to -28), plus blackening/top-down wipe timing.
- Sound choice/volume.
- Repeated rapid deletion visual behaviour.
- `0.1.27-dev9` feedback checkbox placement/clickability between the Auto-Delete checkbox and delete drop target, plus localization widths and independent toggle behavior.

## Deferred
- Buyback-specific Auto-Delete exemption: stock 1.12 buyback API does not expose an exact item link/ID, so no heuristic matching.
- Additional/interpolated burn frames unless this 8-frame test proves too jumpy.
- Polished/custom burn sound unless the stock Vanilla sound is unsatisfactory.

## Exact next step
Install/test `dev` `0.1.27-dev9`. Verify `Show delete animation` and `Show delete message in chat` appear directly below `Auto-Delete` and above the delete drop target, and are now clickable. Confirm each can be toggled independently without affecting deletion itself. Audio remains intentionally disabled.
