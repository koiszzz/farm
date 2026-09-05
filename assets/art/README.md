# Spring farm art — first generation

All assets in this folder are original, generated for this project. They establish
the first-pass visual direction: bright spring pixel art with warm wood, earthy
soil, clear water, and a blue-roofed farmhouse.

## Review status

| File | Intended use | Status |
| --- | --- | --- |
| `concepts/spring_farm_key_art_v1.png` | Art-direction reference / possible main-menu image | Approved as visual reference; not a tile map |
| `source_generated/spring_terrain_source_v1.png` | Terrain, fence, rock, and weed source sheet | Needs grid extraction and edge-tile completion |
| `source_generated/mvp_tools_and_seeds_source_v1.png` | Tool and seed inventory-icon source sheet | Needs uniform square crops before game use |
| `source_generated/farmer_sprite_sheet_source_v1.png` | Player animation source sheet | Needs per-frame crop and pose review before game use |
| `source_generated/mvp_ui_components_source_v1.png` | Inventory, item-slot, hotbar, dialog, coin, and weather source sheet | Needs component extraction and UI nine-slice preparation |
| `concepts/town_square_key_art_v1.png` | Spring town-square layout and building language | Approved as visual reference; needs modular exterior tiles and building layers |
| `concepts/farmhouse_interior_key_art_v1.png` | Farmhouse interior layout and atmosphere | Approved as visual reference; needs modular floor and wall tiles |
| `source_generated/interior_furniture_source_v1.png` | Twelve interior furnishing sprites | Needs individual crops and collision footprints |
| `source_generated/town_npc_cast_source_v1.png` | Florist, shopkeeper, and fisherman animation source sheet | Needs per-frame crops and animation-pose selection |
| `source_generated/npc_florist_uniform_actions_source_v1.png` | Florist action sheet | 3×4 standard action grid; ready for crop review |
| `source_generated/npc_shopkeeper_uniform_actions_source_v1.png` | Shopkeeper action sheet | 3×4 standard action grid; needs background-glow cleanup |
| `source_generated/npc_fisherman_uniform_actions_source_v1.png` | Fisherman action sheet | 3×4 standard action grid; needs background-glow cleanup |

## Technical conventions for the implementation pass

- Keep original generated images under `source_generated/`; never overwrite them.
- Export runtime-ready derivatives into `tilesets/`, `characters/`, `objects/`,
  or `ui/` with stable descriptive filenames.
- Runtime tiles are 32×32 pixels. Player frames are 32×48 pixels. Derivatives
  must have a transparent background and no semi-transparent background glow.
- Godot texture import should disable filtering and use nearest-neighbour pixel
  scaling.

## First-pass visual decisions

- Season: spring.
- Perspective: elevated top-down (not isometric).
- Protagonist: straw hat, green overalls, cream shirt, brown boots.
- Landmark: orange wood farmhouse with a blue tile roof.
- UI direction for the next batch: wood-framed inventory panels and cream-paper
  surfaces, with no embedded text in generated art.
- Town: flower plaza, shop, clinic, cafe, riverside paths, and readable entrances.
- Interior: warm timber-and-plaster farmhouse with open walkable floor.
- First NPC cast: florist, shopkeeper, and fisherman; their clothing palettes and
  props intentionally distinguish their roles at a glance.
- All people, including the protagonist, use the same animation matrix. See
  `ANIMATION_CONTRACT.md` for the required row, column, and frame meanings.
- Customizable-player base, feature layers, palette choices, and save fields are
  defined in `character_creator/README.md` and `character_creator/character_creator_v1.json`.
- `ART_RUNTIME_MAPPING.md` records which generated assets are actually consumed
  by the playable prototype and which still require per-frame processing.
