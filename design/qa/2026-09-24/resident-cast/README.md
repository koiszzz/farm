# 十位居民的独立外观

新增原创透明像素图集 `assets/art/runtime_generated/resident_idle_cast_v1.png`。每列对应一位居民，图集提供正面、侧面、背面三种基础静止造型；左右朝向复用侧面并由 Sprite2D 镜像。这样保留准确的岗位服饰与职业随身物，又避免模型未能稳定生成四行网格时把残缺帧接入游戏。

实机截图由 `npc_idle_visual_capture.gd` 在 Godot 4.7.1、Windows D3D12、NVIDIA RTX 3050 中运行产生。`resident_cast_down/left/right/up.png` 各显示十名角色同时朝向相同方向。对话肖像也使用各自图集列。旧的三套行走图仍在使用，其他七位的行走循环暂时复用花店主模板并分别着色。

验证：`spatial_consistency_test.gd` 通过；`resident_schedule_test.gd` 232项、`friendship_event_test.gd` Windows实机 174项、`game_smoke_test.gd`、`world_travel_test.gd` 均通过。截图仅用于QA；正式场景地面和人物头顶不显示姓名文字。
