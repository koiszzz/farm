extends SceneTree

const GRID := Vector2i(8, 4)
const CELL_SIZE := Vector2i(222, 222)
const MAX_DRAW_SIZE := Vector2i(180, 190)
const FOOT_MARGIN := 14


func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() < 2:
		push_error("Usage: npc_walk_sheet_pack.gd <source.png> <output.png>")
		quit(1)
		return
	var source_path := ProjectSettings.globalize_path(str(arguments[0]))
	var output_path := ProjectSettings.globalize_path(str(arguments[1]))
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Unable to read " + source_path)
		quit(1)
		return
	var output := Image.create(CELL_SIZE.x * GRID.x, CELL_SIZE.y * GRID.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	var frames: Array[Dictionary] = []
	for row in GRID.y:
		for column in GRID.x:
			var start := Vector2i(column * source.get_width() / GRID.x, row * source.get_height() / GRID.y)
			var end := Vector2i((column + 1) * source.get_width() / GRID.x, (row + 1) * source.get_height() / GRID.y)
			var cell := source.get_region(Rect2i(start, end - start))
			var bounds := _opaque_bounds(cell, 0.45)
			if bounds.size == Vector2i.ZERO:
				push_error("Frame has no opaque pixels: %d,%d" % [column, row])
				quit(1)
				return
			var scale := minf(float(MAX_DRAW_SIZE.x) / bounds.size.x, float(MAX_DRAW_SIZE.y) / bounds.size.y)
			var draw_size := Vector2i(roundi(bounds.size.x * scale), roundi(bounds.size.y * scale))
			var crop := cell.get_region(bounds)
			crop.resize(draw_size.x, draw_size.y, Image.INTERPOLATE_NEAREST)
			var destination := Vector2i((CELL_SIZE.x - draw_size.x) / 2, CELL_SIZE.y - FOOT_MARGIN - draw_size.y)
			output.blit_rect(crop, Rect2i(Vector2i.ZERO, draw_size), Vector2i(column * CELL_SIZE.x, row * CELL_SIZE.y) + destination)
			frames.append({"row": row, "column": column, "source_bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "packed_size": [draw_size.x, draw_size.y], "destination": [destination.x, destination.y]})
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var error := output.save_png(output_path)
	if error != OK:
		push_error("Unable to save packed sheet: " + str(error))
		quit(1)
		return
	print(JSON.stringify({"source": source_path, "output": output_path, "source_size": [source.get_width(), source.get_height()], "output_size": [output.get_width(), output.get_height()], "grid": [GRID.x, GRID.y], "foot_margin": FOOT_MARGIN, "frames": frames}))
	quit()


func _opaque_bounds(image: Image, threshold: float) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < threshold:
				continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	return Rect2i(left, top, right - left + 1, bottom - top + 1) if right >= left else Rect2i()
