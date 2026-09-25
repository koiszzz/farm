# 当前版本农舍往返复测与转场门闩修复

设备为 Windows / Godot 4.7.1 / RTX 3050 Laptop GPU / Forward+ D3D12 / i7-13700H。使用隔离存档和显示配置，连续执行30次农舍进出；当前版本包括五分区地图、镇区十位居民路线和独立跑步图集。样本与首个户外实机帧分别见 `door-stability-profile-current-forward_plus.json` 和 `first-stable-outdoor-frame-current.png`。

| 操作 | 输入就绪中位数 | P95 | 最大值 | 超过800ms |
| --- | ---: | ---: | ---: | ---: |
| 进入农舍 | 354.0ms | 824.7ms | 832.1ms | 2 / 30 |
| 出屋回到农场 | 332.9ms | 822.3ms | 827.9ms | 2 / 30 |

本次数据：`door-stability-profile-retry-forward_plus.json`，首个回到户外的D3D12画面：`first-stable-outdoor-frame-retry.png`。地图同步替换中位数：进入8.95ms、出屋19.41ms（P95分别15.58ms、20.67ms）；场景缓存最多2/3，户外地形块134–144。30次往返全部回到可操作场景。当前profile仍有一项阈值失败：进入和出屋各2/30超过800ms。

慢样本落在 `_enter_door()` 的转场/首帧呈现等待；场景替换本身没有同步尖峰（最大进入29.76ms、出屋37.45ms）。多个超过700ms的样本中，场景同步部分仍约9–20ms。结合 `design/qa/2026-09-24/frame-stall/README.md` 中同一设备、D3D12窗口反复出现的约0.52秒帧间停顿，当前尾延迟更像Windows图形窗口主循环停顿叠加动画/首帧等待，而非NPC路线或地图同步构建；这属于跨剖分推断，不证明每个慢样本均来自同一帧停顿。没有仅为达到阈值而缩短或掩盖转场。

上一轮重叠版profile在 `door-stability-profile-current-forward_plus.json`：进入中位数410.9ms、出屋345.0ms，P95仍约822ms。当前重跑中位数分别为354.0ms和332.9ms；尾部仍被窗口呈现尖峰控制，尚不能声称达到暖返回≤0.8秒目标。后续要在目标用户设备和发布构建复测窗口帧停顿。

## 转场重叠与门闩信号竞态修复

在30轮实机复测前发现遮屏与门动画并行时存在竞态：`Tween.finished` 可能在遮屏结束前发出，而转场函数随后才开始等待该信号，导致黑屏永不揭开。修复前的实机窗口证据为 `stuck-black-transition-before-fix.png`。现在转场在遮屏后先检查门动画Tween是否仍运行；已完成就继续切图，仍运行才等待信号。Godot [Tween API](https://docs.godotengine.org/en/stable/classes/class_tween.html) 将 `is_running()`定义为尚未结束的运行状态，当前实现据此避免等待已错过的完成事件。

`door_transition_test.gd` 新增“门Tween在转场等待开始前已完成”的回归，0失败；`game_smoke_test.gd`通过。修复后实机完成30轮、0轮卡黑。Profile每阶段会写一个 `.partial.json` 检查点，最终报告成功落盘后自动清除临时文件。
