# 紧凑游戏 HUD 与像素菜单实机截图

Godot 4.7.1 / Windows / NVIDIA RTX 3050 / D3D12。`ui_style_capture.gd` 在 1280×720 窗口捕获游戏 HUD、背包、角色卡、全域地图、分区地图、设置和商店。

本轮将主 HUD 从双行 84px 顶栏改为单行 58px；地点、日期/时间、天气、金币、体力与生命仍常驻显示。永久操作说明移出场景，农场中只显示当前种子与水量；快捷栏继续显示当前选择。设置、背包、角色卡与地图沿用花溪原创纸本/木框像素样式。随后设置页加入可实时切换并保存在 display.cfg 的三档镜头距离（1.50×、1.75×、2.00×），作为玩家在人物细节与视野范围之间的选择；面板高度同步适配 1280×720，确保返回按钮不被快捷栏遮挡。

窗口截图：`gameplay-hud.png`（初次引导提示）、`gameplay-hud-clear.png`（提示淡出后）、`inventory.png`、`character.png`、`map.png`、`region-map.png`、`settings.png`、`shop.png`。快捷栏物品名称只在鼠标悬停对应格时显示，未选中悬停时不占用屏幕。

背包实机图中的物品格现会在图标右下方显示堆叠数量，空格和单件工具不绘制数字；快捷栏堆叠物品也使用同一位置的数量标记。物品名和说明仍留在固定检查面板中，不在格子上常驻显示。

验证：`character_settings_ui_test.gd` 19项、`inventory_visual_test.gd` 200项、`inventory_input_test.gd` 11项、`map_overview_test.gd` 25项、`regional_world_test.gd` 334项均0失败；`game_smoke_test.gd`通过。设置、背包、人物卡和地图使用 1280×720 D3D12 实机捕捉；更大窗口仍需单独目视检查。
