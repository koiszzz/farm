# NPC步行动作小样

2026-09-25 逐角色动画补齐前，市长首先验证了图集与运行时契约。随后木匠、医生、厨师、护林员、教师和孩子各自获得四向动作图。原始生成候选仅保留在本 QA 目录；运行时接入经过透明边界裁切和最近邻打包的图集。

- 布局：8列×4方向，1776×888，每格222×222。
- 统一锚点：四行步行帧的鞋底基线均为格子内 y=208，格底留14像素。
- 接缝检查：水平、垂直图格边界的不透明像素均为0。
- 运行时图：市长、木匠、医生、厨师、护林员、教师和孩子使用本目录记录的独立八帧图集；花商、店主和渔夫继续使用既有四帧图集。
- 运行时接入：十位居民移动时使用自己的行走图，站姿仍使用身份图；新增八帧角色按移动距离推进周期，原四帧角色的步频不变。
- 自动回归：`resident_crowd_test.gd` 检查十人各自图集、七套8×4图集224个方向/帧范围及步态相位，并模拟十位居民巡逻180秒；0失败，最近间距32px，拥挤样本0。
- D3D12捕捉：`resident_walk_down_phase.png` 展示十位居民同一时刻的实际渲染，`resident_cast_*.png` 检查四向站姿。

## 在线场景参考

- [星露谷官方媒体截图](https://www.stardewvalley.net/media/)及[Steam截图组](https://store.steampowered.com/app/413150/Stardew_Valley/)：用于观察角色、地标和活动区的画面比例。
- [沙滩窄海湾与渔屋](https://www.gamesradar.com/stardew-valley-update-gives-players-beach-farm-and-split-screen-co-op/)：观察沙滩、浅水和可交互建筑形成的分区。
- [山地湖岸与木桥](https://gamenews.es/los-mejores-lugares-para-pescar-en-stardew-valley/)：观察岸线、桥和钓鱼点作为可读目的地的组织方式。
- [五区转译原则与已实现构图](../../../references/2026-09-24/STARDEW_SCENE_STUDY.md)。参考图只用于研究，没有复用游戏内素材。
