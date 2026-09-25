extends SceneTree

const MapDataScript = preload("res://scripts/map_data.gd")
const PROFILE_PATH := "res://design/qa/2026-09-24/loading/navigation-data-profile.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var rows: Array[Dictionary] = []
	for index in range(5):
		var data = MapDataScript.new()
		var started := Time.get_ticks_usec()
		var loaded: bool = data.load_data()
		var load_ms := _elapsed_ms(started)
		started = Time.get_ticks_usec()
		data.build_contiguous_world()
		var contiguous_ms := _elapsed_ms(started)
		started = Time.get_ticks_usec()
		data.build_regions()
		var regions_ms := _elapsed_ms(started)
		rows.append({
			"iteration": index + 1,
			"valid": loaded and data.load_errors.is_empty(),
			"load_json_ms": load_ms,
			"build_contiguous_world_ms": contiguous_ms,
			"build_regions_ms": regions_ms,
			"map_count": data.map_ids().size(),
			"farm_size": data.get_map_size("farm_outdoor"),
			"valley_size": data.get_map_size("valley_world"),
		})
	var result := {"engine": Engine.get_version_info().string, "os": OS.get_name(), "rows": rows, "note": "Isolated MapData construction timings only; excludes Godot process start, rendering, game nodes, save reads and full runtime readiness."}
	var output := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if output == null:
		push_error("Cannot write navigation data profile")
		quit(1)
		return
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
	print("NAVIGATION_DATA_PROFILE " + JSON.stringify(result))
	quit(0)


func _elapsed_ms(started_usec: int) -> float:
	return (Time.get_ticks_usec() - started_usec) / 1000.0
