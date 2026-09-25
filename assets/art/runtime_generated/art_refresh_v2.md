# 美术资源 v2 / 地图美术 v4

生成方式以原创像素素材为主，包括内置 `image_gen` 生成图及少量按像素格绘制的 SVG 图集。以下选定资源供游戏直接加载，不改写旧源图。人物/道具/建筑为透明背景素材；地表为不透明纹理。人物留白差异由 `scripts/sprite_atlas.gd` 运行时切片、脚底对齐，并按可见帧高统一等比缩放，避免不同透明留白造成画面尺寸变化。

| 文件 | 格式与用途 |
| --- | --- |
| farmer_idle_v1.png | 1列4行；下、左、右、上；双脚落地、重心居中的完全静止姿势 |
| farmer_walk_v2.png | 8列4行；下、左、右、上；连续行走，跑步共用并调整步幅、前倾和速度 |
| farmer_swing_v2.png | 4列4行；下、右、左、上；站立、蓄力、挥下接触、回收；运行时已按实际行序映射 |
| farmer_crouch_v2.png | 4列4行；下、左、右、上；站立、蹲下、采收、举起 |
| farmer_offer_v2.png | 4列4行；下、左、右、上；站立、抬手、伸出、收回 |
| florist_idle_v1.png | 1列4行；花匠下、左、右、上完全静止，花篮自然持于身侧 |
| florist_walk_v2.png | 4列4行；花匠，辫子、花篮、围裙背面 |
| shopkeeper_idle_v1.png | 1列4行；店主下、左、右、上完全静止，保留围裙背结 |
| shopkeeper_walk_v2.png | 4列4行；店主，背心、绿色围裙及背面系带 |
| fisherman_idle_v1.png | 1列4行；渔夫下、左、右、上完全静止，保留帽子、兜帽与胶靴 |
| fisherman_walk_v2.png | 4列4行；渔夫，针织帽、黄色外套及背面兜帽 |
| resident_idle_cast_v1.png | 10列3行；小芙、阿谷、老江、林伯、杉月、白芷、陶乐、青禾、知夏、豆豆各自的正面、侧面、背面静止姿势；左右共用侧面并镜像 |
| farmer_walk_v3.png | 8列4行；主角四方向步态重制版，交替呈现左右脚接触、承重、经过和抬脚姿势；仍需减少侧面/背面相似帧 |
| farmer_walk_v4.png | 1536×1024透明8列4行；四向主角循环动作，角色边缘不越格；运行时按可见帧高归一尺寸；背向最近帧相似度仍偏高，需持续动作复核 |
| terrain_atlas_v4.png | 2列2行；草地、土路、耕地、水面；地图连续采样纹理区域 |
| village_buildings_v4.png | 2列2行；农舍、种子铺、诊所、咖啡馆；门扇按立面位置动画 |
| village_props_v4.png | 4列2行；树、花丛、喷泉、公告板、出货箱、水井、长凳、路灯 |
| cave_floor_v1.png | 1024×1024 原创洞穴地面纹理；石板、泥土与零星矿屑按整张地图坐标采样，不再每格铺设纯色矩形 |
| ore_deposits_v1.svg | 256×32 透明8格像素矿脉图；铜矿、铁矿、煤、石英、地晶、紫水晶、冰泪和火水晶各有独立轮廓与矿色，由洞穴实际矿脉类型选择帧，也用作矿物背包图标 |
| journal_frame_v1.svg / journal_header_v1.svg | 原创像素木边与纸面九宫格组件、木质标题条；在 Godot UI 中按控件大小拉伸但保留边角像素密度，用于设置、角色卡、地图、背包及居民/商店面板 |
| fish_icons_v1.svg | 128×64 透明4×2原创像素图集，分别表现溪鱼、鲶鱼、夜鳗、沙丁鱼、比目鱼、红鲷、鱿鱼和金枪鱼；逐种用于背包及鱼类图鉴 |
| beach_props_v1.png | 1774×887 透明原创沙滩道具图集；4×2 单元，含沙丘草、潮池、渔屋、木质栈台、漂流木、海岸灌木、渔网架和遮阳伞，由沙滩地图物件表进行深度排序 |
| beach_collectibles_v1.png | 1774×887 透明原创4×2海岸图集；贝壳和海螺用于每日拾贝，潮池、海草、螃蟹、海鸟与渔篮经沙滩地图物件表接入，并在潮池格保留水域碰撞 |
| community_center_v1.png | 1983×793 透明双状态社区会堂图集；2×1 帧，左侧破败、右侧修复完成，捐献进度存在存档并驱动外观切换 |
| valley_map_v1.png | 1774×887 原创五区像素旅行图；农场、郊区林地、小镇、北部山洞和南部沙滩由步道连接，运行时叠加地名与玩家所在区 |
| orchard_trees_v1.png | 4列4行透明果树图集；横向苹果/橙子/桃子/石榴，纵向树苗/幼树/成熟/挂果 |
| chicken_walk_v1.png | 4列4行透明小鸡图集；下、左、右、上四向；运行时按漫步位移选步态，当前四只母鸡共用同一外观 |
| duck_walk_v1.png | 4列4行透明绿头鸭图集；下、左、右、上四向；按漫步距离选步态，和小鸡使用不同羽色、喙形与体态 |
| cow_walk_v1.png | 4列4行奶牛图集；下、左、右、上四向，奶油白身体、深棕花斑与粉色口鼻；按漫步位移选步态 |

