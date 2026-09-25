# 主角步态 v4 与连续移动测量

`farmer_walk_v4.png` 是项目当前运行中的原创8×4行走图集。四向32个姿势使用可见帧高度归一，实机阵列和路径截图用于复核人物尺度、姿势和镜头构图。

## 画面与步态

- `live-cycle.png`、`live-run-cycle.png`：Windows/D3D12中四方向走路和跑步画面。
- `world-walk.png`：48格连续世界的实际绘制截图。
- `world-walk-before-stream-check.png`：碰撞流送诊断改动前保留的回放截图。
- `movement-performance-stream-diagnostics.json`：D3D12确定性回放，分别记录正常绘制和隐藏世界绘制时的帧间隔。
- `performance-before-v4.json`、`performance-before-stream-check.json`：早期步态版本及碰撞队列测试前的测量保留件。

## 本轮性能读数

显示世界时，48格/720帧回放P95为11.23ms、P99为11.48ms，最大532ms，5帧超过25ms；隐藏世界绘制后P95为11.33ms、P99为11.67ms，最大524ms，6帧超过25ms。慢帧的移动调用约0.12–0.34ms，碰撞队列调用最高0.38ms，其余间隔落在`process_frame`等待/呈现部分。

这次是固定步长脚本回放，不等于前台人工试玩或正式构建帧率结果。隐藏世界绘制后相同尖峰仍在，因此来源仍未确定；不能据此说渲染、碰撞或项目代码已经被排除，也不能宣称卡顿已修复。下一步要在真实前台窗口和独立运行主场景中继续采样。
