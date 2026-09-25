class_name WorldRenderer
extends Node2D

## Renders the same cell classification used by MapData movement/collision.
## Each world cell samples the generated terrain source sheet; no whole-scene
## concept image is stretched beneath an unrelated navigation grid.

const TILE_SIZE := 32.0
const GRASS_HARMONIZE_TINT := Color(0.62, 0.66, 0.49, 0.16)
const TERRAIN_ART: Texture2D = preload("res://assets/art/runtime_generated/terrain_atlas_v2.png")
const TERRAIN_GRID := Vector2i(4, 2)
const SOFT_TERRAIN: Texture2D = preload("res://assets/art/runtime_generated/terrain_atlas_v8.png")
const COUNTRYSIDE_GRASS_ART: Texture2D = preload("res://assets/art/runtime_generated/countryside_grass_v1.svg")
const CAVE_FLOOR_ART: Texture2D = preload("res://assets/art/runtime_generated/cave_floor_v1.png")
const BEACH_PROPS_ART: Texture2D = preload("res://assets/art/runtime_generated/beach_props_v1.png")
const BEACH_COLLECTIBLES_ART: Texture2D = preload("res://assets/art/runtime_generated/beach_collectibles_v1.png")
const COMMUNITY_CENTER_ART: Texture2D = preload("res://assets/art/runtime_generated/community_center_v1.png")
const ORCHARD_ART: Texture2D = preload("res://assets/art/runtime_generated/orchard_trees_v1.png")
const ORCHARD_COLUMNS := {"apple": 0, "orange": 1, "peach": 2, "pomegranate": 3}
const BUILDINGS_ART: Texture2D = preload("res://assets/art/runtime_generated/village_buildings_v4.png")
const PROPS_ART: Texture2D = preload("res://assets/art/runtime_generated/village_props_v4.png")
const ROAD_ART: Texture2D = preload("res://assets/art/runtime_generated/road_transitions_v3.png")
const ROAD_GRID := Vector2i(4, 4)
const TOOLS_ART: Texture2D = preload("res://assets/art/source_generated/mvp_tools_and_seeds_source_v1.png")
const CROPS_ART: Texture2D = preload("res://assets/art/runtime_generated/crop_growth_v1.png")
const CROPS_SPRING_ART: Texture2D = preload("res://assets/art/runtime_generated/crop_growth_spring_v1.png")
const CROPS_SUMMER_ART: Texture2D = preload("res://assets/art/runtime_generated/crop_growth_summer_v1.png")
const CROPS_FALL_ART: Texture2D = preload("res://assets/art/runtime_generated/crop_growth_fall_v1.png")
const CROPS_WINTER_ART: Texture2D = preload("res://assets/art/runtime_generated/crop_growth_winter_v1.png")
const CropAtlas = preload("res://scripts/sprite_atlas.gd")
const FURNITURE_ART: Texture2D = preload("res://assets/art/source_generated/interior_furniture_source_v1.png")
const WorldObject = preload("res://scripts/world_object.gd")
const BeachWaterAmbience = preload("res://scripts/beach_water_ambience.gd")
const CaveAmbience = preload("res://scripts/cave_ambience.gd")
const TerrainChunk = preload("res://scripts/world_terrain_chunk.gd")
const Animals = preload("res://scripts/animal_state.gd")
const FURNITURE_REGIONS := [
	Rect2(65, 8, 225, 365), Rect2(385, 5, 320, 375), Rect2(780, 40, 320, 310), Rect2(1180, 75, 220, 260),
	Rect2(25, 385, 295, 370), Rect2(425, 377, 285, 380), Rect2(785, 370, 290, 390), Rect2(1150, 407, 260, 311),
	Rect2(20, 785, 370, 285), Rect2(430, 758, 280, 322), Rect2(790, 805, 295, 260), Rect2(1180, 780, 230, 275),
]
const DOOR_PROFILES := {
	"farmhouse_interior": {"building_id": "farmhouse", "uv": Rect2(0.475, 0.704, 0.105, 0.221), "animation": "hinge_right", "rug": [Color("7f9b62"), Color("e4d6aa")]},
	"general_store_interior": {"building_id": "general_store", "uv": Rect2(0.42, 0.709, 0.11, 0.218), "animation": "slide_left", "rug": [Color("6f9367"), Color("f0e3bd")]},
	"clinic_interior": {"building_id": "clinic", "uv": Rect2(0.47, 0.618, 0.11, 0.265), "animation": "hinge_left", "rug": [Color("8fa9ad"), Color("e9e3cf")]},
	"cafe_interior": {"building_id": "cafe", "uv": Rect2(0.42, 0.633, 0.11, 0.253), "animation": "double_fold", "rug": [Color("b76043"), Color("f0d8af")]},
}
var raised_objects: Array[Sprite2D] = []
var _all_raised_objects: Array[Sprite2D] = []
var object_nodes: Array[Sprite2D] = []
var _object_cache: Dictionary = {}
var _source_images: Dictionary = {}
var _door_layer: Node2D
var _door_cells: Array[Vector2i] = []
var _sign_nodes: Array[Node2D] = []
var _beach_ambience: Node2D
var _cave_ambience: Node2D
var _terrain_chunks: Dictionary = {}
var _pending_terrain_chunks: Array[Vector2i] = []
var _pending_terrain_chunk_keys: Dictionary = {}
var _pending_terrain_releases: Array[Vector2i] = []
var _pending_terrain_release_keys: Dictionary = {}
var _terrain_keep_bounds := Rect2i()

var navigation: MapData
var farm_state = null
var animal_state = null
var processing_state = null
var orchard_state = null
var community_state = null
var map_id := ""
var origin := Vector2.ZERO
var show_routes := false
var active_door := Vector2i(-1, -1)
var door_open := 0.0
var stream_center := Vector2i.ZERO
var stream_chunk := Vector2i(-999, -999)
var terrain_stream_chunk := Vector2i(-999, -999)
const STREAM_RADIUS := Vector2i(32, 22)
const TERRAIN_CHUNK_SIZE := 8


func configure(next_navigation: MapData, next_map_id: String, next_origin: Vector2, arrival := Vector2i(-1, -1)) -> void:
	if map_id != next_map_id:
		_clear_object_cache()
		_clear_terrain_chunks()
		for sign in _sign_nodes: sign.queue_free()
		_sign_nodes.clear()
	navigation = next_navigation
	map_id = next_map_id
	origin = next_origin
	stream_center = arrival if arrival != Vector2i(-1, -1) else navigation.get_spawn(map_id)
	stream_chunk = Vector2i(-999, -999)
	terrain_stream_chunk = Vector2i(-999, -999)
	_door_cells = navigation.get_door_cells(map_id)
	if _sign_nodes.is_empty():
		for entry in navigation.get_signposts(map_id):
			var sign := preload("res://scripts/world_sign.gd").new()
			sign.position = cell_center_to_screen(Vector2i(entry.post[0], entry.post[1]))
			sign.arrow = int(entry.arrow)
			sign.z_index = int(sign.position.y)
			add_child(sign)
			_sign_nodes.append(sign)
	_prime_object_cache()
	_rebuild_objects()
	_ensure_terrain_chunks(true)
	_update_beach_ambience()
	_update_cave_ambience()
	queue_redraw()

func _update_beach_ambience() -> void:
	if map_id == "beach" and _beach_ambience == null:
		_beach_ambience = BeachWaterAmbience.new()
		_beach_ambience.name = "BeachWaterAmbience"
		_beach_ambience.z_index = 1
		add_child(_beach_ambience)
	if _beach_ambience != null:
		_beach_ambience.configure(navigation, map_id, origin)
		_beach_ambience.set_animation_active(is_visible_in_tree() and map_id == "beach")


func _update_cave_ambience() -> void:
	if map_id in ["cave", "mine_2", "mine_3"] and _cave_ambience == null:
		_cave_ambience = CaveAmbience.new()
		_cave_ambience.name = "CaveTorchAmbience"
		_cave_ambience.z_index = 1
		add_child(_cave_ambience)
	if _cave_ambience != null:
		_cave_ambience.configure(map_id, origin, navigation.get_map_size(map_id))
		_cave_ambience.set_animation_active(is_visible_in_tree() and map_id in ["cave", "mine_2", "mine_3"])

func set_stream_center(cell: Vector2i, immediate := false) -> void:
	stream_center = cell
	var next_terrain_chunk := Vector2i(floori(float(cell.x) / TERRAIN_CHUNK_SIZE), floori(float(cell.y) / TERRAIN_CHUNK_SIZE))
	if next_terrain_chunk != terrain_stream_chunk:
		terrain_stream_chunk = next_terrain_chunk
		_ensure_terrain_chunks(immediate)
	var next_chunk := Vector2i(floori(float(cell.x) / 8.0), floori(float(cell.y) / 8.0))
	if next_chunk != stream_chunk:
		stream_chunk = next_chunk


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if _beach_ambience != null:
		_beach_ambience.set_animation_active(is_visible_in_tree() and map_id == "beach")
	if _cave_ambience != null:
		_cave_ambience.set_animation_active(is_visible_in_tree() and map_id in ["cave", "mine_2", "mine_3"])


func set_farm_state(next_farm_state) -> void:
	farm_state = next_farm_state
	_apply_season_tints()
	queue_redraw()


func set_animal_state(next_animal_state) -> void:
	animal_state = next_animal_state
	queue_redraw()


func set_processing_state(next_processing_state) -> void:
	processing_state = next_processing_state
	queue_redraw()


func set_orchard_state(next_orchard_state) -> void:
	orchard_state = next_orchard_state
	if navigation == null or map_id.is_empty(): return
	_rebuild_objects()
	_apply_season_tints()
	queue_redraw()


func set_community_state(next_community_state) -> void:
	community_state = next_community_state
	if navigation == null or map_id.is_empty(): return
	_rebuild_objects()
	queue_redraw()

