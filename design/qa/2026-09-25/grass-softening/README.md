# Grass palette and decoration density

The farm's open grass field was competing with the player, paths, and tilled plots. Both streamed continuous terrain and regional maps now apply a restrained sage wash to grass only. Hand-drawn grass tufts are placed on 12% of eligible cells instead of 25%, and flower centers on 3% instead of 4%; water, paths, tilled soil, collision, navigation, and seasonal overlays are unchanged.

The current continuous-world D3D12 capture is `farm.png` (Windows, Godot 4.7.1, NVIDIA RTX 3050, 1536x864). It was inspected alongside the earlier spring capture at `../seasons/farm-spring.png`: ground highlights and extra tufts are less prominent while the farmer, crop rows, paths, and pond remain distinct. This is a tuning pass, not a finished five-region palette review.

Validation: `continuous_world_test.gd` 56 checks, `regional_world_test.gd` 334 checks, and `game_smoke_test.gd` all passed headless. The D3D12 framebuffer was captured and visually inspected. The regional screenshot pass shows the current farm framing; separate wide/low-resolution and cave/beach palette reviews remain open.
