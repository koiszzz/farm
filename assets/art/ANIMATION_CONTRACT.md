# Character animation contract

The runtime contract is defined by `scripts/avatar_renderer.gd` and `scripts/sprite_atlas.gd`. New player art must follow this file; the former 4-column × 3-row contract is obsolete.

## Player locomotion atlas

- Grid: **8 columns × 4 rows**, one complete locomotion cycle per row.
- Row order: `down`, `left`, `right`, `up`.
- Columns are chronological stride phases 0–7. A cycle should clearly show contact, down/weight, passing, and up poses for the left foot, then the mirrored sequence for the right foot.
- Every cell must have the same integer width and height. The exported image dimensions must be exactly divisible by 8 and 4.
- Keep the pelvis, head scale, clothing details, and ground line consistent. Put the foot contact point on the same local ground line in every cell.
- Use transparent pixels outside the character. Do not let hair, outlines, shadows, or antialiasing bleed across cell boundaries.
- Left and right rows should be separately authored when possible. If mirroring is used, mirror one completed row offline and then fix asymmetric clothing and tool details.

The renderer selects a frame from actual distance travelled, not elapsed time. `advance_stride()` advances the 0–7 phase and preserves the cycle across continuous movement. When displacement reaches zero or input is released, the gameplay controller resets the phase to frame 0, an authored planted stance; resuming from a frozen lifted-foot phase makes the feet pop. Walking uses `farmer_walk_v5.png`; holding Shift selects the dedicated `farmer_run_v3.png` atlas with the same row and phase order. Both use the fixed row pivot below; running keeps its stronger bob and side-facing lean. The ground shadow stays fixed and never feeds back into player collision or world position.

For locomotion frames, `SpriteAtlas.row_anchored_frame()` keeps one root pivot across all eight phases in a direction: the cell center on X and the median opaque foot-line Y for that row. Do not recenter the whole character on each frame's lowest-foot midpoint. That pivot moved as much as 68 source pixels across the current front-facing cycle and shifted the torso with the support leg. Cropping may change each frame's visible rectangle, but the shared cell anchor must remain fixed; foot contact and clearance come from the authored pose relative to that anchor.

`farmer_walk_v5.png` is the current runtime iteration. It uses an exact 1536 × 1024 canvas, 192 × 256 per cell. The relative pose differences are larger than v4; closest-pair similarity is 0.8890 down, 0.9023 left, 0.9004 right, and 0.8901 up. It has 451 opaque pixels exactly on horizontal cell boundaries and none on vertical boundaries, so this version does not have the old generous transparent row margin. The renderer therefore clips each Sprite2D region and uses nearest filtering; a regression assertion protects that setting. The live D3D12 four-direction capture at `design/qa/2026-09-24/avatar-walk-v5/live-cycle.png` shows no row bleed and the runtime boots remain readable. `avatar_rendering_test.gd` checks the atlas dimensions, renderer guard, and all 32 direction/phase visible heights. Movement-input and action regressions pass, but a real player-controlled feel review is still required before calling the walk final. v4 and earlier evidence remain in `design/qa/2026-09-24/avatar-walk-v4/` and `avatar-walk-v3/`.

`farmer_run_v3.png` is the first separate run cycle. It uses the same 1536 × 1024 canvas and 192 × 256 cells. The directional montage and frame metrics are in `design/qa/2026-09-25/locomotion/`; the generated sheet has 12 opaque pixels on vertical cell seams and none on horizontal seams, so sprite-region clipping remains required. The staged D3D12 capture shows all four rows at runtime scale. `avatar_rendering_test.gd` checks run/walk selection, fixed anchors and body height for all run phases. Physical input reports 27.73 px walk and 45.76 px run over the same test interval. Human-controlled play feel and further cleanup of the 12 seam pixels remain open.

NPC walk cycles have four phases per direction. When an NPC switches from walking to idle (for example, at a patrol pause or to greet the player), reset its stride to the planted first phase; resuming at a partially lifted foot reads as a foot pop. NPC walk art still needs distinct, frame-safe atlases for every resident; only the florist, shopkeeper, and fisherman currently have dedicated walk sheets.

## Idle and action atlases

- Idle art uses **1 column × 4 rows** in the same direction order.
- Hoe, scythe, and pickaxe swings use **4 columns × 4 rows**. The swing sheet currently maps rows as down, right, left, up for compatibility; preserve that order until the renderer and all assets migrate together.
- Seed, harvest, pet, water, gift, and fish actions use **4 columns × 4 rows** in down, left, right, up order.
- Four action columns represent prepare, contact, early recovery, and return. Gameplay commits exactly once at contact; visual frames must make that moment readable.

## Acceptance

Review the atlas as a loop and in the running game at 1.75× camera zoom. Check start, stop, instant reverse, diagonal travel, wall slide, walk, run, and all four directions. Reject visible foot sliding, sideways body jumps, changing body scale, duplicated phases, or a rear view that reads as eight idle frames. Verify with a real rendered framebuffer as well as the movement and action regression scripts.
