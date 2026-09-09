extends RefCounted

## Generated sheets have uneven transparent padding. Measure each cell once,
## retaining a shared scale while anchoring the lowest opaque foot pixels.
static var _frames: Dictionary = {}

static func frame(texture: Texture2D, grid: Vector2i, column: int, row: int) -> Dictionary:
	var key := texture.resource_path + str(grid)
	if not _frames.has(key):
		var source := texture.get_image()
		if source.is_compressed(): source.decompress()
		var values: Array[Dictionary] = []
		for y in grid.y:
			for x in grid.x:
				var from := Vector2i(x * source.get_width() / grid.x, y * source.get_height() / grid.y)
				var to := Vector2i((x + 1) * source.get_width() / grid.x, (y + 1) * source.get_height() / grid.y)
				var cell := source.get_region(Rect2i(from, to - from))
				var used := cell.get_used_rect()
				var low := used.end.y - 1
				var left := used.end.x
				var right := used.position.x
				for py in range(maxi(used.position.y, low - 6), low + 1):
					for px in range(used.position.x, used.end.x):
						if cell.get_pixel(px, py).a > 0.4:
							left = mini(left, px)
							right = maxi(right, px)
				var anchor := Vector2((left + right) / 2.0, used.end.y)
				values.append({"region": Rect2(Vector2(from + used.position), Vector2(used.size)), "offset": Vector2(used.position) - anchor})
		_frames[key] = values
	return _frames[key][row * grid.x + column]
