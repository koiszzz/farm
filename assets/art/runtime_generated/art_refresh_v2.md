# 美术资源 v2 / 地图美术 v4

生成方式：内置 `image_gen`。以下最终选定资源均已复制到此目录供游戏直接加载，未改写旧源图。人物/道具/建筑为带 alpha 的 PNG；地表为不透明纹理。人物留白差异由 `scripts/sprite_atlas.gd` 运行时切片、脚底对齐，不拉伸单帧身体高度。

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
| terrain_atlas_v4.png | 2列2行；草地、土路、耕地、水面；地图连续采样纹理区域 |
| village_buildings_v4.png | 2列2行；农舍、种子铺、诊所、咖啡馆；门扇按立面位置动画 |
| village_props_v4.png | 4列2行；树、花丛、喷泉、公告板、出货箱、水井、长凳、路灯 |

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

### 建筑

Exactly two columns/two rows, four isolated building sprites, same orthographic three-quarter overhead perspective, front south-facing facade. Top left honey timber farmhouse with slate blue gable, stone foundation, central oak door, flower boxes. Top right cream timber general store with green roof, sage striped awning and produce baskets. Bottom left ivory clinic with sage roof and green cross. Bottom right cafe with terracotta roof and coffee cup sign. Central doors near bottom of each sprite, no long stairs, no surrounding ground patch, transparent outside footprint.

### 道具

Exactly four columns/two rows. Row 1: leafy oak with visible trunk; flowering hydrangea; circular stone fountain with teal water/spout; timber roofed noticeboard. Row 2: wooden shipping crate; stone well with timber roof/bucket; wooden bench; warm iron lamp post. Consistent top-down RPG perspective and warm detailed pixel shading. Whole objects fit equal cells, transparent margins, no labels/ground patches.
