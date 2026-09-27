extends SceneTree

const SOURCE_DIR := "res://assets/art/source_generated/"
const OUTPUT_DIR := "res://assets/art/runtime_generated/"
const BUILDING_BOARD := SOURCE_DIR + "user_reference_building_board_v1.png"

const BUILDING_CROPS := {
	"farmhouse_tier_1_reference_v1.png": Rect2i(165, 54, 312, 310),
	"farmhouse_tier_2_reference_v1.png": Rect2i(515, 52, 390, 316),
	"farmhouse_tier_3_reference_v1.png": Rect2i(944, 24, 508, 340),
	"farm_coop_tier_1_reference_v1.png": Rect2i(21, 390, 185, 226),
	"farm_coop_tier_2_reference_v1.png": Rect2i(213, 386, 222, 236),
	"farm_coop_tier_3_reference_v1.png": Rect2i(432, 376, 281, 239),
	"farm_barn_tier_1_reference_v1.png": Rect2i(721, 378, 199, 235),
	"farm_barn_tier_2_reference_v1.png": Rect2i(918, 374, 261, 240),
	"farm_barn_tier_3_reference_v1.png": Rect2i(1178, 365, 343, 252),
	"farm_silo_reference_v1.png": Rect2i(22, 650, 180, 320),
	"farm_greenhouse_repair_reference_v1.png": Rect2i(206, 679, 226, 285),
	"farm_greenhouse_reference_v1.png": Rect2i(430, 680, 280, 284),
	"farm_shed_reference_v1.png": Rect2i(652, 680, 220, 280),
	"farm_stable_reference_v1.png": Rect2i(854, 642, 292, 326),
	"farm_mill_reference_v1.png": Rect2i(1104, 642, 235, 326),
	"farm_fish_pond_reference_v1.png": Rect2i(1302, 672, 222, 288),
}


