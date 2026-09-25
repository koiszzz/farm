## Runtime reader for the outdoor navigation design.
##
## `design/maps/outdoor_navigation_v1.json` is the single source of truth for
## map bounds, collisions, interaction stand positions, exits, and NPC routes.
## This class turns the authored rectangles/points into per-cell lookup data so
## the scene, avatar, and NPCs all make decisions in the same 32 px grid.
class_name MapData
extends RefCounted


const DEFAULT_PATH := "res://design/maps/outdoor_navigation_v1.json"
const DEFAULT_RESOLUTION_ORDER := ["exit", "interaction", "solid", "water", "crop_occupied", "surface"]


var source_path := DEFAULT_PATH
var tile_px := 32
var load_errors: Array[String] = []

var _loaded := false
var _resolution_order: Array = DEFAULT_RESOLUTION_ORDER.duplicate()
var _classes: Dictionary = {}
var _maps: Dictionary = {}
var _navigation_grids: Dictionary = {}
var _route_cache: Dictionary = {}
var _door_cache: Dictionary = {}


static func load_default() -> MapData:
	var map_data := MapData.new()
	map_data.load_from_json(DEFAULT_PATH)
	return map_data


## Compatibility-friendly entry point for scene code.
func load_data(path: String = DEFAULT_PATH) -> bool:
	return load_from_json(path)


