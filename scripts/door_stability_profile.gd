extends SceneTree

const PROFILE_PATH_FORMAT := "res://design/qa/2026-09-24/loading/door-stability-profile-%s.json"
const ITERATIONS := 30

class ProfileGame extends "res://scripts/game.gd":
	var last_swap: Dictionary = {}

	func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
		var started := Time.get_ticks_usec()
		super._change_map(next_map_id, next_cell)
		last_swap = {"total_swap_ms": (Time.get_ticks_usec() - started) / 1000.0}


var failures := 0
var profile_output_path := ""
var progress_output_path := ""
var first_frame_output_path := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_args := OS.get_cmdline_user_args()
	profile_output_path = str(output_args[0]) if output_args.size() > 0 else PROFILE_PATH_FORMAT % RenderingServer.get_current_rendering_method()
	progress_output_path = profile_output_path.trim_suffix(".json") + ".partial.json"
	first_frame_output_path = str(output_args[1]) if output_args.size() > 1 else "res://design/qa/2026-09-24/loading/first-stable-outdoor-frame.png"
	var game := ProfileGame.new()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://door-stability-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://door-stability-unused-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1280, 720)
	await process_frame
	game.creator.hide()

	var farm_door := game.navigation.to_contiguous_world("farm_outdoor", Vector2i(15, 10))
	var farm_arrival := Vector2i(15, 11)
	var interior_spawn: Vector2i = game.navigation.get_spawn("farmhouse_interior")
	game._change_map("valley_world", farm_door)
	await process_frame
	var samples: Array[Dictionary] = []
	var entry_durations := PackedFloat64Array()
	var exit_durations := PackedFloat64Array()
	var max_cache_count := 0
	var cache_sizes: Array[int] = []
	var first_frame_saved := false

	for iteration in ITERATIONS:
		_write_progress(iteration + 1, "entering", samples)
		var entry_start := Time.get_ticks_usec()
		await game._enter_door("farmhouse_interior", interior_spawn, farm_door)
		var entry_transition_ms := (Time.get_ticks_usec() - entry_start) / 1000.0
		var entry_ready := await _wait_for_input_ready(game)
		var entry_ready_ms := (Time.get_ticks_usec() - entry_start) / 1000.0
		var entry_swap := game.last_swap.duplicate()
		var entry_ok := game.current_map_id == "farmhouse_interior" and entry_ready
		if not entry_ok:
			failures += 1
			push_error("Farmhouse entry did not reach a controllable interior at iteration %d" % iteration)
		entry_durations.append(entry_ready_ms)
		_write_progress(iteration + 1, "exiting", samples)

		var exit_start := Time.get_ticks_usec()
		await game._enter_door("farm_outdoor", farm_arrival, Vector2i(18, 17))
		var exit_transition_ms := (Time.get_ticks_usec() - exit_start) / 1000.0
		var exit_ready := await _wait_for_input_ready(game)
		await RenderingServer.frame_post_draw
		var exit_ready_ms := (Time.get_ticks_usec() - exit_start) / 1000.0
		var exit_swap := game.last_swap.duplicate()
		var exit_ok := game.current_map_id == "valley_world" and exit_ready
		if not exit_ok:
			failures += 1
			push_error("Farmhouse exit did not reach a controllable outdoor world at iteration %d" % iteration)
		exit_durations.append(exit_ready_ms)
		max_cache_count = maxi(max_cache_count, game._world_cache.size())
		cache_sizes.append(game._world_cache.size())
		samples.append({
			"iteration": iteration + 1,
			"entry_transition_ms": entry_transition_ms,
			"entry_input_ready_ms": entry_ready_ms,
			"entry_swap": entry_swap,
			"entry_ok": entry_ok,
			"exit_transition_ms": exit_transition_ms,
			"exit_input_ready_ms": exit_ready_ms,
			"exit_swap": exit_swap,
			"exit_ok": exit_ok,
			"world_cache_count": game._world_cache.size(),
			"resident_count": game.npcs.size(),
			"terrain_chunk_count": game.world._terrain_chunks.size(),
			"collision_cell_count": game.collision_stream_bounds.size.x * game.collision_stream_bounds.size.y
		})
		_write_progress(iteration + 1, "round_trip_complete", samples)
		if not first_frame_saved:
			var frame := root.get_texture().get_image()
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(first_frame_output_path.get_base_dir()))
			frame.save_png(first_frame_output_path)
			first_frame_saved = true
	var entry_summary := _summary(entry_durations)
	var exit_summary := _summary(exit_durations)
	if int(entry_summary.over_800ms) > 0 or int(exit_summary.over_800ms) > 0:
		failures += 1
		push_error("Warm farmhouse round trip exceeded the 800ms input-ready target")
	if max_cache_count > game.WORLD_CACHE_LIMIT:
		failures += 1
		push_error("World renderer cache exceeded its configured limit")

	var result := {
		"engine": Engine.get_version_info().string,
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport_size": game.get_viewport_rect().size,
		"iterations": ITERATIONS,
		"entry_input_ready_ms": entry_summary,
		"exit_input_ready_ms": exit_summary,
		"world_cache_limit": game.WORLD_CACHE_LIMIT,
		"world_cache_max_observed": max_cache_count,
		"world_cache_sizes": cache_sizes,
		"samples": samples,
		"failures": failures,
		"note": "Thirty rendered farmhouse round trips in an isolated Windows process. Input-ready includes the scene transition, a physics frame to release the transition lock, and the first outdoor rendered frame on exit. Production save/config are not read or written."
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(profile_output_path.get_base_dir()))
	var output := FileAccess.open(profile_output_path, FileAccess.WRITE)
	if output == null:
		failures += 1
		push_error("Cannot write door stability profile: " + profile_output_path)
	else:
		result["failures"] = failures
		output.store_string(JSON.stringify(result, "\t"))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(progress_output_path))
	print("DOOR_STABILITY_PROFILE " + JSON.stringify(result))
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
		"over_800ms": over_800ms
	}


func _write_progress(iteration: int, phase: String, samples: Array[Dictionary]) -> void:
	var output := FileAccess.open(progress_output_path, FileAccess.WRITE)
	if output == null:
		push_error("Cannot write door stability progress: " + progress_output_path)
		return
	output.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "expected_iterations": ITERATIONS, "current_iteration": iteration, "phase": phase, "samples": samples}, "\t"))