func refresh_season() -> void:
	_apply_season_tints()
	for chunk_value in _terrain_chunks.values():
		var chunk: Node2D = chunk_value
		chunk.queue_redraw()
	queue_redraw()


func cell_to_screen(cell: Vector2i) -> Vector2:
	return origin + Vector2(cell) * TILE_SIZE


func cell_center_to_screen(cell: Vector2i) -> Vector2:
	return cell_to_screen(cell) + Vector2.ONE * TILE_SIZE * 0.5


func map_pixel_size() -> Vector2:
	if navigation == null:
		return Vector2.ZERO
	return Vector2(navigation.get_map_size(map_id)) * TILE_SIZE


func _draw() -> void:
	if navigation == null or map_id.is_empty() or not navigation.has_map(map_id):
		return
	if map_id.ends_with("_interior"):
		_draw_room()
		return
	var size := navigation.get_map_size(map_id)
	var bounds := Rect2i(Vector2i.ZERO, size)
	if map_id == "valley_world":
		bounds = Rect2i(stream_center - STREAM_RADIUS, STREAM_RADIUS * 2 + Vector2i.ONE).intersection(bounds)
		_draw_streamed_farm_plots(bounds)
	else:
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x):
				var cell := Vector2i(x, y)
				_draw_cell(cell)
	_draw_region_environment()
	_draw_object_grounding()
	if map_id == "farm_outdoor" or map_id == "valley_world":
		_draw_cottage_garden()
		_draw_animal_area()

	if farm_state != null and (map_id == "town_square" or map_id == "valley_world") and not farm_state.Calendar.festival(farm_state.day).is_empty():
		_draw_festival_bunting()
	if show_routes:
		_draw_npc_routes()


func _process(_delta: float) -> void:
	for index in mini(1, _pending_terrain_releases.size()):
		var release_key: Vector2i = _pending_terrain_releases.pop_front()
		_pending_terrain_release_keys.erase(release_key)
		var release_chunk: Node2D = _terrain_chunks.get(release_key)
		if release_chunk != null and not _terrain_keep_bounds.intersects(release_chunk.cell_bounds):
			remove_child(release_chunk)
			release_chunk.queue_free()
			_terrain_chunks.erase(release_key)
	for index in mini(1, _pending_terrain_chunks.size()):
		var chunk_key: Vector2i = _pending_terrain_chunks.pop_front()
		_pending_terrain_chunk_keys.erase(chunk_key)
		var chunk_bounds := Rect2i(chunk_key * TERRAIN_CHUNK_SIZE, Vector2i.ONE * TERRAIN_CHUNK_SIZE)
		if not _terrain_chunks.has(chunk_key) and _terrain_keep_bounds.intersects(chunk_bounds):
			_create_terrain_chunk(chunk_key)
	if _door_layer != null: _door_layer.queue_redraw()


func _clear_terrain_chunks() -> void:
	for chunk_value in _terrain_chunks.values():
		var chunk: Node2D = chunk_value
		if chunk.get_parent() == self:
			remove_child(chunk)
		chunk.queue_free()
	_terrain_chunks.clear()
	_pending_terrain_chunks.clear()
	_pending_terrain_chunk_keys.clear()
	_pending_terrain_releases.clear()
	_pending_terrain_release_keys.clear()
	_terrain_keep_bounds = Rect2i()


func _ensure_terrain_chunks(immediate: bool) -> void:
	if navigation == null or map_id != "valley_world":
		return
	var map_size := navigation.get_map_size(map_id)
	var map_bounds := Rect2i(Vector2i.ZERO, map_size)
	var padding := Vector2i.ONE * TERRAIN_CHUNK_SIZE * 2
	var wanted := Rect2i(stream_center - STREAM_RADIUS - padding, STREAM_RADIUS * 2 + padding * 2 + Vector2i.ONE).intersection(map_bounds)
	_terrain_keep_bounds = Rect2i(stream_center - STREAM_RADIUS - Vector2i(12, 12), STREAM_RADIUS * 2 + Vector2i(25, 25)).intersection(map_bounds)
	var first := Vector2i(floori(float(wanted.position.x) / TERRAIN_CHUNK_SIZE), floori(float(wanted.position.y) / TERRAIN_CHUNK_SIZE))
	var last_cell := wanted.end - Vector2i.ONE
	var last := Vector2i(floori(float(last_cell.x) / TERRAIN_CHUNK_SIZE), floori(float(last_cell.y) / TERRAIN_CHUNK_SIZE))
	for chunk_y in range(first.y, last.y + 1):
		for chunk_x in range(first.x, last.x + 1):
			var chunk_key := Vector2i(chunk_x, chunk_y)
			if _terrain_chunks.has(chunk_key):
				if _pending_terrain_release_keys.has(chunk_key):
					_pending_terrain_release_keys.erase(chunk_key)
					_pending_terrain_releases.erase(chunk_key)
				continue
			if immediate:
				if _pending_terrain_chunk_keys.has(chunk_key):
					_pending_terrain_chunk_keys.erase(chunk_key)
					_pending_terrain_chunks.erase(chunk_key)
				_create_terrain_chunk(chunk_key)
			elif not _pending_terrain_chunk_keys.has(chunk_key):
				_pending_terrain_chunks.append(chunk_key)
				_pending_terrain_chunk_keys[chunk_key] = true
	for chunk_value in _terrain_chunks.keys():
		var chunk_key: Vector2i = chunk_value
		var chunk: Node2D = _terrain_chunks[chunk_key]
		if _terrain_keep_bounds.intersects(chunk.cell_bounds) or _pending_terrain_release_keys.has(chunk_key):
			continue
		_pending_terrain_releases.append(chunk_key)
		_pending_terrain_release_keys[chunk_key] = true


func _create_terrain_chunk(chunk_key: Vector2i) -> void:
	var map_bounds := Rect2i(Vector2i.ZERO, navigation.get_map_size(map_id))
	var chunk := TerrainChunk.new()
	chunk.name = "Terrain_%d_%d" % [chunk_key.x, chunk_key.y]
	chunk.renderer = self
	chunk.cell_bounds = Rect2i(chunk_key * TERRAIN_CHUNK_SIZE, Vector2i.ONE * TERRAIN_CHUNK_SIZE).intersection(map_bounds)
	chunk.z_index = -100
	add_child(chunk)
	_terrain_chunks[chunk_key] = chunk


func draw_terrain_chunk(canvas: Node2D, bounds: Rect2i) -> void:
	if navigation == null or map_id != "valley_world":
		return
	var season: int = int(farm_state.Calendar.date(farm_state.day).season) if farm_state != null else 0
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			_draw_static_cell(canvas, Vector2i(x, y), season)


func _draw_static_cell(canvas: Node2D, cell: Vector2i, season: int) -> void:
	var layers := navigation.get_cell_layers(map_id, cell)
	var tile_class := navigation.get_cell_class(map_id, cell)
	var rect := Rect2(cell_to_screen(cell), Vector2.ONE * TILE_SIZE)
	var surface := str(layers.get("surface", "grass"))
	var terrain := Vector2i.ZERO
	if tile_class == "water": terrain = Vector2i(1, 1)
	elif surface == "path": terrain = Vector2i(1, 0)
	elif surface == "tillable": terrain = Vector2i(0, 1)
	var quadrant_size := SOFT_TERRAIN.get_size() / 2.0
	var sample_size := quadrant_size / 8.0
	var offset := Vector2(posmod(cell.x, 8), posmod(cell.y, 8)) * sample_size
	canvas.draw_texture_rect_region(SOFT_TERRAIN, rect, Rect2(Vector2(terrain) * quadrant_size + offset, sample_size))
	if surface == "grass": canvas.draw_rect(rect, GRASS_HARMONIZE_TINT)
	if tile_class == "water": _draw_static_water_bank(canvas, rect, cell)
	if tile_class == "solid" and str(layers.get("blocked_id", "")).contains("fence"):
		_draw_static_fence(canvas, rect, str(layers.get("blocked_id", "")).ends_with("west"))
	if surface == "path":
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not _has_path_at(cell + direction):
				_draw_static_path_edge(canvas, rect, cell, direction)
	if surface == "grass" and tile_class != "water":
		_draw_static_meadow_details(canvas, rect, cell)
	_draw_season_ground(canvas, rect, cell, surface, season)


func _draw_static_water_bank(canvas: Node2D, rect: Rect2, cell: Vector2i) -> void:
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbor: Vector2i = cell + direction
		if navigation.is_in_bounds(map_id, neighbor) and navigation.get_cell_class(map_id, neighbor) == "water": continue
		var normal := Vector2(direction)
		var tangent := normal.orthogonal()
		var edge := rect.get_center() + normal * 15
		canvas.draw_line(edge - tangent * 16, edge + tangent * 16, Color("76532f"), 6)
		canvas.draw_line(edge - tangent * 16 - normal * 3, edge + tangent * 16 - normal * 3, Color("d7a64f"), 4)
		for notch in 5:
			var point := edge + tangent * (-13 + notch * 7) - normal * (4 + posmod(cell.x + cell.y + notch, 3))
			canvas.draw_circle(point, 2, Color("e5c06a"))
	var corner_specs := [[Vector2i.LEFT, Vector2i.UP, Vector2.ZERO, Vector2(13, 0), Vector2(0, 13)], [Vector2i.RIGHT, Vector2i.UP, Vector2(32, 0), Vector2(19, 0), Vector2(32, 13)], [Vector2i.LEFT, Vector2i.DOWN, Vector2(0, 32), Vector2(13, 32), Vector2(0, 19)], [Vector2i.RIGHT, Vector2i.DOWN, Vector2(32, 32), Vector2(19, 32), Vector2(32, 19)]]
	for spec in corner_specs:
		if navigation.get_cell_class(map_id, cell + spec[0]) != "water" and navigation.get_cell_class(map_id, cell + spec[1]) != "water":
			canvas.draw_colored_polygon(PackedVector2Array([rect.position + spec[2], rect.position + spec[3], rect.position + spec[4]]), Color("d7a64f"))


