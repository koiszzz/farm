# 美术资源运行时映射

此表记录已生成的美术资源在当前原型中的实际消费位置。资源文件不能只停留在
`source_generated/` 而没有运行时引用。

| 资源 | 当前运行时用途 | 消费代码 |
| --- | --- | --- |
| `runtime_generated/terrain_atlas_v2.png` | 农场、城镇的逐格草地、耕地、浇水耕地、水面、岸、石头和围栏图块 | `scripts/world_renderer.gd` 的 `TERRAIN_ART` |
| `runtime_generated/road_transitions_v3.png` | 农场、城镇的直道、转角、T 字口、十字口和道路终点图块 | `scripts/world_renderer.gd` 根据相邻道路格选择 `ROAD_ART` 区域 |
| `runtime_generated/farmhouse_front_v3.png` | 农场占地 `[10,2,11,8]` 的正面透明农舍精灵 | `scripts/world_renderer.gd` 的 `FARMHOUSE_ART` |
| `concepts/farmhouse_interior_key_art_v1.png` | 农舍室内场景完整背景 | `scripts/world_renderer.gd` 的 `FARMHOUSE_INTERIOR_ART` |
| `runtime_generated/general_store_interior_v1.png` | 杂货店室内完整背景 | `scripts/world_renderer.gd` 的 `GENERAL_STORE_INTERIOR_ART` |
| `runtime_generated/clinic_interior_v1.png` | 诊所室内完整背景 | `scripts/world_renderer.gd` 的 `CLINIC_INTERIOR_ART` |
| `runtime_generated/cafe_interior_v1.png` | 咖啡馆室内完整背景 | `scripts/world_renderer.gd` 的 `CAFE_INTERIOR_ART` |
| `concepts/town_square_key_art_v1.png` | 杂货店、诊所、咖啡馆的裁取物件图 | `scripts/world_renderer.gd` 将物件锚定到对应多格占地 |
| `source_generated/mvp_tools_and_seeds_source_v1.png` | 当前工具/种子 HUD 图标 | `scripts/game.gd` 的 `TOOLS_ART` 与 `AtlasTexture` 区域 |
| `source_generated/npc_florist_uniform_actions_source_v1.png` | 花店主 3×4 动作帧 | `scripts/art_actor.gd` |
| `source_generated/npc_shopkeeper_uniform_actions_source_v1.png` | 店主 3×4 动作帧 | `scripts/art_actor.gd` |
| `source_generated/npc_fisherman_uniform_actions_source_v1.png` | 渔夫 3×4 动作帧 | `scripts/art_actor.gd` |
| `source_generated/farmer_sprite_sheet_source_v1.png` | 玩家下、左、右三朝向的待机、两帧行走、使用动作 | `scripts/avatar_renderer.gd` 的 `ACTION_ART` |
| `character_creator/*.png` | 人物创建器的属性选项与持久化配置 | `scripts/character_creator.gd` |

玩家现在优先使用完整的 3×4 动作表，避免将静态外观选项板叠加到行走帧上而遮住
角色。创建器会保留肤色、头发、眼睛、鼻子、嘴巴、耳朵与服饰的选择；下一批资源
将把这些选项补齐为同一动作契约的逐朝向覆盖层后再接回运行时。
