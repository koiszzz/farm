# Four-season farm visual check

Captured on Windows with Godot 4.7.1, NVIDIA RTX 3050, D3D12 at 1536×864. Each image uses the same farm spawn, camera, and layout with the calendar set to the first day of each season.

| Season | Day | Capture |
|---|---:|---|
| Spring | 1 | `farm-spring.png` |
| Summer | 29 | `farm-summer.png` |
| Autumn | 57 | `farm-autumn.png` |
| Winter | 85 | `farm-winter.png` |

The pass checked that seasonal ground treatment appears in both streamed continuous terrain and ordinary outdoor maps. The broad seasonal palettes remain, while sparse flower, grass, leaf, and snow marks are placed deterministically from map coordinates, so they do not flicker when a tile redraws. Crops and tree tinting continue to use their existing seasonal data. No collision, navigation, or save data is changed.

The comparison makes seasons distinguishable, especially winter, while keeping the player, plots, paths, and major props visible. The farm still has a high-contrast repeating grass pattern across large open areas; this pass adds seasonal cues but does not resolve that larger density/composition issue.

## Reference translation

Scene composition was checked against the [official Stardew Valley media page](https://www.stardewvalley.net/media/) and community location references for [Pelican Town](https://stardewvalleywiki.com/Pelican_Town), [the Beach](https://wiki.stardewvalley.net/The_Beach), and [seasons](https://wiki.stardewvalley.net/Seasons). They inform general principles only: each area should pair a readable landmark with an activity, and seasonal shifts should affect the whole scene. This project uses its own maps, generated artwork, palette, and decorations.

## Validation

- `continuous_world_test.gd`: 46 checks, 0 failures (headless; logic/streaming path).
- `regional_world_test.gd`: 334 checks, 0 failures (headless; region/map rendering logic).
- `game_smoke_test.gd`: passed (headless).
- `seasonal_world_capture.gd`: all four D3D12 window framebuffers captured and visually inspected.