func _draw_static_fence(canvas: Node2D, rect: Rect2, vertical: bool) -> void:
	var center := rect.get_center()
	var direction := Vector2.DOWN if vertical else Vector2.RIGHT
	canvas.draw_rect(Rect2(center + Vector2(-4, 7), Vector2(12, 6)), Color(0.20, 0.16, 0.06, 0.22))
	for offset in [-6, 3]:
		var cross := direction.orthogonal() * float(offset)
		canvas.draw_line(center - direction * 16 + cross, center + direction * 16 + cross, Color("694321"), 6)
		canvas.draw_line(center - direction * 16 + cross - Vector2(0, 1), center + direction * 16 + cross - Vector2(0, 1), Color("bc843b"), 3)
	canvas.draw_rect(Rect2(center - Vector2(4, 14), Vector2(9, 25)), Color("694321"))
	canvas.draw_rect(Rect2(center - Vector2(3, 14), Vector2(6, 22)), Color("ba8038"))
	canvas.draw_rect(Rect2(center - Vector2(3, 14), Vector2(6, 3)), Color("edbe67"))
	canvas.draw_rect(Rect2(center + Vector2(1, -8), Vector2(1, 14)), Color("92602b"))
	canvas.draw_rect(Rect2(center + Vector2(0, -5), Vector2(2, 2)), Color("573c29"))


func _draw_static_path_edge(canvas: Node2D, rect: Rect2, cell: Vector2i, direction: Vector2i) -> void:
	var normal := Vector2(direction)
	var tangent := normal.orthogonal()
	var middle := rect.get_center() + normal * 15
	for index in 8:
		var point := middle + tangent * (-14 + index * 4)
		var depth := float(posmod(cell.x * 13 + cell.y * 7 + index * 3, 4) + 2)
		canvas.draw_line(point - normal * depth, point + tangent * 4 - normal * depth, Color("ba8b3f"), 2)
		canvas.draw_line(point - normal, point - normal * depth, Color("759537"), 2)


func _draw_static_meadow_details(canvas: Node2D, rect: Rect2, cell: Vector2i) -> void:
	var value := posmod(cell.x * 73 + cell.y * 137, 101)
	if value > 11: return
	var point := rect.position + Vector2(5 + value % 21, 8 + (value * 7) % 18)
	canvas.draw_line(point, point + Vector2(-3, -4), Color("588632"), 2)
	canvas.draw_line(point + Vector2(2, 0), point + Vector2(3, -6), Color("90b940"), 2)
	if value < 3:
		var petal := Color("fff1b4") if value % 2 == 0 else Color("efb1aa")
		canvas.draw_rect(Rect2(point + Vector2(-3, -7), Vector2(6, 2)), petal)
		canvas.draw_rect(Rect2(point + Vector2(-1, -9), Vector2(2, 6)), petal)
		canvas.draw_rect(Rect2(point + Vector2(-1, -7), Vector2(2, 2)), Color("e5ab38"))


func _draw_season_ground(canvas: Node2D, rect: Rect2, cell: Vector2i, surface: String, season: int) -> void:
	# Keep the broad season palette and small landmarks in one path so streamed
	# continuous terrain and ordinary regional maps stay visually consistent.
	match season:
		1:
			if surface == "grass": canvas.draw_rect(rect, Color(0.22, 0.51, 0.18, 0.12))
		2:
			canvas.draw_rect(rect, Color(0.83, 0.46, 0.12, 0.35 if surface == "grass" else 0.12))
		3:
			canvas.draw_rect(rect, Color(0.86, 0.93, 0.96, 0.82 if surface == "grass" else 0.46))
	if surface != "grass": return
	var seed := posmod(cell.x * 47 + cell.y * 83, 97)
	var point := rect.position + Vector2(4 + seed % 23, 5 + (seed * 11) % 23)
	match season:
		0:
			if seed % 23 != 0: return
			var petal := Color("fff0bb") if seed % 2 == 0 else Color("eab4c2")
			canvas.draw_rect(Rect2(point + Vector2(-3, -2), Vector2(3, 3)), petal)
			canvas.draw_rect(Rect2(point + Vector2(2, 1), Vector2(3, 3)), Color("f2d789"))
			canvas.draw_rect(Rect2(point + Vector2(-1, 4), Vector2(2, 4)), Color("748f43"))
		1:
			if seed % 19 != 0: return
			canvas.draw_line(point, point + Vector2(-2, -5), Color("6c9c3d"), 2)
			canvas.draw_line(point + Vector2(3, 1), point + Vector2(4, -4), Color("9cbd4f"), 2)
		2:
			if seed % 11 != 0: return
			var leaf := Color("c77343") if seed % 2 == 0 else Color("d99745")
			canvas.draw_rect(Rect2(point, Vector2(5, 3)), leaf)
			canvas.draw_rect(Rect2(point + Vector2(3, 3), Vector2(3, 2)), leaf.darkened(0.14))
			canvas.draw_line(point + Vector2(1, 1), point + Vector2(5, 4), Color("e8b765"), 1)
		3:
			if seed % 6 != 0: return
			canvas.draw_line(point + Vector2(-3, 2), point + Vector2(7, 0), Color("d8e5e5", 0.68), 2)
			if seed % 2 == 0: canvas.draw_rect(Rect2(point + Vector2(8, 5), Vector2(2, 2)), Color("f1f4e7", 0.76))


func _draw_streamed_farm_plots(bounds: Rect2i) -> void:
	if farm_state == null:
		return
	for cell_value in farm_state.get_plots():
		var cell: Vector2i = cell_value
		_draw_farm_plot(cell, Rect2(cell_to_screen(cell), Vector2.ONE * TILE_SIZE))


func _world_object_entries() -> Array:
	var entries: Array = []
	for source_entry in navigation.get_objects(map_id):
		if str(source_entry.get("atlas", "")) == "community_center":
			var entry: Dictionary = source_entry.duplicate(true)
			var restored := community_state != null and bool(community_state.grand_reward)
			entry.index = [1 if restored else 0, 0]
			entries.append(entry)
		else:
			entries.append(source_entry)
	if orchard_state == null or map_id not in ["farm_outdoor", "valley_world"]: return entries
	var offset := navigation.to_contiguous_world("farm_outdoor", Vector2i.ZERO) if map_id == "valley_world" else Vector2i.ZERO
	for tree in orchard_state.trees:
		var world_cell := Vector2i(int(tree.x), int(tree.y)) + offset
		if map_id == "valley_world" and navigation.zone_at(map_id, world_cell) != "farm_outdoor": continue
		var tree_id := str(tree.type)
		var identity := "%s_%d_%d" % [tree_id, int(tree.x), int(tree.y)]
		var stage: int = orchard_state.growth_stage(tree, farm_state.day) if farm_state != null else 0
		entries.append({"id": "orchard_" + identity, "atlas": "orchard", "index": [ORCHARD_COLUMNS[tree_id], stage], "visual_rect": [world_cell.x - 1, world_cell.y - 2, 3, 3], "orchard_tree": tree.duplicate(true)})
	return entries


func _rebuild_objects() -> void:
	object_nodes.clear()
	raised_objects.clear()
	for cached_object in _object_cache.values():
		cached_object.visible = false
	if _door_layer == null:
		_door_layer = Node2D.new()
		_door_layer.z_index = 2048
		add_child(_door_layer)
		_door_layer.draw.connect(_draw_doors)
	for entry in _world_object_entries():
		var entry_rect: Array = entry.visual_rect
		if map_id == "valley_world" and not Rect2i(stream_center - STREAM_RADIUS - Vector2i(12, 12), STREAM_RADIUS * 2 + Vector2i(25, 25)).intersects(Rect2i(Vector2i(int(entry_rect[0]), int(entry_rect[1])), Vector2i(int(entry_rect[2]), int(entry_rect[3])))): continue
		var cache_key := str(entry.id)
		var object: Sprite2D = _object_cache.get(cache_key)
		if object == null:
			object = _create_world_object(entry)
			_object_cache[cache_key] = object
			if not entry.get("ground", false): _all_raised_objects.append(object)
		if str(entry.get("atlas", "")) in ["orchard", "community_center"]:
			var atlas_grid := Vector2(4, 4) if str(entry.atlas) == "orchard" else Vector2(2, 1)
			var frame_size: Vector2 = object.texture.get_size() / atlas_grid
			object.region_rect = Rect2(Vector2(int(entry.index[0]), int(entry.index[1])) * frame_size, frame_size)
		var visual_rect: Array = entry.visual_rect
		var visual_size := Vector2(visual_rect[2], visual_rect[3]) * TILE_SIZE
		object.position = origin + Vector2(visual_rect[0], visual_rect[1]) * TILE_SIZE
		object.scale = visual_size / object.region_rect.size
		object.z_index = int((float(visual_rect[1]) + float(visual_rect[3])) * TILE_SIZE)
		object.visible = not (map_id.ends_with("_interior") and cache_key == "rug")
		object_nodes.append(object)
		if not entry.get("ground", false): raised_objects.append(object)


func _clear_object_cache() -> void:
	for object_value in _object_cache.values():
		var object: Sprite2D = object_value
		if object.get_parent() == self:
			remove_child(object)
		object.queue_free()
	_object_cache.clear()
	object_nodes.clear()
	raised_objects.clear()
	_all_raised_objects.clear()


func _prime_object_cache() -> void:
	for entry in _world_object_entries():
		var cache_key := str(entry.id)
		if _object_cache.has(cache_key):
			continue
		var object := _create_world_object(entry)
		_object_cache[cache_key] = object
		if not entry.get("ground", false):
			_all_raised_objects.append(object)
	_apply_season_tints()


