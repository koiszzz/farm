# 村民四朝向静止姿势验证

- `npc_idle_down.png`、`npc_idle_left.png`、`npc_idle_right.png`、`npc_idle_up.png` 由 `scripts/npc_idle_visual_capture.gd` 在真实 Godot D3D12 游戏 viewport 中截取。
- 每张图由左至右依次展示花匠、店主、渔夫；四个方向均读取各自独立的静止图集。
- `scripts/spatial_consistency_test.gd` 对三位村民共 12 个静止方向检查有效像素、资源绑定，以及静止/行走纹理分离。
