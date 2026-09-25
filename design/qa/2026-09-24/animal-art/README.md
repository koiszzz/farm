# 鸡舍小鸡像素角色实机检查

- 素材：`assets/art/runtime_generated/chicken_walk_v1.png`，4列×4行，方向为下、左、右、上
- 运行时：`scripts/chicken_actor.gd` 根据漫步距离选择步态帧，保留影子与抚摸爱心
- 实机：Godot 4.7.1、Windows D3D12、RTX 3050
- `chicken-pen.png`：养殖玩法测试实际截图；覆盖围栏、鸡只、玩家和农场地表
- `duck-directions.png`：鸭子通过实际农场角色同步后，使用同一 `DuckActor` 做四方向16格渲染检查
- `cow-pen.png`：牛棚实机截图，包含独立四向图集、实际漫步与抚摸反馈
- 自动覆盖：`animal_gameplay_test.gd` 46项，0失败
- 鸭子映射与步态覆盖：`duck_actor_test.gd` 40项，0失败
- 奶牛、牛舍经营与图集步态覆盖：`barn_gameplay_test.gd` 59项，0失败（headless、Windows D3D12均通过）

小鸡图像生成尺寸1774×887，4×4切片边缘有1像素差；所有小鸡仍共用同一白羽外观。鸭子各帧动作差异仍需进一步加强。

鸭子现在使用绿色头部、棕色胸部与蓝绿色翼斑的独立图集；首张候选的相邻图格残片已在[筛选记录](../rejected-walk-atlases/README.md)中留档，没有进入运行版。奶牛现使用深棕花斑四向图集，牛舍实机画面确认透明背景、漫步和抚摸反馈正常；步姿变化和比例仍需加强，奶牛花色变化尚未制作。