func load_from_json(path: String = DEFAULT_PATH) -> bool:
	source_path = path
	_loaded = false
	load_errors.clear()
	_classes.clear()
	_maps.clear()
	_navigation_grids.clear()
	_route_cache.clear()
	_door_cache.clear()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_add_error("Unable to open navigation data: %s" % path)
		return false

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		_add_error("Navigation JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false
	if not (json.data is Dictionary):
		_add_error("Navigation JSON root must be an object.")
		return false

	var document: Dictionary = json.data
	var grid = document.get("grid", {})
	if grid is Dictionary:
		tile_px = max(1, int(grid.get("tile_px", 32)))
	else:
		tile_px = 32
		_add_error("Missing or invalid grid; using a 32 px tile size.")

	var configured_order = document.get("resolution_order", DEFAULT_RESOLUTION_ORDER)
	if configured_order is Array and not configured_order.is_empty():
		_resolution_order = configured_order.duplicate()
	else:
		_resolution_order = DEFAULT_RESOLUTION_ORDER.duplicate()
		_add_error("Missing or invalid resolution_order; using the default order.")
	_classes = document.get("classes", {}) if document.get("classes", {}) is Dictionary else {}

	var raw_maps = document.get("maps", [])
	if not (raw_maps is Array):
		_add_error("Navigation JSON maps must be an array.")
		return false

	for raw_map in raw_maps:
		if not (raw_map is Dictionary):
			_add_error("Ignored a map entry that is not an object.")
			continue
		_build_map(raw_map)

	if _maps.is_empty():
		_add_error("Navigation JSON did not contain any valid maps.")
		return false
	_loaded = true
	_install_signposts()
	return true

func build_contiguous_world() -> void:
	preload("res://scripts/valley_world_builder.gd").build(self)
	_install_signposts("valley_world")

func build_regions() -> void:
	for terrain in ["sand", "boardwalk", "cave_floor"]:
		_classes[terrain] = {"walkable": true}
	preload("res://scripts/region_world_builder.gd").build(self)
	_install_signposts()


func _install_signposts(only_map := "") -> void:
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://design/maps/signposts.json"))
	for map_id in records:
		if not _maps.has(map_id) or (not only_map.is_empty() and map_id != only_map): continue
		var map: Dictionary = _maps[map_id]
		if not map.has("signposts"): map["signposts"] = []
		for entry in records[map_id]:
			var existing := false
			for installed in map.signposts:
				if installed.id == entry.id: existing = true
			if existing: continue
			var post := _as_cell(entry.post)
			var stand := _as_cell(entry.stand)
			if not is_walkable(map_id, post) or not is_walkable(map_id, stand) or not interaction_at(map_id, stand).is_empty():
				_add_error("Signpost conflicts with map: " + str(entry.id))
				continue
			map.cells[post]["solid"] = "solid"
			map.cells[post]["blocked_id"] = entry.id
			map.cells[stand]["interaction"] = "interaction"
			map.cells[stand]["interaction_record"] = {"target": "signpost", "title": entry.title, "text": entry.text, "id": entry.id}
			map.signposts.append(entry.duplicate(true))
		# Connecting world roads may repaint merged stand cells. Restore the
		# sign contract from its authored local-to-world coordinates afterwards.
		for entry in map.signposts:
			var post := _as_cell(entry.post)
			var stand := _as_cell(entry.stand)
			map.cells[post]["solid"] = "solid"
			map.cells[post]["blocked_id"] = entry.id
			map.cells[stand]["interaction"] = "interaction"
			map.cells[stand]["interaction_record"] = {"target": "signpost", "title": entry.title, "text": entry.text, "id": entry.id}
		_navigation_grids.erase(map_id)
		_door_cache.erase(map_id)
	_route_cache.clear()


func get_signposts(map_id: String) -> Array:
	return _get_map(map_id).get("signposts", []).duplicate(true)


func has_clear_line(map_id: String, from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1, ceili(from.distance_to(to) / 8.0))
	for index in range(1, steps + 1):
		if not is_walkable(map_id, world_to_cell(from.lerp(to, float(index) / steps))): return false
	return true

func to_contiguous_world(map_id: String, cell: Vector2i) -> Vector2i:
	return preload("res://scripts/valley_world_builder.gd").to_world(map_id, cell)

func zone_at(map_id: String, cell: Vector2i) -> String:
	if map_id == "valley_world": return preload("res://scripts/valley_world_builder.gd").zone_at(cell)
	return map_id


func is_loaded() -> bool:
	return _loaded


func map_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for map_id in _maps.keys():
		ids.append(str(map_id))
	ids.sort()
	return ids


func has_map(map_id: String) -> bool:
	return _maps.has(map_id)


## Returns a deep copy so a caller cannot desynchronise the navigation cache.
func get_map(map_id: String) -> Dictionary:
	return _get_map(map_id).duplicate(true)


## Narrow snapshots avoid copying every terrain cell just to read decorations.
func get_objects(map_id: String) -> Array:
	return _get_map(map_id).get("objects", []).duplicate(true)


func get_door_cells(map_id: String) -> Array[Vector2i]:
	if not _door_cache.has(map_id):
		var doors: Array[Vector2i] = []
		if not map_id.ends_with("_interior"):
			var cells: Dictionary = _get_map(map_id).get("cells", {})
			for cell in cells:
				if str(interaction_at(map_id, cell).get("target", "")).ends_with("_interior"):
					doors.append(cell)
		_door_cache[map_id] = doors
	return _door_cache[map_id].duplicate()


## Static topology belongs to the map. Consumers receive paths, not a mutable grid.
func patrol_route(map_id: String, checkpoints: Array[Vector2i]) -> Array[Vector2i]:
	var key := map_id + str(checkpoints)
	if _route_cache.has(key): return _route_cache[key].duplicate()
	if not _navigation_grids.has(map_id):
		var grid := AStarGrid2D.new()
		grid.region = get_map_bounds(map_id)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()
		for y in grid.region.size.y:
			for x in grid.region.size.x:
				grid.set_point_solid(Vector2i(x, y), not is_walkable(map_id, Vector2i(x, y)))
		_navigation_grids[map_id] = grid
	var grid: AStarGrid2D = _navigation_grids[map_id]
	var route: Array[Vector2i] = []
	for index in checkpoints.size():
		var segment := grid.get_id_path(checkpoints[index], checkpoints[(index + 1) % checkpoints.size()])
		for step in range(segment.size() - 1): route.append(segment[step])
	_route_cache[key] = route
	return route.duplicate()


func get_map_size(map_id: String) -> Vector2i:
	var map = _get_map(map_id)
	var size = map.get("size", Vector2i.ZERO)
	return size if size is Vector2i else Vector2i.ZERO


func get_map_bounds(map_id: String) -> Rect2i:
	return Rect2i(Vector2i.ZERO, get_map_size(map_id))


func get_spawn(map_id: String) -> Vector2i:
	var map = _get_map(map_id)
	var spawn = map.get("spawn", Vector2i.ZERO)
	return spawn if spawn is Vector2i else Vector2i.ZERO


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / tile_px), floori(world_position.y / tile_px))


## Returns the center of a cell. Use cell_to_world_top_left for TileMap placement.
func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * tile_px + tile_px * 0.5, cell.y * tile_px + tile_px * 0.5)


func cell_to_world_top_left(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * tile_px, cell.y * tile_px)


func is_in_bounds(map_id: String, cell: Vector2i) -> bool:
	var size := get_map_size(map_id)
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


