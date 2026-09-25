# Cave floor lighting pass

The three mine floors now use separate low-opacity ambient tints and wider flickering torch halos. The entrance level keeps warm amber light, floor two shifts toward blue-teal, and floor three uses a dim violet tint. The overlay is drawn behind the player; mining deposits, collision, navigation, and floor progression are unchanged.

Windows / Godot 4.7.1 / NVIDIA RTX 3050 / D3D12 screenshots at 1536x864:

- `cave.png`
- `mine-2.png`
- `mine-3.png`

Visual inspection confirms that the level color temperature changes from floor to floor while the player, ladder, torch, and ore deposits remain visible. The effect is intentionally subtle; the existing cave wall/floor artwork still needs more material variety and the lighting needs a dark-room readability review.

Validation: `mining_gameplay_test.gd` 85 checks, `regional_world_test.gd` 334 checks, and `game_smoke_test.gd` passed headless. All three screenshots were captured in the D3D12 game window.
