# 房屋门与明暗过渡验证

## 实现结果

- 连续大地图中的门不再以人物脚下格为默认位置；运行时按入口目标找到建筑对象，并把动画固定到建筑原图的门框区域。
- 动画直接裁取 `village_buildings_v4.png` 中对应房屋的门像素：农舍右侧内旋、杂货店侧滑、诊所左侧内旋、咖啡馆双扇折叠。
- 室内不绘制出口门动画。旧的统一大地毯不再显示，入口小地毯由外部门宽按比例计算，并使用对应建筑配色。
- 进屋与出屋都会先完全黑屏；场景在黑屏下切换，再从画面中心向外扩散亮区。
- 地图切换先设置人物落点再重置相机平滑，展开首帧已对准实际门内/门外位置，不会短暂照到旧坐标对应的无关区域。

## 实际帧缓冲

- `01_farmhouse_closed.png`：原始农舍门与自动入口位置。
- `door_*_opening.png`：四栋建筑各自的门框内动画中间帧。
- `03_black_cover.png`：场景切换时的完整黑屏。
- `04_center_light_reveal.png`：新室内从中心向外展开的亮区。
- `06_exit_center_light_reveal.png`：不播放室内门动画，黑屏后由中心展开室外画面。
- `05_farmhouse_rug.png`、`rug_*_interior.png`：四种与外门尺寸及配色对应的室内地毯。

以上 PNG 均由 `door_transition_visual_capture.gd` 从实际 Godot 游戏 Viewport 保存，不是静态设计稿。

## 自动验证

- `door_transition_test.gd`：0 failures；覆盖连续大地图门锚点、四种动画、比例地毯、室内无门动画和双向中心光圈切换。
- `world_travel_test.gd`：0 failures；四栋房屋自动往返、室内通道和设施交互。
- `continuous_world_test.gd`：44 checks，0 failures。
- `game_smoke_test.gd`：passed。
- `action_system_test.gd`、`movement_input_test.gd`、`spatial_consistency_test.gd`、`navigation_motion_test.gd`：均为 0 failures。
- `map_data_test.gd`：passed。
- `git diff --check`：通过；只有现有工作区的 CRLF/LF 提示，无空白错误。
