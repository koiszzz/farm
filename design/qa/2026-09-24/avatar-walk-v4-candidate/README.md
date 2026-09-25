# 主角四向步态图集 v4 候选（未接入）

该候选由内置 ImageGen 根据现有主角图集作为造型参考生成，并保存到工作区供审查：`farmer_walk_v4-candidate.png`。它不是正式运行时素材；原 v3 仍由 `AvatarRenderer` 使用。

## 栅格与姿势审查

- 输出 1448×1086 RGBA；宽度可均分8列，每列181像素，但高度不能均分4行（271/272像素交替）。
- 32格中横向列缝没有不透明像素，行缝采样到857个不透明像素；多帧角色贴近格子上下沿，没有稳妥的透明隔离边距。
- 与 v3 相比，候选相邻帧的差异更明显：四方向最相似帧对分别为下0.9192、左0.9403、右0.9394、上0.9348。脚锚Y跨度为0、7、0、12源像素，运行时脚锚可部分校正，但帧边沿仍需人工逐格确认。
- 结论：不覆盖、不接入。需要保留更清楚的逐格透明余量并人工检查关键姿势后，才能进入运行时对照。

审查数据由 `scripts/avatar_walk_candidate_analysis.gd` 写入本目录 `frame-analysis.json`。

## 生成提示词

使用 Codex 内置 ImageGen 工具；以 `assets/art/runtime_generated/farmer_walk_v3.png` 作为主角造型参考。提交的最终提示词：

> Use case: stylized-concept. Asset type: original transparent 2D game sprite sheet for a top-down pixel-art farming life simulation. Create a polished full-body looping walk atlas for the original farmer in the reference, using only its character identity as guide: chestnut hair, teal work overalls, cream shirt, brown boots. Do not copy any existing game character or asset. EXACT canvas 1024x768, transparent RGBA, exactly 8 equal columns and 4 equal rows (128x192 pixels per cell), no gutters, grid lines, labels, or decoration. Exactly one farmer centered in each cell; same size/proportions throughout; foot baseline y=180 in each cell. Rows: face camera, face left, face right, face away. Each row is a seamless 8-frame loop with eight distinct readable poses: left-foot contact, compression, passing, right-foot contact, compression, passing, recovery, recovery back to contact. Clearly alternate legs and opposite arm swing, subtle torso bob only, grounded feet. Crisp small-scale pixel clusters, restrained warm natural palette, careful dark-brown outlines, hand-authored-looking 16-bit pixel art. No text, symbols, extra objects, shadows beyond the character feet, crop, blur, antialiasing, gradients, or changing camera angle.
