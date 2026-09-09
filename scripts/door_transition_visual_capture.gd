extends SceneTree

const OUTPUT := "res://design/qa/2026-09-09/doors"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var farm_door: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(15, 10))
	game._change_map("valley_world", farm_door)
	game.player.set_pose("up", "idle")
	await _capture("01_farmhouse_closed", 0.22)
	var exterior_samples := {
		"farmhouse": ["farm_outdoor", Vector2i(15, 10)],
		"general_store": ["town_square", Vector2i(10, 11)],
		"clinic": ["town_square", Vector2i(24, 9)],
		"cafe": ["town_square", Vector2i(38, 11)],
	}
	for label in exterior_samples:
		var sample: Array = exterior_samples[label]
		var sample_cell: Vector2i = game.navigation.to_contiguous_world(str(sample[0]), sample[1])
		game._change_map("valley_world", sample_cell)
		game.player.set_pose("up", "idle")
		game.world.active_door = sample_cell
		game.world.door_open = 0.65
		game.world.queue_redraw()
		await _capture("door_" + str(label) + "_opening", 0.18)
	game.world.active_door = Vector2i(-1, -1)
	game.world.door_open = 0.0
	game._change_map("valley_world", farm_door)
	game.player.set_pose("up", "idle")
	game._enter_door("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"), farm_door)
	await _capture("02_farmhouse_opening", 0.13)
	await _capture("03_black_cover", 0.28)
	await _capture("04_center_light_reveal", 0.20)
	await _capture("05_farmhouse_rug", 0.45)
	for interior in ["general_store_interior", "clinic_interior", "cafe_interior"]:
		game._change_map(interior, game.navigation.get_spawn(interior))
		await _capture("rug_" + interior, 0.16)
	game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
	game._enter_door("farm_outdoor", Vector2i(15, 11), Vector2i(18, 17))
	await _capture("06_exit_center_light_reveal", 0.35)
	game.queue_free()
	quit()


func _capture(label: String, delay: float) -> void:
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var path := OUTPUT + "/" + label + ".png"
	image.save_png(path)
	print("FRAMEBUFFER " + path)
