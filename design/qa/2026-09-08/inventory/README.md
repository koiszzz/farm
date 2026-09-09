# 背包与快捷栏验证

## 完成范围

- 背包初始为 25 格、5 列展示，可每次扩展 5 格且不设扩展次数上限。
- 背包物品支持拿起后放入任意格，目标非空时交换位置。
- 10 格快捷栏支持从背包设置任意物品，数字键 `1`–`9`、`0` 对应十格。
- 工具按数字键立即使用；食物立即食用；种子、材料等普通物品不执行使用行为。
- 说明默认隐藏，仅在鼠标悬停或键盘选择符选中物品后按 `I` 展开。
- 所有背包格与快捷栏格分别保持严格等宽等高；静止格子只显示图标，快捷栏额外保留数字键。
- 鼠标悬停或键盘选择符选中时显示轻量悬浮信息；移开后恢复到当前选择符信息，完整说明仍由 `I` 打开。
- 鱼竿、木材、石料、野莓、蘑菇和溪鱼使用独立透明像素缩略图；镰刀复用工具图集缩略图。
- 背包容量、任意格位置、快捷栏设置和当前快捷栏格写入现有存档；没有布局字段的旧存档仍可读取。

## 自动验证

- `inventory_state_test.gd`: 12 checks, 0 failures。
- `inventory_input_test.gd`: 8 checks, 0 failures，使用 Godot 真实输入事件验证 `I`、`Esc`、`1`、`9`、`0`。
- `life_system_test.gd`: 73 checks, 0 failures。
- `homestead_gameplay_test.gd`: 49 checks, 0 failures。
- `continuous_world_test.gd`: 44 checks, 0 failures。
- `action_system_test.gd`: 0 failures。
- `game_smoke_test.gd`: passed。
- Godot 4.7.1 editor parse: passed。
- `inventory_visual_test.gd`: 86 checks, 0 failures。

## 实际渲染

- `backpack-grid.png`: 1280×720 下完整显示 25 格背包与 10 格快捷栏。
- `item-details.png`: 按 `I` 后右侧说明区展开，背包格仍保持完整。
- `ten-slot-hotbar.png`: 游戏画面底部完整显示十格快捷栏。
- `visual-capture.log`: D3D12 / NVIDIA GeForce RTX 3050 实际游戏帧渲染成功，并检查统一格子尺寸、隐藏常驻文字、悬浮信息、7 类原缺图物品缩略图及透明边缘。
