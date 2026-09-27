extends SceneTree

const SOURCE := "res://assets/art/runtime_generated/village_props_v4.png"
const OUTPUT := "res://assets/art/runtime_generated/farm_cherry_tree_seasons_v1.png"


func _init() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if sheet == null or sheet.is_empty():
		push_error("Could not load the farm tree source atlas.")
		quit(1)
		return
	var frame_size := sheet.get_size() / Vector2i(4, 2)
	var tree := sheet.get_region(Rect2i(Vector2i.ZERO, frame_size))
	var atlas := Image.create(frame_size.x * 4, frame_size.y, false, Image.FORMAT_RGBA8)
	var season_hues := [0.94, -1.0, 0.105, 0.56]
	for season in 4:
		var seasonal_tree := tree.duplicate()
		for y in frame_size.y:
			for x in frame_size.x:
				var pixel: Color = seasonal_tree.get_pixel(x, y)
				if pixel.a <= 0.05 or pixel.s < 0.18 or pixel.h < 0.16 or pixel.h > 0.48:
					continue
				if season == 1:
					continue # retain the source's lush summer canopy
				var hue: float = float(season_hues[season])
				var saturation := clampf(pixel.s * (0.50 if season == 3 else 0.72) + 0.18, 0.24, 0.78)
				seasonal_tree.set_pixel(x, y, Color.from_hsv(hue, saturation, pixel.v, pixel.a))
		atlas.blit_rect(seasonal_tree, Rect2i(Vector2i.ZERO, frame_size), Vector2i(season * frame_size.x, 0))
	var error := atlas.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("Could not save the seasonal cherry tree: %s" % OUTPUT)
		quit(1)
		return
	print("created seasonal cherry tree atlas=%s size=%s" % [OUTPUT, atlas.get_size()])
	quit()
