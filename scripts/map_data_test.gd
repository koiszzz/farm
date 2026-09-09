extends SceneTree


const MapDataService = preload("res://scripts/map_data.gd")

var _failed := false


func _init() -> void:
	var navigation = MapDataService.new()
	_expect(navigation.load_data(), "navigation JSON should load")
	_expect(navigation.map_ids() == PackedStringArray(["cafe_interior", "clinic_interior", "farm_outdoor", "farmhouse_interior", "general_store_interior", "riverside", "town_square"]), "all seven authored outdoor and interior maps should be indexed")
	_expect(navigation.get_map_size("farm_outdoor") == Vector2i(64, 44), "expanded farm preserves old fields inside the new garden and river lanes")
	_expect(navigation.get_spawn("town_square") == Vector2i(41, 22), "town spawn should match the safe design arrival cell")
	_expect(navigation.world_to_cell(Vector2(63.9, 32.0)) == Vector2i(1, 1), "world coordinates should floor into cells")
	_expect(navigation.cell_to_world(Vector2i(1, 1)) == Vector2(48, 48), "cell positions should resolve to cell centers")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(13, 11)) == "path", "farm path should fill the segment from (12,11) to (17,11)")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(13, 13)) == "grass", "grass outside the current farm path stays grass")
	_expect(navigation.interaction_at("farmhouse_interior", Vector2i(10, 8)).get("target") == "bed", "farmhouse bed is reachable through its authored bedside tile")
	_expect(navigation.interaction_at("town_square", Vector2i(10, 11)).get("target") == "general_store_interior", "shop door targets the existing interior")

	_expect(navigation.is_tillable("farm_outdoor", Vector2i(3, 15)), "crop plot should be tillable")
	_expect(navigation.is_walkable("farm_outdoor", Vector2i(3, 15)), "empty crop plot should be walkable")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(3, 15), true), "occupied crop plot should block movement")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(10, 8)), "farmhouse ground footprint should block movement")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(27, 16)), "pond should block movement")

	var farm_exit: Dictionary = navigation.exit_at("farm_outdoor", Vector2i(0, 13))
	_expect(farm_exit.get("target", "") == "town_square", "farm exit should target town")
	var arrival = farm_exit.get("arrival", [])
	_expect(arrival is Array and arrival.size() == 2 and int(arrival[0]) == 41 and int(arrival[1]) == 22, "farm exit arrival should preserve the safe JSON arrival cell")
	var shipping_box: Dictionary = navigation.interaction_at("farm_outdoor", Vector2i(22, 11))
	_expect(shipping_box.get("target", "") == "shipping_box", "shipping box stand cell should be interactive")

	var routes: Dictionary = navigation.get_npc_routes("town_square")
	_expect(routes.has("florist") and routes.has("shopkeeper") and routes.has("fisherman"), "town NPC routes should be available")
	for actor in routes.keys():
		for cell in navigation.get_npc_route("town_square", str(actor)):
			_expect(navigation.is_walkable("town_square", cell), "%s route point %s should be walkable" % [actor, cell])

	if _failed:
		quit(1)
		return
	print("MapData tests passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("MapData test failed: %s" % message)
