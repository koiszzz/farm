extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game._change_map("farm_outdoor", Vector2i(4, 5))
	await _capture("tree_behind")
	game._change_map("farm_outdoor", Vector2i(4, 7))
	await _capture("tree_front")
	game._change_map("farm_outdoor", Vector2i(15, 5))
	await _capture("house_behind")
	game._change_map("town_square", Vector2i(23, 18))
	await _capture("fountain_behind")
	game._change_map("farm_outdoor", Vector2i(15, 10))
	game.player.set_pose("up")
	await _capture("farm_back")
	game._after_arrival()
	await _capture("door_open", 0.18)
	await create_timer(1.0).timeout
	game._change_map("farm_outdoor", Vector2i(4, 14))
	game.player.set_pose("down", "water")
	game.player.action_progress = 0.55
	await _capture("water_action")
	game._change_map("town_square", Vector2i(24, 12))
	await _capture("town")
	game._change_map("farmhouse_interior", Vector2i(18, 16))
	await _capture("interior")
	for interior in ["general_store_interior", "clinic_interior", "cafe_interior"]:
		game._change_map(interior, Vector2i(18,16))
		await _capture(interior)
	game._change_map("riverside", Vector2i(23,15))
	game.player.set_pose("right")
	game.current_tool = "fish"
	game._farm_action()
	game.actor_action.advance(1.3)
	game.player.set_pose("right", "fish")
	game.player.action_progress = 0.65
	await _capture("riverside_fishing")
	game._cancel_fishing()
	game._open_world_map()
	await _capture("world_map")
	game.queue_free()
	quit()

func _capture(label: String, delay := 0.3) -> void:
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://design/qa/2026-09-06/spatial/" + label + ".png"
	DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-06/spatial")
	image.save_png(path)
	print("FRAMEBUFFER " + path)