func _apply_season_tints() -> void:
	if farm_state == null or navigation == null or map_id.is_empty():
		return
	var entries_by_id: Dictionary = {}
	for entry in _world_object_entries():
		entries_by_id[str(entry.id)] = entry
	var season: int = farm_state.Calendar.date(farm_state.day).season
	for cache_key in _object_cache:
		var object: Sprite2D = _object_cache[cache_key]
		var entry: Dictionary = entries_by_id.get(cache_key, {})
		object.modulate = Color.WHITE
		if entry.get("atlas", "") == "props" and (str(cache_key).contains("tree") or str(cache_key).contains("bush")):
			if season == 2: object.modulate = Color("d78b58")
			elif season == 3: object.modulate = Color("c8d8d5")
		if str(cache_key).begins_with("orchard_"):
			object.modulate = Color.WHITE


func _create_world_object(entry: Dictionary) -> Sprite2D:
		var texture: Texture2D = FURNITURE_ART
		var grid := Vector2i(4, 3)
		match str(entry.atlas):
			"buildings": texture = BUILDINGS_ART; grid = Vector2i(2, 2)
			"props": texture = PROPS_ART; grid = Vector2i(4, 2)
			"beach_props": texture = BEACH_PROPS_ART; grid = Vector2i(4, 2)
			"beach_collectibles": texture = BEACH_COLLECTIBLES_ART; grid = Vector2i(4, 2)
			"community_center": texture = COMMUNITY_CENTER_ART; grid = Vector2i(2, 1)
			"orchard": texture = ORCHARD_ART; grid = Vector2i(4, 4)
		var object := WorldObject.new()
		object.name = str(entry.id)
		object.texture = texture
		if entry.atlas == "buildings":
			var roof_material := ShaderMaterial.new()
			roof_material.shader = preload("res://assets/art/runtime_generated/warm_roof.gdshader")
			object.material = roof_material
		object.centered = false
		object.region_enabled = true
		object.region_filter_clip_enabled = true
		var frame_size := texture.get_size() / Vector2(grid)
		object.region_rect = Rect2(Vector2(entry.index[0], entry.index[1]) * frame_size, frame_size)
		if entry.atlas == "furniture":
			# This source is hand packed, not an equal-cell atlas. Explicit bounds
			# prevent a shelf/rug from bleeding into the next row of furniture.
			object.region_rect = FURNITURE_REGIONS[int(entry.index[1]) * 4 + int(entry.index[0])]
		var r: Array = entry.visual_rect
		object.position = origin + Vector2(r[0], r[1]) * TILE_SIZE
		object.scale = Vector2(r[2], r[3]) * TILE_SIZE / object.region_rect.size
		if entry.atlas == "furniture":
			object.scale = Vector2.ONE * minf(object.scale.x, object.scale.y)
			object.position += (Vector2(r[2], r[3]) * TILE_SIZE - object.region_rect.size * object.scale) * Vector2(0.5, 1)
		object.z_index = 1 if entry.get("ground", false) else int((r[1] + r[3]) * TILE_SIZE)
		# The old one-size-fits-all carpet is retained in authored data for save/map
		# compatibility, but each room now draws a doorway mat from its exterior
		# door proportions and facade palette.
		object.visible = not (map_id.ends_with("_interior") and str(entry.id) == "rug")
		if not _source_images.has(texture.resource_path):
			var source := texture.get_image()
			if source.is_compressed(): source.decompress()
			_source_images[texture.resource_path] = source
		object.source_image = _source_images[texture.resource_path]
		add_child(object)
		return object


func is_actor_occluded(foot: Vector2) -> bool:
	for object in _all_raised_objects:
		if object.z_index <= int(foot.y): continue
		if absf(object.position.x - foot.x) > 512.0 or absf(object.position.y - foot.y) > 512.0: continue
		for offset in [Vector2(0, -36), Vector2(0, -28), Vector2(-6, -18), Vector2(6, -18), Vector2(0, -6), Vector2(0, -2)]:
			if object.covers(foot + offset): return true
	return false


func _draw_room() -> void:
	# Same 32 px world units and camera scale as outdoors. Furniture is separate
	# art with authored footprints, leaving every visible floor aisle playable.
	draw_rect(Rect2(origin, map_pixel_size()), Color("253330"))
	for y in range(4, 18):
		for x in range(7, 30):
			var rect := Rect2(cell_to_screen(Vector2i(x, y)), Vector2.ONE * TILE_SIZE)
			var color := Color("ad8056") if map_id != "clinic_interior" else Color("aebcad")
			for plank in 2:
				var start := rect.position + Vector2(0, plank * 16)
				var shade := color.lightened(float((x / 3 + y * 3 + plank) % 5) * 0.018)
				draw_rect(Rect2(start, Vector2(32, 16)), shade)
				draw_line(start, start + Vector2(32, 0), color.darkened(0.23), 1)
				draw_line(start + Vector2(0, 1), start + Vector2(32, 1), color.lightened(0.12), 1)
				if (x + y + plank) % 3 == 0: draw_line(start, start + Vector2(0, 16), color.darkened(0.19), 1)
				for grain in 2:
					var offset := Vector2((x * 7 + y * 11 + grain * 13) % 20, 5 + grain * 5)
					draw_line(start + offset, start + offset + Vector2(7, 0), shade.darkened(0.045), 1)
	var wall := Rect2(cell_to_screen(Vector2i(7, 2)), Vector2(23, 2) * TILE_SIZE)
	draw_rect(wall, Color("d4bf90"))
	draw_rect(Rect2(wall.position, Vector2(wall.size.x, 9)), Color("75543d"))
	draw_rect(Rect2(wall.position + Vector2(0, 57), Vector2(wall.size.x, 7)), Color("75543d"))
	for x in [10, 22, 27]:
		var window := Rect2(cell_to_screen(Vector2i(x, 2)) + Vector2(2, 14), Vector2(42, 35))
		draw_rect(window.grow(4), Color("805b3c"))
		draw_rect(window, Color("b9d8ca"))
		draw_line(window.get_center() - Vector2(0, 17), window.get_center() + Vector2(0, 17), Color("eee0b4"), 3)
	for x in [7, 30]: draw_rect(Rect2(Vector2(x * 32 - 5, 64), Vector2(6, 512)), Color("75543d"))
	for r in [Rect2(224, 576, 320, 8), Rect2(608, 576, 352, 8)]: draw_rect(r, Color("75543d"))
	_draw_entry_rug()


func _draw_doors() -> void:
	for cell in _door_cells:
		var amount := door_open if cell == active_door else 0.0
		if amount <= 0.0:
			continue
		var target := str(navigation.interaction_at(map_id, cell).get("target", ""))
		var profile := door_profile(target)
		var rect := door_visual_rect(cell)
		var source := door_source_rect(target)
		if profile.is_empty() or rect.size == Vector2.ZERO or source.size == Vector2.ZERO:
			continue
		_draw_animated_door(rect, source, profile, amount)


func door_profile(target: String) -> Dictionary:
	var profile = DOOR_PROFILES.get(target, {})
	return profile.duplicate(true) if profile is Dictionary else {}


func door_visual_rect(cell: Vector2i) -> Rect2:
	if navigation == null:
		return Rect2()
	var target := str(navigation.interaction_at(map_id, cell).get("target", ""))
	var profile := door_profile(target)
	var building := _building_entry(str(profile.get("building_id", "")))
	if building.is_empty():
		return Rect2()
	var values: Array = building.visual_rect
	var building_rect := Rect2(cell_to_screen(Vector2i(int(values[0]), int(values[1]))), Vector2(float(values[2]), float(values[3])) * TILE_SIZE)
	var uv: Rect2 = profile.uv
	return Rect2(building_rect.position + uv.position * building_rect.size, uv.size * building_rect.size)


func door_source_rect(target: String) -> Rect2:
	var profile := door_profile(target)
	var building := _building_entry(str(profile.get("building_id", "")))
	if building.is_empty():
		return Rect2()
	var frame_size := BUILDINGS_ART.get_size() / Vector2(2, 2)
	var frame_origin := Vector2(int(building.index[0]), int(building.index[1])) * frame_size
	var uv: Rect2 = profile.uv
	return Rect2(frame_origin + uv.position * frame_size, uv.size * frame_size)


func entrance_rug_size(interior_id := map_id) -> Vector2:
	var profile := door_profile(interior_id)
	if profile.is_empty():
		return Vector2(56, 24)
	var exterior_width_tiles: float = {"farmhouse_interior": 11.0, "general_store_interior": 11.0, "clinic_interior": 9.0, "cafe_interior": 10.0}.get(interior_id, 10.0)
	var uv: Rect2 = profile.uv
	var outside_door_width := exterior_width_tiles * TILE_SIZE * uv.size.x
	return Vector2(roundf(outside_door_width * 1.5), roundf(clampf(outside_door_width * 0.55, 20.0, 30.0)))


func _building_entry(building_id: String) -> Dictionary:
	if building_id.is_empty() or navigation == null:
		return {}
	for entry in navigation.get_objects(map_id):
		var entry_id := str(entry.get("id", ""))
		if entry_id == building_id or entry_id.ends_with("_" + building_id):
			return entry
	return {}


