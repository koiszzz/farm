extends SceneTree

const SOURCE := "res://assets/art/runtime_generated/farmer_walk_v3.png"
const GRID := Vector2i(8, 4)
const ROW_NAMES := ["down", "left", "right", "up"]


func _init() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Unable to load " + SOURCE)
		quit(1)
		return
	var rows: Array[Dictionary] = []
	for row in GRID.y:
		var frames: Array[Image] = []
		var frame_data: Array[Dictionary] = []
		for column in GRID.x:
			var from := Vector2i(column * source.get_width() / GRID.x, row * source.get_height() / GRID.y)
			var to := Vector2i((column + 1) * source.get_width() / GRID.x, (row + 1) * source.get_height() / GRID.y)
			var frame := source.get_region(Rect2i(from, to - from))
			frames.append(frame)
			var used := frame.get_used_rect()
			var foot := _foot_anchor(frame, used)
			frame_data.append({"frame": column, "source_rect": [from.x, from.y, to.x - from.x, to.y - from.y], "used_rect": [used.position.x, used.position.y, used.size.x, used.size.y], "foot_anchor": [foot.x, foot.y]})
		var adjacent: Array[float] = []
		for column in GRID.x:
			adjacent.append(snappedf(_similarity(frames[column], frames[(column + 1) % GRID.x]), 0.0001))
		var closest := {"frames": [0, 1], "similarity": -1.0}
		for left in GRID.x:
			for right in range(left + 1, GRID.x):
				var similarity := _similarity(frames[left], frames[right])
				if similarity > float(closest.similarity):
					closest = {"frames": [left, right], "similarity": snappedf(similarity, 0.0001)}
		rows.append({"direction": ROW_NAMES[row], "frames": frame_data, "adjacent_similarity": adjacent, "closest_pair": closest, "foot_y_range": _foot_y_range(frame_data)})
	var report := {"source": SOURCE, "image_size": [source.get_width(), source.get_height()], "grid": [GRID.x, GRID.y], "total_frames": GRID.x * GRID.y, "rows": rows, "metric": "1 - mean RGBA absolute difference across the union of non-transparent pixels; higher means more alike"}
	DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/avatar-walk-v3")
	FileAccess.open("res://design/qa/2026-09-24/avatar-walk-v3/frame-analysis.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print(JSON.stringify(report, "  "))
	quit()


func _foot_anchor(frame: Image, used: Rect2i) -> Vector2:
	if used.size == Vector2i.ZERO:
		return Vector2.ZERO
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
	var width := mini(first.get_width(), second.get_width())
	var height := mini(first.get_height(), second.get_height())
	var difference := 0.0
	var samples := 0
	for y in height:
		for x in width:
			var a := first.get_pixel(x, y)
			var b := second.get_pixel(x, y)
			if a.a <= 0.02 and b.a <= 0.02:
				continue
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
