extends SceneTree

const SOURCE := "res://assets/art/source_generated/farm_terrain_user_seasons_source_v1.png"
const OUTPUT := "res://assets/art/runtime_generated/farm_terrain_user_tiles_v1.png"
const MEADOW_OUTPUT := "res://assets/art/runtime_generated/farm_meadow_details_v1.png"
const TILE_PX := 32
const SOURCE_TILE_PX := 96
const SEASON_ORIGINS := [Vector2i(0, 0), Vector2i(768, 0), Vector2i(0, 500), Vector2i(768, 500)]
const PATH_X := [18, 129, 243, 355, 469, 618]
const SOIL_X := [20, 130, 244, 350]


func _init() -> void:
	call_deferred("_extract")


func _extract() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if source == null or source.is_empty():
		push_error("Could not load supplied terrain sheet: %s" % SOURCE)
		quit(1)
		return
	var atlas := Image.create(TILE_PX * 10, TILE_PX * 4, false, Image.FORMAT_RGBA8)
	var meadow_atlas := Image.create(TILE_PX * 6, TILE_PX * 4, false, Image.FORMAT_RGBA8)
	for season in 4:
		var origin: Vector2i = SEASON_ORIGINS[season]
		for tile_column in 6:
			var meadow_tile := _extract_tile(source, Rect2i(origin + Vector2i(PATH_X[tile_column], 0), Vector2i(SOURCE_TILE_PX, SOURCE_TILE_PX)), true)
			meadow_atlas.blit_rect(meadow_tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_PX, TILE_PX)), Vector2i(tile_column * TILE_PX, season * TILE_PX))
			var path_tile := _extract_tile(source, Rect2i(origin + Vector2i(PATH_X[tile_column], 128), Vector2i(SOURCE_TILE_PX, SOURCE_TILE_PX)), false)
			_matte_path_tile(path_tile)
			path_tile.resize(TILE_PX, TILE_PX, Image.INTERPOLATE_NEAREST)
			atlas.blit_rect(path_tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_PX, TILE_PX)), Vector2i(tile_column * TILE_PX, season * TILE_PX))
		_match_path_edges(atlas, season)
		for soil_column in 3:
			var soil_tile := _extract_tile(source, Rect2i(origin + Vector2i(SOIL_X[soil_column], 240), Vector2i(SOURCE_TILE_PX, SOURCE_TILE_PX)), true)
			_matte_soil_tile(soil_tile, soil_column, season)
			atlas.blit_rect(soil_tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_PX, TILE_PX)), Vector2i((6 + soil_column) * TILE_PX, season * TILE_PX))
		var water_tile := _extract_tile(source, Rect2i(origin + Vector2i(SOIL_X[3], 240), Vector2i(SOURCE_TILE_PX, SOURCE_TILE_PX)), false)
		atlas.blit_rect(water_tile, Rect2i(Vector2i.ZERO, Vector2i(TILE_PX, TILE_PX)), Vector2i(9 * TILE_PX, season * TILE_PX))
	var error := atlas.save_png(ProjectSettings.globalize_path(OUTPUT))
	if error != OK:
		push_error("Could not save extracted 32x32 terrain atlas: %s" % error)
		quit(1)
		return
	error = meadow_atlas.save_png(ProjectSettings.globalize_path(MEADOW_OUTPUT))
	if error != OK:
		push_error("Could not save extracted meadow detail atlas: %s" % MEADOW_OUTPUT)
		quit(1)
		return
	print("extracted terrain atlas=%s size=%s; tiles are 32x32" % [OUTPUT, atlas.get_size()])
	print("extracted meadow atlas=%s size=%s; tiles are 32x32" % [MEADOW_OUTPUT, meadow_atlas.get_size()])
	quit()


func _extract_tile(source: Image, region: Rect2i, remove_backdrop: bool) -> Image:
	var tile := source.get_region(region)
	if remove_backdrop:
		_remove_edge_backdrop(tile)
	tile.resize(TILE_PX, TILE_PX, Image.INTERPOLATE_NEAREST)
	return tile


func _matte_soil_tile(tile: Image, soil_column: int, season: int) -> void:
	# Every tilled-ground sprite must cover the complete 32x32 gameplay cell.
	# The supplied sheet has a transparent halo around its soil samples; composite
	# that halo over matching soil so adjacent tiles cannot expose the grass layer.
	var base_colors := [Color("895936"), Color("68482f"), Color("4e392d")]
	var seasonal_shift := [Color(1.0, 1.0, 1.0), Color(0.97, 1.04, 0.97), Color(1.12, 0.91, 0.78), Color(0.82, 0.89, 0.98)]
	var base: Color = base_colors[soil_column]
	var shift: Color = seasonal_shift[season]
	base = Color(base.r * shift.r, base.g * shift.g, base.b * shift.b, 1.0)
	for y in TILE_PX:
		for x in TILE_PX:
			var pixel := tile.get_pixel(x, y)
			var composited := pixel.lerp(base, 1.0 - pixel.a)
			composited.a = 1.0
			tile.set_pixel(x, y, composited)


