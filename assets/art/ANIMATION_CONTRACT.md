# Character animation contract

Every playable character and NPC uses the same source-sheet layout and the same
runtime animation keys. A character's clothing or held item may differ; its
frame position and animation meaning may not.

## Source layout

- Grid: **4 columns × 3 rows** (12 frames total).
- Intended runtime frame size: **32 × 48 pixels** after crop and normalization.
- Rows are directions: `down`, `left`, `right`.
- Columns are actions: `idle`, `walk_a`, `walk_b`, `use`.

| Row | Direction | Col. 1 | Col. 2 | Col. 3 | Col. 4 |
| --- | --- | --- | --- | --- | --- |
| 1 | `down` | idle | walk A | walk B | use / interact |
| 2 | `left` | idle | walk A | walk B | use / interact |
| 3 | `right` | idle | walk A | walk B | use / interact |

`walk_a` and `walk_b` must alternate at the same cadence for every character.
`use` is the same action slot for all actors; a role item (flowers, ledger, or
fishing rod) may appear only in that frame. The player character uses the same
matrix, so shared Godot animation code can select frames without special cases.

The first implementation will mirror left-facing frames to derive `right` only
if a final, separately authored right-facing frame is not suitable.
