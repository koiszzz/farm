extends SceneTree

const OUTPUT_DIR := "res://design/qa/2026-09-25/map-region-art"
const MAPS := ["farm_outdoor", "town_square", "countryside", "beach", "cave"]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	var token := str(Time.get_ticks_usec())
	game.save_path = "user://map-region-art-unused-%s.json" % token
	game.display_config_path = "user://map-region-art-unused-%s.cfg" % token
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	game.clock_minutes = 360
	game._change_map("town_square", game.navigation.get_spawn("town_square"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for target_map in MAPS:
		game._open_world_map(target_map)
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		var path := "%s/%s.png" % [OUTPUT_DIR, target_map]
		var result := image.save_png(ProjectSettings.globalize_path(path))
		if result != OK: push_error("Could not save map capture: " + path)
		else: print("MAP_REGION_CAPTURE " + path)
	game.queue_free()
	await process_frame
	quit()
