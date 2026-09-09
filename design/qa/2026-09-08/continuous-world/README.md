# 连续大世界、显示与四季扩展

## 实现结果

- 户外大地图为 `valley_world`，248×112 格。原农场、小镇、河畔坐标被保留并平移到同一世界。
- 小镇和农场之间增加西林、溪桥林道及河流缓冲带；农场东侧增加北湖、南湖与通往河畔的乡间道路。
- 户外区域没有 `exit_record`，跨区域移动不更换地图 ID。室内仍独立加载。
- 地面只绘制玩家周围 65×45 格；物件按 8 格流送块刷新；碰撞只建立周围 61×41 格。
- 道路全部使用同一黄色土路素材。河流和湖泊使用不规则轮廓，并在四邻边界绘制泥岸、亮边、碎石和斜切拐角。
- 普通移动状态不再显示格子坐标。居民头顶不再显示姓名；姓名仅在对话、居民册和任务中出现。
- 早晨小镇可出现至少 7 位居民；总居民从 3 位扩展到 10 位，并继续使用时间、天气和工作地点日程。
- 窗口基准提升到 1280×720；默认窗口为推荐档 1536×864。显示面板提供 1280×720、1536×864、1920×1080 和全屏，F10/F11 快捷操作。
- 作物由 4 种扩展为 20 种。春夏秋冬均至少 4 种，种子铺只出售当季种子；玉米可跨夏秋继续生长。
- 农田运行状态已覆盖：未耕、耕后干土、耕后湿土、作物干土、作物湿土。冬季草地、道路、农田和树木参与积雪/褪色。
- 四季各自拥有成熟作物素材；春、夏、秋、冬截图来自实际播种、浇水和日期推进。
- 旧版局部地图存档首次载入时转换为连续世界坐标，使用 `world_layout=2` 防止重复迁移；旧农田记录不会丢失。

## 依据

- 作物季节分类：[Stardew Valley Wiki - Crops](https://wiki.stardewvalley.net/Crops)
- 四季结构：[Stardew Valley Wiki - Seasons](https://wiki.stardewvalley.net/Seasons)
- 天气随季节变化：[Stardew Valley Wiki - Weather](https://wiki.stardewvalley.net/Weather)

这里只借鉴季节、种植和连续区域结构。名称、地图布局、角色、规则数值与美术均为本项目实现。

## 实际验证

- `continuous_world_test.gd`：连续地图、缓冲道路、跨区路径、水岸边界、动态渲染/碰撞、人口、无头顶姓名、无坐标框、20 种作物、五种农田状态、夏秋跨季、旧存档迁移、三档窗口和全屏。
- `seasonal_showcase_capture.gd`：实际窗口生成四季作物截图。
- 回归：`game_smoke_test.gd`、`farm_state_test.gd`、`life_system_test.gd`、`action_system_test.gd`、`movement_input_test.gd`、`spatial_consistency_test.gd`、`navigation_motion_test.gd`、`map_data_test.gd`、`world_travel_test.gd`、`homestead_gameplay_test.gd`。
- QA 使用独立存档和显示设置路径，没有覆盖玩家存档或显示配置。

## 仍有限制

- 目前是 2D 连续大地图的第一版，分块流送针对地表、物件和碰撞；尚未实现磁盘级异步区块资源包或跨世界传送。
- 新居民复用现有三套基础行走素材并做颜色变化，人口与日程已扩展，但角色专属肖像和独立建筑仍可继续增加。
