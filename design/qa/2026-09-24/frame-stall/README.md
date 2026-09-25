# Windows窗口帧停顿隔离采样

设备：Windows、Godot 4.7.1、NVIDIA GeForce RTX 3050 Laptop GPU、1536×864窗口。窗口测试时焦点保持在Godot。采样脚本每次等待一个 `process_frame`，测量帧间墙钟时间；窗口模式每组720帧。

| 环境 | 同步模式 | P95 | P99 | 最大帧间隔 | 超过25毫秒 |
| --- | --- | ---: | ---: | ---: | ---: |
| D3D12窗口 | 项目默认 | 11.2 ms | 11.4 ms | 522.8 ms | 5 |
| D3D12窗口 | 关闭垂直同步 | 7.3 ms | 7.8 ms | 531.7 ms | 6 |
| D3D12全屏 | 项目默认 | 33.6 ms | 533.7 ms | 555.8 ms | 201 |
| OpenGL Compatibility窗口 | 项目默认 | 11.2 ms | 11.3 ms | 517.2 ms | 3 |
| OpenGL Compatibility窗口 | 关闭垂直同步 | 6.7 ms | 6.9 ms | 516.3 ms | 4 |
| OpenGL Compatibility全屏 | 项目默认 | 25.3 ms | 508.0 ms | 530.7 ms | 130 |
| headless | 不适用 | 15.8 ms | 16.1 ms | 16.5 ms | 0 |

游戏移动测试里，移动函数约0.1–0.2毫秒，碰撞队列通常低于0.4毫秒；等待 `process_frame` 的尾部约0.52秒。保持窗口焦点、关闭垂直同步、隐藏世界绘制，或关闭整个游戏场景树的脚本回调，尖峰仍然存在。两个图形驱动都复现；最小空窗口也复现，而headless不复现。全屏帧时更差。

**当前结论：** 测量结果不支持把停顿归因于玩家移动、碰撞流或地图绘制；问题出现在Windows图形窗口的主循环/呈现路径中。仅凭本机证据还无法区分Godot Windows窗口处理、显卡驱动与宿主窗口合成/调度。未修改项目的渲染器或游戏逻辑来掩盖此停顿。需要在目标用户设备、不同Windows/显卡驱动环境及最终发布构建中复测，才能决定安全的运行时缓解方案。

数据：`bare-frame-pump-d3d12-fullscreen.json`、`bare-frame-pump-gl-compatibility-fullscreen.json`、`bare-frame-pump-headless.json`；游戏节点回调关闭时的数据在 `movement-performance-scene-callbacks-disabled.json`。复现脚本为 `scripts/frame_pump_profile.gd` 和 `scripts/movement_performance_test.gd`。
