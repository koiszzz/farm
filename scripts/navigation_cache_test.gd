extends SceneTree

var failures := 0

func expect(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func _init() -> void:
	var navigation = preload("res://scripts/map_data.gd").new()
	navigation.load_data()
	var checkpoints: Array[Vector2i] = [Vector2i(17, 12), Vector2i(24, 12)]
	var route: Array[Vector2i] = navigation.patrol_route("farm_outdoor", checkpoints)
	expect(not route.is_empty(), "patrol has a valid route")
	for cell in route:
		expect(navigation.is_walkable("farm_outdoor", cell), "cached patrol remains on walkable ground")
	var original_size := route.size()
	route.clear()
	expect(navigation.patrol_route("farm_outdoor", checkpoints).size() == original_size, "caller cannot corrupt cached route")
	var doors: Array[Vector2i] = navigation.get_door_cells("farm_outdoor")
	expect(not doors.is_empty(), "outdoor door index populated")
	doors.clear()
	expect(not navigation.get_door_cells("farm_outdoor").is_empty(), "caller cannot corrupt door index")
	var objects: Array = navigation.get_objects("farm_outdoor")
	objects[0]["id"] = "corrupted"
	expect(navigation.get_objects("farm_outdoor")[0].id != "corrupted", "object snapshot is isolated")
	var farm = preload("res://scripts/farm_state.gd").new()
	farm.bind(navigation, "farm_outdoor")
	var pet = preload("res://scripts/companion_actor.gd").new()
	pet.navigation = navigation
	pet.farm = farm
	pet.rebuild_grid()
	var initial_grid = pet.grid
	var plot := Vector2i(4, 15)
	farm.till(plot)
	farm.plant(plot, "parsnip")
	pet.rebuild_grid()
	expect(pet.grid == initial_grid, "planting retains static pet grid")
	expect(pet.grid.is_point_solid(plot), "new crop overlays cached topology")
	pet.world_map_id = "farmhouse_interior"
	pet.rebuild_grid()
	farm.reset()
	pet.world_map_id = "farm_outdoor"
	pet.rebuild_grid()
	expect(pet.grid == initial_grid, "returning restores original grid")
	expect(not pet.grid.is_point_solid(plot), "removed crop does not leave stale obstacle")
	expect(pet.grid.is_point_solid(Vector2i(10, 8)), "static farmhouse collision survives dynamic refresh")
	pet.sprite.free() # The test does not enter the scene tree / run _ready.
	pet.free()
	navigation.load_data()
	expect(navigation.patrol_route("farm_outdoor", checkpoints).size() == original_size, "map reload rebuilds valid navigation")
	print("Navigation cache: %d failures" % failures)
	quit(1 if failures else 0)
