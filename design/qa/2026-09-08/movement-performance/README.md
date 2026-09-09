# 行走卡顿优化验证

验证环境：Godot 4.7.1，Windows，NVIDIA GeForce RTX 3050 Laptop GPU，连续大地图 `valley_world`。

## 结果

| 指标 | 优化前 | 优化后 |
| --- | ---: | ---: |
| 同步地图流送平均耗时 | 185.188 ms | 7.528 ms |
| 同步地图流送最大耗时 | 241.734 ms | 21.804 ms（首次远距离样本） |
| 实机连续行走 P95 帧耗时 | - | 11.809 ms |
| 实机连续行走 P99 帧耗时 | 15.181 ms（仍有分块尖峰） | 12.503 ms |
| 实机连续行走最大帧耗时 | 140.413 ms | 22.953 ms |
| 25 ms 以上帧 | 6 | 0 |

优化前的主要阻塞来自三处：每 7 格销毁并重建附近全部碰撞节点、每个地形分块边界重画约三千个格子、宠物每走一格重新计算完整 AStar 路径。

现在碰撞体使用固定池并只同步新进入/离开范围的格子；地形按 2×2 单元缓存，并在视野外逐帧预取；场景物件只创建一次；宠物复用整条路径，目标移动足够远时才重新规划。强制切换位置会立即补齐周边地形，正常走路则保持小批量加载。

## 验证

- `movement_performance_test.gd`：48 格实机连续行走，1081 帧，25 ms 以上尖峰为 0。
- `movement_input_test.gd`：0 failures。
- `continuous_world_test.gd`：无窗口 44 checks / 0 failures；实机 52 checks / 0 failures。
- `game_smoke_test.gd`：passed。
- `action_system_test.gd`：0 failures。
- `spatial_consistency_test.gd`：0 failures。
- `life_system_test.gd`：64 checks / 0 failures。

实机画面见 `walk-after.png`；逐帧与流送数据见 `latest.json`。
