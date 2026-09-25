# 美术资源运行时映射

此表记录已生成的美术资源在当前原型中的实际消费位置。资源文件不能只停留在
`source_generated/` 而没有运行时引用。

| 资源 | 当前运行时用途 | 消费代码 |
| --- | --- | --- |
| `runtime_generated/terrain_atlas_v2.png` | 农场、城镇的逐格草地、耕地、浇水耕地、水面、岸、石头和围栏图块 | `scripts/world_renderer.gd` 的 `TERRAIN_ART` |
| `runtime_generated/terrain_atlas_v8.png` | 当前运行时地形图集：低对比草地、暖色土路、耕地行纹、池水波纹；四象限按 8×8 世界格采样并平铺于农场、小镇、郊区和河畔 | `scripts/world_renderer.gd` 的 `SOFT_TERRAIN` |
| `runtime_generated/countryside_grass_v1.svg` | 郊区专用低对比草地瓦片，统一底色并以少量草簇和稀疏野花区分格面；只替换郊区草面，保留通路、农场地块与其他区域原地形 | `scripts/world_renderer.gd` 的 `_draw_soft_terrain()` |
| `runtime_generated/cave_floor_v1.png` | 洞穴与矿井的石板/泥土底纹，按整张地图坐标采样，石块细节跨格连续 | `scripts/world_renderer.gd` 的 `CAVE_FLOOR_ART` |
| `runtime_generated/ore_deposits_v1.svg` | 铜矿、铁矿、煤、石英及地晶、紫水晶、冰泪、火水晶八种独立轮廓的矿脉图集；按当前楼层的实际掉落类型绘制，受矿镐伤害时叠加裂痕；四种宝石亦共用对应格作为背包图标 | `scripts/homestead_scenery.gd` 的 `ORE_DEPOSIT_ART` 与 `ORE_DEPOSIT_INDEX`；`scripts/game.gd` 的 `_resource_icon()` |
| `runtime_generated/journal_frame_v1.svg` / `journal_header_v1.svg` | 像素木框与木质标题带，采用九宫格拉伸；旅行手册背包、角色卡、设置、地图、居民/商店面板共用 | `scripts/farm_ui_skin.gd` 的 `frame()` 与 `header()` |
| `runtime_generated/fish_icons_v1.svg` | 八格原创淡水/海水鱼、鳗鱼和鱿鱼像素图标；各物种在背包、钓鱼收藏图鉴中使用独立图格 | `scripts/game.gd` 的 `FISH_ART`、`FISH_ICON_INDEX` 与 `_fish_icon()` |
| `runtime_generated/beach_collectibles_v1.png` | 八格原创海岸像素物件；贝壳/海螺作为每日拾贝外观，潮池、海草、螃蟹、海鸟和渔篮补强沙滩场景 | `scripts/homestead_scenery.gd` 的贝壳拾取绘制；`scripts/world_renderer.gd` 的世界物件图集裁切；`scripts/region_world_builder.gd` 的沙滩物件表 |
| `runtime_generated/backpack_goods_v1.svg` | 7×4原创物品图集，覆盖四种果园果实、三种畜产品、三类加工品、八道料理、四种农场设施和四种果树苗；背包按物品类别和ID裁切独立图格 | `scripts/game.gd` 的 `GOODS_ART`、`GOODS_ICON_INDEX` 与 `_goods_icon()` |
| `runtime_generated/orchard_trees_v1.png` | 苹果、橙子、桃子、石榴四个树种各自的树苗、幼树、成熟与挂果帧 | `scripts/world_renderer.gd` 的 `ORCHARD_ART`，按生长天数换帧 |
| `runtime_generated/road_transitions_v3.png` | 农场、城镇的直道、转角、T 字口、十字口和道路终点图块 | `scripts/world_renderer.gd` 根据相邻道路格选择 `ROAD_ART` 区域 |
| `runtime_generated/farmhouse_front_v3.png` | 农场占地 `[10,2,11,8]` 的正面透明农舍精灵 | `scripts/world_renderer.gd` 的 `FARMHOUSE_ART` |
| `concepts/farmhouse_interior_key_art_v1.png` | 农舍室内场景完整背景 | `scripts/world_renderer.gd` 的 `FARMHOUSE_INTERIOR_ART` |
| `runtime_generated/general_store_interior_v1.png` | 杂货店室内完整背景 | `scripts/world_renderer.gd` 的 `GENERAL_STORE_INTERIOR_ART` |
| `runtime_generated/clinic_interior_v1.png` | 诊所室内完整背景 | `scripts/world_renderer.gd` 的 `CLINIC_INTERIOR_ART` |
| `runtime_generated/cafe_interior_v1.png` | 咖啡馆室内完整背景 | `scripts/world_renderer.gd` 的 `CAFE_INTERIOR_ART` |
| `concepts/town_square_key_art_v1.png` | 杂货店、诊所、咖啡馆的裁取物件图 | `scripts/world_renderer.gd` 将物件锚定到对应多格占地 |
| `runtime_generated/valley_map_v1.png` | 花溪五区旅行手册全域插画底图；游戏叠加农场、林地、小镇、山洞、沙滩标签与实时当前位置标记 | `scripts/map_overview.gd` 的 `VALLEY_MAP_ART` |
| `source_generated/mvp_tools_and_seeds_source_v1.png` | 当前工具/种子 HUD 图标 | `scripts/game.gd` 的 `TOOLS_ART` 与 `AtlasTexture` 区域 |
| `source_generated/npc_florist_uniform_actions_source_v1.png` | 早期花店主动作原稿（留档参考，当前不直接加载） | — |
| `source_generated/npc_shopkeeper_uniform_actions_source_v1.png` | 早期店主动作原稿（留档参考，当前不直接加载） | — |
| `source_generated/npc_fisherman_uniform_actions_source_v1.png` | 早期渔夫动作原稿（留档参考，当前不直接加载） | — |
| `runtime_generated/resident_idle_cast_v1.png` | 十位居民各自独立的正面、侧面、背面待机图集（10列×3行）；侧面镜像供左右朝向共用，供场景角色和对话肖像使用 | `scripts/game.gd` 按居民列选择，`scripts/art_actor.gd` 按朝向选择 |
| `runtime_generated/farmer_walk_v5.png` | 主角四方向各8帧的原创行走图集；步幅和手臂摆动更容易辨认，帧高按可见轮廓归一缩放；逐格Sprite区域开启边缘裁切和nearest采样 | `scripts/avatar_renderer.gd` 按实际位移选择帧并用 `SpriteAtlas` 锚定可见底部 |
| `runtime_generated/chicken_walk_v1.png` | 小鸡四向像素动作图；动态帧按实际漫步距离切换，保留游戏交互爱心特效 | `scripts/chicken_actor.gd` 的 `CHICKEN_ART` |
| `runtime_generated/duck_walk_v1.png` | 绿头、棕胸、蓝绿翼羽的四向鸭子动作图；按漫步距离切帧 | `scripts/duck_actor.gd` 的 `DUCK_ART` |
| `runtime_generated/cow_walk_v1.png` | 奶油白与深棕花斑奶牛四向行走图；按漫步距离切换步态，独立于抚摸爱心和脚下影子 | `scripts/cow_actor.gd` 的 `COW_ART` |
| `runtime_generated/florist_walk_v2.png` / `shopkeeper_walk_v2.png` / `fisherman_walk_v2.png` | 花店主、店主、渔夫三类四方向行走图；其余七位暂复用行走模板，站立及肖像保持各自原创造型 | `scripts/game.gd` 的 `NPC_ART` |
| `source_generated/farmer_sprite_sheet_source_v1.png` | 历史参考：玩家三朝向待机、两帧行走和使用动作；不再用于当前运行时行走渲染 | 仅留作旧素材对照 |
| `character_creator/*.png` | 人物创建器的属性选项与持久化配置 | `scripts/character_creator.gd` |

玩家行走使用8列×4行图集，行走朝向、可见尺寸归一、锚点与自定义色板由 `avatar_renderer.gd` 统一处理。创建器会保留肤色、头发、眼睛、鼻子、嘴巴、耳朵与服饰的选择；后续仍需将每种自定义属性扩充到工具与其他动作帧。