`resident_idle_cast_v1.png` 目前已接入实际NPC静止姿势与对话肖像。三张已有走路图继续保留给相应角色，其他居民移动时暂用共享步态模板；后续仍需补齐每位居民的独立行走周期和动作帧。

## 最终生成提示词组

共同要求：cozy top-down farming RPG, detailed 16-bit pixel art, consistent identity and palette, exact equal-cell atlas, no text or grid lines; transparent alpha outside character/building/prop silhouettes; no ground backdrop. 地形单独使用不透明无缝纹理。人物每行一个方向、列为连续姿势。以下为各最终请求的主体约束；没有采用生成失败的棕色/棋盘格花匠背景版本。

### 玩家静止

Create a dedicated 1-column by 4-row idle atlas for the same farmer, ordered front/left/right/back. Every pose stands completely still with both boots planted side by side at equal height, balanced neutral weight, relaxed straight legs and arms, and a shared foot anchor. No extended foot, lifted heel, arm swing, walking gesture, floor, shadow, text or grid; the back row shows no face. The final selected output was background-extracted to real alpha and normalized to equal 256 px cells without changing the poses.

### 玩家行走

Create a production-ready transparent PNG pixel art sprite atlas for a cozy top-down farming game. Exactly 8 columns and 4 rows, equal sized cells, no text, no grid lines, transparent background. One consistent young farmer with chestnut short hair, cream shirt, teal-blue overalls with straps, brown boots. Each cell centered identically at feet, sprite fills 75 percent height, ample separation. Row 1 facing front/south, row 2 facing left/west, row 3 facing right/east, row 4 facing BACK/north (full back of head, NO face or eyes, back overall straps). Each row eight consecutive frames of a smooth natural walk cycle: alternating feet planting, passing, lifting, heel contact, synchronized opposing arm swing. Maintain proportions and identity exactly in all 32 sprites, clean crisp pixel clusters, dark warm outlines, restrained 16-bit farming RPG palette. Orthographic three-quarter overhead view, no perspective variation. Image wide 2:1 aspect ratio. Functional game sprite art.

### 玩家动作

Swing: exactly four columns and four rows of the same farmer. Rows front, left, right, BACK. Columns: neutral standing; both empty hands lifted overhead with body leaned back; hands driven forward/down with knees bent and torso deeply forward; arms lowering and body returning upright. Feet fixed, no tools or effects in the source. 实际生成左右行颠倒，由资源映射显式修正。

Crouch: four columns/four rows, south/left/right/back. Columns: relaxed stand; squat with one arm reaching forward/down; low crouch pulling upward with empty hands; stand and hold hands near chest. Body lowers substantially, feet stay on baseline. No tools/crops/effects.

Offer: four columns/four rows, south/left/right/back. Columns: neutral; raise both empty hands in front of chest; extend both hands forward at waist height with slight forward lean; draw hands back. Offering/holding action, not walking or crouching.

### 居民

Four columns/four rows of each same character. Rows front/left/right/back, no face on back. Columns left foot extended, passing, right foot extended, passing with opposing arms. Consistent feet baseline, transparent empty margin.

Florist: female florist, long auburn braid, sage dress, cream apron with crossed straps and pink flower in hair. Shopkeeper: middle-aged man, short dark brown side-parted hair, small mustache, cream sleeves, rust waistcoat, forest-green apron tied behind, dark trousers/brown shoes. Fisherman: older man, gray hair/beard, navy knit cap, ochre yellow fisher jacket, muted teal trousers and rubber boots; rear view shows hat and jacket, no beard.

### 居民静止

For each resident, create a dedicated 1-column by 4-row idle atlas using the corresponding walk sheet as the strict identity, palette, clothing and camera reference. Rows are front, left, right and back. Every pose stands completely still with both feet planted side by side at equal height, balanced neutral weight, straight relaxed legs, no extended foot, lifted heel, arm swing or walking gesture. Preserve the florist's flower basket, braid and crossed apron straps; the shopkeeper's mustache, waistcoat, green apron and back knot; and the fisherman's beard, knit cap, hood, yellow jacket and rubber boots. The back row has no visible face. Final selected outputs were background-extracted to real alpha and normalized to equal 256 px cells.

### 地表