func _init() -> void:
	var board := _load_image(BUILDING_BOARD)
	for output_name in BUILDING_CROPS:
		var crop: Image = board.get_region(BUILDING_CROPS[output_name])
		_remove_connected_building_matte(crop)
		_clean_low_alpha(crop, 0.04)
		crop = crop.get_region(crop.get_used_rect())
		if output_name == "farmhouse_tier_1_reference_v1.png":
			_clip_to_polygons(crop, [
				PackedVector2Array([
					Vector2(143, 11), Vector2(154, 0), Vector2(166, 1), Vector2(181, 21), Vector2(199, 35),
					Vector2(220, 51), Vector2(238, 70), Vector2(250, 94), Vector2(250, 119), Vector2(250, 184),
					Vector2(259, 207), Vector2(284, 224), Vector2(296, 235), Vector2(278, 244), Vector2(260, 247), Vector2(244, 258),
					Vector2(64, 266), Vector2(39, 260), Vector2(19, 250), Vector2(5, 240), Vector2(0, 227),
					Vector2(8, 210), Vector2(12, 174), Vector2(15, 142), Vector2(23, 124), Vector2(38, 106),
					Vector2(65, 87), Vector2(103, 63), Vector2(128, 40)
				]),
				PackedVector2Array([Vector2(278, 22), Vector2(301, 21), Vector2(303, 39), Vector2(296, 45), Vector2(298, 69), Vector2(286, 77), Vector2(276, 66)])
			])
		elif output_name == "farm_coop_tier_1_reference_v1.png":
			_clip_to_polygons(crop, [
				PackedVector2Array([
					Vector2(53, 0), Vector2(140, 0), Vector2(147, 15), Vector2(141, 38), Vector2(145, 47),
					Vector2(148, 65), Vector2(147, 104), Vector2(144, 131), Vector2(140, 150), Vector2(25, 159),
					Vector2(0, 151), Vector2(0, 130), Vector2(12, 122), Vector2(14, 69), Vector2(27, 48),
					Vector2(39, 42), Vector2(42, 19)
				]),
				PackedVector2Array([Vector2(108, 106), Vector2(134, 103), Vector2(157, 112), Vector2(170, 132), Vector2(165, 153), Vector2(145, 160), Vector2(111, 154)])
			])
		elif output_name == "farm_barn_tier_1_reference_v1.png":
			_clip_to_polygons(crop, [PackedVector2Array([
				Vector2(90, 0), Vector2(111, 0), Vector2(136, 18), Vector2(160, 36), Vector2(179, 59),
				Vector2(190, 83), Vector2(194, 114), Vector2(188, 131), Vector2(198, 149), Vector2(191, 162),
				Vector2(3, 164), Vector2(0, 146), Vector2(18, 122), Vector2(19, 103), Vector2(24, 80),
				Vector2(40, 59), Vector2(60, 42)
			])])
		if output_name == "farmhouse_tier_1_reference_v1.png":
			_fill_masked_alpha_holes(crop, [
				PackedVector2Array([Vector2(144, 10), Vector2(153, 0), Vector2(166, 1), Vector2(180, 21), Vector2(201, 36), Vector2(222, 52), Vector2(239, 69), Vector2(248, 89), Vector2(251, 111), Vector2(244, 125), Vector2(223, 108), Vector2(204, 93), Vector2(180, 77), Vector2(157, 62), Vector2(144, 54), Vector2(123, 65), Vector2(100, 78), Vector2(76, 91), Vector2(52, 105), Vector2(34, 122), Vector2(17, 141), Vector2(20, 127), Vector2(39, 104), Vector2(70, 82), Vector2(108, 57), Vector2(129, 39)]),
				PackedVector2Array([Vector2(43, 111), Vector2(252, 111), Vector2(252, 218), Vector2(43, 218)]),
				PackedVector2Array([Vector2(277, 22), Vector2(303, 22), Vector2(305, 39), Vector2(297, 44), Vector2(300, 70), Vector2(286, 78), Vector2(275, 68)])
			])
		elif output_name == "farm_coop_tier_1_reference_v1.png":
			_fill_masked_alpha_holes(crop, [PackedVector2Array([Vector2(44, 57), Vector2(148, 57), Vector2(148, 145), Vector2(44, 145)])])
		elif output_name == "farm_barn_tier_1_reference_v1.png":
			_fill_masked_alpha_holes(crop, [PackedVector2Array([Vector2(31, 74), Vector2(168, 74), Vector2(168, 158), Vector2(31, 158)])])
		crop.save_png(OUTPUT_DIR + output_name)
	print("Extracted %d transparent building crops." % BUILDING_CROPS.size())
	_prepare_gendered_walker("user_reference_chicken_gender_sheet_v1.png", "farm_chicken_female_walk_v2.png", "farm_chicken_male_walk_v2.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_duck_gender_sheet_v1.png", "farm_duck_female_walk_v2.png", "farm_duck_male_walk_v2.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_cow_gender_sheet_v1.png", "farm_cow_female_walk_v2.png", "farm_cow_male_walk_v2.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_sheep_gender_sheet_v1.png", "farm_sheep_female_walk_v1.png", "farm_sheep_male_walk_v1.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_goat_gender_sheet_v1.png", "farm_goat_female_walk_v1.png", "farm_goat_male_walk_v1.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_pig_gender_sheet_v1.png", "farm_pig_female_walk_v1.png", "farm_pig_male_walk_v1.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_horse_gender_sheet_v1.png", "farm_horse_female_walk_v1.png", "farm_horse_male_walk_v1.png", 8, 4, 0, 4, [0, 1, 2, 3])
	_prepare_gendered_walker("user_reference_dog_gender_sheet_v1.png", "farm_dog_female_walk_v2.png", "farm_dog_male_walk_v2.png", 6, 4, 0, 3, [0, 1, 2, 1])
	_prepare_single_walker("user_reference_cat_walk_sheet_v1.png", "farm_cat_walk_v2.png", 8, 4)
	quit()


func _prepare_gendered_walker(source_name: String, female_name: String, male_name: String, grid_x: int, grid_y: int, female_start: int, frames_per_gender: int, sequence: Array) -> void:
	var source := _load_image(SOURCE_DIR + source_name)
	for variant in [{"name": female_name, "start": female_start}, {"name": male_name, "start": female_start + frames_per_gender}]:
		var atlas := _split_walker(source, grid_x, grid_y, int(variant.start), frames_per_gender, sequence)
		atlas.save_png(OUTPUT_DIR + str(variant.name))
	print("Prepared female/male atlas from %s." % source_name)


func _prepare_single_walker(source_name: String, output_name: String, grid_x: int, grid_y: int) -> void:
	var source := _load_image(SOURCE_DIR + source_name)
	var sequence: Array = []
	for frame_index in grid_x:
		sequence.append(frame_index)
	var atlas := _split_walker(source, grid_x, grid_y, 0, grid_x, sequence)
	atlas.save_png(OUTPUT_DIR + output_name)
	print("Prepared cat walk atlas from %s." % source_name)


