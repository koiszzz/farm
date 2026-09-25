extends RefCounted

const REGIONS := ["farm_outdoor", "countryside", "town_square", "beach", "cave"]
const TITLES := {"farm_outdoor": "花溪农场", "countryside": "郊区林地", "town_square": "花溪镇", "beach": "风铃沙滩", "cave": "青石山洞"}

static func build(nav) -> void:
	if nav.has_map("countryside"): return
	var country := _map("countryside", Vector2i(80, 48), Vector2i(61, 24))
	# Let the stream meander gently between the northern waterline, the timber
	# crossing and the southern marsh. The bridge and paths remain authored on top.
	for segment in [[30, 2, 4, 8], [28, 10, 4, 8], [29, 18, 4, 8], [31, 26, 4, 8], [30, 34, 4, 12]]:
		country.surfaces.append(_rect("creek", "water", segment))
	country.surfaces.append(_rect("bridge", "path", [27, 22, 8, 5]))
	country.surfaces.append(_rect("road", "path", [1, 23, 78, 3]))
	country.surfaces.append(_rect("north_path", "path", [43, 1, 3, 24]))
	country.surfaces.append(_rect("south_path", "path", [18, 24, 3, 23]))
	# Dense tree belts keep the crossroads readable while giving every camera
	# position a near, middle and far layer instead of a flat grass rectangle.
	for point in [Vector2i(6, 5), Vector2i(9, 7), Vector2i(13, 8), Vector2i(50, 5), Vector2i(54, 7), Vector2i(57, 10), Vector2i(7, 16), Vector2i(10, 18), Vector2i(52, 13), Vector2i(7, 34), Vector2i(10, 36), Vector2i(14, 38), Vector2i(17, 35), Vector2i(23, 38), Vector2i(27, 36), Vector2i(33, 38), Vector2i(51, 34), Vector2i(56, 36), Vector2i(60, 33), Vector2i(72, 8), Vector2i(75, 11), Vector2i(72, 38), Vector2i(76, 35)]:
		country.blocked.append(_rect("tree", "solid", [point.x, point.y, 1, 1]))
		country.objects.append({"id": "tree_%d_%d" % [point.x, point.y], "atlas": "props", "index": [0, 0], "visual_rect": [point.x - 1, point.y - 2, 3, 3]})
	for point in [Vector2i(16, 10), Vector2i(18, 10), Vector2i(55, 19), Vector2i(57, 20), Vector2i(8, 29), Vector2i(10, 31), Vector2i(45, 34), Vector2i(47, 35), Vector2i(67, 16), Vector2i(70, 17)]:
		country.blocked.append(_rect("bush", "solid", [point.x, point.y, 1, 1]))
		country.objects.append({"id": "bush_%d_%d" % [point.x, point.y], "atlas": "props", "index": [1, 0], "visual_rect": [point.x - 1, point.y - 1, 2, 2]})
	country.blocked.append(_rect("roadside_bench", "solid", [35, 20, 2, 1]))
	country.objects.append({"id": "roadside_bench", "atlas": "props", "index": [2, 1], "visual_rect": [35, 19, 2, 2]})
	for point in [Vector2i(36, 22), Vector2i(46, 21)]:
		country.blocked.append(_rect("lamp", "solid", [point.x, point.y, 1, 1]))
		country.objects.append({"id": "country_lamp_%d_%d" % [point.x, point.y], "atlas": "props", "index": [3, 1], "visual_rect": [point.x, point.y - 2, 1, 3]})
	country.exits = [_exit("to_farm", [79, 23, 1, 3], "farm_outdoor", [1, 14]), _exit("to_town", [0, 23, 1, 3], "town_square", [41, 22]), _exit("to_cave", [43, 0, 3, 1], "cave", [18, 25]), _exit("to_beach", [18, 47, 3, 1], "beach", [27, 12])]
	country.npc_routes = [
		{"actor": "carpenter", "points": [[8, 24], [24, 24], [38, 24], [54, 24]]},
		{"actor": "ranger", "points": [[44, 21], [44, 10], [38, 24], [20, 24], [19, 38]]},
	]
	# Land players at the north-shore approach so the first camera view includes
	# the fishing hut, tide pool and pier instead of clamping to the map's top edge.
	var beach := _map("beach", Vector2i(56, 40), Vector2i(27, 12), "sand")
	beach.surfaces.append(_rect("ocean", "water", [1, 17, 54, 22]))
	beach.surfaces.append(_rect("east_inlet", "water", [43, 10, 12, 7]))
	beach.surfaces.append(_rect("pier", "boardwalk", [25, 13, 4, 17]))
	beach.surfaces.append(_rect("tide_pool", "water", [6, 13, 7, 4]))
	# The fishing hut and dune rocks frame the open shore. Their custom artwork is
	# recorded here so physical footprints and artwork share one authored map.
	beach.blocked.append(_rect("beach_fishing_hut", "solid", [17, 9, 7, 4]))
	beach.objects.append({"id": "beach_fishing_hut_art", "atlas": "beach_props", "index": [2, 0], "visual_rect": [17, 6, 7, 6]})
	for rect in [[2, 5, 4, 3], [47, 5, 7, 4], [24, 8, 3, 2], [38, 10, 4, 2]]:
		beach.blocked.append(_rect("beach_dune_rock", "solid", rect))
	beach.objects.append({"id": "beach_dune_grass_west", "atlas": "beach_props", "index": [0, 0], "visual_rect": [1, 4, 5, 4]})
	beach.objects.append({"id": "beach_dune_grass_east", "atlas": "beach_props", "index": [0, 0], "visual_rect": [47, 4, 5, 4]})
	beach.objects.append({"id": "beach_tide_pool_art", "atlas": "beach_props", "index": [1, 0], "visual_rect": [5, 11, 8, 5]})
	beach.objects.append({"id": "beach_driftwood", "atlas": "beach_props", "index": [0, 1], "visual_rect": [21, 13, 4, 2]})
	beach.objects.append({"id": "beach_coastal_shrub", "atlas": "beach_props", "index": [1, 1], "visual_rect": [43, 8, 5, 4]})
	beach.objects.append({"id": "beach_net_rack", "atlas": "beach_props", "index": [2, 1], "visual_rect": [38, 16, 4, 4]})
	beach.objects.append({"id": "beach_parasols", "atlas": "beach_props", "index": [3, 1], "visual_rect": [32, 12, 5, 4]})
	# The extra shore details frame a small traversable activity pocket around the
	# second pool without covering the fishing route or the daily shell spawns.
	beach.surfaces.append(_rect("east_tide_pool", "water", [18, 16, 2, 2]))
	beach.objects.append({"id": "beach_east_tide_pool_art", "atlas": "beach_collectibles", "index": [2, 0], "visual_rect": [18, 15, 2, 2]})
	for point in [Vector2i(23, 9), Vector2i(42, 13)]:
		beach.blocked.append(_rect("beach_seagrass", "solid", [point.x, point.y, 1, 1]))
		beach.objects.append({"id": "beach_seagrass_%d_%d" % [point.x, point.y], "atlas": "beach_collectibles", "index": [3, 0], "visual_rect": [point.x - 1, point.y - 1, 2, 2]})
	beach.blocked.append(_rect("beach_crab", "solid", [30, 16, 1, 1]))
	beach.objects.append({"id": "beach_crab_art", "atlas": "beach_collectibles", "index": [1, 1], "visual_rect": [30, 16, 1, 1]})
	beach.objects.append({"id": "beach_seabird_art", "atlas": "beach_collectibles", "index": [3, 1], "visual_rect": [35, 14, 1, 1]})
	beach.objects.append({"id": "beach_rope_basket_art", "atlas": "beach_collectibles", "index": [2, 1], "visual_rect": [36, 15, 1, 1]})
	beach.blocked.append(_rect("beach_bench", "solid", [20, 15, 2, 1]))
	beach.objects.append({"id": "beach_bench", "atlas": "props", "index": [2, 1], "visual_rect": [20, 14, 2, 2]})
	for point in [Vector2i(23, 16), Vector2i(31, 16)]:
		beach.blocked.append(_rect("lamp", "solid", [point.x, point.y, 1, 1]))
		beach.objects.append({"id": "beach_lamp_%d_%d" % [point.x, point.y], "atlas": "props", "index": [3, 1], "visual_rect": [point.x, point.y - 2, 1, 3]})
	beach.exits = [_exit("to_country", [26, 0, 3, 1], "countryside", [19, 45])]
	beach.npc_routes = [
		{"actor": "fisherman", "points": [[14, 16], [24, 16], [27, 22], [36, 16]]},
		{"actor": "child", "points": [[10, 10], [20, 14], [35, 14], [40, 15]]},
	]
	var cave := _map("cave", Vector2i(36, 28), Vector2i(18, 25), "cave_floor")
	for rect in [[5, 5, 7, 3], [23, 5, 7, 4], [6, 17, 5, 3], [24, 17, 5, 4]]:
		cave.blocked.append(_rect("rock_wall", "solid", rect))
	for rect in [[2, 11, 2, 2], [14, 10, 2, 2], [21, 13, 2, 2], [32, 11, 2, 2], [13, 21, 2, 2], [29, 23, 2, 2]]:
		cave.blocked.append(_rect("cave_rock_pile", "solid", rect))
	cave.exits = [_exit("to_country", [17, 27, 3, 1], "countryside", [44, 2])]
	for definition in [country, beach, cave]: nav._build_map(definition)
	for floor_number in [2, 3]:
		var floor_map: Dictionary = cave.duplicate(true)
		floor_map.id = "mine_%d" % floor_number
		floor_map.exits = []
		floor_map.interactions = []
		floor_map.blocked = floor_map.blocked.filter(func(record: Dictionary): return str(record.get("id", "")) != "cave_rock_pile")
		var rubble_layout: Array = [
			[[4, 13, 2, 2], [11, 9, 2, 2], [19, 17, 2, 2], [28, 18, 2, 2], [16, 22, 2, 2], [30, 10, 2, 2]],
			[[3, 16, 2, 2], [8, 12, 2, 2], [17, 15, 2, 2], [25, 12, 2, 2], [11, 22, 2, 2], [31, 20, 2, 2]],
		][floor_number - 2]
		for rubble in rubble_layout:
			floor_map.blocked.append(_rect("cave_rock_pile", "solid", rubble))
		nav._build_map(floor_map)
	for map_id in ["cave", "mine_2", "mine_3"]:
		var actions := [{"id": "mine_return", "class": "interaction", "rect": [18, 24, 1, 1], "target": "mine_return"}]
		if map_id != "mine_3": actions.append({"id": "mine_down", "class": "interaction", "rect": [18, 4, 1, 1], "target": "mine_down"})
		nav._apply_records(nav._maps[map_id], actions, "interaction")
	# Preserve established doorway positions while connecting them to the hub.
	_link(nav, "farm_outdoor", [0, 13, 1, 3], "countryside", [61, 24])
	_link(nav, "town_square", [42, 21, 1, 3], "countryside", [2, 24])
	nav._navigation_grids.clear()
	nav._route_cache.clear()