Exactly 2 columns and 2 rows, equal square tiles filling whole image without gaps/borders. Upper left seamless muted sage grass with subtle pixel clusters, no large objects; upper right warm beige compacted dirt path; lower left rich brown cultivated soil and horizontal furrows; lower right calm teal pond water with sparse horizontal ripples. Low contrast and readable behind small characters, no photoreal noise/neon green/diagonal water grid.

### 连续世界地表 v6

来源：内置 `image_gen` 生成的原创 1254×1254 不透明图集，存放为 `terrain_atlas_v6.png`。四象限分别是自然草甸、赭金土路、深棕耕土、蓝绿色池水；每象限提供 8×8 个纹理变化块，由连续世界 renderer 按世界坐标采样。没有复用《星露谷物语》截图或游戏内贴图。实机使用最近邻采样；素材初次接入后仍需根据五区、四季场景的实际综合色调继续逐区校正。

提示词规格：Create an ORIGINAL seamless pixel-art terrain atlas for a cozy top-down farming life game. Request a square 1024x1024 opaque RGB image. Divide it into exactly four equal edge-to-edge quadrants: top-left grass meadow; top-right worn ochre dirt path; bottom-left rich tilled farm soil; bottom-right calm deep teal pond water. Each quadrant is a seamless 8-by-8 field of square variations. Use crisp hard-edged pixel clusters, no blur, antialiasing, gradients, perspective, borders, labels or cross-quadrant objects. Grass uses natural spring greens and restrained olive/sage shadows with sparse blades and tiny clover flecks; path uses warm earth, small pebbles and edge grass; soil has coherent furrows and light clods; water uses muted blue-teal with short pale ripples. Keep a consistent 16-bit hand-crafted top-down scale and invisible repeat edges. The generator returned 1254×1254; the sampler already divides the actual image size into four equal quadrants.

v7 画面复核：v6 实机中的植物纹样和橙黄色土路与现有环境叠加后显得偏密、偏亮；内置 imagegen 在保留版式/耕地/水面约束下生成 v7，调低草地与土路饱和度并减少小装饰。运行时切换到 v7，v6 保留为非运行时迭代版本，等待后续美术整体调色时再复审。

### 建筑

Exactly two columns/two rows, four isolated building sprites, same orthographic three-quarter overhead perspective, front south-facing facade. Top left honey timber farmhouse with slate blue gable, stone foundation, central oak door, flower boxes. Top right cream timber general store with green roof, sage striped awning and produce baskets. Bottom left ivory clinic with sage roof and green cross. Bottom right cafe with terracotta roof and coffee cup sign. Central doors near bottom of each sprite, no long stairs, no surrounding ground patch, transparent outside footprint.

### 道具

Exactly four columns/two rows. Row 1: leafy oak with visible trunk; flowering hydrangea; circular stone fountain with teal water/spout; timber roofed noticeboard. Row 2: wooden shipping crate; stone well with timber roof/bucket; wooden bench; warm iron lamp post. Consistent top-down RPG perspective and warm detailed pixel shading. Whole objects fit equal cells, transparent margins, no labels/ground patches.

### 背包农场物品

原创SVG像素图集 `backpack_goods_v1.svg`，7列×4行、每格32×32；依次放置四种果实、鸡蛋/鸭蛋/牛奶、三种加工品、八道料理、洒水器和三类加工设施、四种果树苗。图标通过 `GOODS_ICON_INDEX` 显式映射到背包物品ID，每格独立裁切；鸭蛋保留原有专属插画。像素轮廓、暖土色阴影与项目已有背包物品保持同一手绘比例，不包含名称文字。

### 沙滩场景道具

生成日期：2026-09-24，内置 `image_gen`。提示词规格：Create an original transparent pixel-art atlas, exact 4 columns × 2 rows, for a cozy top-down farming RPG beach. Cells contain coastal dune grass, a shallow tide pool with rocks and shells, a teal-roof timber fishing hut with no sign or text, a short wood fishing dock, driftwood and shells, a wind-shaped coastal shrub, a fishing net rack and basket, and folded parasols with a beach blanket. Handmade crisp 16-bit pixel art, warm restrained palette, one shared orthographic view and lighting, one complete isolated object per cell, no characters/background/UI/text/grid and no borrowed game art. Generator output is 1774×887 RGBA; runtime regions divide the actual image size into 4×2 equal frames.

### 社区会堂修复状态

生成日期：2026-09-24，内置 `image_gen`。提示词规格：Create an original transparent 2-column × 1-row pixel-art building atlas. Both frames show the same town community hall from the same elevated 3/4 view, with the same door, windows and footprint. The left frame is an abandoned hall with a damaged blue-teal roof, weathered timber, boarded window and tiny weeds; the right frame is the same building fully repaired, with clean blue-teal shingles, fresh plaster and timber, open windows, flower boxes and a blank clock face without numbers or lettering. Crisp 16-bit cozy farm-sim art, no copied game assets, no text, no broad ground plate or shadow. The 1983×793 RGBA output is divided at runtime into two equal states. The repaired frame is selected only when all four existing donation bundles are complete.
