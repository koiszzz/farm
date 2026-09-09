extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://style_preview_unused.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for shot in [["farm", "farm_outdoor", Vector2i(15, 10)], ["fields", "farm_outdoor", Vector2i(17, 16)], ["town", "town_square", Vector2i(24, 12)], ["river", "riverside", Vector2i(23, 15)]]:
		game._change_map(shot[1], shot[2])
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var folder := "res://design/qa/2026-09-08/style/"
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + shot[0] + ".png")
		print("STYLE FRAMEBUFFER: " + shot[0])
	game.queue_free()
	quit()
