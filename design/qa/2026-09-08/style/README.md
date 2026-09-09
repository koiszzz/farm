# 暖色像素农场视觉优化

参考用户提供的像素农场截图，使用原创生成地表图集 terrain_atlas_v5.png；不替换导航地图或玩家存档。

变化：鲜绿草地、金黄道路、青绿水面、暖棕耕地；道路不规则草边、零星野花；厚木围栏与木纹；农舍红瓦着色器（保留窗玻璃）、前庭花坛、物件底部阴影；木色 HUD 和羊皮纸提示面板。翻土沟槽由真实 tilled/watered 状态驱动。

Godot 4.7.1 / D3D12 实际运行：scripts/style_visual_capture.gd，关闭自动存档并使用独立 QA 路径。farm.png、fields.png、town.png、river.png 为游戏 viewport framebuffer 截图。runtime.log 无脚本或着色器报错。

验证：
- Game smoke test passed.
- Spatial consistency: 0 failures.
- Life systems: 57 checks, 0 failures.
- git diff --check（本次修改的两个既有脚本）通过。

范围限制：本轮提升地表和装饰风格，未增加动物、建筑种类或修改场景布局；场景密度仍低于参考。既有未提交修改与插件删除均予以保留。
