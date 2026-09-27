# 美术资源运行时映射

此表记录已生成的美术资源在当前原型中的实际消费位置。资源文件不能只停留在
`source_generated/` 而没有运行时引用。

| 资源 | 当前运行时用途 | 消费代码 |
| --- | --- | --- |
| `runtime_generated/terrain_atlas_v2.png` | 农场、城镇的逐格草地、耕地、浇水耕地、水面、岸、石头和围栏图块 | `scripts/world_renderer.gd` 的 `TERRAIN_ART` |
| `runtime_generated/terrain_atlas_v8.png` | 当前运行时地形图集：低对比草地、暖色土路、耕地行纹、池水波纹；农场草地基底继续采用其无缝草面，避免单格接缝；其它区域按 8×8 世界格采样 | `scripts/world_renderer.gd` 的 `SOFT_TERRAIN`、`_draw_farm_surface()` |
| `runtime_generated/countryside_grass_v1.svg` | 郊区专用低对比草地瓦片，统一底色并以少量草簇和稀疏野花区分格面；只替换郊区草面，保留通路、农场地块与其他区域原地形 | `scripts/world_renderer.gd` 的 `_draw_soft_terrain()` |
| `runtime_generated/cave_floor_v1.png` | 洞穴与矿井的石板/泥土底纹，按整张地图坐标采样，石块细节跨格连续 | `scripts/world_renderer.gd` 的 `CAVE_FLOOR_ART` |
| `runtime_generated/ore_deposits_v1.svg` | 铜矿、铁矿、煤、石英及地晶、紫水晶、冰泪、火水晶八种独立轮廓的矿脉图集；按当前楼层的实际掉落类型绘制，受矿镐伤害时叠加裂痕；四种宝石亦共用对应格作为背包图标 | `scripts/homestead_scenery.gd` 的 `ORE_DEPOSIT_ART` 与 `ORE_DEPOSIT_INDEX`；`scripts/game.gd` 的 `_resource_icon()` |
| `runtime_generated/journal_frame_v1.svg` / `journal_header_v1.svg` | 像素木框与木质标题带，采用九宫格拉伸；旅行手册背包、角色卡、设置、地图、居民/商店面板共用 | `scripts/farm_ui_skin.gd` 的 `frame()` 与 `header()` |
| `runtime_generated/fish_icons_v1.svg` | 八格原创淡水/海水鱼、鳗鱼和鱿鱼像素图标；各物种在背包、钓鱼收藏图鉴中使用独立图格 | `scripts/game.gd` 的 `FISH_ART`、`FISH_ICON_INDEX` 与 `_fish_icon()` |
| `runtime_generated/beach_collectibles_v1.png` | 八格原创海岸像素物件；贝壳/海螺作为每日拾贝外观，潮池、海草、螃蟹、海鸟和渔篮补强沙滩场景 | `scripts/homestead_scenery.gd` 的贝壳拾取绘制；`scripts/world_renderer.gd` 的世界物件图集裁切；`scripts/region_world_builder.gd` 的沙滩物件表 |
| `runtime_generated/backpack_goods_v1.svg` | 7×4原创物品图集，覆盖四种果园果实、三种畜产品、三类加工品、八道料理、四种农场设施和四种果树苗；背包按物品类别和ID裁切独立图格 | `scripts/game.gd` 的 `GOODS_ART`、`GOODS_ICON_INDEX` 与 `_goods_icon()` |
| `runtime_generated/orchard_trees_v1.png` | 苹果、橙子、桃子、石榴四个树种各自的树苗、幼树、成熟与挂果帧 | `scripts/world_renderer.gd` 的 `ORCHARD_ART`，按生长天数换帧 |
| `runtime_generated/road_transitions_v3.png` | 农场、城镇的直道、转角、T 字口、十字口和道路终点图块 | `scripts/world_renderer.gd` 根据相邻道路格选择 `ROAD_ART` 区域 |
| `runtime_generated/farm_well_v1.png` | 农场水井独立 3×4 格透明精灵；地图对象 `v2_well` 保持素材 3:4 比例，以 7.5×10 格显示，实体底座碰撞为 6×2 格 | `scripts/world_renderer.gd` 的 `FARM_WELL_ART`；`design/maps/outdoor_navigation_v1.json` 的 `v2_well` |
| `runtime_generated/farm_cherry_tree_seasons_v1.png` | 以农场树素材重绘的四季樱花树；春季粉冠、夏季绿冠、秋季金叶、冬季蓝白冠，树干保持原始色彩并以树根格碰撞 | `scripts/world_renderer.gd` 的 `FARM_CHERRY_TREE_ART`；`design/maps/outdoor_navigation_v1.json` 的 `tree_farm_19` |
| `runtime_generated/farmhouse_tier_1_concept_v2.png` | 采用屋顶烟囱、中央门、木质门廊与窗台花箱的透明农舍；按 17×15.3 格视觉框底部对齐，压低立面高度并让中央门与农场主路 x=27 对齐；门动画区域从同图裁切，地基碰撞保持独立数据 | `scripts/world_renderer.gd` 的 `FARMHOUSE_FRONT_ART`；`design/maps/outdoor_navigation_v1.json` 的 `farmhouse` |
| `runtime_generated/farmhouse_tier_2_reference_v1.png` / `farmhouse_tier_3_reference_v1.png`、`farm_coop_tier_2_reference_v1.png` / `farm_coop_tier_3_reference_v1.png`、`farm_barn_tier_2_reference_v1.png` / `farm_barn_tier_3_reference_v1.png` | 用户素材库中各类建筑的二、三级外观裁图已备好；当前建筑升级流程尚未提供，场景继续使用一级图 | `assets/art/runtime_generated/`（待建筑升级功能接入） |
	| `runtime_generated/farm_terrain_user_tiles_v1.png` | 从用户四季图逐项提取的 32×32 图集；耕地/浇水土壤逐格铺满，水面逐格绘制季节波纹。土路按相邻格拓扑选择季节图块；弯道和 T 口由同一基础图块按连接方向旋转，直道/十字口连续铺接，单格端点使用圆头过渡；农舍门口、田地、水井与南门组成可通行路线。图集原图保存在 `source_generated/farm_terrain_user_seasons_source_v1.png` | `scripts/world_renderer.gd` 的 `FARM_TERRAIN_ART`、`_draw_farm_path_tile()`、`_draw_farm_path_network()`、`farm_path_rotation_from_mask()`、`_draw_farm_plot()` |
