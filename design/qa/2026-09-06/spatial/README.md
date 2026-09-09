# 人物与场景空间一致性

- 静止使用行走素材的中立帧，四方向保持相同人物、比例和脚底锚点。
- 踩到四栋建筑的入口格自动开门进入，室内出口自动返回。F 仍可与设施互动。
- 导航 JSON 的 blocked 是地面占地；objects.visual_rect 是美术投影范围。屋顶、树冠及家具上部不参与阻挡。
- 物体与角色按脚底纵坐标排序，透明像素不算遮挡；被遮挡人物显示蓝绿色剪影和浅金色边缘。
- 四个室内采用同一 32 像素世界尺度和独立家具，家具间地面连通。

## 验证

Godot 4.7.1 实际运行，OpenGL Compatibility 帧缓冲截图保存在本目录。

通过：game_smoke_test、action_system_test、movement_input_test、map_data_test、spatial_consistency_test、world_travel_test。

空间测试包括四方向静止/行走同帧身份、树根阻挡及树冠下实际移动、屋顶/池体碰撞分离、前后遮挡、所有室内可走地面连通。

旅行测试从出生点实际移动至四个室外出口、自动进入四个室内、行走两侧通道及全部家具交互点、自动出门返回。所有测试通过。git diff --check 通过。

关键截图：tree_behind.png、tree_front.png、house_behind.png、fountain_behind.png、interior.png、general_store_interior.png、clinic_interior.png、cafe_interior.png。

本次未改动或恢复已被移除的 addons/godot_ai；截图来自独立游戏进程的 Viewport 帧缓冲，非编辑器视口。
