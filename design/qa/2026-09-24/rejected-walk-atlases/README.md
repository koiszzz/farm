# 未采用的居民行走图集候选

这两张候选经过 Godot `ArtActor` 四方向实机切片后未进入运行版：镇长图在列阵中主要姿势重复；医生图在图格边缘有游离红色像素。保留在 QA 目录仅作后续重画参考，不是正式运行时资源。

- `mayor_walk_candidate.png`：镇长4×4候选
- `doctor_walk_candidate.png`：医生4×4候选
- `duck_walk_cell-bleed.png`：首张鸭图候选；D3D12切片出现相邻图格残片，已由修订版替换
- 实机结果：`../mayor-walk-v1/live-cycle.png`、`../doctor-walk-v1/live-cycle.png`
- 镇长相邻帧差异报告：`../mayor-walk-v1/frame-analysis.json`
