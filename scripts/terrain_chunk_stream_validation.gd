extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")

const OUTPUT_DIR := "res://design/qa/2026-09-24/terrain-chunk-v8-repeat"
const SAMPLE_CELLS := [
	Vector2i(61, 70), Vector2i(68, 70), Vector2i(75, 70),
	Vector2i(82, 70), Vector2i(89, 70), Vector2i(96, 70),
]

var game
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(value: bool, label: String) -> void:
	if value:
		return
	failures += 1
	push_error(label)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://movement-performance-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://movement-performance-display-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)

	var samples: Array[Dictionary] = []
	for cell in SAMPLE_CELLS:
		game.player_cell = cell
		game.player_body.position = game._avatar_position_for(cell)
		var world_started := Time.get_ticks_usec()
		game.world.set_stream_center(cell)
		var world_elapsed := Time.get_ticks_usec() - world_started
		var collision_started := Time.get_ticks_usec()
		game._rebuild_world_collisions()
		var collision_elapsed := Time.get_ticks_usec() - collision_started
		var elapsed := world_elapsed + collision_elapsed
		samples.append({
			"cell": [cell.x, cell.y],
			"microseconds": elapsed,
			"world_microseconds": world_elapsed,
			"collision_microseconds": collision_elapsed,
			"collision_nodes": game.collision_root.get_child_count(),
			"object_nodes": game.world.object_nodes.size(),
		})
		await process_frame

	var total_usec := 0
	var max_usec := 0
	for sample in samples:
		total_usec += int(sample.microseconds)
		max_usec = maxi(max_usec, int(sample.microseconds))
	var average_usec := int(total_usec / maxi(samples.size(), 1))
	var result := {
		"display_server": DisplayServer.get_name(),
		"world_object_entries": game.navigation.get_map("valley_world").get("objects", []).size(),
		"cached_object_nodes": game.world._object_cache.size(),
		"average_stream_microseconds": average_usec,
		"max_stream_microseconds": max_usec,
		"samples": samples,
	}
	if DisplayServer.get_name() != "headless":
		result["walk_frames"] = await _measure_visible_walk()
	var output_path := OUTPUT_DIR + "/latest.json"
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()

	_expect(game.current_map_id == "valley_world", "performance test uses the continuous world")
	_expect(game.collision_root.get_child_count() < 3000, "collision streaming remains bounded")
	print("Movement performance: avg=%dus max=%dus samples=%s" % [average_usec, max_usec, JSON.stringify(samples)])
	game.queue_free()
	quit(1 if failures else 0)


func _measure_visible_walk() -> Dictionary:
	var start: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(1, 14))
	var finish: Vector2i = game.navigation.to_contiguous_world("town_square", Vector2i(41, 22))
	var route_points: Array[Vector2i] = [start, finish]
	var route: Array[Vector2i] = game._npc_walk_route(route_points)
	_expect(route.size() > 40, "visual performance route crosses the countryside buffer")
	game.player_cell = route[0]
	game.player_body.position = game._avatar_position_for(route[0])
	game.moving = false
	game.transition_lock_frames = 0
	game._stream_world(true)
	game.set_physics_process(false)
	for warmup in 3:
		await process_frame

	var frame_times: Array[int] = []
	var spikes: Array[Dictionary] = []
	var travelled := 0
	for route_index in range(1, mini(route.size(), 49)):
		var direction: Vector2i = route[route_index] - route[route_index - 1]
		if absi(direction.x) + absi(direction.y) != 1:
			continue
		Motion.hold(direction)
		var target: Vector2 = game._avatar_position_for(route[route_index])
		var guard := 0
		var previous_tick := Time.get_ticks_usec()
		while game.player_body.position.distance_to(target) > 0.05 and guard < 120:
			game._update_player_movement(minf(1.0 / 60.0, game.player_body.position.distance_to(target) / 128.0))
			await process_frame
			var next_tick := Time.get_ticks_usec()
			var frame_usec := next_tick - previous_tick
			frame_times.append(frame_usec)
			if frame_usec >= 25000:
				spikes.append({
					"frame": frame_times.size(),
					"microseconds": frame_usec,
					"cell": [game.player_cell.x, game.player_cell.y],
					"chunk": [game.world.stream_chunk.x, game.world.stream_chunk.y],
				})
			previous_tick = next_tick
			guard += 1
		_expect(guard < 120, "walk step completes without hanging")
		travelled += 1
	Motion.hold(Vector2i.ZERO)
	game._update_player_movement(0.0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT_DIR + "/walk-after.png")
	frame_times.sort()
	var p95_index := clampi(int(ceil(frame_times.size() * 0.95)) - 1, 0, maxi(frame_times.size() - 1, 0))
	var p99_index := clampi(int(ceil(frame_times.size() * 0.99)) - 1, 0, maxi(frame_times.size() - 1, 0))
	var report := {
		"travelled_cells": travelled,
		"frame_count": frame_times.size(),
		"p95_microseconds": frame_times[p95_index] if not frame_times.is_empty() else 0,
		"p99_microseconds": frame_times[p99_index] if not frame_times.is_empty() else 0,
		"max_microseconds": frame_times[-1] if not frame_times.is_empty() else 0,
		"spikes_over_25ms": spikes,
	}
	print("Visible walk frames: %s" % JSON.stringify(report))
	return report
