# 美术、动作和地图验收

2026-09-06，Godot 4.7.1，工程 `E:/project/farm`。

## 需求与证据

| 需求 | 已实现行为 | 当前证据 |
| --- | --- | --- |
| 人物走路、跑步不生硬 | 八帧四方向步态，跨格连续，按实际距离推进；正常 128 px/s，Shift 跑步 211.2 px/s，跑步加大步幅并前倾；停止、碰撞不继续踏步 | `movement_input_test.log`：同一输入时段行走 25.60 px、跑步 39.04 px；挡墙步态不推进 |
| NPC 走路与跑步 | 三位居民各自四方向四帧图集；按移动距离推进，取消每格停顿；路线起点休息、靠近玩家停下，雨天或傍晚加快为赶路姿态 | `life_system_test.log` 路线/居民交互通过；`movement_input_test.log` 傍晚跑步通过；`town.png` |
| 朝上背面与人物/服装一致 | 玩家和三位 NPC 均有真正背面；玩家各动作有背面关键帧；发型尾部、发髻、围裙背带、背包、雨衣等附属细节跟随角色，配色作用于各方向 | `action_system_test.log` 独立背面行检查；`appearance_gallery.png`、`action_gallery.png`、`farm_back.png` |
| 耕地、播种、浇水、采收 | 挥下、蹲下、握持三组四方向身体关键帧，手部工具和水滴等效果；准备—接触—回收，接触时只提交一次事务，动作期间阻止冲突输入 | `action_system_test.log` 接触前后体力/土地、重复输入检查；`game_smoke_test.log`、`farm_state_test.log`；`water_action.png` |
| 镰刀收割 | 5 选择镰刀，独立镰刀弧线与挥下动作，接触时收获面前成熟作物 | `action_system_test.log` 镰刀姿态和成熟作物入库检查 |
| 钓鱼 | 6 选择鱼竿，岸边面向水面 E 抛竿；等待 2 秒后咬钩，1.4 秒窗口内 E 提竿；超时失鱼，Esc 收竿；鱼获进背包并保存 | `action_system_test.log` 干地拒绝、抛竿、等待、咬钩、提竿、超时和磁盘恢复；`riverside_fishing.png` |
| 送礼 | G 选择礼物，关闭面板后递出，接触阶段交出物品，动作后显示回复；保留原有每日/喜好/生日规则 | `action_system_test.log` 接触前不扣、接触后仅扣一次、回复与磁盘恢复；`life_system_test.log` 原有社交规则 |
| 地图无法离开房屋周围 | 碰撞脚底与格子中心一致；城镇到达点由返回出口上的 (42,22) 移至 (41,22)；独立出口双向通行 | `navigation_motion_test.log`；`world_travel_test.log` 从出生点沿实际物理路径走完四条区域路线 |
| 大地图重设计 | 农场扩为 64×44，保留原农田和存档坐标；新增南侧园路、东侧河畔道路、树木、水井与出货箱；新增河畔区域；连续地表和广场，M 显示区域地图和当前位置 | `map_data_test.log`；`world_map.png`、`town.png`、`farm_back.png`、`riverside_fishing.png` |
| 房屋重新设计并能进出 | 四栋独立透明建筑新图集；站门口或面向相邻门按 F；开门 0.28 秒、人物过门淡出/淡入、关门 0.28 秒，期间防止重复输入；室内走到南门返回 | `world_travel_test.log` 四栋建筑实际步行往返；`action_system_test.log` 开门前不跳图、到达关门/可见性；`door_open.png` 和四个室内截图 |

## 检查结果

八组测试均通过，退出码均为 0，同行 `.err` 文件为空：

- `map_data_test.gd`
- `farm_state_test.gd`
- `game_smoke_test.gd`
- `life_system_test.gd`：57 检查，0 失败。
- `navigation_motion_test.gd`：修复前出现围栏附近物理阻挡、到达点落在返回出口两项失败；修复后 0 失败。
- `action_system_test.gd`：事务时机、镰刀、钓鱼、送礼、开门及真实磁盘恢复。
- `world_travel_test.gd`：四条户外路径、四栋房屋往返，0 失败。
- `movement_input_test.gd`：使用 Godot 输入事件队列发送按键，刷新缓冲后驱动实际移动逻辑。

运行方式：`Godot --headless --path E:/project/farm --script scripts/<test>.gd`。

## 画面验证方式

`motion_visual_capture.gd` 在真实独立游戏进程中实例化 Main 场景，使用项目默认 **D3D12 / Forward+**、RTX 3050，读取渲染后的游戏 framebuffer，保存十张场景帧。日志见 `framebuffer.log`，无渲染或脚本错误。截图场景使用隔离状态/指定动作阶段，不冒充连续手工通关。

`actor_gallery_capture.gd` 使用实际角色渲染器展示四方向动作和外观组合，是姿态与造型检查图。步态时序由输入和移动测试验证，图集本身不代替交互测试。

测试禁用正常自动存档；磁盘恢复用例写入独立 QA 文件，验证后删除该文件。原有作物与居民生活系统继续通过回归。

## 操作

WASD/方向键行走，Shift 跑步；1 锄头、2 种子、3 浇水壶、4 采收、5 镰刀、6 鱼竿；E 使用，F 门口/设施/居民互动，G 送礼，M 地图，I 背包，Tab 日历，C 外观，Q 换种，N 休息，F5 保存。F3 为开发用导航格显示。

新美术与生成提示词记录见 `assets/art/runtime_generated/art_refresh_v2.md`。
