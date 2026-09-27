# 用户生成素材库登记

素材来源：`C:\Users\hsysa\.codex\generated_images\01a0d758-fdf1-7290-99d6-5ac0bcd5d692`

本次替换只从该素材库选用已有图像，不重绘样式。原图副本保存在本目录，运行时所需的单体建筑与性别动物图集由 `design/qa/2026-09-26/reference-art/prepare_user_reference_art.gd` 从副本确定性拆分，避免手工改画。

| 本地原图副本 | 内容 | 已输出/接入 |
| --- | --- | --- |
| `user_reference_building_board_v1.png` | 一级至三级农舍、鸡舍、畜棚；筒仓、修复/完整温室、储物棚、马厩、磨坊、鱼塘 | 建筑按独立 PNG 裁出；一级农舍、鸡舍、畜棚已用于游戏 |
| `user_reference_chicken_gender_sheet_v1.png` | 公母鸡，四方向各四帧 | 公母图集已接入鸡舍活动动物 |
| `user_reference_duck_gender_sheet_v1.png` | 公母鸭，四方向各四帧 | 公母图集已接入鸡舍活动动物 |
| `user_reference_cow_gender_sheet_v1.png` | 公母牛，四方向各四帧 | 公母图集已接入畜棚活动动物 |
| `user_reference_sheep_gender_sheet_v1.png` | 公母羊，四方向动作 | 已切为公母图集；尚无羊的饲养系统 |
| `user_reference_goat_gender_sheet_v1.png` | 公母山羊，四方向动作 | 已切为公母图集；尚无山羊的饲养系统 |
| `user_reference_pig_gender_sheet_v1.png` | 公母猪，四方向各四帧 | 已切为公母图集；尚无猪的饲养系统 |
| `user_reference_horse_gender_sheet_v1.png` | 公母马，四方向各四帧 | 已切为公母图集；尚无马厩/骑乘系统 |
| `user_reference_dog_gender_sheet_v1.png` | 公母狗的四方向动作 | 已接入农场伙伴，面板可切换公母外观 |
| `user_reference_cat_walk_sheet_v1.png` | 四方向猫动作（原图未拆分公母） | 已接入农场伙伴，面板可切换猫/狗 |

建筑板为不透明合成图；切图时执行边界连通的深色底去除，保留各图独立透明画布。物种图集沿用原始格线与动作顺序，动物帧按位移累积切换。游戏现有存档缺少性别字段时会默认显示母性外观，新购买动物按同物种购入次序交替分配公母外观。
