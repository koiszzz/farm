class_name WorldRenderer
extends Node2D

## Renders the same cell classification used by MapData movement/collision.
## Each world cell samples the generated terrain source sheet; no whole-scene
## concept image is stretched beneath an unrelated navigation grid.

const TILE_SIZE := 32.0
const TERRAIN_ART: Texture2D = preload("res://assets/art/runtime_generated/terrain_atlas_v2.png")
const TERRAIN_GRID := Vector2i(4, 2)
const FARMHOUSE_ART: Texture2D = preload("res://assets/art/runtime_generated/farmhouse_front_v3.png")
const ROAD_ART: Texture2D = preload("res://assets/art/runtime_generated/road_transitions_v3.png")
const ROAD_GRID := Vector2i(4, 4)
const FARMHOUSE_INTERIOR_ART: Texture2D = preload("res://assets/art/concepts/farmhouse_interior_key_art_v1.png")
const GENERAL_STORE_INTERIOR_ART: Texture2D = preload("res://assets/art/runtime_generated/general_store_interior_v1.png")
const CLINIC_INTERIOR_ART: Texture2D = preload("res://assets/art/runtime_generated/clinic_interior_v1.png")
const CAFE_INTERIOR_ART: Texture2D = preload("res://assets/art/runtime_generated/cafe_interior_v1.png")
const TOWN_CONCEPT_ART: Texture2D = preload("res://assets/art/concepts/town_square_key_art_v1.png")
const TOOLS_ART: Texture2D = preload("res://assets/art/source_generated/mvp_tools_and_seeds_source_v1.png")

var navigation: MapData
var farm_state = null
var map_id := ""
var origin := Vector2.ZERO
var show_routes := false


func configure(next_navigation: MapData, next_map_id: String, next_origin: Vector2) -> void:
	navigation = next_navigation
	map_id = next_map_id
	origin = next_origin
	queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_farm_state(next_farm_state) -> void:
	farm_state = next_farm_state
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
	if map_id == "farmhouse_interior":
		draw_texture_rect(FARMHOUSE_INTERIOR_ART, Rect2(origin, map_pixel_size()), false)
		return
	var interior_art := _town_interior_art()
	if interior_art != null:
		draw_texture_rect(interior_art, Rect2(origin, map_pixel_size()), false)
		return
	var size := navigation.get_map_size(map_id)
	for y in range(size.y):
		for x in range(size.x):
			var cell := Vector2i(x, y)
			_draw_cell(cell)
	_draw_snapped_buildings()
	if farm_state != null and map_id == "town_square" and not farm_state.Calendar.festival(farm_state.day).is_empty():
		_draw_festival_bunting()
	if show_routes:
		_draw_npc_routes()


func _town_interior_art() -> Texture2D:
	match map_id:
		"general_store_interior": return GENERAL_STORE_INTERIOR_ART
		"clinic_interior": return CLINIC_INTERIOR_ART
		"cafe_interior": return CAFE_INTERIOR_ART
		_: return null


func _draw_cell(cell: Vector2i) -> void:
	var layers := navigation.get_cell_layers(map_id, cell)
	var tile_class := navigation.get_cell_class(map_id, cell)
	var rect := Rect2(cell_to_screen(cell), Vector2.ONE * TILE_SIZE)
	if str(layers.get("surface", "")) == "path":
		_draw_road_tile(rect, _road_index_for(cell))
	else:
		_draw_terrain_tile(rect, _terrain_index_for(cell, layers, tile_class))
	if farm_state != null and str(layers.get("surface", "grass")) == "grass" and tile_class != "water":
		var season: int = farm_state.Calendar.date(farm_state.day).season
		if season == 1: draw_rect(rect, Color(0.22, 0.51, 0.18, 0.12))
		if season == 2: draw_rect(rect, Color(0.83, 0.46, 0.12, 0.35))
		if season == 3: draw_rect(rect, Color(0.86, 0.93, 0.96, 0.78))
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


