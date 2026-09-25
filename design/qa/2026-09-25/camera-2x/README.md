# 五区域近景取景复核

对照《星露谷物语》官方媒体截图与各区域资料，检查角色在场景中的占比、区域入口地标及可行走路线。参考仅用于构图和玩法布局观察；没有下载或导入原作图像、地图或素材。

参考来源：[官方媒体截图](https://www.stardewvalley.net/media/)、[鹈鹕镇](https://stardewvalleywiki.com/Pelican_Town)、[农场地图](https://wiki.stardewvalley.net/Farm_Maps)、[沙滩](https://wiki.stardewvalley.net/The_Beach)、[采矿](https://wiki.stardewvalley.net/Mining)。

使用 Godot 4.7.1、Windows D3D12 / NVIDIA RTX 3050、1536×864 游戏窗口采集，默认镜头为 2.00×。为了检查世界画面，捕捉时隐藏了会在场景切换后出现的短时提示和靠近交互提示；正式 HUD 与快捷栏仍显示。

| 区域 | 实机画面 |
| --- | --- |
| 农场 | `farm_outdoor.png` |
| 沙滩 | `beach.png` |
| 小镇 | `town_square.png` |
| 山洞 | `cave.png` |
| 郊外 | `countryside.png` |

复核发现郊外原农场入口落在地图东缘，近景镜头会把角色推到屏幕右侧。现把郊外东侧林道延展到新的农场出口，并把入口路标放到到达点附近；五区入口均以 2.00×重拍。郊外路标依然通过近身阅读面板提供方向信息，地面和角色上方没有地点文字。
