# Travel map live position markers

The travel map shows the farmer's live coordinate, visible residents, available forage spots, and unfinished daily requests. Forage comes from the live homestead pickup data, so collecting an item removes its marker for the day; completed requests disappear, and active request markers follow the resident's live position. The full valley view translates local outdoor coordinates into continuous-world coordinates using the authored region placements; detailed region maps translate back from the continuous world when the player is inside that region. Indoor maps and unrelated regions do not receive guessed markers. Opening or changing map pages remains read-only and never moves the farmer.

Windows / Godot 4.7.1 / NVIDIA RTX 3050 / D3D12 captures at 1536x864:

- `valley.png` shows the farmer, town residents, forage spots, and request locations over the illustrated full-region map.
- `town.png` shows residents, forage, and request locations at local map scale.
- `beach.png` shows the live shell-pickup locations on the beach map while the farmer remains in town.

The parchment legend identifies the farmer, residents, forage, and requests. Validation: `map_overview_test.gd` 25 checks, `regional_world_test.gd` 334 checks, and `game_smoke_test.gd` passed headless. The map test also verifies that collecting an item and completing a request remove the matching marker. Both screenshots were captured in the D3D12 game window. The valley base art remains schematic; richer filters and lower-resolution layout checks are still future work.
