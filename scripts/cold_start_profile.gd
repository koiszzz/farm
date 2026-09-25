extends SceneTree

const PROFILE_PATH_FORMAT := "res://design/qa/2026-09-24/loading/cold-start-profile-%s.json"
const DONE_MARKER_PATH_FORMAT := "res://design/qa/2026-09-24/loading/cold-start-profile-%s.done"

class ProfileGame extends "res://scripts/game.gd":
	var ready_duration_ms := -1.0
	var startup_stages_ms: Dictionary = {}

	func _ready() -> void:
		var started := Time.get_ticks_usec()
		super._ready()
		ready_duration_ms = (Time.get_ticks_usec() - started) / 1000.0

	func _prime_collision_pool() -> void:
		var started := Time.get_ticks_usec()
		super._prime_collision_pool()
		startup_stages_ms["prime_collision_pool_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _build_hud() -> void:
		var started := Time.get_ticks_usec()
		super._build_hud()
		startup_stages_ms["build_hud_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _sync_inventory() -> void:
		var started := Time.get_ticks_usec()
		super._sync_inventory()
		startup_stages_ms["sync_inventory_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _change_map(next_map_id: String, next_cell: Vector2i) -> void:
		var started := Time.get_ticks_usec()
		super._change_map(next_map_id, next_cell)
		startup_stages_ms["initial_map_change_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _activate_world(map_id: String) -> void:
		var started := Time.get_ticks_usec()
		super._activate_world(map_id)
		startup_stages_ms["activate_world_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _stream_world(force: bool) -> void:
		var started := Time.get_ticks_usec()
		super._stream_world(force)
		startup_stages_ms["stream_world_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _spawn_map_npcs() -> void:
		var started := Time.get_ticks_usec()
		super._spawn_map_npcs()
		startup_stages_ms["spawn_npcs_ms"] = (Time.get_ticks_usec() - started) / 1000.0

	func _rebuild_world_collisions() -> void:
		var started := Time.get_ticks_usec()
		super._rebuild_world_collisions()
		startup_stages_ms["rebuild_collisions_ms"] = (Time.get_ticks_usec() - started) / 1000.0


var script_started_usec := 0
var sample_suffix := "single"


func _init() -> void:
	script_started_usec = Time.get_ticks_usec()
	var requested_suffix := OS.get_environment("FARM_COLD_START_SAMPLE").strip_edges()
	if not requested_suffix.is_empty() and requested_suffix.is_valid_filename():
		sample_suffix = requested_suffix
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://design/qa/2026-09-24/loading"))
	var game := ProfileGame.new()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = false
	game.save_path = "user://cold-start-unused-%d.json" % script_started_usec
	game.display_config_path = "user://cold-start-unused-%d.cfg" % script_started_usec
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	root.add_child(game)
	await process_frame
	await RenderingServer.frame_post_draw
	var first_game_frame_ms := _since_script_start_ms()
	var creator_visible_on_first_frame := game.creator != null and game.creator.visible
	var frame_name := "cold-start-first-game-frame.png" if sample_suffix == "single" else "cold-start-first-game-frame-%s.png" % sample_suffix
	root.get_texture().get_image().save_png("res://design/qa/2026-09-24/loading/" + frame_name)
	await process_frame
	await RenderingServer.frame_post_draw
	var input_ready_ms := _since_script_start_ms()
	var world_input_ready := game.current_map_id in ["farm_outdoor", "valley_world"] and not creator_visible_on_first_frame and not game.entering_door and game.transition_lock_frames <= 0

	var result := {
		"engine": Engine.get_version_info().string,
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"display": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport_size": game.get_viewport_rect().size,
		"window_size": root.get_window().size,
		"script_entry_to_game_ready_ms": game.ready_duration_ms,
		"startup_stages_ms": game.startup_stages_ms,
		"script_entry_to_first_game_frame_ms": first_game_frame_ms,
		"script_entry_to_input_ready_ms": input_ready_ms,
		"character_creator_visible_on_first_frame": creator_visible_on_first_frame,
		"world_input_ready": world_input_ready,
		"world_cache_count": game._world_cache.size(),
		"terrain_chunk_count": game.world._terrain_chunks.size(),
		"merged_world_constructed": game.navigation.has_map("valley_world"),
		"regional_maps_ready": ["farm_outdoor", "countryside", "town_square", "beach", "cave"].all(func(map_id: String) -> bool: return game.navigation.has_map(map_id)),
		"resident_count": game.npcs.size(),
		"note": "Fresh Godot process using the production default separated farm_outdoor map, project game script and assets loaded, unique temporary save/config paths, autosave disabled. Timing begins at SceneTree script entry; external process spawn-to-first-profile-file duration is measured by the PowerShell harness. This profile does not read or write the production save.",
	}
	var profile_path := PROFILE_PATH_FORMAT % sample_suffix
	var done_marker_path := DONE_MARKER_PATH_FORMAT % sample_suffix
	var output := FileAccess.open(profile_path, FileAccess.WRITE)
	if output == null:
		push_error("Cannot write cold start profile: " + profile_path)
		game.queue_free()
		await process_frame
		quit(1)
		return
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
	var marker := FileAccess.open(done_marker_path, FileAccess.WRITE)
	if marker != null:
		marker.store_string("complete")
	print("COLD_START_PROFILE " + JSON.stringify(result))
	game.queue_free()
	await process_frame
	quit(0 if world_input_ready else 1)


func _since_script_start_ms() -> float:
	return (Time.get_ticks_usec() - script_started_usec) / 1000.0
