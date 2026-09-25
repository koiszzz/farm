extends SceneTree

const DEFAULT_SOURCE := "res://design/qa/2026-09-24/avatar-walk-v4-candidate/farmer_walk_v4-candidate.png"
const GRID := Vector2i(8, 4)
const ROW_NAMES := ["down", "left", "right", "up"]


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	var source := str(arguments[0]) if arguments.size() > 0 else DEFAULT_SOURCE
	var output_path := str(arguments[1]) if arguments.size() > 1 else "res://design/qa/2026-09-24/avatar-walk-v4-candidate/frame-analysis.json"
	var grid := Vector2i(int(arguments[2]), int(arguments[3])) if arguments.size() > 3 and str(arguments[2]).is_valid_int() and str(arguments[3]).is_valid_int() else GRID
	var image := Image.load_from_file(ProjectSettings.globalize_path(source))
	if image == null or image.is_empty():
		push_error("Unable to load " + source)
		quit(1)
		return
	var rows: Array[Dictionary] = []
	var seam_pixels := {"vertical": 0, "horizontal": 0}
	for y in range(1, grid.y):
		var seam_y := y * image.get_height() / grid.y
		for x in image.get_width():
			if image.get_pixel(x, seam_y).a > 0.05: seam_pixels.horizontal += 1
	for x in range(1, grid.x):
		var seam_x := x * image.get_width() / grid.x
		for y in image.get_height():
			if image.get_pixel(seam_x, y).a > 0.05: seam_pixels.vertical += 1
	for row in grid.y:
		var frames: Array[Image] = []
		var frame_data: Array[Dictionary] = []
		for column in grid.x:
			var from := Vector2i(column * image.get_width() / grid.x, row * image.get_height() / grid.y)
			var to := Vector2i((column + 1) * image.get_width() / grid.x, (row + 1) * image.get_height() / grid.y)
			var frame := image.get_region(Rect2i(from, to - from))
			frames.append(frame)
			var used := frame.get_used_rect()
			var foot := _foot_anchor(frame, used)
			frame_data.append({"frame": column, "cell": [from.x, from.y, to.x - from.x, to.y - from.y], "used_rect": [used.position.x, used.position.y, used.size.x, used.size.y], "foot_anchor": [foot.x, foot.y]})
		var adjacent: Array[float] = []
		for column in grid.x:
			adjacent.append(snappedf(_similarity(frames[column], frames[(column + 1) % grid.x]), 0.0001))
		var closest := {"frames": [0, 1], "similarity": -1.0}
		for left in grid.x:
			for right in range(left + 1, grid.x):
				var similarity := _similarity(frames[left], frames[right])
				if similarity > float(closest.similarity): closest = {"frames": [left, right], "similarity": snappedf(similarity, 0.0001)}
		var row_name: String = ROW_NAMES[row] if grid.y == ROW_NAMES.size() else "row_%d" % row
		rows.append({"direction": row_name, "frames": frame_data, "adjacent_similarity": adjacent, "closest_pair": closest, "foot_y_range": _foot_y_range(frame_data)})
	var report := {"source": source, "image_size": [image.get_width(), image.get_height()], "grid": [grid.x, grid.y], "total_frames": grid.x * grid.y, "seam_opaque_pixels": seam_pixels, "rows": rows, "metric": "1 minus mean RGBA absolute difference over union of non-transparent pixels; higher means more alike"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_path.get_base_dir()))
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		push_error("Unable to write " + output_path)
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit()


func _foot_anchor(frame: Image, used: Rect2i) -> Vector2:
	if used.size == Vector2i.ZERO: return Vector2.ZERO
	var low := used.end.y - 1
	var left := used.end.x
	var right := used.position.x
	for y in range(maxi(used.position.y, low - 6), low + 1):
		for x in range(used.position.x, used.end.x):
			if frame.get_pixel(x, y).a > 0.4:
				left = mini(left, x)
				right = maxi(right, x)
	return Vector2((left + right) / 2.0, used.end.y)


func _similarity(first: Image, second: Image) -> float:
	var difference := 0.0
	var samples := 0
	for y in mini(first.get_height(), second.get_height()):
		for x in mini(first.get_width(), second.get_width()):
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if a.a <= 0.02 and b.a <= 0.02: continue
			difference += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)) / 4.0
			samples += 1
	return 1.0 if samples == 0 else clampf(1.0 - difference / samples, 0.0, 1.0)


func _foot_y_range(frames: Array[Dictionary]) -> Array[int]:
	var low := 1000000
	var high := -1000000
	for frame in frames:
		var value := int(frame.foot_anchor[1])
		low = mini(low, value)
		high = maxi(high, value)
	return [low, high, high - low]
