# Regional music listening sample

`original-region-themes-preview.wav` is exported from the same `AudioStreamWAV` data used by the runtime music player. It contains four spring daytime themes in order: farm (0:00–0:05), town (0:05.5–0:10.5), beach (0:11–0:16), and cave (0:16.5–0:21.5). Each sample lasts five seconds, followed by half a second of silence.

The file is mono 16-bit PCM at 11.025 kHz so it matches the in-game generated stream. Run `Godot --headless --path . --script design/qa/2026-09-25/music/export_region_preview.gd` to regenerate it. It is a listening/review artifact, not a game asset.
