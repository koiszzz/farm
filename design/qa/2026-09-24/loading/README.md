# 农舍往返实机稳定性采样

`door-stability-profile.json` 由 `scripts/door_stability_profile.gd` 在独立 Windows 图形进程执行，Godot 4.7.1、13th Gen Intel Core i7-13700H、RTX 3050 Laptop GPU、OpenGL Compatibility、1280×720。测试使用唯一临时存档/显示配置路径，不读取或覆盖玩家正常存档。

同一进程内完成30次农舍进出，共60次真实异步门转场；每次等待转场结束、释放一帧物理输入锁，并在出屋侧等到第一帧实际绘制。农舍进入室内输入就绪时间：中位数589.0ms、P95 614.1ms、最大616.3ms；出屋回到农场：中位数444.4ms、P95 455.9ms、最大478.2ms；两组均无样本超过800ms。同步场景切换分别为进入中位数13.8ms/P95 24.1ms、退出中位数32.6ms/P95 40.8ms，表明目前可见的大头仍是中心光圈转场，而不是地图同步构建。

30轮中场景缓存始终2/3，没有随往返累积；流送地形块节点数在126–130间变化。首帧捕获 `first-stable-outdoor-frame.png` 用于确认出屋后农舍、农田、玩家和HUD均已绘制。

以上是动画缩短前的农舍基线，只证明当时农舍暖进程转场达到≤800ms目标；其冷启动、其它室内、天气/时段和发布构建覆盖由下方“缩短转场后的复测”更新说明。

## 缩短转场后的复测

将门扇动画从240ms改为160ms，中心转场遮黑从80ms缩短为50ms、黑场停留从15ms改为10ms、中心显现从240ms改为160ms。门扇开启动画与完整遮黑后换场的顺序保持不变。

同设备与画面设置再次执行农舍30次往返。进入中位数399.9ms/P95 411.2ms，出屋中位数322.2ms/P95 344.2ms；相对旧基线中位数分别减少约32%和28%。60次过渡均成功，缓存最多2/3。完整样本在 `door-stability-profile-gl_compatibility.json`。

新增镇上三间室内计时：种子铺、诊所、咖啡馆各10次进入与退出，共60次过渡全部成功。进入中位数分别268.2ms、272.3ms、284.7ms；退出分别322.1ms、267.3ms、311.1ms。最高样本450.2ms，场景缓存最多3/3。设备、逐样本见 `town-indoor-stability-profile-gl_compatibility.json`，返回镇上的首帧见 `first-stable-town-frame.png`。

`door_transition_test.gd` 通过并确认四种门样式、开门后才遮黑、室内旧通用地毯隐藏及转场往返。测试从固定睡眠改为轮询门动画状态；运行中也修复了世界对象重建时将地毯重新显示的问题。上述数据只覆盖暖进程，冷启动、雨天/晚间/节日和发布构建仍未验证。

默认 Windows Forward+ / D3D12 路径也完成复测：农舍30次往返进入中位数398.7ms/P95 414.1ms、出屋344.2ms/P95 366.0ms；缓存2/3。镇上三家各10次往返，进入中位数为种子铺289.7ms、诊所294.4ms、咖啡馆284.3ms；出屋依次289.2ms、290.2ms、321.9ms，最高样本503.3ms，缓存最多3/3。全部转场成功，详细数据分别保存在 `door-stability-profile-forward_plus.json`、`town-indoor-stability-profile-forward_plus.json`。OpenGL Compatibility 的完整记录另存为同名 `-gl_compatibility.json` 文件。

## 新进程首次启动采样

用5个独立Godot图形进程按项目默认开档路径启动，使用默认 `farm_outdoor` 地图、不读取或写入正式存档，在Windows进程创建时开始计时，到首个实际绘制的农场画面时停止。Forward+ / D3D12进程到首帧中位数4639.7ms（范围4611.9–5899.6ms）；OpenGL Compatibility中位数3712.1ms（范围3686.0–5380.8ms）。内部脚本计时分别是D3D12：Ready 375.2ms、首帧569.7ms、首个输入帧1118.1ms；Compatibility：337.6ms、468.0ms、1114.1ms。全部10次进程均正常退出。

剖分说明：大约3.2–4.1秒花在Godot进程启动和项目/渲染器初始化、进入游戏脚本之前；游戏自身Ready约0.34–0.38秒。Compatibility中位数比Forward+低约20%，但还没有在发布包中核对启动速度、画面一致性和设备兼容性，因此暂不切换项目默认渲染路径。Windows进程启动数据与各次引擎细分时间见 `cold-start-process-profile-forward_plus.json`、`cold-start-process-profile-gl_compatibility.json`；实机首帧见 `cold-start-first-game-frame.png`。

此处测的是开发项目从Godot进程创建到首帧的时间，不是发布构建冷启动；也没有清空操作系统/驱动磁盘缓存。发布包、雨天/晚间/节日，以及真实存档恢复仍待单独验收。

## 正常分区模式的启动减载

项目日常以五张分区地图运行，但过去每次启动仍同步构建一份248×112格的 `valley_world` 合并地图；该字典只供连续世界模式与其测试使用。启动现在按运行模式选择地图构建：分区模式构建五个可玩区域，不创建 `valley_world`；连续世界模式仍完整构建该地图。旧版布局2的 `valley_world` 存档会先按静态区域拓扑换算回本地区域，不再要求开档前生成整张合并地图。

五个独立进程、Forward+ / D3D12、新逻辑路径的 SceneTree 入口至Game Ready中位数为332.7ms；此前五样本为375.2ms，下降约11%。首帧中位数从569.7ms降至526.2ms，输入检查点从1118.1ms降至1063.5ms；五次均确认没有合并地图、五个区域都已就绪。完整样本见 `cold-start-regional-profile-forward_plus.json`，初始五次基线仍见 `cold-start-process-profile-forward_plus.json`。单独分段分析显示，跳过的合并地图生成约需34–49ms；`navigation-data-profile.json` 留有五轮构建时间。

这项减少了游戏脚本启动和常驻地图数据量，但不会消除此前Windows进程启动至首帧约4.6–5.9秒的大部分等待；那段主要发生在SceneTree脚本执行之前。本次后测没有重新采样外部进程启动时间，也未测发布构建或最低配置设备。正常区域启动、旧布局2实际存档迁移与连续世界模式分别由 `game_smoke_test.gd`、`regional_world_test.gd` 和 `continuous_world_test.gd` 覆盖。
