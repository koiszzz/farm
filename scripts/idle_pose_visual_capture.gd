extends SceneTree

const OUTPUT_DIR := "res://design/qa/2026-09-09/player-idle"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game._change_map("farm_outdoor", Vector2i(8, 13))
	game.game_camera.zoom = Vector2.ONE * 4.0
	game.game_camera.reset_smoothing()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for facing in ["down", "left", "right", "up"]:
		game.player.set_pose(facing, "idle")
		await create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path: String = OUTPUT_DIR + "/idle_" + facing + ".png"
		image.save_png(path)
		print("IDLE_FRAMEBUFFER " + path)
	game.queue_free()
	quit()
