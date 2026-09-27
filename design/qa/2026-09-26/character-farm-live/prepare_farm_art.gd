extends SceneTree


func _init() -> void:
	var terrain := Image.load_from_file("res://assets/art/source_generated/farm_terrain_seasons_source_v1.png")
	_save_4x4_atlas(terrain, "res://assets/art/runtime_generated/farm_terrain_seasons_v1.png", 26)
	var flora := Image.load_from_file("res://assets/art/source_generated/farm_flora_seasons_source_v1.png")
	_save_4x4_atlas(flora, "res://assets/art/runtime_generated/farm_flora_seasons_v1.png", 0)
	_trim_asset("res://assets/art/runtime_generated/farm_coop_front_v1.png", "res://assets/art/runtime_generated/farm_coop_front_v2.png", Rect2i(126, 194, 1022, 880))
	_trim_asset("res://assets/art/runtime_generated/farm_barn_front_v1.png", "res://assets/art/runtime_generated/farm_barn_front_v2.png", Rect2i(208, 50, 1118, 850))
	print("Prepared farm terrain/flora atlases (4x4, 32px per cell) and trimmed coop/barn anchors.")
	quit()


func _save_4x4_atlas(source: Image, output_path: String, inset: int) -> void:
	var output := Image.create(128, 128, false, source.get_format())
	for row in 4:
		for column in 4:
			var left := floori(float(column) * source.get_width() / 4.0)
			var right := floori(float(column + 1) * source.get_width() / 4.0)
			var top := floori(float(row) * source.get_height() / 4.0)
			var bottom := floori(float(row + 1) * source.get_height() / 4.0)
			var cell := source.get_region(Rect2i(left + inset, top + inset, right - left - inset * 2, bottom - top - inset * 2))
			cell.resize(32, 32, Image.INTERPOLATE_NEAREST)
			output.blit_rect(cell, Rect2i(Vector2i.ZERO, Vector2i(32, 32)), Vector2i(column * 32, row * 32))
	output.save_png(output_path)


func _trim_asset(source_path: String, output_path: String, region: Rect2i) -> void:
	var image := Image.load_from_file(source_path)
	image = image.get_region(region)
	image.save_png(output_path)
