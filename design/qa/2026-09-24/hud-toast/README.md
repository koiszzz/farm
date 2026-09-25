# 操作提示淡出实机复核

Godot 4.7.1、Windows、NVIDIA RTX 3050、项目默认 D3D12 渲染器。

- `toast-visible.png`：关闭路标阅读面板后显示操作反馈。提示使用既有纸色边框。
- `toast-hidden.png`：提示等待 4.5 秒并淡出后的同一场景；面板完全隐藏，场景不再被空提示栏覆盖。
- `signpost_interaction_test.gd`：窗口实机和 headless 各 67 项、0 失败，包含提示出现/消失；窗口日志无 `ERROR`、`SCRIPT ERROR` 或 `WARNING`。
- `game_smoke_test.gd`：headless 通过。

提示淡出只作用于短时操作反馈。顶部地点/日期状态、靠近物件时的互动提示和十格快捷栏仍按原逻辑显示。