static func _map(id: String, size: Vector2i, spawn: Vector2i, surface := "grass") -> Dictionary:
	return {"id": id, "size_tiles": [size.x, size.y], "spawn": [spawn.x, spawn.y], "surfaces": [_rect("ground", surface, [0, 0, size.x, size.y])], "blocked": [_rect("edge", "solid", [0, 0, size.x, 1]), _rect("edge", "solid", [0, size.y - 1, size.x, 1]), _rect("edge", "solid", [0, 0, 1, size.y]), _rect("edge", "solid", [size.x - 1, 0, 1, size.y])], "objects": [], "interactions": [], "exits": [], "npc_routes": []}

static func _rect(id: String, kind: String, rect: Array) -> Dictionary:
	return {"id": id, "class": kind, "rect": rect}

static func _exit(id: String, rect: Array, target: String, arrival: Array) -> Dictionary:
	return {"id": id, "class": "exit", "rect": rect, "target": target, "arrival": arrival}

static func _link(nav, map_id: String, rect: Array, target: String, arrival: Array) -> void:
	nav._apply_records(nav._maps[map_id], [_exit("region_link", rect, target, arrival)], "exit")

static func migrate(data: Dictionary, navigation) -> void:
	if int(data.get("world_layout", 1)) == 2:
		var offset: Vector2i = navigation.to_contiguous_world("farm_outdoor", Vector2i.ZERO)
		for row in data.get("farm", {}).get("plots", []):
			row.x = int(row.x) - offset.x
			row.y = int(row.y) - offset.y
		for row in data.get("farm", {}).get("structures", []):
			row.x = int(row.x) - offset.x
			row.y = int(row.y) - offset.y
		for row in data.get("processing", {}).get("jobs", []):
			row.x = int(row.x) - offset.x
			row.y = int(row.y) - offset.y
		if str(data.get("map", "")) == "valley_world":
			var cell := Vector2i(data.cell[0], data.cell[1])
			var region: String = navigation.zone_at("valley_world", cell)
			if region in ["farm_outdoor", "town_square", "riverside"]:
				cell -= navigation.to_contiguous_world(region, Vector2i.ZERO)
			else:
				region = "countryside"
				cell = navigation.get_spawn(region)
			data.map = region
			data.cell = [cell.x, cell.y]
	data.world_layout = 3