func _draw_animated_door(rect: Rect2, source: Rect2, profile: Dictionary, amount: float) -> void:
	_door_layer.draw_rect(rect.grow(1), Color("3b261f"))
	_door_layer.draw_rect(rect, Color("17191a"))
	var glow := Color("e6b568", 0.18 + amount * 0.34)
	_door_layer.draw_rect(rect.grow(-2), glow)
	match str(profile.animation):
		"hinge_right":
			var width := maxf(2.0, rect.size.x * (1.0 - amount * 0.88))
			_draw_door_texture(Rect2(rect.end.x - width, rect.position.y, width, rect.size.y), source)
			_door_layer.draw_line(Vector2(rect.end.x - width, rect.position.y), Vector2(rect.end.x - width, rect.end.y), Color("f2cf8a", amount * 0.65), 1)
		"hinge_left":
			var width := maxf(2.0, rect.size.x * (1.0 - amount * 0.88))
			_draw_door_texture(Rect2(rect.position, Vector2(width, rect.size.y)), source)
			_door_layer.draw_line(Vector2(rect.position.x + width, rect.position.y), Vector2(rect.position.x + width, rect.end.y), Color("d9edf0", amount * 0.55), 1)
		"slide_left":
			var visible_width := maxf(1.0, rect.size.x * (1.0 - amount * 0.96))
			var source_width := source.size.x * (visible_width / rect.size.x)
			_draw_door_texture(Rect2(rect.position, Vector2(visible_width, rect.size.y)), Rect2(source.position + Vector2(source.size.x - source_width, 0), Vector2(source_width, source.size.y)))
		"double_fold":
			var half_width := rect.size.x * 0.5
			var folded_width := maxf(1.0, half_width * (1.0 - amount * 0.84))
			var source_half := source.size.x * 0.5
			_draw_door_texture(Rect2(rect.position, Vector2(folded_width, rect.size.y)), Rect2(source.position, Vector2(source_half, source.size.y)))
			_draw_door_texture(Rect2(Vector2(rect.end.x - folded_width, rect.position.y), Vector2(folded_width, rect.size.y)), Rect2(source.position + Vector2(source_half, 0), Vector2(source_half, source.size.y)))


func _draw_door_texture(destination: Rect2, source: Rect2) -> void:
	_door_layer.draw_texture_rect_region(BUILDINGS_ART, destination, source)


func _draw_entry_rug() -> void:
	var profile := door_profile(map_id)
	if profile.is_empty():
		return
	var size := entrance_rug_size(map_id)
	var center := cell_center_to_screen(Vector2i(18, 17)) + Vector2(0, 3)
	var rect := Rect2(center - size * 0.5, size)
	var colors: Array = profile.rug
	var style := StyleBoxFlat.new()
	style.bg_color = colors[0]
	style.border_color = colors[1].darkened(0.28)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	draw_style_box(style, rect)
	var stripe_count := 3 if map_id in ["general_store_interior", "cafe_interior"] else 2
	for index in stripe_count:
		var stripe_x := rect.position.x + rect.size.x * float(index + 1) / float(stripe_count + 1)
		draw_rect(Rect2(Vector2(stripe_x - 2, rect.position.y + 3), Vector2(4, rect.size.y - 6)), colors[1])
	for x in range(int(rect.position.x) + 5, int(rect.end.x) - 4, 8):
		draw_line(Vector2(x, rect.end.y), Vector2(x, rect.end.y + 3), colors[1].darkened(0.18), 1)


func _draw_cell(cell: Vector2i) -> void:
	var layers := navigation.get_cell_layers(map_id, cell)
	var tile_class := navigation.get_cell_class(map_id, cell)
	var rect := Rect2(cell_to_screen(cell), Vector2.ONE * TILE_SIZE)
	var surface := str(layers.get("surface", "grass"))
	if map_id == "beach" or map_id == "cave" or map_id.begins_with("mine_"):
		_draw_region_cell(cell, rect, surface, tile_class)
		return
	var terrain := Vector2i.ZERO
	if tile_class == "water": terrain = Vector2i(1, 1)
	elif surface == "path": terrain = Vector2i(1, 0)
	elif surface == "tillable": terrain = Vector2i(0, 1)
	_draw_soft_terrain(rect, cell, terrain)
	if tile_class == "water": _draw_water_bank(rect, cell)
	if tile_class == "solid" and str(layers.get("blocked_id", "")).contains("fence"):
		_draw_fence(rect, str(layers.get("blocked_id", "")).ends_with("west"))
	if surface == "path":
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not _has_path_at(cell + direction):
				_draw_path_edge(rect, cell, direction)
	if surface == "grass" and tile_class != "water" and map_id != "countryside":
		_draw_meadow_details(rect, cell)
	if farm_state != null and surface == "tillable" and farm_state.get_cell_state(cell).get("watered", false):
		draw_rect(rect, Color(0.12, 0.10, 0.08, 0.30))
	if farm_state != null and tile_class != "water":
		var season: int = farm_state.Calendar.date(farm_state.day).season
		_draw_season_ground(self, rect, cell, surface, season)
	_draw_farm_plot(cell, rect)

	if show_routes:
		match tile_class:
			"solid": draw_rect(rect, Color("#c95d58", 0.45))
			"water": draw_rect(rect, Color("#55b8de", 0.38))
			"interaction": draw_rect(rect, Color("#ad6cc0", 0.38))
			"exit": draw_rect(rect, Color("#e176a8", 0.45))
			_:
				pass

	# These marks are deliberately debug-only. Normal gameplay renders only the
	# supplied artwork; M enables this authored-navigation inspection overlay.
	if show_routes and layers.has("interaction_record"):
		draw_circle(rect.get_center(), 2.5, Color("#e8d3ff", 0.88))
	if show_routes and layers.has("exit_record"):
		draw_rect(rect.grow(-1), Color("#f6b5d1"), false, 1.5)
		_draw_arrow(rect.get_center(), Color("#fff0fa"))


func _draw_region_cell(cell: Vector2i, rect: Rect2, surface: String, tile_class: String) -> void:
	var variation := posmod(cell.x * 17 + cell.y * 23, 11)
	if tile_class == "water":
		var water_color := Color("3e91a2") if map_id == "beach" else Color("3f536a")
		draw_rect(rect, water_color.lightened(float(variation % 3) * 0.018))
		if variation % 2 == 0:
			draw_line(rect.position + Vector2(3, 11), rect.position + Vector2(19, 11), Color("8dd5cf" if map_id == "beach" else "718499"), 2)
		if variation % 4 == 0:
			draw_line(rect.position + Vector2(15, 23), rect.position + Vector2(29, 23), Color("67b8bc" if map_id == "beach" else "596d82"), 1)
		return
	if map_id == "beach":
		draw_rect(rect, Color("d9bd82").lightened(float(variation % 4) * 0.012))
		if surface == "boardwalk":
			draw_rect(rect, Color("8b6747"))
			for y in range(0, 32, 8):
				draw_line(rect.position + Vector2(0, y), rect.position + Vector2(32, y), Color("594b38"), 1)
			draw_rect(Rect2(rect.position + Vector2(3, 4), Vector2(2, 2)), Color("d6ad73"))
			if cell.x == 25 or cell.x == 28:
				draw_circle(rect.position + Vector2(5 if cell.x == 25 else 27, 27), 3, Color("493d31"))
		else:
			if _adjacent_to_water(cell):
				draw_rect(rect, Color(0.42, 0.62, 0.55, 0.10))
			if variation < 4:
				var grain := rect.position + Vector2(6 + variation * 4, 18 + (variation % 2) * 5)
				draw_rect(Rect2(grain, Vector2(3, 2)), Color("b79a69"))
				draw_rect(Rect2(grain + Vector2(7, -5), Vector2(2, 1)), Color("efd79c"))
			if variation == 7:
				var shell := rect.position + Vector2(21, 12)
				draw_arc(shell, 4, PI, TAU, 6, Color("f4dfba"), 2)
	else:
		var texture_size := CAVE_FLOOR_ART.get_size()
		var map_size := Vector2(navigation.get_map_size(map_id))
		var sample_size := Vector2(texture_size) / map_size
		var source_position := Vector2(cell) * sample_size
		draw_texture_rect_region(CAVE_FLOOR_ART, rect, Rect2(source_position, sample_size))
		var depth_tint: Color = {
			"cave": Color("c8914d", 0.14),
			"mine_2": Color("5b9ba6", 0.18),
			"mine_3": Color("8862a4", 0.22),
		}.get(map_id, Color.TRANSPARENT)
		draw_rect(rect, depth_tint)
	var blocked_id := str(navigation.get_cell_layers(map_id, cell).get("blocked_id", ""))
	if map_id == "beach" and blocked_id == "beach_fishing_hut":
		return
	if tile_class == "solid":
		var rim := Color("817b70") if map_id == "beach" else Color("34333e")
		var face := Color("aaa18e") if map_id == "beach" else Color("4b4a59")
		draw_rect(rect, rim)
		draw_colored_polygon(PackedVector2Array([rect.position + Vector2(2, 8), rect.position + Vector2(8, 2), rect.position + Vector2(25, 3), rect.position + Vector2(30, 10), rect.position + Vector2(27, 25), rect.position + Vector2(5, 26)]), face)
		draw_line(rect.position + Vector2(8, 4), rect.position + Vector2(24, 5), Color("d3c8ae") if map_id == "beach" else Color("777486"), 2)


func _adjacent_to_water(cell: Vector2i) -> bool:
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if navigation.is_in_bounds(map_id, cell + direction) and navigation.get_cell_class(map_id, cell + direction) == "water":
			return true
	return false


func _draw_region_environment() -> void:
	match map_id:
		"beach": _draw_beach_landmarks()
		"countryside": _draw_country_bridge()
		"town_square": _draw_town_plaza()
		"cave", "mine_2", "mine_3": _draw_cave_landmarks()


func _draw_town_plaza() -> void:
	# Make the shared square read as a civic gathering place. This sits below
	# sprites and residents, so benches, fountain and foot traffic stay legible.
	var top_left := cell_to_screen(Vector2i(17, 13)) + Vector2(2, 2)
	var plaza := Rect2(top_left, Vector2(14 * TILE_SIZE - 4, 7 * TILE_SIZE - 4))
	draw_rect(plaza, Color("d4c8ae", 0.27))
	draw_rect(plaza, Color("706856", 0.34), false, 2)
	draw_rect(plaza.grow(-5), Color("eadbb8", 0.20), false, 1)
	for row in range(1, 7):
		var y := top_left.y + float(row) * TILE_SIZE
		draw_line(Vector2(top_left.x + 2, y), Vector2(plaza.end.x - 2, y), Color("796f5c", 0.13), 1)
		var y_top := top_left.y + float(row - 1) * TILE_SIZE
		var stagger := 0.0 if row % 2 == 0 else TILE_SIZE
		for column in range(1, 14, 2):
			var x := top_left.x + float(column) * TILE_SIZE + stagger
			if x < plaza.end.x - 2:
				draw_line(Vector2(x, y_top + 2), Vector2(x, minf(y_top + TILE_SIZE, plaza.end.y - 2)), Color("796f5c", 0.13), 1)


