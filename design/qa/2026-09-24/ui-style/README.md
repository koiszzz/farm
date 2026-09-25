# 旅行手册页面实机检查

`inventory.png`、`character.png`、`map.png`、`region-map.png`、`settings.png` 和 `shop.png` 由 `scripts/ui_style_capture.gd` 在 Godot 4.7.1 Windows 独立窗口捕获。本轮刷新使用 NVIDIA RTX 3050 的 D3D12 渲染器。

2026-09-24 D3D12更新：背包、角色卡、地图和设置共用 `farm_ui_skin.gd` 定义的原创像素木框、九宫格纸底和木质标题带；地图视口高度同步压缩，让全域图、区域切换与图鉴入口完整显示。未使用星露谷UI截图或贴图。

- `map.png` 是五区全域旅行图，展示原创像素谷地底图、当前区域标记和五个详细地图入口。
- `region-map.png` 保留单一区域的地形/水域/道路概览与出口位置。
- 背包最新布局与详情面板截图、输入/视觉测试结果见相邻目录 `../inventory-rework/README.md`。
- `character.png` 的五项技能采用两列纸质技能卡；角色资料卡按三列紧凑排列，并显示钓鱼装备。`settings.png` 中的三档窗口尺寸、全屏切换、音量和操作速查及返回按钮都位于画面内。
- `character_settings_ui_test.gd` 在隔离存档/显示配置下验证角色卡与设置页边界、资料卡水平排布、技能数量/排布/宽度、无滚动、音量写入和新游戏实例读取配置；14项通过，headless 与 D3D12 均为0失败。实机捕获布局尺寸见 `scripts/ui_style_capture.gd` 输出的 `UI_LAYOUT`。
- 最近一次 D3D12 捕获：角色卡内容高375px/可用375px，设置页高374px/可用374px；两页无需竖向滚动，地图全域页完整显示五区入口和鱼类图鉴按钮。截图为当前同名 PNG。

路线图拓扑自动检查见 `scripts/map_overview_test.gd`；14项通过，覆盖五个地图区域、真实出口方向、当前位置归属、室内映射和区域按钮不会移动玩家。
