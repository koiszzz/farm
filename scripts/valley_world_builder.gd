extends RefCounted

const WORLD_ID := "valley_world"
const SIZE := Vector2i(248, 112)
const PLACEMENTS := {
	"town_square": Vector2i(8, 32),
	"farm_outdoor": Vector2i(88, 40),
	"riverside": Vector2i(188, 40),
}

static func build(navigation) -> void:
	if navigation._maps.has(WORLD_ID): return
	var cells := {}
	for y in SIZE.y:
		for x in SIZE.x:
			cells[Vector2i(x, y)] = {"surface": "grass"}
	var world := {"id": WORLD_ID, "size": SIZE, "spawn": to_world("farm_outdoor", navigation.get_spawn("farm_outdoor")), "cells": cells, "npc_routes": {}, "objects": [], "zones": {}}
	_paint_wilderness(world)
	for source_id in PLACEMENTS:
		_merge_map(navigation, world, source_id, PLACEMENTS[source_id])
	_connect_regions(world)
	var visible_objects: Array = []
	for object in world.objects:
		if object.has("anchor") and str(world.cells[object.anchor].get("surface", "")) == "path": continue
		visible_objects.append(object)
	world.objects = visible_objects
	navigation._maps[WORLD_ID] = world

static func to_world(map_id: String, cell: Vector2i) -> Vector2i:
	return PLACEMENTS.get(map_id, Vector2i.ZERO) + cell

static func zone_at(cell: Vector2i) -> String:
	for id in PLACEMENTS:
		var sizes := {"town_square": Vector2i(48, 32), "farm_outdoor": Vector2i(64, 44), "riverside": Vector2i(48, 32)}
		if Rect2i(PLACEMENTS[id], sizes[id]).has_point(cell): return id
	if cell.x < 76: return "western_forest"
	if cell.x < 88: return "forest_crossing"
	if cell.x < 188: return "farm_country"
	return "eastern_lakes"

static func _merge_map(navigation, world: Dictionary, source_id: String, offset: Vector2i) -> void:
	var source: Dictionary = navigation._maps[source_id]
	for local_cell in source.cells:
		var layers: Dictionary = source.cells[local_cell].duplicate(true)
		layers.erase("exit")
		layers.erase("exit_record")
		world.cells[offset + local_cell] = layers
	for actor in source.npc_routes:
		var route: Array[Vector2i] = []
		for cell in source.npc_routes[actor]: route.append(offset + cell)
		world.npc_routes[actor] = route
	for value in source.objects:
		var object: Dictionary = value.duplicate(true)
		var r: Array = object.visual_rect.duplicate()
		r[0] = float(r[0]) + offset.x
		r[1] = float(r[1]) + offset.y
		object.visual_rect = r
		object.id = source_id + "_" + str(object.id)
		world.objects.append(object)

static func _paint_wilderness(world: Dictionary) -> void:
	# Outer cliffs/forest frame keep the continuous valley readable and bounded.
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if x < 3 or y < 3 or x >= SIZE.x - 3 or y >= SIZE.y - 3:
				_solid(world, cell, "world_edge")
	# A winding north-south stream and two organic lakes make the buffer land useful.
	for y in range(8, 101):
		var center := 69 + roundi(sin(float(y) * 0.16) * 4.0)
		for x in range(center - 3, center + 4): _water(world, Vector2i(x, y), "western_stream")
	for y in range(13, 38):
		for x in range(154, 181):
			var dx := float(x - 167) / 13.0
			var dy := float(y - 25) / 11.0
			if dx * dx + dy * dy + sin(float(x + y)) * 0.05 < 1.0: _water(world, Vector2i(x, y), "north_lake")
	for y in range(77, 104):
		for x in range(164, 191):
			var dx := float(x - 177) / 13.0
			var dy := float(y - 90) / 12.0
			if dx * dx + dy * dy < 1.0: _water(world, Vector2i(x, y), "south_lake")
	# Forest clusters leave broad paths instead of filling the buffer with empty grass.
	for y in range(7, 105, 5):
		for x in range(5, 243, 6):
			if x in range(57, 82) or x in range(139, 188):
				if (x * 17 + y * 29) % 5 < 3:
					var cell := Vector2i(x, y)
					_solid(world, cell, "forest_tree")
					world.objects.append({"id": "forest_tree_%d_%d" % [x, y], "atlas": "props", "index": [0, 0], "visual_rect": [x - 1.0, y - 2.0, 3.0, 3.0], "anchor": cell})

static func _connect_regions(world: Dictionary) -> void:
	# Same path material runs without a scene seam from town through forest to farm and lakes.
	var main_y := 54
	_path_line(world, Vector2i(49, main_y), Vector2i(89, main_y), 3)
	_path_line(world, Vector2i(151, 60), Vector2i(190, 55), 3)
	_path_line(world, Vector2i(74, main_y), Vector2i(88, 64), 3)
	_path_line(world, Vector2i(136, 64), Vector2i(167, 39), 2)
	_path_line(world, Vector2i(136, 70), Vector2i(177, 76), 2)
	# Bridge deck replaces water while retaining visible stream on both sides.
	for y in range(main_y - 2, main_y + 3):
		for x in range(63, 76): _path(world, Vector2i(x, y), "bridge_path")

static func _path_line(world: Dictionary, start: Vector2i, finish: Vector2i, width: int) -> void:
	var steps := maxi(absi(finish.x - start.x), absi(finish.y - start.y))
	for index in range(steps + 1):
		var p := Vector2(start).lerp(Vector2(finish), float(index) / maxi(steps, 1))
		for oy in range(-width / 2, width / 2 + 1):
			for ox in range(-width / 2, width / 2 + 1): _path(world, Vector2i(roundi(p.x) + ox, roundi(p.y) + oy), "valley_road")

static func _path(world: Dictionary, cell: Vector2i, id: String) -> void:
	if not Rect2i(Vector2i.ZERO, SIZE).has_point(cell): return
	world.cells[cell] = {"surface": "path", "landmark": id}

static func _water(world: Dictionary, cell: Vector2i, id: String) -> void:
	if not Rect2i(Vector2i.ZERO, SIZE).has_point(cell): return
	world.cells[cell] = {"surface": "grass", "water": "water", "blocked_id": id}

static func _solid(world: Dictionary, cell: Vector2i, id: String) -> void:
	if not Rect2i(Vector2i.ZERO, SIZE).has_point(cell): return
	world.cells[cell] = {"surface": "grass", "solid": "solid", "blocked_id": id}
