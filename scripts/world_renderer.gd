class_name WorldRenderer
extends Node2D

## Renders the same cell classification used by MapData movement/collision.
## Each world cell samples the generated terrain source sheet; no whole-scene
## concept image is stretched beneath an unrelated navigation grid.

const TILE_SIZE := 32.0
const FARM_PATH_FILL_HALF_WIDTH := TILE_SIZE * 0.5 - 2.5
## Fill beneath each authored path tile through its antialiased edge pixels.
## The previous 10px underlay was narrower than the 32px atlas road core and
## let meadow colors leak through at joins and rotated bends.
const FARM_PATH_CONTINUITY_HALF_WIDTH := TILE_SIZE * 0.5 - 2.5
const FARM_TERRAIN_ATLAS_COLUMNS := 10
const FARM_TERRAIN_ATLAS_ROWS := 4
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
const FARM_WELL_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_well_v1.png")
const FARM_CHERRY_TREE_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_cherry_tree_seasons_v1.png")
const FARMHOUSE_FRONT_ART: Texture2D = preload("res://assets/art/runtime_generated/farmhouse_tier_1_concept_v2.png")
const FARM_TERRAIN_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_terrain_user_tiles_v1.png")
const FARM_MEADOW_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_meadow_details_v1.png")
const FARM_FLORA_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_flora_seasons_v1.png")
const FARM_COOP_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_coop_tier_1_reference_v1.png")
const FARM_BARN_ART: Texture2D = preload("res://assets/art/runtime_generated/farm_barn_tier_1_reference_v1.png")
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
	"farmhouse_interior": {"building_id": "farmhouse", "uv": Rect2(0.46, 0.58, 0.14, 0.24), "animation": "hinge_right", "rug": [Color("7f9b62"), Color("e4d6aa")]},
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
		if map_id == "farm_outdoor":
			_draw_farm_top_margin(size.x)
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x):
				var cell := Vector2i(x, y)
				_draw_cell(cell)
		if map_id == "farm_outdoor":
			_draw_farm_path_network(bounds)
	_draw_region_environment()
	_draw_object_grounding()
	if map_id == "farm_outdoor" or map_id == "valley_world":
		_draw_animal_area()

	if farm_state != null and (map_id == "town_square" or map_id == "valley_world") and not farm_state.Calendar.festival(farm_state.day).is_empty():
		_draw_festival_bunting()
	if show_routes:
		_draw_npc_routes()


func _draw_farm_top_margin(map_width: int) -> void:
	# The farm camera shows a little above the authored map so the farmhouse roof
	# stays visible below the HUD. Extend the meadow behind the forest canopy.
	var season: int = farm_state.Calendar.date(farm_state.day).season if farm_state != null else 0
	for y in range(-5, 0):
		for x in map_width:
			var cell := Vector2i(x, y)
			var rect := Rect2(cell_to_screen(cell), Vector2.ONE * TILE_SIZE)
			_draw_farm_surface(self, rect, cell, "grass", season)


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
	var is_farm := _is_farm_cell(cell)
	if is_farm and tile_class == "water":
		_draw_farm_water(canvas, rect, season, cell)
	elif is_farm:
		_draw_farm_surface(canvas, rect, cell, surface, season)
	else:
		var terrain := Vector2i.ZERO
		if tile_class == "water": terrain = Vector2i(1, 1)
		elif surface == "path": terrain = Vector2i(1, 0)
		elif surface == "tillable": terrain = Vector2i(0, 1)
		var quadrant_size := SOFT_TERRAIN.get_size() / 2.0
		var sample_size := quadrant_size / 8.0
		var offset := Vector2(posmod(cell.x, 8), posmod(cell.y, 8)) * sample_size
		canvas.draw_texture_rect_region(SOFT_TERRAIN, rect, Rect2(Vector2(terrain) * quadrant_size + offset, sample_size))
	if surface == "grass" and not is_farm: canvas.draw_rect(rect, GRASS_HARMONIZE_TINT)
	if tile_class == "water": _draw_static_water_bank(canvas, rect, cell)
	if tile_class == "solid" and str(layers.get("blocked_id", "")).contains("fence"):
		_draw_static_fence(canvas, rect, str(layers.get("blocked_id", "")).ends_with("west"))
	if surface == "path" and not is_farm:
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not _has_path_at(cell + direction):
				_draw_static_path_edge(canvas, rect, cell, direction)
	if is_farm and surface == "grass" and tile_class != "water":
		_draw_farm_flora(canvas, rect, cell, season)
	elif surface == "grass" and tile_class != "water":
		_draw_static_meadow_details(canvas, rect, cell)
	if not is_farm:
		_draw_season_ground(canvas, rect, cell, surface, season)