## `crop_occupied` applies only to tillable ground and models a crop collision
## without duplicating static collision data outside this service.
func is_walkable(map_id: String, cell: Vector2i, crop_occupied := false) -> bool:
	if not is_in_bounds(map_id, cell):
		return false
	var resolved_class := get_cell_class(map_id, cell, crop_occupied)
	if resolved_class == "crop_occupied":
		return false
	var class_info = _classes.get(resolved_class, {})
	return class_info is Dictionary and bool(class_info.get("walkable", false))


func get_cell_class(map_id: String, cell: Vector2i, crop_occupied := false) -> String:
	if not is_in_bounds(map_id, cell):
		return "out_of_bounds"
	var map = _get_map(map_id)
	var cells: Dictionary = map.get("cells", {})
	var layers: Dictionary = cells.get(cell, {})
	for layer_name in _resolution_order:
		match str(layer_name):
			"crop_occupied":
				if crop_occupied and str(layers.get("surface", "")) == "tillable":
					return "crop_occupied"
			_:
				var layer_class := str(layers.get(str(layer_name), ""))
				if not layer_class.is_empty():
					return layer_class
	return "void"


## A copy of the resolved layers for debug overlays and TileMap construction.
func get_cell_layers(map_id: String, cell: Vector2i) -> Dictionary:
	if not is_in_bounds(map_id, cell):
		return {}
	var map = _get_map(map_id)
	var cells: Dictionary = map.get("cells", {})
	var layers = cells.get(cell, {})
	return layers.duplicate(true) if layers is Dictionary else {}


func is_tillable(map_id: String, cell: Vector2i) -> bool:
	return is_in_bounds(map_id, cell) and str(get_cell_layers(map_id, cell).get("surface", "")) == "tillable"


func exit_at(map_id: String, cell: Vector2i) -> Dictionary:
	return _record_at(map_id, cell, "exit")


func interaction_at(map_id: String, cell: Vector2i) -> Dictionary:
	return _record_at(map_id, cell, "interaction")


func get_npc_route(map_id: String, actor: String) -> Array[Vector2i]:
	var map = _get_map(map_id)
	var routes: Dictionary = map.get("npc_routes", {})
	var route = routes.get(actor, [])
	var result: Array[Vector2i] = []
	if route is Array:
		for cell in route:
			if cell is Vector2i:
				result.append(cell)
	return result


func get_npc_routes(map_id: String) -> Dictionary:
	var result := {}
	var map = _get_map(map_id)
	var routes: Dictionary = map.get("npc_routes", {})
	for actor in routes.keys():
		result[actor] = get_npc_route(map_id, str(actor))
	return result


