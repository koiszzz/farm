extends SceneTree


const MapDataService = preload("res://scripts/map_data.gd")
const WorldRenderer = preload("res://scripts/world_renderer.gd")

var _failed := false


func _init() -> void:
	var navigation = MapDataService.new()
	_expect(navigation.load_data(), "navigation JSON should load")
	_expect(navigation.map_ids() == PackedStringArray(["cafe_interior", "clinic_interior", "farm_outdoor", "farmhouse_interior", "general_store_interior", "riverside", "town_square"]), "all seven authored outdoor and interior maps should be indexed")
	_expect(navigation.get_map_size("farm_outdoor") == Vector2i(64, 44), "farm keeps the expanded outdoor area needed by the animal yards")
	_expect(navigation.get_spawn("town_square") == Vector2i(41, 22), "town spawn should match the safe design arrival cell")
	_expect(navigation.world_to_cell(Vector2(63.9, 32.0)) == Vector2i(1, 1), "world coordinates should floor into cells")
	_expect(navigation.cell_to_world(Vector2i(1, 1)) == Vector2(48, 48), "cell positions should resolve to cell centers")
	_expect(navigation.get_spawn("farm_outdoor") == Vector2i(27, 14), "farm spawn should stand below the centered farmhouse doorway")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(27, 16)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(27, 23)) == "path", "the main trail should run from the farmhouse through the south gate")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(22, 18)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(24, 18)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(24, 16)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(26, 16)) == "path", "the crop branch should curve from the field edge back to the main trail through two corners")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(35, 15)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(44, 15)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(45, 15)) == "path" and navigation.get_cell_class("farm_outdoor", Vector2i(38, 13)) == "grass" and navigation.interaction_at("farm_outdoor", Vector2i(46, 15)).get("target", "") == "well", "the direct well lane should meet its interaction cell without the former S bend and crate spur")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(40, 11)) == "grass", "the old long cross-farm lane should no longer cut through the field")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(3, true, false, false, true), 0.0), "the authored NW bend should keep its base orientation")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(3, true, true, false, false), PI * 0.5), "NE bends should rotate clockwise from the authored NW tile")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(3, false, true, true, false), PI), "SE bends should rotate clockwise from the authored NW tile")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(3, false, false, true, true), PI * 1.5), "SW bends should rotate clockwise from the authored NW tile")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(6, false, true, false, false), PI * 0.5), "a one-neighbor end cap should rotate toward its east connection")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(6, false, false, true, false), PI), "a one-neighbor end cap should rotate toward its south connection")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(4, true, true, false, true), 0.0), "the authored N-E-W T junction should keep its base orientation")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(4, true, true, true, false), PI * 0.5), "rotated T junction should connect N-E-S")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(4, false, true, true, true), PI), "rotated T junction should connect E-S-W")
	_expect(is_equal_approx(WorldRenderer.farm_path_rotation_from_mask(4, true, false, true, true), PI * 1.5), "rotated T junction should connect N-S-W")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(13, 13)) == "grass", "grass outside the current farm path stays grass")
	_expect(navigation.interaction_at("farmhouse_interior", Vector2i(5, 6)).get("target") == "bed", "farmhouse bed is reachable through its authored bedside tile")
	_expect(navigation.interaction_at("town_square", Vector2i(10, 11)).get("target") == "general_store_interior", "shop door targets the existing interior")

	_expect(navigation.is_tillable("farm_outdoor", Vector2i(16, 16)), "crop plot should be tillable")
	_expect(navigation.is_walkable("farm_outdoor", Vector2i(16, 16)), "empty crop plot should be walkable")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(16, 16), true), "occupied crop plot should block movement")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(20, 12)) and not navigation.is_walkable("farm_outdoor", Vector2i(32, 12)), "farmhouse stone foundation should block its centered measured base")
	_expect(navigation.is_walkable("farm_outdoor", Vector2i(19, 11)) and navigation.is_walkable("farm_outdoor", Vector2i(33, 11)), "farmhouse foundation collision should not include transparent side margins")
	_expect(navigation.get_cell_class("farm_outdoor", Vector2i(27, 12)) == "interaction", "farmhouse doorway remains a walkable entry tile centered under the door art")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(44, 13)) and not navigation.is_walkable("farm_outdoor", Vector2i(49, 14)), "well blocks its full six-by-two measured stone base")
	_expect(navigation.get_cell_class("farmhouse_interior", Vector2i(10, 10)) == "path", "starter farmhouse has a walkable path from its door")
	_expect(not navigation.is_walkable("farm_outdoor", Vector2i(58, 25)) and not navigation.is_walkable("farm_outdoor", Vector2i(49, 26)), "pond core and curved west shore should block movement")

	var farm_exit: Dictionary = navigation.exit_at("farm_outdoor", Vector2i(27, 21))
	_expect(farm_exit.get("target", "") == "town_square", "farm exit should target town")
	var arrival = farm_exit.get("arrival", [])
	_expect(arrival is Array and arrival.size() == 2 and int(arrival[0]) == 41 and int(arrival[1]) == 22, "farm exit arrival should preserve the safe JSON arrival cell")
	var shipping_box: Dictionary = navigation.interaction_at("farm_outdoor", Vector2i(38, 11))
	_expect(shipping_box.get("target", "") == "shipping_box", "shipping box stand cell should be interactive")
	var well: Dictionary = navigation.interaction_at("farm_outdoor", Vector2i(46, 15))
	_expect(well.get("target", "") == "well", "well approach should remain reachable from the connected front path")

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
