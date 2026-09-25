extends SceneTree

## Read-only gameplay investigation; no saves and no production-code changes.
class ProfileGame extends "res://scripts/game.gd":
	var timings: Dictionary = {}
	func _spawn_map_npcs() -> void:
		var started := Time.get_ticks_usec()
		super._spawn_map_npcs()
		timings["npcs_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	func _stream_world(force: bool) -> void:
		var started := Time.get_ticks_usec()
		super._stream_world(force)
		timings["stream_ms"] = (Time.get_ticks_usec() - started) / 1000.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := ProfileGame.new()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://investigation-unused.json"
	game.display_config_path = "user://investigation-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var samples: Array = []
	for iteration in 5:
		game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
		await process_frame
		game.timings.clear()
		var started := Time.get_ticks_usec()
		game._change_map("farm_outdoor", Vector2i(15, 11))
		var row := game.timings.duplicate()
		row["total_swap_ms"] = (Time.get_ticks_usec() - started) / 1000.0
		row["iteration"] = iteration
		row["npc_count"] = game.npcs.size()
		row["terrain_chunks"] = game.world._terrain_chunks.size()
		row["object_count"] = game.world._object_cache.size()
		samples.append(row)
		await process_frame
	var started := Time.get_ticks_usec()
	game.world.configure(game.navigation, "valley_world", Vector2.ZERO)
	var warm_config_ms := (Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	game.pet.rebuild_grid()
	var pet_ms := (Time.get_ticks_usec() - started) / 1000.0
	var result := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "samples": samples, "warm_config_ms": warm_config_ms, "pet_grid_ms": pet_ms, "note": "CPU synchronous swap only; excludes transition animation, first rendered frame and cold startup. Fresh session, day 1 at 06:00."}
	if DisplayServer.get_name() != "headless":
		game.creator.hide()
		game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
		await process_frame
		started = Time.get_ticks_usec()
		await game._enter_door("farm_outdoor", Vector2i(15, 11), game.player_cell)
		await RenderingServer.frame_post_draw
		result["rendered_exit_ms"] = (Time.get_ticks_usec() - started) / 1000.0
		result["display"] = DisplayServer.get_name()
	var destination := "res://design/qa/2026-09-21/transition-investigation.json"
	if DisplayServer.get_name() != "headless": destination = "res://design/qa/2026-09-21/transition-rendered.json"
	DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-21")
	FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print(JSON.stringify(result))
	game.queue_free()
	await process_frame
	quit()