func _matte_path_tile(tile: Image) -> void:
	# Unlike the grass fringe, soil and shadow pixels are part of the authored
	# road silhouette. Remove contact-sheet backdrop and any leftover green fringe
	# so the actual map meadow shows through the transparent edge of every tile.
	_remove_edge_backdrop(tile)
	for y in tile.get_height():
		for x in tile.get_width():
			var pixel := tile.get_pixel(x, y)
			if pixel.a <= 0.05:
				continue
			var green_fringe := pixel.g > pixel.r * 1.12 and pixel.g > pixel.b * 1.08 and pixel.s > 0.18
			if green_fringe:
				tile.set_pixel(x, y, Color.TRANSPARENT)


func _match_path_edges(atlas: Image, season: int) -> void:
	# Straight road tiles define shared pixel profiles. Corners, T-junctions and
	# crossings copy those same profiles on every connected side, so rotated
	# neighbors meet without a color step at the 32x32 boundary.
	var vertical_profile: Array[Color] = []
	var horizontal_profile: Array[Color] = []
	var vertical_x := TILE_PX
	var horizontal_x := TILE_PX * 2
	var row_y := season * TILE_PX
	for offset in TILE_PX:
		var top := atlas.get_pixel(vertical_x + offset, row_y)
		var bottom := atlas.get_pixel(vertical_x + offset, row_y + TILE_PX - 1)
		vertical_profile.append((top + bottom) * 0.5)
		var left := atlas.get_pixel(horizontal_x, row_y + offset)
		var right := atlas.get_pixel(horizontal_x + TILE_PX - 1, row_y + offset)
		horizontal_profile.append((left + right) * 0.5)
	var corner := (vertical_profile[0] + vertical_profile[TILE_PX - 1] + horizontal_profile[0] + horizontal_profile[TILE_PX - 1]) * 0.25
	vertical_profile[0] = corner
	vertical_profile[TILE_PX - 1] = corner
	horizontal_profile[0] = corner
	horizontal_profile[TILE_PX - 1] = corner
	for column in range(1, 6):
		var tile_x := column * TILE_PX
		if column in [1, 3, 4, 5]:
			for offset in TILE_PX:
				atlas.set_pixel(tile_x + offset, row_y, vertical_profile[offset])
				atlas.set_pixel(tile_x + offset, row_y + TILE_PX - 1, vertical_profile[offset])
		if column in [2, 3, 4, 5]:
			for offset in TILE_PX:
				atlas.set_pixel(tile_x, row_y + offset, horizontal_profile[offset])
				atlas.set_pixel(tile_x + TILE_PX - 1, row_y + offset, horizontal_profile[offset])


func _remove_edge_backdrop(tile: Image) -> void:
	var width := tile.get_width()
	var height := tile.get_height()
	var backdrop := (tile.get_pixel(0, 0) + tile.get_pixel(width - 1, 0) + tile.get_pixel(0, height - 1) + tile.get_pixel(width - 1, height - 1)) / 4.0
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue := PackedInt32Array()
	for x in width:
		_enqueue_if_backdrop(tile, backdrop, x, 0, width, height, visited, queue)
		_enqueue_if_backdrop(tile, backdrop, x, height - 1, width, height, visited, queue)
	for y in height:
		_enqueue_if_backdrop(tile, backdrop, 0, y, width, height, visited, queue)
		_enqueue_if_backdrop(tile, backdrop, width - 1, y, width, height, visited, queue)
	var cursor := 0
	while cursor < queue.size():
		var index := queue[cursor]
		cursor += 1
		var x := index % width
		var y := int(index / width)
		tile.set_pixel(x, y, Color.TRANSPARENT)
		for neighbor in [Vector2i(x - 1, y), Vector2i(x + 1, y), Vector2i(x, y - 1), Vector2i(x, y + 1)]:
			_enqueue_if_backdrop(tile, backdrop, neighbor.x, neighbor.y, width, height, visited, queue)


func _enqueue_if_backdrop(tile: Image, backdrop: Color, x: int, y: int, width: int, height: int, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	if x < 0 or y < 0 or x >= width or y >= height:
		return
	var index := y * width + x
	if visited[index] != 0:
		return
	var color := tile.get_pixel(x, y)
	if Vector3(color.r, color.g, color.b).distance_to(Vector3(backdrop.r, backdrop.g, backdrop.b)) > 0.16:
		return
	visited[index] = 1
	queue.append(index)