func _split_walker(source: Image, grid_x: int, grid_y: int, start_column: int, output_frames: int, sequence: Array) -> Image:
	const INSET := 3
	var source_cell_width := float(source.get_width()) / float(grid_x)
	var source_cell_height := float(source.get_height()) / float(grid_y)
	var cell_width := floori(source_cell_width) - INSET * 2
	var cell_height := floori(source_cell_height) - INSET * 2
	var atlas := Image.create(cell_width * output_frames, cell_height * grid_y, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))
	for row in grid_y:
		for column in output_frames:
			var source_column := start_column + int(sequence[column])
			var left := floori(float(source_column) * source_cell_width) + INSET
			var top := floori(float(row) * source_cell_height) + INSET
			var cell := source.get_region(Rect2i(left, top, cell_width, cell_height))
			_remove_connected_dark_background(cell)
			_clean_low_alpha(cell, 0.10)
			atlas.blit_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(column * cell_width, row * cell_height))
	return atlas


func _remove_connected_dark_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[int] = []
	for x in width:
		_enqueue_background(image, visited, queue, x, width)
		_enqueue_background(image, visited, queue, (height - 1) * width + x, width)
	for y in height:
		_enqueue_background(image, visited, queue, y * width, width)
		_enqueue_background(image, visited, queue, y * width + width - 1, width)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % width
		var y := index / width
		image.set_pixel(x, y, Color(0, 0, 0, 0))
		if x > 0: _enqueue_background(image, visited, queue, index - 1, width)
		if x + 1 < width: _enqueue_background(image, visited, queue, index + 1, width)
		if y > 0: _enqueue_background(image, visited, queue, index - width, width)
		if y + 1 < height: _enqueue_background(image, visited, queue, index + width, width)


func _remove_connected_building_matte(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[int] = []
	for x in width:
		_enqueue_building_matte(image, visited, queue, x, width)
		_enqueue_building_matte(image, visited, queue, (height - 1) * width + x, width)
	for y in height:
		_enqueue_building_matte(image, visited, queue, y * width, width)
		_enqueue_building_matte(image, visited, queue, y * width + width - 1, width)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % width
		var y := index / width
		image.set_pixel(x, y, Color(0, 0, 0, 0))
		if x > 0: _enqueue_building_matte(image, visited, queue, index - 1, width)
		if x + 1 < width: _enqueue_building_matte(image, visited, queue, index + 1, width)
		if y > 0: _enqueue_building_matte(image, visited, queue, index - width, width)
		if y + 1 < height: _enqueue_building_matte(image, visited, queue, index + width, width)


func _enqueue_building_matte(image: Image, visited: PackedByteArray, queue: Array[int], index: int, width: int) -> void:
	if visited[index] != 0:
		return
	visited[index] = 1
	var color := image.get_pixel(index % width, index / width)
	var darkest := minf(color.r, minf(color.g, color.b))
	var brightest := maxf(color.r, maxf(color.g, color.b))
	# The source board uses a warm dark-brown matte instead of transparency.
	# Remove only low-saturation regions connected to the crop edge so the
	# saturated dark outline around the building remains intact.
	if brightest < 0.48 and brightest - darkest < 0.23:
		queue.append(index)


func _enqueue_background(image: Image, visited: PackedByteArray, queue: Array[int], index: int, width: int) -> void:
	if visited[index] != 0:
		return
	visited[index] = 1
	var color := image.get_pixel(index % width, index / width)
	if color.a < 0.88 and maxf(color.r, maxf(color.g, color.b)) < 0.30:
		queue.append(index)


func _clean_low_alpha(image: Image, threshold: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a <= threshold:
				image.set_pixel(x, y, Color(0, 0, 0, 0))


func _clip_to_polygons(image: Image, polygons: Array[PackedVector2Array]) -> void:
	var original := image.duplicate()
	for y in image.get_height():
		for x in image.get_width():
			var inside := false
			for polygon in polygons:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
					inside = true
					break
			if not inside:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
			elif original.get_pixel(x, y).a <= 0.04 and _has_nearby_building_pixel(original, x, y):
				# Matte removal can erase one-pixel seams between dark beams.
				# Seal only narrow cracks; do not fill the whole silhouette polygon.
				image.set_pixel(x, y, Color("493126"))


func _has_nearby_building_pixel(image: Image, x: int, y: int) -> bool:
	for offset_y in range(-2, 3):
		for offset_x in range(-2, 3):
			var sample_x := x + offset_x
			var sample_y := y + offset_y
			if sample_x < 0 or sample_y < 0 or sample_x >= image.get_width() or sample_y >= image.get_height():
				continue
			if image.get_pixel(sample_x, sample_y).a > 0.8:
				return true
	return false


func _fill_masked_alpha_holes(image: Image, polygons: Array[PackedVector2Array]) -> void:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.04:
				continue
			for polygon in polygons:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
					image.set_pixel(x, y, Color("38251c"))
					break


func _load_image(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image.is_compressed():
		image.decompress()
	return image