func _draw_country_bridge() -> void:
	# Give the existing creek crossing a distinct wooden silhouette. This is
	# strictly a visual overlay: navigation still comes from the authored path
	# surface and keeps the same 8x5 bridge footprint.
	var bridge_origin := cell_to_screen(Vector2i(29, 23))
	var bridge_rect := Rect2(bridge_origin + Vector2(2, 2), Vector2(4 * TILE_SIZE - 4, 3 * TILE_SIZE - 4))
	draw_rect(bridge_rect.grow(3), Color("443629"))
	draw_rect(bridge_rect, Color("9b7046"))
	draw_rect(Rect2(bridge_rect.position, Vector2(bridge_rect.size.x, 5)), Color("c49a65"))
	for plank_y in range(int(bridge_rect.position.y) + 13, int(bridge_rect.end.y) - 4, 16):
		draw_line(Vector2(bridge_rect.position.x + 3, plank_y), Vector2(bridge_rect.end.x - 3, plank_y), Color("684c38"), 2)
		draw_line(Vector2(bridge_rect.position.x + 5, plank_y + 2), Vector2(bridge_rect.end.x - 5, plank_y + 2), Color("b88a58"), 1)
	# Low rails and evenly spaced posts frame the crossing without blocking it.
	for rail_y in [bridge_rect.position.y + 5, bridge_rect.end.y - 5]:
		draw_line(Vector2(bridge_rect.position.x + 3, rail_y), Vector2(bridge_rect.end.x - 3, rail_y), Color("5c4938"), 4)
		draw_line(Vector2(bridge_rect.position.x + 3, rail_y - 2), Vector2(bridge_rect.end.x - 3, rail_y - 2), Color("d0a36a"), 2)
		for post_x in range(int(bridge_rect.position.x) + 9, int(bridge_rect.end.x) - 5, TILE_SIZE):
			draw_rect(Rect2(Vector2(post_x, rail_y - 6), Vector2(5, 12)), Color("76583d"))
			draw_rect(Rect2(Vector2(post_x + 1, rail_y - 5), Vector2(2, 4)), Color("d2a46b"))


func _draw_beach_landmarks() -> void:
	# Shoreline landmarks are authored as depth-sorted sprite objects in the map
	# data so they share a style and anchor with the rest of the world art.
	pass


func _draw_cave_landmarks() -> void:
	# Both mine interactions are visible physical ladders instead of invisible
	# action cells. Each deep level carries its own ore/rubble layout and palette.
	var accent := Color("c99449") if map_id == "cave" else (Color("85a7ad") if map_id == "mine_2" else Color("a889b7"))
	for ladder_cell in [Vector2i(18, 4), Vector2i(18, 24)]:
		var ladder := cell_to_screen(ladder_cell) + Vector2(7, 1)
		draw_rect(Rect2(ladder + Vector2(-3, -2), Vector2(24, 31)), Color(0.10, 0.09, 0.12, 0.52))
		draw_line(ladder, ladder + Vector2(0, 27), Color("8a5d37"), 4)
		draw_line(ladder + Vector2(17, 0), ladder + Vector2(17, 27), Color("8a5d37"), 4)
		for rung in range(4, 26, 7):
			draw_line(ladder + Vector2(1, rung), ladder + Vector2(16, rung), accent, 3)
	for x in [12, 24]:
		var beam := cell_to_screen(Vector2i(x, 12))
		draw_rect(Rect2(beam + Vector2(3, 0), Vector2(8, 96)), Color("4b352c"))
		draw_rect(Rect2(beam + Vector2(21, 0), Vector2(8, 96)), Color("4b352c"))
		draw_rect(Rect2(beam, Vector2(32, 9)), Color("76513a"))


func _draw_terrain_tile(destination: Rect2, index: Vector2i) -> void:
	var source_size := TERRAIN_ART.get_size()
	var source_cell := Vector2(source_size.x / TERRAIN_GRID.x, source_size.y / TERRAIN_GRID.y)
	var source_rect := Rect2(Vector2(index) * source_cell, source_cell)
	draw_texture_rect_region(TERRAIN_ART, destination, source_rect)


func _draw_soft_terrain(destination: Rect2, cell: Vector2i, quadrant: Vector2i) -> void:
	if map_id == "countryside" and quadrant == Vector2i.ZERO:
		var tile_size := Vector2(COUNTRYSIDE_GRASS_ART.get_size()) / 8.0
		var tile_offset := Vector2(posmod(cell.x, 8), posmod(cell.y, 8)) * tile_size
		draw_texture_rect_region(COUNTRYSIDE_GRASS_ART, destination, Rect2(tile_offset, tile_size))
		draw_rect(destination, GRASS_HARMONIZE_TINT)
		return
	var quadrant_size := SOFT_TERRAIN.get_size() / 2.0
	var sample_size := quadrant_size / 8.0
	var offset := Vector2(posmod(cell.x, 8), posmod(cell.y, 8)) * sample_size
	draw_texture_rect_region(SOFT_TERRAIN, destination, Rect2(Vector2(quadrant) * quadrant_size + offset, sample_size))
	if quadrant == Vector2i.ZERO: draw_rect(destination, GRASS_HARMONIZE_TINT)

func _draw_water_bank(rect: Rect2, cell: Vector2i) -> void:
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbor: Vector2i = cell + direction
		if navigation.is_in_bounds(map_id, neighbor) and navigation.get_cell_class(map_id, neighbor) == "water": continue
		var normal := Vector2(direction)
		var tangent := normal.orthogonal()
		var edge := rect.get_center() + normal * 15
		draw_line(edge - tangent * 16, edge + tangent * 16, Color("76532f"), 6)
		draw_line(edge - tangent * 16 - normal * 3, edge + tangent * 16 - normal * 3, Color("d7a64f"), 4)
		for notch in 5:
			var point := edge + tangent * (-13 + notch * 7) - normal * (4 + posmod(cell.x + cell.y + notch, 3))
			draw_circle(point, 2, Color("e5c06a"))
	var corner_specs := [[Vector2i.LEFT, Vector2i.UP, Vector2.ZERO, Vector2(13, 0), Vector2(0, 13)], [Vector2i.RIGHT, Vector2i.UP, Vector2(32, 0), Vector2(19, 0), Vector2(32, 13)], [Vector2i.LEFT, Vector2i.DOWN, Vector2(0, 32), Vector2(13, 32), Vector2(0, 19)], [Vector2i.RIGHT, Vector2i.DOWN, Vector2(32, 32), Vector2(19, 32), Vector2(32, 19)]]
	for spec in corner_specs:
		if navigation.get_cell_class(map_id, cell + spec[0]) != "water" and navigation.get_cell_class(map_id, cell + spec[1]) != "water":
			draw_colored_polygon(PackedVector2Array([rect.position + spec[2], rect.position + spec[3], rect.position + spec[4]]), Color("d7a64f"))


func _draw_fence(rect: Rect2, vertical: bool) -> void:
	var center := rect.get_center()
	var direction := Vector2.DOWN if vertical else Vector2.RIGHT
	draw_rect(Rect2(center + Vector2(-4, 7), Vector2(12, 6)), Color(0.20, 0.16, 0.06, 0.22))
	for offset in [-6, 3]:
		var cross: Vector2 = direction.orthogonal() * float(offset)
		draw_line(center - direction * 16 + cross, center + direction * 16 + cross, Color("694321"), 6)
		draw_line(center - direction * 16 + cross - Vector2(0, 1), center + direction * 16 + cross - Vector2(0, 1), Color("bc843b"), 3)
	draw_rect(Rect2(center - Vector2(4, 14), Vector2(9, 25)), Color("694321"))
	draw_rect(Rect2(center - Vector2(3, 14), Vector2(6, 22)), Color("ba8038"))
	draw_rect(Rect2(center - Vector2(3, 14), Vector2(6, 3)), Color("edbe67"))
	draw_rect(Rect2(center + Vector2(1, -8), Vector2(1, 14)), Color("92602b"))
	draw_rect(Rect2(center + Vector2(0, -5), Vector2(2, 2)), Color("573c29"))


func _draw_path_edge(rect: Rect2, cell: Vector2i, direction: Vector2i) -> void:
	var normal := Vector2(direction)
	var tangent := normal.orthogonal()
	var middle := rect.get_center() + normal * 15
	for index in 8:
		var point := middle + tangent * (-14 + index * 4)
		var depth := float(posmod(cell.x * 13 + cell.y * 7 + index * 3, 4) + 2)
		draw_line(point - normal * depth, point + tangent * 4 - normal * depth, Color("ba8b3f"), 2)
		draw_line(point - normal, point - normal * depth, Color("759537"), 2)


func _draw_meadow_details(rect: Rect2, cell: Vector2i) -> void:
	# Stable world coordinates avoid flickering/randomizing decoration on redraw.
	var value := posmod(cell.x * 73 + cell.y * 137, 101)
	if value > 11: return
	var point := rect.position + Vector2(5 + value % 21, 8 + (value * 7) % 18)
	draw_line(point, point + Vector2(-3, -4), Color("588632"), 2)
	draw_line(point + Vector2(2, 0), point + Vector2(3, -6), Color("90b940"), 2)
	if value < 3:
		var petal := Color("fff1b4") if value % 2 == 0 else Color("efb1aa")
		draw_rect(Rect2(point + Vector2(-3, -7), Vector2(6, 2)), petal)
		draw_rect(Rect2(point + Vector2(-1, -9), Vector2(2, 6)), petal)
		draw_rect(Rect2(point + Vector2(-1, -7), Vector2(2, 2)), Color("e5ab38"))


