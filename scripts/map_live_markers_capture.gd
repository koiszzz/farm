extends SceneTree

const OUTPUT_DIR := "res://design/qa/2026-09-25/map-live-markers"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	var token := str(Time.get_ticks_usec())
	game.save_path = "user://map-live-markers-unused-%s.json" % token
	game.display_config_path = "user://map-live-markers-unused-%s.cfg" % token
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	game.clock_minutes = 360
	game._change_map("town_square", game.navigation.get_spawn("town_square"))
	game._open_world_map()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/valley.png"))
	game._open_world_map("town_square")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/town.png"))
	game._open_world_map("beach")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/beach.png"))
	print("MAP_LIVE_MARKERS_FRAMEBUFFER " + OUTPUT_DIR)
	game.queue_free()
	await process_frame
	quit()
