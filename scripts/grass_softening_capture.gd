extends SceneTree

const OUTPUT_PATH := "res://design/qa/2026-09-25/grass-softening/farm.png"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	var token := str(Time.get_ticks_usec())
	game.save_path = "user://grass-softening-unused-%s.json" % token
	game.display_config_path = "user://grass-softening-unused-%s.cfg" % token
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	var farm_start: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", game.navigation.get_spawn("farm_outdoor"))
	game._change_map("valley_world", farm_start)
	game.creator.hide()
	game.hud_status_panel.hide()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
	print("GRASS_SOFTENING_FRAMEBUFFER " + OUTPUT_PATH)
	game.queue_free()
	await process_frame
	quit()