func _draw_object_grounding() -> void:
	for entry in navigation.get_objects(map_id):
		if entry.get("ground", false): continue
		var r: Array = entry.visual_rect
		var base := origin + Vector2(r[0], r[1] + r[3]) * TILE_SIZE
		var width := float(r[2]) * TILE_SIZE
		var points := PackedVector2Array([base + Vector2(width * 0.1, -9), base + Vector2(width * 0.88, -9), base + Vector2(width * 0.97, 5), base + Vector2(width * 0.2, 5)])
		draw_colored_polygon(points, Color(0.22, 0.26, 0.08, 0.22))


func _draw_cottage_garden() -> void:
	# Low flowers flank the authored front door; the central approach stays clear.
	for column in [10, 18]:
		var cell := Vector2i(column, 10)
		if map_id == "valley_world": cell = navigation.to_contiguous_world("farm_outdoor", cell)
		var base := cell_to_screen(cell) + Vector2(1, 0)
		draw_rect(Rect2(base + Vector2(2, 16), Vector2(62, 7)), Color(0.23, 0.20, 0.08, 0.22))
		draw_rect(Rect2(base, Vector2(62, 19)), Color("694124"))
		draw_rect(Rect2(base + Vector2(2, 2), Vector2(58, 14)), Color("a16b32"))
		for plank in 7:
			draw_line(base + Vector2(5 + plank * 8, 3), base + Vector2(5 + plank * 8, 15), Color("cb944b"), 2)
		for blossom in 8:
			var point := base + Vector2(5 + blossom * 7, 2 - (blossom % 2) * 4)
			draw_rect(Rect2(point - Vector2(4, 2), Vector2(9, 6)), Color("3e722e"))
			draw_rect(Rect2(point + Vector2(0, -5), Vector2(5, 6)), Color("75a43b"))
			var color := Color("f1a6a4") if blossom % 3 != 0 else Color("fff1c0")
			draw_rect(Rect2(point - Vector2(2, 6), Vector2(6, 2)), color)
			draw_rect(Rect2(point - Vector2(0, 8), Vector2(2, 6)), color)
			draw_rect(Rect2(point - Vector2(0, 6), Vector2(2, 2)), Color("edc44e"))


func _draw_animal_area() -> void:
	if animal_state == null or (not animal_state.coop_built and not animal_state.barn_built):
		return
	if animal_state.coop_built:
		var coop_visible := true
		if map_id == "valley_world":
			coop_visible = navigation.zone_at(map_id, _farm_visual_cell(Animals.COOP_RECT.position)) == "farm_outdoor"
		if coop_visible:
			var coop_cell := _farm_visual_cell(Animals.COOP_RECT.position)
			var top_left := cell_to_screen(coop_cell + Vector2i(0, -2))
			var width := float(Animals.COOP_RECT.size.x) * TILE_SIZE
			# Deep shadow, timber facade and a broad roof make the coop read as a farm
			# building at the same camera scale as the farmhouse.
			draw_rect(Rect2(top_left + Vector2(7, 112), Vector2(width - 2, 116)), Color(0.18, 0.13, 0.08, 0.24))
			draw_rect(Rect2(top_left + Vector2(10, 91), Vector2(width - 20, 133)), Color("a9673f"))
			for plank in range(20, int(width) - 20, 28):
				draw_line(top_left + Vector2(plank, 94), top_left + Vector2(plank, 220), Color("75452f"), 2)
			draw_colored_polygon(PackedVector2Array([top_left + Vector2(0, 104), top_left + Vector2(38, 30), top_left + Vector2(width - 38, 30), top_left + Vector2(width, 104)]), Color("7e4f3a"))
			draw_colored_polygon(PackedVector2Array([top_left + Vector2(13, 96), top_left + Vector2(45, 43), top_left + Vector2(width - 45, 43), top_left + Vector2(width - 13, 96)]), Color("b4734a"))
			var door := top_left + Vector2(width * 0.5 - 25, 150)
			draw_rect(Rect2(door, Vector2(50, 74)), Color("4f382e"))
			draw_rect(Rect2(door + Vector2(7, 9), Vector2(36, 65)), Color("704a34"))
			draw_circle(door + Vector2(36, 42), 3, Color("d5a84a"))
			for window_x in [36.0, width - 72.0]:
				draw_rect(Rect2(top_left + Vector2(window_x, 126), Vector2(36, 31)), Color("4d392f"))
				draw_rect(Rect2(top_left + Vector2(window_x + 5, 131), Vector2(26, 21)), Color("b8d4bd"))
				draw_line(top_left + Vector2(window_x + 18, 131), top_left + Vector2(window_x + 18, 152), Color("f0dda8"), 2)
	var trough_cell := _farm_visual_cell(Vector2i(53, 29))
	if animal_state.coop_built:
		var trough := cell_to_screen(trough_cell) + Vector2(2, 14)
		draw_rect(Rect2(trough + Vector2(2, 6), Vector2(58, 12)), Color(0.18, 0.13, 0.08, 0.22))
		draw_rect(Rect2(trough, Vector2(62, 14)), Color("755039"))
		draw_rect(Rect2(trough + Vector2(4, 3), Vector2(54, 7)), Color("d3b46a"))
	# The fence uses the same physical cells returned by AnimalState. The open
	# south gate leaves a clear route for entering the pen and petting chickens.
	for local_cell in animal_state.structure_cells():
		if Animals.COOP_RECT.has_point(local_cell) or Animals.BARN_RECT.has_point(local_cell): continue
		var world_cell := _farm_visual_cell(local_cell)
		var rect := Rect2(cell_to_screen(world_cell), Vector2.ONE * TILE_SIZE)
		var vertical: bool = local_cell.x == Animals.PEN_RECT.position.x or local_cell.x == Animals.PEN_RECT.end.x - 1 or local_cell.x == Animals.BARN_PEN_RECT.position.x or local_cell.x == Animals.BARN_PEN_RECT.end.x - 1
		_draw_fence(rect, vertical)
	_draw_barn_area()


func _draw_barn_area() -> void:
	if animal_state == null or not animal_state.barn_built:
		return
	if map_id == "valley_world" and navigation.zone_at(map_id, _farm_visual_cell(Animals.BARN_RECT.position)) != "farm_outdoor":
		return
	var barn_cell := _farm_visual_cell(Animals.BARN_RECT.position)
	var top_left := cell_to_screen(barn_cell + Vector2i(0, -2))
	var width := float(Animals.BARN_RECT.size.x) * TILE_SIZE
	# The barn reads larger and heavier than the coop: stone footings, a wide
	# timber facade and a hayloft gable, so the two livestock buildings are
	# distinguishable at the 1.5x camera.
	draw_rect(Rect2(top_left + Vector2(6, 116), Vector2(width - 2, 118)), Color(0.16, 0.11, 0.07, 0.26))
	draw_rect(Rect2(top_left + Vector2(8, 92), Vector2(width - 16, 138)), Color("8d5a34"))
	for plank in range(22, int(width) - 22, 32):
		draw_line(top_left + Vector2(plank, 96), top_left + Vector2(plank, 226), Color("66402a"), 2)
	draw_colored_polygon(PackedVector2Array([top_left + Vector2(-2, 106), top_left + Vector2(48, 26), top_left + Vector2(width - 48, 26), top_left + Vector2(width + 2, 106)]), Color("6f4433"))
	draw_colored_polygon(PackedVector2Array([top_left + Vector2(12, 98), top_left + Vector2(56, 42), top_left + Vector2(width - 56, 42), top_left + Vector2(width - 12, 98)]), Color("9c6240"))
	# Hayloft opening in the gable.
	draw_rect(Rect2(top_left + Vector2(width * 0.5 - 17, 52), Vector2(34, 26)), Color("4f382e"))
	draw_rect(Rect2(top_left + Vector2(width * 0.5 - 12, 57), Vector2(24, 16)), Color("d3b46a"))
	# Double barn doors.
	var door := top_left + Vector2(width * 0.5 - 38, 148)
	draw_rect(Rect2(door, Vector2(76, 82)), Color("4f382e"))
	draw_rect(Rect2(door + Vector2(5, 7), Vector2(31, 75)), Color("70492f"))
	draw_rect(Rect2(door + Vector2(40, 7), Vector2(31, 75)), Color("70492f"))
	draw_line(door + Vector2(38, 8), door + Vector2(38, 80), Color("d5a84a"), 3)
	for window_x in [30.0, width - 66.0]:
		draw_rect(Rect2(top_left + Vector2(window_x, 128), Vector2(36, 30)), Color("4d392f"))
		draw_rect(Rect2(top_left + Vector2(window_x + 5, 133), Vector2(26, 20)), Color("b8d4bd"))
	# Hay trough inside the pen.
	var trough_cell := _farm_visual_cell(Vector2i(52, 40))
	var trough := cell_to_screen(trough_cell) + Vector2(2, 12)
	draw_rect(Rect2(trough + Vector2(2, 8), Vector2(58, 12)), Color(0.18, 0.13, 0.08, 0.22))
	draw_rect(Rect2(trough, Vector2(62, 16)), Color("755039"))
	draw_rect(Rect2(trough + Vector2(4, 3), Vector2(54, 9)), Color("d3b46a"))


func _farm_visual_cell(local_cell: Vector2i) -> Vector2i:
	return navigation.to_contiguous_world("farm_outdoor", local_cell) if map_id == "valley_world" else local_cell


func _draw_road_tile(destination: Rect2, index: Vector2i) -> void:
	var source_size := ROAD_ART.get_size()
	var source_cell := Vector2(source_size.x / ROAD_GRID.x, source_size.y / ROAD_GRID.y)
	var source_rect := Rect2(Vector2(index) * source_cell, source_cell)
	draw_texture_rect_region(ROAD_ART, destination, source_rect)


