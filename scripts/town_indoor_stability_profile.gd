extends SceneTree

const PROFILE_PATH_FORMAT := "res://design/qa/2026-09-24/loading/town-indoor-stability-profile-%s.json"
const ITERATIONS_PER_BUILDING := 10

const BUILDINGS := {
	"general_store_interior": {"door": Vector2i(10, 11), "arrival": Vector2i(10, 12), "exit": Vector2i(17, 17)},
	"clinic_interior": {"door": Vector2i(24, 9), "arrival": Vector2i(24, 9), "exit": Vector2i(17, 17)},
	"cafe_interior": {"door": Vector2i(38, 11), "arrival": Vector2i(38, 11), "exit": Vector2i(17, 17)},
}

class ProfileGame extends "res://scripts/game.gd":
	var last_swap: Dictionary = {}

	func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
		var started := Time.get_ticks_usec()
		super._change_map(next_map_id, next_cell)
		last_swap = {"total_swap_ms": (Time.get_ticks_usec() - started) / 1000.0}


var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := ProfileGame.new()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://town-indoor-stability-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://town-indoor-stability-unused-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1280, 720)
	await process_frame
	game.creator.hide()

	var samples_by_building: Dictionary = {}
	var cache_sizes: Array[int] = []
	var first_exit_frame_saved := false
	for target_variant in BUILDINGS:
		var target := str(target_variant)
		var building: Dictionary = BUILDINGS[target]
		var exterior_door: Vector2i = game.navigation.to_contiguous_world("town_square", building.door)
		var exterior_arrival: Vector2i = game.navigation.to_contiguous_world("town_square", building.arrival)
		var interior_exit: Vector2i = building.exit
		var spawn: Vector2i = game.navigation.get_spawn(target)
		var samples: Array[Dictionary] = []
		var entry_durations := PackedFloat64Array()
		var exit_durations := PackedFloat64Array()
		var entry_swaps := PackedFloat64Array()
		var exit_swaps := PackedFloat64Array()

		for iteration in ITERATIONS_PER_BUILDING:
			game._change_map("valley_world", exterior_door)
			await process_frame
			var entry_started := Time.get_ticks_usec()
			await game._enter_door(target, spawn, exterior_door)
			var entry_animation_ms := (Time.get_ticks_usec() - entry_started) / 1000.0
			var entry_ready := await _wait_for_input_ready(game)
			var entry_ready_ms := (Time.get_ticks_usec() - entry_started) / 1000.0
			var entry_swap: Dictionary = game.last_swap.duplicate()
			var entry_ok := game.current_map_id == target and entry_ready
			if not entry_ok:
				failures += 1
				push_error("%s entry did not reach a controllable interior at iteration %d" % [target, iteration + 1])
			entry_durations.append(entry_ready_ms)
			entry_swaps.append(float(entry_swap.get("total_swap_ms", -1.0)))

			var exit_started := Time.get_ticks_usec()
			await game._enter_door("town_square", building.arrival, interior_exit)
			var exit_animation_ms := (Time.get_ticks_usec() - exit_started) / 1000.0
			var exit_ready := await _wait_for_input_ready(game)
			await RenderingServer.frame_post_draw
			var exit_ready_ms := (Time.get_ticks_usec() - exit_started) / 1000.0
			var exit_swap: Dictionary = game.last_swap.duplicate()
			var exit_ok := game.current_map_id == "valley_world" and exit_ready
			if not exit_ok:
				failures += 1
				push_error("%s exit did not reach a controllable town at iteration %d" % [target, iteration + 1])
			exit_durations.append(exit_ready_ms)
			exit_swaps.append(float(exit_swap.get("total_swap_ms", -1.0)))
			cache_sizes.append(game._world_cache.size())
			if game._world_cache.size() > game.WORLD_CACHE_LIMIT:
				failures += 1
				push_error("World renderer cache exceeded its configured limit after %s" % target)
			if not first_exit_frame_saved:
				root.get_texture().get_image().save_png("res://design/qa/2026-09-24/loading/first-stable-town-frame.png")
				first_exit_frame_saved = true
			samples.append({
				"iteration": iteration + 1,
				"entry_animation_ms": entry_animation_ms,
				"entry_input_ready_ms": entry_ready_ms,
				"entry_swap_ms": entry_swap.get("total_swap_ms", -1.0),
				"entry_ok": entry_ok,
				"exit_animation_ms": exit_animation_ms,
				"exit_input_ready_ms": exit_ready_ms,
				"exit_swap_ms": exit_swap.get("total_swap_ms", -1.0),
				"exit_ok": exit_ok,
				"world_cache_count": game._world_cache.size(),
				"resident_count": game.npcs.size(),
				"terrain_chunk_count": game.world._terrain_chunks.size(),
				"collision_cell_count": game.collision_stream_bounds.size.x * game.collision_stream_bounds.size.y,
			})
		samples_by_building[target] = {
			"entry_input_ready_ms": _summary(entry_durations),
			"exit_input_ready_ms": _summary(exit_durations),
			"entry_scene_swap_ms": _summary(entry_swaps),
			"exit_scene_swap_ms": _summary(exit_swaps),
			"samples": samples,
		}

	var result := {
		"engine": Engine.get_version_info().string,
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport_size": game.get_viewport_rect().size,
		"iterations_per_building": ITERATIONS_PER_BUILDING,
		"world_cache_limit": game.WORLD_CACHE_LIMIT,
		"world_cache_sizes": cache_sizes,
		"buildings": samples_by_building,
		"failures": failures,
		"note": "Thirty rendered town-building round trips in an isolated Windows process. Each sample waits for the actual door transition, physics input unlock, and first rendered outdoor frame on exit. Production save/config are not read or written.",
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://design/qa/2026-09-24/loading"))
	var output_path := PROFILE_PATH_FORMAT % RenderingServer.get_current_rendering_method()
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		failures += 1
		push_error("Cannot write town indoor stability profile: " + output_path)
	else:
		result["failures"] = failures
		output.store_string(JSON.stringify(result, "\t"))
	print("TOWN_INDOOR_STABILITY_PROFILE " + JSON.stringify(result))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)


func _wait_for_input_ready(game: Node) -> bool:
	for _frame in 12:
		if not game.entering_door and game.transition_lock_frames <= 0:
			await RenderingServer.frame_post_draw
			return true
		await process_frame
	return false


func _summary(values: PackedFloat64Array) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	var sorted := values.duplicate()
	sorted.sort()
	var over_800ms := 0
	for value in sorted:
		if value > 800.0:
			over_800ms += 1
	return {
		"count": sorted.size(),
		"min": sorted[0],
		"median": sorted[sorted.size() / 2],
		"p95": sorted[mini(sorted.size() - 1, ceili(sorted.size() * 0.95) - 1)],
		"max": sorted[-1],
		"over_800ms": over_800ms,
	}