func _draw_terrain_tile(destination: Rect2, index: Vector2i) -> void:
	var source_size := TERRAIN_ART.get_size()
	var source_cell := Vector2(source_size.x / TERRAIN_GRID.x, source_size.y / TERRAIN_GRID.y)
	var source_rect := Rect2(Vector2(index) * source_cell, source_cell)
	draw_texture_rect_region(TERRAIN_ART, destination, source_rect)


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
	if farm_state == null or map_id != "farm_outdoor":
		return
	var plot: Dictionary = farm_state.get_cell_state(cell)
	if plot.is_empty() or not bool(plot.get("tilled", false)):
		return
	var seed_id := str(plot.get("seed", ""))
	if seed_id.is_empty():
		return
	var growth: int = int(plot.get("growth", 0))
	var mature := bool(plot.get("mature", false))
	if mature:
		_draw_tool_crop(rect.grow(-2), seed_id)
		draw_circle(rect.position + Vector2(27, 5), 3, Color("ffe29a"))
	else:
		var center := rect.get_center() + Vector2(0, 6)
		var height := 5.0 + minf(growth, 5) * 2.0
		draw_line(center, center - Vector2(0, height), Color("31572d"), 2)
		draw_circle(center + Vector2(-3, -height + 2), 3 + minf(growth, 3), Color("76b643"))
		draw_circle(center + Vector2(4, -height), 3 + minf(growth, 3), Color("a3ce58"))
	var definition: Dictionary = farm_state.get_crop_definition(seed_id)
	var progress := clampf(float(growth) / float(definition.get("grow_days", 1)), 0, 1)
	draw_rect(Rect2(rect.position + Vector2(3, 27), Vector2(26, 2)), Color("56402c"))
	draw_rect(Rect2(rect.position + Vector2(3, 27), Vector2(26 * progress, 2)), Color("f7d875"))


func _draw_festival_bunting() -> void:
	var start := cell_center_to_screen(Vector2i(30, 18))
	var finish := cell_center_to_screen(Vector2i(39, 18))
	draw_line(start, finish, Color("6c4c38"), 2)
	var colors := [Color("ee9b7c"), Color("f3d677"), Color("9dc79b"), Color("9cbfce")]
	for index in 20:
		var point := start.lerp(finish, float(index) / 20)
		draw_colored_polygon(PackedVector2Array([point, point + Vector2(17, 0), point + Vector2(8, 20)]), colors[index % colors.size()])
	var event: Dictionary = farm_state.Calendar.festival(farm_state.day)
	var sign_position := cell_to_screen(Vector2i(31, 19))
	draw_style_box(_festival_sign_style(), Rect2(sign_position, Vector2(240, 32)))
	draw_string(ThemeDB.fallback_font, sign_position + Vector2(12, 23), "%s · F 参加" % event.name, HORIZONTAL_ALIGNMENT_LEFT, 220, 17, Color("483b34"))

func _festival_sign_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff3d7")
	style.border_color = Color("805b40")
	style.set_border_width_all(2)
	return style


func _draw_snapped_buildings() -> void:
	if map_id == "farm_outdoor":
		_draw_art_object(Rect2i(10, 2, 11, 8), FARMHOUSE_ART, Rect2(Vector2.ZERO, FARMHOUSE_ART.get_size()))
	elif map_id == "town_square":
		_draw_art_object(Rect2i(5, 2, 11, 9), TOWN_CONCEPT_ART, Rect2(140, 0, 520, 420))
		_draw_art_object(Rect2i(20, 2, 9, 7), TOWN_CONCEPT_ART, Rect2(820, 20, 340, 310))
		_draw_art_object(Rect2i(34, 2, 10, 9), TOWN_CONCEPT_ART, Rect2(1160, 0, 480, 420))


func _draw_art_object(cells: Rect2i, texture: Texture2D, source_rect: Rect2) -> void:
	var rect := Rect2(cell_to_screen(cells.position), Vector2(cells.size) * TILE_SIZE)
	draw_texture_rect_region(texture, rect, source_rect)


func _draw_tool_crop(destination: Rect2, seed_id: String) -> void:
	var source_size := TOOLS_ART.get_size()
	var source_cell := Vector2(source_size.x / 4.0, source_size.y / 2.0)
	var crop_indices := {"parsnip": Vector2i(1, 1), "turnip": Vector2i(1, 1), "tomato": Vector2i(2, 1), "pumpkin": Vector2i(3, 1)}
	var crop_index: Vector2i = Vector2i(crop_indices.get(seed_id, Vector2i(1, 1)))
	var source_rect := Rect2(Vector2(crop_index) * source_cell, source_cell)
	draw_texture_rect_region(TOOLS_ART, destination, source_rect)


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
