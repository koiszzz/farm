extends SceneTree

const MAPS := ["cave", "mine_2", "mine_3"]
const OUTPUT_DIR := "res://design/qa/2026-09-25/cave-lighting"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = false
	var token := str(Time.get_ticks_usec())
	game.save_path = "user://cave-lighting-unused-%s.json" % token
	game.display_config_path = "user://cave-lighting-unused-%s.cfg" % token
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	game.creator.hide()
	game.hud_status_panel.hide()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for map_id in MAPS:
		game._change_map(map_id, game.navigation.get_spawn(map_id))
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var filename := str(map_id).replace("_", "-") + ".png"
		image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + "/" + filename))
		print("CAVE_LIGHTING_FRAMEBUFFER " + OUTPUT_DIR + "/" + filename)
	game.queue_free()
	await process_frame
	quit()
