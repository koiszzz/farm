extends SceneTree

## Profiles warm transitions without reading or writing the normal player save.
class ProfileGame extends "res://scripts/game.gd":
	var stage_ms: Dictionary = {}
	var last_swap: Dictionary = {}

	func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
		stage_ms.clear()
		var started := Time.get_ticks_usec()
		super._change_map(next_map_id, next_cell)
		stage_ms["total_swap_ms"] = (Time.get_ticks_usec() - started) / 1000.0
		last_swap = stage_ms.duplicate()

	func _activate_world(map_id: String) -> void:
		var started := Time.get_ticks_usec()
		super._activate_world(map_id)
		stage_ms["activate_world_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _stream_world(force: bool) -> void:
		var started := Time.get_ticks_usec()
		super._stream_world(force)
		stage_ms["stream_and_collisions_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _spawn_map_npcs() -> void:
		var started := Time.get_ticks_usec()
		super._spawn_map_npcs()
		stage_ms["npc_schedule_and_nodes_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _rebuild_world_collisions() -> void:
		var started := Time.get_ticks_usec()
		super._rebuild_world_collisions()
		stage_ms["collision_rebuild_ms"] = (Time.get_ticks_usec() - started) / 1000.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/loading")
	var game := ProfileGame.new()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://loading-profile-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://loading-profile-unused-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var samples: Array[Dictionary] = []
	for iteration in 5:
		game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
		await process_frame
		game._change_map("farm_outdoor", Vector2i(15, 11))
		var sample := game.last_swap.duplicate()
		sample["iteration"] = iteration
		sample["npc_count"] = game.npcs.size()
		sample["terrain_chunks"] = game.world._terrain_chunks.size()
		sample["collision_cells"] = game.collision_stream_bounds.size.x * game.collision_stream_bounds.size.y
		samples.append(sample)
		await process_frame
	var window_size_before_resize := root.get_window().size
	var collision_cells_before_resize := game.collision_stream_bounds.size.x * game.collision_stream_bounds.size.y
	var viewport_before_resize := game.get_viewport_rect().size
	var result := {
		"engine": Engine.get_version_info().string,
		"display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport_size": game.get_viewport_rect().size,
		"samples": samples,
		"note": "Warm house-to-outdoor map swaps; temporary unique save/config paths; production saves are not read or written. Timings omit the transition animation unless marked rendered_exit_ms."
	}
	if DisplayServer.get_name() != "headless":
		game.creator.hide()
		game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
		await process_frame
		var started := Time.get_ticks_usec()
		await game._enter_door("farm_outdoor", Vector2i(15, 11), game.player_cell)
		await RenderingServer.frame_post_draw
		result["rendered_exit_ms"] = (Time.get_ticks_usec() - started) / 1000.0
		result["door_transition_lock_cleared"] = not game.entering_door
		var exit_image := root.get_texture().get_image()
		exit_image.save_png("res://design/qa/2026-09-24/loading/after-exit.png")
	root.get_window().size = Vector2i(1920, 1080)
	await process_frame
	result["resize_probe"] = {
		"viewport_before": viewport_before_resize,
		"viewport_after": game.get_viewport_rect().size,
		"collision_cells_before": collision_cells_before_resize,
		"collision_cells_after": game.collision_stream_bounds.size.x * game.collision_stream_bounds.size.y
	}
	root.get_window().size = window_size_before_resize
	await process_frame
	var output := FileAccess.open("res://design/qa/2026-09-24/loading/loading-profile.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	game.queue_free()
	await process_frame
	quit()