func _road_index_for(cell: Vector2i) -> Vector2i:
	var north := _has_path_at(cell + Vector2i.UP)
	var east := _has_path_at(cell + Vector2i.RIGHT)
	var south := _has_path_at(cell + Vector2i.DOWN)
	var west := _has_path_at(cell + Vector2i.LEFT)
	var connections := int(north) + int(east) + int(south) + int(west)
	if connections == 4:
		return Vector2i(0, 3)
	if connections == 3:
		if not south: return Vector2i(0, 2)
		if not north: return Vector2i(1, 2)
		if not east: return Vector2i(2, 2)
		return Vector2i(3, 2)
	if connections == 2:
		if north and south: return Vector2i(2, 0)
		if east and west: return Vector2i(1, 0)
		if north and west: return Vector2i(0, 1)
		if north and east: return Vector2i(1, 1)
		if south and west: return Vector2i(2, 1)
		return Vector2i(3, 1)
	# The authored maps only use a path end at a door or scene boundary. The
	# neutral end tile is preferable to synthesising a code-drawn cap.
	return Vector2i(3, 0)


func _has_path_at(cell: Vector2i) -> bool:
	if navigation == null:
		return false
	if not navigation.is_in_bounds(map_id, cell):
		return false
	return str(navigation.get_cell_layers(map_id, cell).get("surface", "")) == "path"


func _terrain_index_for(cell: Vector2i, layers: Dictionary, tile_class: String) -> Vector2i:
	if tile_class == "water":
		return Vector2i(0, 1)
	if tile_class == "solid":
		return _solid_terrain_index(cell)
	var surface := str(layers.get("surface", "grass"))
	if surface == "path":
		return Vector2i(3, 0)
	if surface == "tillable":
		if farm_state != null:
			var plot: Dictionary = farm_state.get_cell_state(cell)
			if bool(plot.get("tilled", false)):
				return Vector2i(2, 0) if bool(plot.get("watered", false)) else Vector2i(1, 0)
		return Vector2i(1, 0)
	return Vector2i(0, 0)


func _solid_terrain_index(cell: Vector2i) -> Vector2i:
	# Solid routing cells receive authored prop tiles, while building footprints
	# are overlaid only on their matching navigation footprint below.
	if (cell.x + cell.y) % 3 == 0:
		return Vector2i(2, 1) # rock
	return Vector2i(3, 1) # fence


func _draw_farm_plot(cell: Vector2i, rect: Rect2) -> void:
	if farm_state == null or (map_id != "farm_outdoor" and not (map_id == "valley_world" and navigation.zone_at(map_id, cell) == "farm_outdoor")):
		return
	var plot: Dictionary = farm_state.get_cell_state(cell)
	if plot.is_empty() or not bool(plot.get("tilled", false)):
		return
	var soil := Color("85502c") if not plot.get("watered", false) else Color("553c2b")
	draw_rect(rect.grow(-1), soil)
	for row in 4:
		var start := rect.position + Vector2(3, 5 + row * 7)
		draw_line(start, start + Vector2(25, 0), soil.darkened(0.22), 2)
		draw_line(start + Vector2(0, 2), start + Vector2(25, 2), soil.lightened(0.13), 1)
	var structure_id: String = farm_state.structure_at(cell)
	if structure_id == "sprinkler":
		_draw_sprinkler(rect)
		return
	if structure_id in ["mayo_machine", "preserves_jar"]:
		_draw_processing_machine(rect, structure_id, processing_state.job_at(cell) if processing_state != null else {})
		return
	var seed_id := str(plot.get("seed", ""))
	if seed_id.is_empty():
		return
	var growth: int = int(plot.get("growth", 0))
	var mature := bool(plot.get("mature", false))
	var definition: Dictionary = farm_state.get_crop_definition(seed_id)
	var progress := clampf(float(growth) / float(definition.get("grow_days", 1)), 0, 1)
	_draw_crop_stage(rect, seed_id, 3 if mature else mini(2, int(progress * 3)))
	if show_routes:
		draw_rect(Rect2(rect.position + Vector2(3, 27), Vector2(26, 2)), Color("56402c"))
		draw_rect(Rect2(rect.position + Vector2(3, 27), Vector2(26 * progress, 2)), Color("f7d875"))


func _draw_sprinkler(rect: Rect2) -> void:
	var center := rect.get_center()
	draw_rect(Rect2(center + Vector2(-9, 7), Vector2(18, 5)), Color("3e3d42"))
	draw_rect(Rect2(center + Vector2(-6, -6), Vector2(12, 15)), Color("a96c48"))
	draw_rect(Rect2(center + Vector2(-4, -4), Vector2(8, 11)), Color("d79462"))
	draw_rect(Rect2(center + Vector2(-11, -9), Vector2(22, 5)), Color("526c72"))
	draw_rect(Rect2(center + Vector2(-2, -13), Vector2(4, 8)), Color("9fc6cb"))
	for offset in [Vector2(-12, -7), Vector2(12, -7), Vector2(0, -15)]:
		draw_circle(center + offset, 2.0, Color("9de2ef"))


func _draw_processing_machine(rect: Rect2, machine_id: String, job: Dictionary) -> void:
	var center := rect.get_center()
	draw_set_transform(center + Vector2(0, 8), 0, Vector2(1, 0.36))
	draw_circle(Vector2.ZERO, 13, Color(0.16, 0.12, 0.08, 0.24))
	draw_set_transform(Vector2.ZERO)
	if machine_id == "mayo_machine":
		draw_rect(Rect2(center + Vector2(-10, -8), Vector2(20, 21)), Color("7f5236"))
		draw_rect(Rect2(center + Vector2(-8, -6), Vector2(16, 17)), Color("ba7d49"))
		draw_rect(Rect2(center + Vector2(-12, -12), Vector2(24, 6)), Color("d2b56f"))
		draw_circle(center + Vector2(0, -10), 5, Color("f2e2b5"))
	else:
		draw_rect(Rect2(center + Vector2(-11, -10), Vector2(22, 23)), Color("536b65"))
		draw_rect(Rect2(center + Vector2(-8, -7), Vector2(16, 17)), Color("9bc1ad"))
		draw_rect(Rect2(center + Vector2(-12, -14), Vector2(24, 6)), Color("76513a"))
		draw_rect(Rect2(center + Vector2(-5, -4), Vector2(10, 11)), Color(0.55, 0.27, 0.19, 0.62))
	if not job.is_empty():
		var light := Color("8fe09c") if bool(job.get("ready", false)) else Color("f0c35e")
		draw_circle(center + Vector2(9, -13), 3, light)


func _draw_festival_bunting() -> void:
	var start_cell := Vector2i(30, 18)
	var finish_cell := Vector2i(39, 18)
	if map_id == "valley_world":
		start_cell = navigation.to_contiguous_world("town_square", start_cell)
		finish_cell = navigation.to_contiguous_world("town_square", finish_cell)
	var start := cell_center_to_screen(start_cell)
	var finish := cell_center_to_screen(finish_cell)
	draw_line(start, finish, Color("6c4c38"), 2)
	var colors := [Color("ee9b7c"), Color("f3d677"), Color("9dc79b"), Color("9cbfce")]
	for index in 20:
		var point := start.lerp(finish, float(index) / 20)
		draw_colored_polygon(PackedVector2Array([point, point + Vector2(17, 0), point + Vector2(8, 20)]), colors[index % colors.size()])


static func crop_visual(seed_id: String) -> Array:
	var texture := CROPS_ART
	var row := int({"parsnip": 0, "turnip": 1, "tomato": 2, "pumpkin": 3}.get(seed_id, 0))
	var groups := {
		"cauliflower": [CROPS_SPRING_ART, 0], "potato": [CROPS_SPRING_ART, 1], "green_bean": [CROPS_SPRING_ART, 2], "strawberry": [CROPS_SPRING_ART, 3],
		"blueberry": [CROPS_SUMMER_ART, 0], "corn": [CROPS_SUMMER_ART, 1], "pepper": [CROPS_SUMMER_ART, 2], "melon": [CROPS_SUMMER_ART, 3],
		"cranberry": [CROPS_FALL_ART, 0], "eggplant": [CROPS_FALL_ART, 1], "yam": [CROPS_FALL_ART, 2], "bok_choy": [CROPS_FALL_ART, 3],
		"powdermelon": [CROPS_WINTER_ART, 0], "winter_root": [CROPS_WINTER_ART, 1], "snow_yam": [CROPS_WINTER_ART, 2], "crystal_berry": [CROPS_WINTER_ART, 3],
	}
	if groups.has(seed_id):
		texture = groups[seed_id][0]
		row = int(groups[seed_id][1])
	return [texture, row]

func _draw_crop_stage(destination: Rect2, seed_id: String, stage: int) -> void:
	var visual: Array = crop_visual(seed_id)
	var texture: Texture2D = visual[0]
	var row: int = visual[1]
	var frame: Dictionary = CropAtlas.frame(texture, Vector2i(4, 4), stage, row)
	var scale := 30.0 / (texture.get_height() / 4.0)
	var point: Vector2 = destination.get_center() + Vector2(0, 10) + Vector2(frame.offset) * scale
	draw_texture_rect_region(texture, Rect2(point, frame.region.size * scale), frame.region)


func _draw_npc_routes() -> void:
	for route_value in navigation.get_npc_routes(map_id).values():
		var route: Array = route_value
		for index in range(route.size() - 1):
			var from_cell: Vector2i = route[index]
			var to_cell: Vector2i = route[index + 1]
			draw_dashed_line(cell_center_to_screen(from_cell), cell_center_to_screen(to_cell), Color("#77518d", 0.75), 1.5, 5.0)


func _draw_arrow(center: Vector2, color: Color) -> void:
	var points := PackedVector2Array([center + Vector2(-4, -3), center + Vector2(4, 0), center + Vector2(-4, 3)])
	draw_colored_polygon(points, color)