| `runtime_generated/farm_flora_seasons_v1.png` | 四季野草、低矮花簇与季节植被图集，按稳定格坐标稀疏铺设在农场可通行草地 | `scripts/world_renderer.gd` 的 `FARM_FLORA_ART`、`_draw_farm_flora()` |
| `runtime_generated/farm_meadow_details_v1.png` | 从用户四季地形板顶部提取的 6×4 透明 32×32 草丛/花簇细节；与基础草纹混铺，不改变通行格或碰撞 | `scripts/world_renderer.gd` 的 `FARM_MEADOW_ART`、`_draw_farm_flora()` |
| `runtime_generated/farm_coop_tier_1_reference_v1.png` / `farm_barn_tier_1_reference_v1.png` | 采用用户素材库中的一级鸡舍与一级畜棚；按设施占地宽度和底部锚点缩放，碰撞格、围栏、饲槽和动物行动逻辑维持现有配置 | `scripts/world_renderer.gd` 的 `_draw_animal_area()`、`_draw_barn_area()` |
| `concepts/farmhouse_interior_key_art_v1.png` | 农舍家具、动线与暖色气氛参考稿；运行时地面/墙面由 `_draw_farmhouse_room()` 按地图尺寸绘制，家具从源图裁切 | `scripts/world_renderer.gd` 的 `_draw_farmhouse_room()`、`FURNITURE_ART` |
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
| `runtime_generated/farm_chicken_female_walk_v2.png` / `farm_chicken_male_walk_v2.png` | 用户素材库中鸡的母/公四方向 4 帧行走图；按实际漫步距离切帧，存档性别决定外观 | `scripts/chicken_actor.gd` 的 `FEMALE_ART` / `MALE_ART` |
| `runtime_generated/farm_duck_female_walk_v2.png` / `farm_duck_male_walk_v2.png` | 用户素材库中鸭的母/公四方向 4 帧行走图；按实际漫步距离切帧 | `scripts/duck_actor.gd` 的 `FEMALE_ART` / `MALE_ART` |
| `runtime_generated/farm_cow_female_walk_v2.png` / `farm_cow_male_walk_v2.png` | 用户素材库中牛的母/公四方向 4 帧行走图；按实际漫步距离切帧 | `scripts/cow_actor.gd` 的 `FEMALE_ART` / `MALE_ART` |
| `runtime_generated/farm_dog_female_walk_v2.png` / `farm_dog_male_walk_v2.png` / `farm_cat_walk_v2.png` | 用户素材库中的公母狗与猫行走图；宠物面板可切换猫/狗及狗的公母外观，猫使用单一图集 | `scripts/companion_actor.gd` 的 `set_variant()` |
| `runtime_generated/farm_sheep_female_walk_v1.png` / `farm_sheep_male_walk_v1.png`, `farm_goat_female_walk_v1.png` / `farm_goat_male_walk_v1.png`, `farm_pig_female_walk_v1.png` / `farm_pig_male_walk_v1.png`, `farm_horse_female_walk_v1.png` / `farm_horse_male_walk_v1.png` | 用户素材库中的公母动作图已切成游戏尺寸的图集，作为后续羊圈、山羊、猪和马厩玩法的直接素材；当前游戏尚无这些物种的运行 actor/饲养逻辑 | `assets/art/runtime_generated/`（待对应玩法接入） |
| `runtime_generated/florist_walk_v2.png` / `shopkeeper_walk_v2.png` / `fisherman_walk_v2.png` | 花店主、店主、渔夫三类四方向行走图；其余七位暂复用行走模板，站立及肖像保持各自原创造型 | `scripts/game.gd` 的 `NPC_ART` |
| `source_generated/farmer_sprite_sheet_source_v1.png` | 历史参考：玩家三朝向待机、两帧行走和使用动作；不再用于当前运行时行走渲染 | 仅留作旧素材对照 |
| `character_creator/*.png` | 人物创建器的属性选项与持久化配置 | `scripts/character_creator.gd` |

玩家行走使用8列×4行图集，行走朝向、可见尺寸归一、锚点与自定义色板由 `avatar_renderer.gd` 统一处理。创建器会保留肤色、头发、眼睛、鼻子、嘴巴、耳朵与服饰的选择；后续仍需将每种自定义属性扩充到工具与其他动作帧。

农场物件新增设计尺寸与碰撞规范见 [`farm/FARM_ASSET_GUIDE.md`](farm/FARM_ASSET_GUIDE.md) 和 [`farm/farm_asset_contract_v1.json`](farm/farm_asset_contract_v1.json)：32×32 世界基础格；视觉范围、碰撞脚印、交互格与四季变体分别定义。JSON 当前是新素材的制作合同；尚未替换/确认的运行图集仍按地图对象表的 `visual_rect` 与 `blocked` 数据渲染。
