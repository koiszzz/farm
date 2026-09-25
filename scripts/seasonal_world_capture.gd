extends SceneTree

const OUTPUT_DIR := "res://design/qa/2026-09-25/seasons"
const SEASON_DAYS := [1, 29, 57, 85]
const SEASON_NAMES := ["spring", "summer", "autumn", "winter"]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = false
	var token := str(Time.get_ticks_usec())
	game.save_path = "user://season-capture-unused-%s.json" % token
	game.display_config_path = "user://season-capture-unused-%s.cfg" % token
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	game._change_map("farm_outdoor", game.navigation.get_spawn("farm_outdoor"))
	game.creator.hide()
	for index in SEASON_DAYS.size():
		game.farm.day = SEASON_DAYS[index]
		game._update_farm_hud()
		game.world.refresh_season()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := OUTPUT_DIR + "/farm-%s.png" % SEASON_NAMES[index]
		image.save_png(ProjectSettings.globalize_path(path))
		print("SEASON_WORLD_FRAMEBUFFER " + path)
	game.queue_free()
	await process_frame
	quit()