func _draw_farm_surface(canvas: Node2D, rect: Rect2, cell: Vector2i, surface: String, season: int) -> void:
	# Blend the 8x8 grass samples over one season-colored field base. The art
	# sheet has small color shifts between cells; this base removes the visible
	# checker while retaining its grass and flower detail.
	var quadrant_size := SOFT_TERRAIN.get_size() / 2.0
	var sample_size := quadrant_size / 8.0
	var offset := Vector2(posmod(cell.x, 8), posmod(cell.y, 8)) * sample_size
	var meadow_colors := [Color("789b42"), Color("76a043"), Color("9c803e"), Color("a8b6b4")]
	canvas.draw_rect(rect, meadow_colors[season])
	canvas.draw_texture_rect_region(SOFT_TERRAIN, rect, Rect2(offset, sample_size), Color(1, 1, 1, 0.48))
	_draw_farm_season_tint(canvas, rect, season)
	if surface == "path" and map_id != "farm_outdoor":
		_draw_farm_path_base(canvas, rect, cell, season)


func _farm_terrain_source(column: int, season: int) -> Rect2:
	# Every soil/road/water tile occupies one complete 32x32 gameplay cell.
	assert(FARM_TERRAIN_ART.get_width() == int(TILE_SIZE) * FARM_TERRAIN_ATLAS_COLUMNS)
	assert(FARM_TERRAIN_ART.get_height() == int(TILE_SIZE) * FARM_TERRAIN_ATLAS_ROWS)
	assert(column >= 0 and column < FARM_TERRAIN_ATLAS_COLUMNS)
	assert(season >= 0 and season < FARM_TERRAIN_ATLAS_ROWS)
	return Rect2(Vector2(column, season) * TILE_SIZE, Vector2.ONE * TILE_SIZE)


func _draw_farm_water(canvas: Node2D, rect: Rect2, season: int, cell: Vector2i) -> void:
	# Draw one calm, shared-color water field with cell-seeded ripples instead of
	# repeating the same square sample, which exposed a visible checker grid.
	var water_colors := [Color("277fae"), Color("2783a9"), Color("397c98"), Color("a9c8cc")]
	var ripple_colors := [Color("62c6df"), Color("66c7dc"), Color("85b9c6"), Color("e0ece6")]
	var shadow_colors := [Color("176993"), Color("1b6b8b"), Color("315f79"), Color("8faeb5")]
	canvas.draw_rect(rect, water_colors[season])
	var seed := posmod(cell.x * 73 + cell.y * 137, 997)
	for ripple_index in 4:
		var x := rect.position.x + 3 + posmod(seed * (ripple_index * 11 + 7), 21)
		var y := rect.position.y + 4 + posmod(seed * (ripple_index * 17 + 13), 22)
		var length := 3 + posmod(seed + ripple_index * 5, 5)
		canvas.draw_rect(Rect2(Vector2(x, y), Vector2(length, 1)), ripple_colors[season])
		if ripple_index % 2 == 0:
			canvas.draw_rect(Rect2(Vector2(x + 1, y + 1), Vector2(maxi(2, length - 2), 1)), shadow_colors[season])
	if season == 2 and seed % 3 == 0:
		canvas.draw_rect(Rect2(rect.position + Vector2(20, 22), Vector2(3, 2)), Color("e99536"))


func _farm_path_tile_index(cell: Vector2i) -> int:
	var north := _has_path_at(cell + Vector2i.UP)
	var east := _has_path_at(cell + Vector2i.RIGHT)
	var south := _has_path_at(cell + Vector2i.DOWN)
	var west := _has_path_at(cell + Vector2i.LEFT)
	var count := int(north) + int(east) + int(south) + int(west)
	if count == 0:
		return 0 # isolated patch or authored dirt cap
	if count == 1:
		return 6 # a directional round cap attached to its single neighbor
	if count == 2:
		if north and south: return 1
		if east and west: return 2
		return 3 # corner
	if count == 3:
		return 4 # T junction
	return 5 # four-way junction


func _farm_path_rotation(cell: Vector2i, tile_index: int) -> float:
	var north := _has_path_at(cell + Vector2i.UP)
	var east := _has_path_at(cell + Vector2i.RIGHT)
	var south := _has_path_at(cell + Vector2i.DOWN)
	var west := _has_path_at(cell + Vector2i.LEFT)
	return farm_path_rotation_from_mask(tile_index, north, east, south, west)


static func farm_path_rotation_from_mask(tile_index: int, north: bool, east: bool, south: bool, west: bool) -> float:
	if tile_index == 0:
		if south: return PI * 0.5
		if west: return PI
		if north: return PI * 1.5
	if tile_index == 6: # canonical end cap connects north; rotate toward its only neighbor
		if east: return PI * 0.5
		if south: return PI
		if west: return PI * 1.5
	if tile_index == 3: # authored corner tile connects north and west
		if north and east: return PI * 0.5
		if east and south: return PI
		if south and west: return PI * 1.5
	if tile_index == 4: # authored T tile has north, east, and west arms
		if north and east and south: return PI * 0.5
		if east and south and west: return PI
		if south and west and north: return PI * 1.5
	return 0.0