func get_cells_with_class(map_id: String, requested_class: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var map = _get_map(map_id)
	var cells: Dictionary = map.get("cells", {})
	for cell in cells.keys():
		if get_cell_class(map_id, cell) == requested_class:
			result.append(cell)
	return result


func _build_map(raw_map: Dictionary) -> void:
	var map_id := str(raw_map.get("id", "")).strip_edges()
	var size := _as_cell(raw_map.get("size_tiles", []))
	if map_id.is_empty() or size.x <= 0 or size.y <= 0:
		_add_error("Ignored map with missing id or invalid size_tiles.")
		return
	if _maps.has(map_id):
		_add_error("Ignored duplicate map id: %s" % map_id)
		return

	var cells := {}
	for y in size.y:
		for x in size.x:
			cells[Vector2i(x, y)] = {"surface": "void"}

	var map := {
		"id": map_id,
		"size": size,
		"spawn": _as_cell(raw_map.get("spawn", [])),
		"cells": cells,
		"npc_routes": {},
		"objects": raw_map.get("objects", []).duplicate(true),
	}
	_apply_records(map, raw_map.get("surfaces", []), "surface")
	_apply_records(map, raw_map.get("blocked", []), "blocked")
	_apply_records(map, raw_map.get("interactions", []), "interaction")
	_apply_records(map, raw_map.get("exits", []), "exit")
	_build_npc_routes(map, raw_map.get("npc_routes", []))

	if not is_in_bounds_for_size(size, map["spawn"]):
		_add_error("Map %s has an invalid spawn; using (0, 0)." % map_id)
		map["spawn"] = Vector2i.ZERO
	_maps[map_id] = map
	_validate_map(map)


func _apply_records(map: Dictionary, raw_records, group: String) -> void:
	if not (raw_records is Array):
		_add_error("Map %s has invalid %s records." % [map["id"], group])
		return
	for record in raw_records:
		if not (record is Dictionary):
			_add_error("Map %s has a non-object %s record." % [map["id"], group])
			continue
		var record_class := str(record.get("class", ""))
		if record_class.is_empty():
			_add_error("Map %s has a %s record without a class." % [map["id"], group])
			continue
		for cell in _cells_from_record(record, map["size"]):
			var layers: Dictionary = map["cells"][cell]
			match group:
				"surface":
					layers["surface"] = record_class
				"blocked":
					# `solid` and `water` remain separate so resolution_order is meaningful.
					layers[record_class] = record_class
					layers["blocked_id"] = str(record.get("id", ""))
				"interaction", "exit":
					layers[group] = record_class
					layers["%s_record" % group] = record.duplicate(true)
			map["cells"][cell] = layers


func _build_npc_routes(map: Dictionary, raw_routes) -> void:
	if not (raw_routes is Array):
		return
	var routes: Dictionary = map["npc_routes"]
	for raw_route in raw_routes:
		if not (raw_route is Dictionary):
			continue
		var actor := str(raw_route.get("actor", "")).strip_edges()
		if actor.is_empty():
			_add_error("Map %s contains an NPC route without an actor." % map["id"])
			continue
		var route: Array[Vector2i] = []
		var raw_points = raw_route.get("points", [])
		if raw_points is Array:
			for raw_point in raw_points:
				var cell := _as_cell(raw_point)
				if is_in_bounds_for_size(map["size"], cell):
					route.append(cell)
				else:
					_add_error("NPC route %s on %s contains an out-of-bounds point." % [actor, map["id"]])
		routes[actor] = route


func _validate_map(map: Dictionary) -> void:
	var map_id: String = map["id"]
	var spawn: Vector2i = map["spawn"]
	if not is_walkable(map_id, spawn):
		_add_error("Map %s spawn %s is not walkable." % [map_id, spawn])
	var routes = map.get("npc_routes", {})
	if not (routes is Dictionary):
		return
	for actor in routes.keys():
		for cell in get_npc_route(map_id, str(actor)):
			if not is_walkable(map_id, cell):
				_add_error("NPC route %s on %s crosses a blocked cell %s." % [actor, map_id, cell])


func _record_at(map_id: String, cell: Vector2i, layer_name: String) -> Dictionary:
	if not is_in_bounds(map_id, cell):
		return {}
	var layers := get_cell_layers(map_id, cell)
	var record = layers.get("%s_record" % layer_name, {})
	if not (record is Dictionary):
		return {}
	# An absent record must remain empty.  Adding `cell` to an empty record
	# makes every ordinary tile behave like an exit or interaction.
	if record.is_empty():
		return {}
	var result: Dictionary = record.duplicate(true)
	result["cell"] = cell
	return result


func _cells_from_record(record: Dictionary, size: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if record.get("rect", null) is Array:
		var rect = record["rect"]
		if rect.size() < 4:
			return result
		var origin := Vector2i(int(rect[0]), int(rect[1]))
		var extent := Vector2i(int(rect[2]), int(rect[3]))
		for y in range(max(0, origin.y), min(size.y, origin.y + max(0, extent.y))):
			for x in range(max(0, origin.x), min(size.x, origin.x + max(0, extent.x))):
				result.append(Vector2i(x, y))
		return result
	if record.get("points", null) is Array:
		var points: Array[Vector2i] = []
		for raw_point in record["points"]:
			var cell := _as_cell(raw_point)
			if is_in_bounds_for_size(size, cell):
				points.append(cell)
		if points.size() == 1:
			return points
		for point_index in range(1, points.size()):
			for cell in _rasterize_line(points[point_index - 1], points[point_index]):
				if not result.has(cell):
					result.append(cell)
	return result


## Points in the design file describe a polyline (for example the farm road),
## not isolated cells. Bresenham keeps that line deterministic on the grid.
func _rasterize_line(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var current := start
	var delta_x := absi(finish.x - start.x)
	var step_x := 1 if start.x < finish.x else -1
	var delta_y := -absi(finish.y - start.y)
	var step_y := 1 if start.y < finish.y else -1
	var error := delta_x + delta_y
	while true:
		result.append(current)
		if current == finish:
			break
		var doubled_error := 2 * error
		if doubled_error >= delta_y:
			error += delta_y
			current.x += step_x
		if doubled_error <= delta_x:
			error += delta_x
			current.y += step_y
	return result


func _as_cell(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


func _get_map(map_id: String) -> Dictionary:
	var map = _maps.get(map_id, {})
	return map if map is Dictionary else {}


func _add_error(message: String) -> void:
	load_errors.append(message)
	push_warning("MapData: %s" % message)


static func is_in_bounds_for_size(size: Vector2i, cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y
