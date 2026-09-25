extends SceneTree

func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var output_dir := "res://design/qa/2026-09-24/terrain-atlas-v8"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = false
	game.save_path = "user://terrain-atlas-capture-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://terrain-atlas-capture-unused-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	game._change_map("farm_outdoor", game.navigation.get_spawn("farm_outdoor"))
	game.creator.hide()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(output_dir + "/farm-default.png"))
	game.queue_free()
	await process_frame
	quit()