func _draw_farm_path_base(canvas: Node2D, rect: Rect2, cell: Vector2i, season: int) -> void:
	var tile_index := _farm_path_tile_index(cell)
	_draw_farm_path_tile(canvas, cell, tile_index, season)


func _draw_farm_path_network(bounds: Rect2i) -> void:
	# Use the authored 32x32 seasonal road tiles selected from the live neighbor
	# graph. Matching cell edges and rotating canonical turns keeps dirt and grass
	# borders continuous through bends and junctions.
	var season: int = farm_state.Calendar.date(farm_state.day).season if farm_state != null else 0
	var path_cells: Array[Vector2i] = []
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			var layers := navigation.get_cell_layers(map_id, cell)
			if str(layers.get("surface", "")) == "path" and navigation.get_cell_class(map_id, cell) not in ["solid", "water"]:
				path_cells.append(cell)
	# Opaque narrow underlay bridges the antialiased transparent pixels at atlas
	# cell boundaries while staying inside the authored dirt shoulder.
	var continuity_color := _farm_path_soil_color(season)
	for cell in path_cells:
		var tile_index := _farm_path_tile_index(cell)
		draw_set_transform(cell_center_to_screen(cell), _farm_path_rotation(cell, tile_index), Vector2.ONE)
		_draw_farm_path_shape(self, tile_index, FARM_PATH_CONTINUITY_HALF_WIDTH, continuity_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for cell in path_cells:
		var tile_index := _farm_path_tile_index(cell)
		_draw_farm_path_tile(self, cell, tile_index, season)


func _draw_farm_path_tile(canvas: Node2D, cell: Vector2i, tile_index: int, season: int) -> void:
	canvas.draw_set_transform(cell_center_to_screen(cell), _farm_path_rotation(cell, tile_index), Vector2.ONE)
	if tile_index == 6:
		# The atlas has no directional end-cap; retain a rounded, connected cap
		# for a path that terminates at the house, field, crate, well, or map edge.
		_draw_farm_path_shape(canvas, tile_index, 15.5, _farm_path_edge_color(season))
		_draw_farm_path_shape(canvas, tile_index, FARM_PATH_FILL_HALF_WIDTH, _farm_path_soil_color(season))
	else:
		_draw_farm_path_shape(canvas, tile_index, FARM_PATH_CONTINUITY_HALF_WIDTH, _farm_path_soil_color(season))
		var destination := Rect2(Vector2.ONE * -TILE_SIZE * 0.5, Vector2.ONE * TILE_SIZE)
		canvas.draw_texture_rect_region(FARM_TERRAIN_ART, destination, _farm_terrain_source(tile_index, season))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if tile_index == 6:
		_draw_farm_path_details(cell, season)



func _farm_path_edge_color(season: int) -> Color:
	return [Color("a56d3b"), Color("a56d3b"), Color("9b6138"), Color("a5a9a1")][season]


func _farm_path_soil_color(season: int) -> Color:
	return [Color("f5af59"), Color("f5b55e"), Color("f5ac54"), Color("d8e3f4")][season]


func _draw_farm_path_network_layer(cell: Vector2i, season: int, half_width: float, color: Color) -> void:
	var tile_index := _farm_path_tile_index(cell)
	var rotation := _farm_path_rotation(cell, tile_index)
	draw_set_transform(cell_center_to_screen(cell), rotation, Vector2.ONE)
	_draw_farm_path_shape(self, tile_index, half_width, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_farm_path_details(cell: Vector2i, season: int) -> void:
	var tile_index := _farm_path_tile_index(cell)
	var rotation := _farm_path_rotation(cell, tile_index)
	draw_set_transform(cell_center_to_screen(cell), rotation, Vector2.ONE)
	var highlights := [Color("e9b970"), Color("e8b66c"), Color("d99b5c"), Color("e2e0d5")]
	var shadows := [Color("bd854a"), Color("bb854b"), Color("ac7042"), Color("aaa99d")]
	var texture_rng := RandomNumberGenerator.new()
	texture_rng.seed = int(cell.x * 73856093) ^ int(cell.y * 19349663)
	for fleck_index in 24:
		var fleck_position := Vector2(texture_rng.randi_range(-13, 11), texture_rng.randi_range(-13, 11))
		var fleck_size := Vector2(1 + texture_rng.randi_range(0, 2), 1 + texture_rng.randi_range(0, 1))
		if not _farm_path_contains(tile_index, fleck_position + fleck_size * 0.5, FARM_PATH_FILL_HALF_WIDTH):
			continue
		var color: Color = highlights[season] if texture_rng.randi_range(0, 2) != 0 else shadows[season]
		draw_rect(Rect2(fleck_position, fleck_size), Color(color, 0.52))
		if texture_rng.randi_range(0, 5) == 0:
			var groove := Rect2(fleck_position + Vector2(-1, 2), Vector2(3 + texture_rng.randi_range(0, 3), 1))
			if _farm_path_contains(tile_index, groove.position + groove.size * 0.5, FARM_PATH_FILL_HALF_WIDTH):
				draw_rect(groove, Color(shadows[season], 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_farm_path_shape(canvas: Node2D, tile_index: int, half_width: float, color: Color) -> void:
	if tile_index in [0, 6]:
		canvas.draw_circle(Vector2.ZERO, half_width, color)
	else:
		# A square junction core lets adjacent 32px road cells meet flush instead
		# of leaving scalloped, antialiased seams at each cell center.
		canvas.draw_rect(Rect2(Vector2.ONE * -half_width, Vector2.ONE * half_width * 2.0), color)
	var arms: Array[Vector2i] = []
	match tile_index:
		1: arms = [Vector2i.UP, Vector2i.DOWN]
		2: arms = [Vector2i.LEFT, Vector2i.RIGHT]
		3: arms = [Vector2i.UP, Vector2i.LEFT]
		4: arms = [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT]
		5: arms = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
		6: arms = [Vector2i.UP]
	for direction in arms:
		var arm_rect: Rect2
		if direction == Vector2i.UP:
			arm_rect = Rect2(Vector2(-half_width, -TILE_SIZE * 0.5), Vector2(half_width * 2.0, TILE_SIZE * 0.5))
		elif direction == Vector2i.RIGHT:
			arm_rect = Rect2(Vector2(0, -half_width), Vector2(TILE_SIZE * 0.5, half_width * 2.0))
		elif direction == Vector2i.DOWN:
			arm_rect = Rect2(Vector2(-half_width, 0), Vector2(half_width * 2.0, TILE_SIZE * 0.5))
		else:
			arm_rect = Rect2(Vector2(-TILE_SIZE * 0.5, -half_width), Vector2(TILE_SIZE * 0.5, half_width * 2.0))
		canvas.draw_rect(arm_rect, color)


func _farm_path_contains(tile_index: int, point: Vector2, half_width: float) -> bool:
	if tile_index in [0, 6] and point.length_squared() <= half_width * half_width:
		return true
	match tile_index:
		1: return absf(point.x) <= half_width
		2: return absf(point.y) <= half_width
		3: return (point.y <= 0 and absf(point.x) <= half_width) or (point.x <= 0 and absf(point.y) <= half_width)
		4: return (point.y <= 0 and absf(point.x) <= half_width) or (point.x >= 0 and absf(point.y) <= half_width) or (point.x <= 0 and absf(point.y) <= half_width)
		5: return true
		6: return point.y <= 0 and absf(point.x) <= half_width
	return false
func _draw_farm_season_tint(canvas: Node2D, rect: Rect2, season: int) -> void:
	match season:
		0: canvas.draw_rect(rect, Color("d7c45c", 0.05))
		1: canvas.draw_rect(rect, Color("d8c56f", 0.09))
		2: canvas.draw_rect(rect, Color("c78a43", 0.17))
		3: canvas.draw_rect(rect, Color("b9d0d4", 0.36))


func _draw_farm_flora(canvas: Node2D, rect: Rect2, cell: Vector2i, season: int) -> void:
	var stable_seed := posmod((cell.x * 73856093) ^ (cell.y * 19349663), 101)
	var local_cell := cell
	if map_id == "valley_world":
		local_cell -= navigation.to_contiguous_world("farm_outdoor", Vector2i.ZERO)
	var map_size := navigation.get_map_size("farm_outdoor")
	var edge_distance := mini(mini(local_cell.x, map_size.x - 1 - local_cell.x), mini(local_cell.y, map_size.y - 1 - local_cell.y))
	var near_pond_bank := local_cell.x >= 48 and local_cell.y >= 16
	var outer_growth := edge_distance <= 5 or near_pond_bank
	var open_yard := Rect2i(12, 8, 40, 15).has_point(local_cell)
	var tall_flora_threshold := 30 if outer_growth else 12 if open_yard else 19
	var detail_threshold := 52 if outer_growth else 25 if open_yard else 39
	if stable_seed <= tall_flora_threshold:
		var flora_column := posmod(stable_seed, 4)
		if season <= 1:
			flora_column = posmod(stable_seed, 3)
		var flora_source_size := FARM_FLORA_ART.get_size() / Vector2(4, 4)
		var flora_source := Rect2(Vector2(flora_column, season) * flora_source_size, flora_source_size)
		canvas.draw_texture_rect_region(FARM_FLORA_ART, rect, flora_source)
		return
	if stable_seed > detail_threshold:
		return
	var meadow_column := posmod(stable_seed * 13 + cell.x * 3 + cell.y * 5, 6)
	if season <= 1:
		var spring_summer_columns := [0, 1, 2, 5]
		meadow_column = spring_summer_columns[posmod(meadow_column, spring_summer_columns.size())]
	var meadow_source_size := FARM_MEADOW_ART.get_size() / Vector2(6, 4)
	var meadow_source := Rect2(Vector2(meadow_column, season) * meadow_source_size, meadow_source_size)
	canvas.draw_texture_rect_region(FARM_MEADOW_ART, rect, meadow_source)


func _is_farm_cell(cell: Vector2i) -> bool:
	if map_id == "farm_outdoor":
		return true
	return map_id == "valley_world" and navigation.zone_at(map_id, cell) == "farm_outdoor"


func _draw_static_water_bank(canvas: Node2D, rect: Rect2, cell: Vector2i) -> void:
	if _is_farm_cell(cell):
		_draw_farm_water_bank(canvas, rect, cell)
		return
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
		_draw_farm_plot(cell)


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
	var current_season := int(farm_state.Calendar.date(farm_state.day).season) if farm_state != null else 0
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
		if str(entry.get("atlas", "")) in ["orchard", "community_center", "farm_cherry_tree"]:
			var atlas_name := str(entry.atlas)
			var atlas_grid := Vector2(4, 4) if atlas_name == "orchard" else Vector2(4, 1) if atlas_name == "farm_cherry_tree" else Vector2(2, 1)
			var frame_size: Vector2 = object.texture.get_size() / atlas_grid
			var source_index := Vector2(int(entry.index[0]), int(entry.index[1]))
			if atlas_name == "farm_cherry_tree":
				source_index = Vector2(current_season, 0)
			object.region_rect = Rect2(source_index * frame_size, frame_size)
		var visual_rect: Array = entry.visual_rect
		var visual_size := Vector2(visual_rect[2], visual_rect[3]) * TILE_SIZE
		object.position = origin + Vector2(visual_rect[0], visual_rect[1]) * TILE_SIZE
		var canopy_scale := 1.2 if cache_key.begins_with("tree_farm_") and str(entry.get("atlas", "")) == "props" else 1.0
		object.scale = visual_size * canopy_scale / object.region_rect.size
		if canopy_scale > 1.0:
			object.position += Vector2(-visual_size.x * (canopy_scale - 1.0) * 0.5, -visual_size.y * (canopy_scale - 1.0))
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
		"farm_cherry_tree": texture = FARM_CHERRY_TREE_ART; grid = Vector2i(4, 1)
		"farm_well": texture = FARM_WELL_ART; grid = Vector2i.ONE
		"farmhouse_front": texture = FARMHOUSE_FRONT_ART; grid = Vector2i.ONE
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
	if entry.atlas == "farmhouse_front":
		# Trim the transparent tail under the stone steps so the visible ground
		# contact aligns with the map's foundation row without distorting the art.
		object.region_rect = Rect2(Vector2.ZERO, texture.get_size())
	if entry.atlas == "furniture":
		# This source is hand packed, not an equal-cell atlas. Explicit bounds
		# prevent a shelf/rug from bleeding into the next row of furniture.
		object.region_rect = FURNITURE_REGIONS[int(entry.index[1]) * 4 + int(entry.index[0])]
	var r: Array = entry.visual_rect
	object.position = origin + Vector2(r[0], r[1]) * TILE_SIZE
	if entry.atlas == "farmhouse_front":
		var visual_size := Vector2(r[2], r[3]) * TILE_SIZE
		var uniform_scale := minf(visual_size.x / object.region_rect.size.x, visual_size.y / object.region_rect.size.y)
		object.scale = Vector2.ONE * uniform_scale
		object.position += Vector2((visual_size.x - object.region_rect.size.x * uniform_scale) * 0.5, visual_size.y - object.region_rect.size.y * uniform_scale)
	else:
		object.scale = Vector2(r[2], r[3]) * TILE_SIZE / object.region_rect.size
	if entry.atlas == "furniture":
		object.scale = Vector2.ONE * minf(object.scale.x, object.scale.y)
		object.position += (Vector2(r[2], r[3]) * TILE_SIZE - object.region_rect.size * object.scale) * Vector2(0.5, 1)
	object.z_index = 1 if entry.get("ground", false) else int((r[1] + r[3]) * TILE_SIZE)
	# The old one-size-fits-all carpet is retained in authored data for save/map
	# compatibility, but each room now draws a doorway mat from its exterior
	# door proportions and facade palette.
	object.visible = not (map_id.ends_with("_interior") and str(entry.id) == "rug" and map_id != "farmhouse_interior")
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
	if map_id == "farmhouse_interior":
		_draw_farmhouse_room()
		return
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


func _draw_farmhouse_room() -> void:
	# A compact starter room keeps the bed, hearth, storage and exit in one view.
	draw_rect(Rect2(origin, map_pixel_size()), Color("302a24"))
	for y in range(3, 11):
		for x in range(2, 18):
			var rect := Rect2(cell_to_screen(Vector2i(x, y)), Vector2.ONE * TILE_SIZE)
			var plank_color := Color("a97748").lightened(float((x * 3 + y) % 5) * 0.018)
			for plank in 2:
				var board := Rect2(rect.position + Vector2(0, plank * 16), Vector2(32, 16))
				draw_rect(board, plank_color)
				draw_line(board.position, board.position + Vector2(32, 0), Color("70482e"), 1)
				if (x + y + plank) % 3 == 0:
					draw_line(board.position, board.position + Vector2(0, 16), Color("70482e"), 1)
				var grain := board.position + Vector2((x * 7 + y * 11 + plank * 5) % 19, 6 + (plank % 2) * 4)
				draw_line(grain, grain + Vector2(8, 0), Color("8d5f3a"), 1)
	var rear_wall := Rect2(cell_to_screen(Vector2i(2, 1)), Vector2(16, 2) * TILE_SIZE)
	draw_rect(rear_wall, Color("d7c49a"))
	draw_rect(Rect2(rear_wall.position, Vector2(rear_wall.size.x, 8)), Color("79563c"))
	draw_rect(Rect2(rear_wall.position + Vector2(0, 56), Vector2(rear_wall.size.x, 8)), Color("79563c"))
	for x in [5, 14]:
		var window := Rect2(cell_to_screen(Vector2i(x, 1)) + Vector2(4, 14), Vector2(42, 34))
		draw_rect(window.grow(4), Color("755039"))
		draw_rect(window, Color("b5d8d0"))
		draw_line(window.get_center() - Vector2(0, 16), window.get_center() + Vector2(0, 16), Color("f0dfb5"), 3)
		draw_line(window.get_center() + Vector2(-21, 0), window.get_center() + Vector2(21, 0), Color("f0dfb5"), 2)
	for x in [2, 17]:
		var side := Rect2(cell_to_screen(Vector2i(x, 3)), Vector2(1, 8) * TILE_SIZE)
		draw_rect(side, Color("d5c096"))
		draw_rect(Rect2(side.position, Vector2(32, 8)), Color("79563c"))
		draw_rect(Rect2(side.position + Vector2(0, side.size.y - 8), Vector2(32, 8)), Color("79563c"))
	for wall_segment in [Rect2(3, 11, 6, 1), Rect2(11, 11, 6, 1)]:
		var segment := Rect2(cell_to_screen(Vector2i(int(wall_segment.position.x), int(wall_segment.position.y))), Vector2(wall_segment.size) * TILE_SIZE)
		draw_rect(segment, Color("79563c"))
		draw_rect(segment.grow(-5), Color("d2bd91"))
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
	if str(building.get("atlas", "")) == "farmhouse_front":
		# The authored farmhouse is deliberately a little wider than tall. Match
		# the door animation to the same non-uniform visual rect as the facade.
		return Rect2(building_rect.position + uv.position * building_rect.size, uv.size * building_rect.size)
	return Rect2(building_rect.position + uv.position * building_rect.size, uv.size * building_rect.size)


func door_source_rect(target: String) -> Rect2:
	var profile := door_profile(target)
	var building := _building_entry(str(profile.get("building_id", "")))
	if building.is_empty():
		return Rect2()
	if str(building.get("atlas", "")) == "farmhouse_front":
		var farmhouse_uv: Rect2 = profile.uv
		return Rect2(farmhouse_uv.position * FARMHOUSE_FRONT_ART.get_size(), farmhouse_uv.size * FARMHOUSE_FRONT_ART.get_size())
	var frame_size := BUILDINGS_ART.get_size() / Vector2(2, 2)
	var frame_origin := Vector2(int(building.index[0]), int(building.index[1])) * frame_size
	var uv: Rect2 = profile.uv
	return Rect2(frame_origin + uv.position * frame_size, uv.size * frame_size)


func entrance_rug_size(interior_id := map_id) -> Vector2:
	var profile := door_profile(interior_id)
	if profile.is_empty():
		return Vector2(56, 24)
	var exterior_width_tiles: float = {"farmhouse_interior": 9.0, "general_store_interior": 11.0, "clinic_interior": 9.0, "cafe_interior": 10.0}.get(interior_id, 10.0)
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
	var door_art: Texture2D = FARMHOUSE_FRONT_ART if str(profile.get("building_id", "")) == "farmhouse" else BUILDINGS_ART
	_door_layer.draw_rect(rect.grow(1), Color("3b261f"))
	_door_layer.draw_rect(rect, Color("17191a"))
	var glow := Color("e6b568", 0.18 + amount * 0.34)
	_door_layer.draw_rect(rect.grow(-2), glow)
	match str(profile.animation):
		"hinge_right":
			var width := maxf(2.0, rect.size.x * (1.0 - amount * 0.88))
			_draw_door_texture(Rect2(rect.end.x - width, rect.position.y, width, rect.size.y), source, door_art)
			_door_layer.draw_line(Vector2(rect.end.x - width, rect.position.y), Vector2(rect.end.x - width, rect.end.y), Color("f2cf8a", amount * 0.65), 1)
		"hinge_left":
			var width := maxf(2.0, rect.size.x * (1.0 - amount * 0.88))
			_draw_door_texture(Rect2(rect.position, Vector2(width, rect.size.y)), source, door_art)
			_door_layer.draw_line(Vector2(rect.position.x + width, rect.position.y), Vector2(rect.position.x + width, rect.end.y), Color("d9edf0", amount * 0.55), 1)
		"slide_left":
			var visible_width := maxf(1.0, rect.size.x * (1.0 - amount * 0.96))
			var source_width := source.size.x * (visible_width / rect.size.x)
			_draw_door_texture(Rect2(rect.position, Vector2(visible_width, rect.size.y)), Rect2(source.position + Vector2(source.size.x - source_width, 0), Vector2(source_width, source.size.y)), door_art)
		"double_fold":
			var half_width := rect.size.x * 0.5
			var folded_width := maxf(1.0, half_width * (1.0 - amount * 0.84))
			var source_half := source.size.x * 0.5
			_draw_door_texture(Rect2(rect.position, Vector2(folded_width, rect.size.y)), Rect2(source.position, Vector2(source_half, source.size.y)), door_art)
			_draw_door_texture(Rect2(Vector2(rect.end.x - folded_width, rect.position.y), Vector2(folded_width, rect.size.y)), Rect2(source.position + Vector2(source_half, 0), Vector2(source_half, source.size.y)), door_art)


func _draw_door_texture(destination: Rect2, source: Rect2, art: Texture2D = BUILDINGS_ART) -> void:
	_door_layer.draw_texture_rect_region(art, destination, source)


func _draw_entry_rug() -> void:
	var profile := door_profile(map_id)
	if profile.is_empty():
		return
	var size := entrance_rug_size(map_id)
	var center_cell := Vector2i(10, 10) if map_id == "farmhouse_interior" else Vector2i(18, 17)
	var center := cell_center_to_screen(center_cell) + Vector2(0, 3)
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
	var is_farm := _is_farm_cell(cell)
	var season: int = farm_state.Calendar.date(farm_state.day).season if farm_state != null else 0
	if is_farm and tile_class == "water":
		_draw_farm_water(self, rect, season, cell)
	elif is_farm:
		_draw_farm_surface(self, rect, cell, surface, season)
	else:
		var terrain := Vector2i.ZERO
		if tile_class == "water": terrain = Vector2i(1, 1)
		elif surface == "path": terrain = Vector2i(1, 0)
		elif surface == "tillable": terrain = Vector2i(0, 1)
		_draw_soft_terrain(rect, cell, terrain)
	if tile_class == "water": _draw_water_bank(rect, cell)
	if tile_class == "solid" and str(layers.get("blocked_id", "")).contains("fence"):
		_draw_fence(rect, str(layers.get("blocked_id", "")).ends_with("west"))
	if surface == "path" and not is_farm:
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not _has_path_at(cell + direction):
				_draw_path_edge(rect, cell, direction)
	if is_farm and surface == "grass" and tile_class != "water":
		_draw_farm_flora(self, rect, cell, season)
	elif surface == "grass" and tile_class != "water" and map_id != "countryside":
		_draw_meadow_details(rect, cell)
	if farm_state != null and tile_class != "water" and not is_farm:
		_draw_season_ground(self, rect, cell, surface, season)
	_draw_farm_plot(cell)

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
	if _is_farm_cell(cell):
		_draw_farm_water_bank(self, rect, cell)
		return
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


func _draw_farm_water_bank(canvas: Node2D, rect: Rect2, cell: Vector2i) -> void:
	var earth_colors := [Color("785338"), Color("99643a"), Color("b77a3c"), Color("d29a4b")]
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbor: Vector2i = cell + direction
		if navigation.is_in_bounds(map_id, neighbor) and navigation.get_cell_class(map_id, neighbor) == "water":
			continue
		var normal := Vector2(direction)
		var edge := rect.get_center() + normal * 15.0
		var tangent := normal.orthogonal()
		for segment in 6:
			var along := -14.0 + segment * 5.0
			var seed := posmod(cell.x * 53 + cell.y * 97 + segment * 29 + int(direction.x * 7 + direction.y * 13), 101)
			var depth := 5.0 + float(seed % 4)
			var center := edge + tangent * (along + 2.0) + normal * (depth * 0.5)
			var size := Vector2(depth, 6.0) if absf(normal.x) > 0.5 else Vector2(6.0, depth)
			canvas.draw_rect(Rect2(center - size * 0.5, size), earth_colors[posmod(seed, earth_colors.size())])
			if seed % 4 == 0:
				var stone_center := center + tangent * 1.0 - normal * 1.0
				canvas.draw_rect(Rect2(stone_center - Vector2(2, 1), Vector2(4, 3)), Color("655d50"))
				canvas.draw_rect(Rect2(stone_center - Vector2(1, 1), Vector2(2, 1)), Color("b3a58b"))
			if seed % 3 == 0:
				var foam_center := edge - normal * 2.0 + tangent * along
				var foam_size := Vector2(2, 1) if absf(normal.x) > 0.5 else Vector2(1, 2)
				canvas.draw_rect(Rect2(foam_center, foam_size), Color("f1e8c7", 0.82))


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
			_draw_grounded_farm_asset(self, FARM_COOP_ART, Rect2(top_left, Vector2(width, 6.0 * TILE_SIZE)))
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
	_draw_grounded_farm_asset(self, FARM_BARN_ART, Rect2(top_left, Vector2(width, 6.0 * TILE_SIZE)))
	# Hay trough inside the pen.
	var trough_cell := _farm_visual_cell(Vector2i(52, 40))
	var trough := cell_to_screen(trough_cell) + Vector2(2, 12)
	draw_rect(Rect2(trough + Vector2(2, 8), Vector2(58, 12)), Color(0.18, 0.13, 0.08, 0.22))
	draw_rect(Rect2(trough, Vector2(62, 16)), Color("755039"))
	draw_rect(Rect2(trough + Vector2(4, 3), Vector2(54, 9)), Color("d3b46a"))


func _draw_grounded_farm_asset(canvas: Node2D, texture: Texture2D, bounds: Rect2) -> void:
	var scale_factor := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var size := texture.get_size() * scale_factor
	var rect := Rect2(Vector2(bounds.position.x + (bounds.size.x - size.x) * 0.5, bounds.end.y - size.y), size)
	canvas.draw_texture_rect(texture, rect, false)


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


func _draw_farm_plot(cell: Vector2i) -> void:
	if farm_state == null or (map_id != "farm_outdoor" and not (map_id == "valley_world" and navigation.zone_at(map_id, cell) == "farm_outdoor")):
		return
	var plot: Dictionary = farm_state.get_cell_state(cell)
	if plot.is_empty() or not bool(plot.get("tilled", false)):
		return
	# One soil tile is exactly one 32x32 gameplay cell. Keep adjacent cells edge
	# to edge; a per-tile inset outline reads as an artificial gap in the field.
	var soil_rect := Rect2(cell_to_screen(cell), Vector2.ONE * TILE_SIZE)
	var season: int = farm_state.Calendar.date(farm_state.day).season
	var soil_column := 8 if bool(plot.get("watered", false)) else 6
	# The authored atlas has transparent antialias/edge pixels. Backfill the whole
	# 32x32 cell first so those pixels never reveal meadow and create apparent
	# gaps between adjacent soil blocks.
	var soil_base := Color("38291f") if soil_column == 8 else Color("70432d")
	draw_rect(soil_rect, soil_base)
	draw_texture_rect_region(FARM_TERRAIN_ART, soil_rect, _farm_terrain_source(soil_column, season))
	var structure_id: String = farm_state.structure_at(cell)
	if structure_id == "sprinkler":
		_draw_sprinkler(soil_rect)
		return
	if structure_id in ["mayo_machine", "preserves_jar"]:
		_draw_processing_machine(soil_rect, structure_id, processing_state.job_at(cell) if processing_state != null else {})
		return
	var seed_id := str(plot.get("seed", ""))
	if seed_id.is_empty():
		return
	var growth: int = int(plot.get("growth", 0))
	var mature := bool(plot.get("mature", false))
	var definition: Dictionary = farm_state.get_crop_definition(seed_id)
	var progress := clampf(float(growth) / float(definition.get("grow_days", 1)), 0, 1)
	_draw_crop_stage(soil_rect, seed_id, 3 if mature else mini(2, int(progress * 3)))
	if show_routes:
		draw_rect(Rect2(soil_rect.position + Vector2(3, 27), Vector2(26, 2)), Color("56402c"))
		draw_rect(Rect2(soil_rect.position + Vector2(3, 27), Vector2(26 * progress, 2)), Color("f7d875"))


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
