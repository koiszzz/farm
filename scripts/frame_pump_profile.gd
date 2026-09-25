extends SceneTree

const OUTPUT_PATH := "res://design/qa/2026-09-24/frame-stall/bare-frame-pump.json"
const FRAME_COUNT := 720


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var window: Window = root.get_window()
	var is_headless := DisplayServer.get_name() == "headless"
	var focus_before := window.has_focus()
	var focus_after := focus_before
	var original_vsync := -1
	var original_window_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var reports: Array[Dictionary] = []
	if is_headless:
		reports.append(await _sample("headless", window))
	else:
		window.grab_focus()
		await process_frame
		focus_after = window.has_focus()
		original_vsync = DisplayServer.window_get_vsync_mode()
		reports.append(await _sample("original", window))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		await process_frame
		reports.append(await _sample("disabled", window))
		DisplayServer.window_set_vsync_mode(original_vsync)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		await process_frame
		reports.append(await _sample("fullscreen", window))
		DisplayServer.window_set_mode(original_window_mode)
	var result := {
		"display_server": DisplayServer.get_name(),
		"window_focus_before_request": focus_before,
		"window_focus_after_request": focus_after,
		"vsync_mode_original": original_vsync,
		"node_count": root.get_child_count(),
		"reports": reports,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	for report in reports:
		print("Bare frame pump: %s" % JSON.stringify(report))
	quit(0)


func _sample(label: String, window: Window) -> Dictionary:
	var frame_times: Array[int] = []
	var spikes: Array[Dictionary] = []
	for index in FRAME_COUNT:
		var before := Time.get_ticks_usec()
		var process_frame_before := Engine.get_process_frames()
		await process_frame
		var elapsed := Time.get_ticks_usec() - before
		frame_times.append(elapsed)
		if elapsed >= 25000:
			spikes.append({
				"frame": index + 1,
				"microseconds": elapsed,
				"process_frames_elapsed": Engine.get_process_frames() - process_frame_before,
				"frames_per_second": Engine.get_frames_per_second(),
				"window_focused": window.has_focus(),
			})
	frame_times.sort()
	var p95_index := clampi(int(ceil(frame_times.size() * 0.95)) - 1, 0, frame_times.size() - 1)
	var p99_index := clampi(int(ceil(frame_times.size() * 0.99)) - 1, 0, frame_times.size() - 1)
	return {
		"mode": label,
		"frame_count": frame_times.size(),
		"p95_microseconds": frame_times[p95_index],
		"p99_microseconds": frame_times[p99_index],
		"max_microseconds": frame_times[-1],
		"spikes_over_25ms": spikes,
		"window_focused_after_sample": window.has_focus(),
	}
