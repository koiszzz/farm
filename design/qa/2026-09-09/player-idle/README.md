# 玩家四朝向静止姿势验证

- `idle_down.png`、`idle_left.png`、`idle_right.png`、`idle_up.png` 均由 `scripts/idle_pose_visual_capture.gd` 在真实 Godot 游戏 viewport 中以 4 倍镜头截取。
- 四个方向统一读取 `farmer_idle_v1.png` 的独立站姿，不复用 `farmer_walk_v2.png` 的迈步帧。
- 代码回归由 `scripts/spatial_consistency_test.gd` 检查：静止资源存在有效像素，且静止与行走纹理、裁切区域均不同。
