extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")

var failures := 0
var game

func _init() -> void:
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	for route in [["farm_outdoor", Vector2i(0,14), "countryside"], ["town_square", Vector2i(42,22), "countryside"], ["farm_outdoor", Vector2i(63,20), "riverside"], ["riverside", Vector2i(0,15), "farm_outdoor"]]:
		game._change_map(route[0], game.navigation.get_spawn(route[0]))
		await physics_frame
		await walk_to(route[1])
		expect(game.current_map_id == route[2], "walking reaches exit from spawn: " + str(route))
		expect(game.navigation.exit_at(game.current_map_id, game.player_cell).is_empty(), "arrival lies outside a return trigger")
	for route in [["farm_outdoor", Vector2i(15,10), "farmhouse_interior"], ["town_square", Vector2i(10,11), "general_store_interior"], ["town_square", Vector2i(24,9), "clinic_interior"], ["town_square", Vector2i(38,11), "cafe_interior"]]:
		game._change_map(route[0], game.navigation.get_spawn(route[0]))
		await physics_frame
		await walk_to(route[1])
		await wait_for_door_transition()
		expect(game.current_map_id == route[2] and not game.entering_door, "automatically enter on foot: " + str(route[2]))
		# Exercise actual physics through the room, including both side aisles
		# and the functional furniture stand positions, before leaving.
		await walk_to(Vector2i(7, 8))
		await walk_to(Vector2i(29, 16))
		var size: Vector2i = game.navigation.get_map_size(game.current_map_id)
		for y in size.y:
			for x in size.x:
				var cell := Vector2i(x, y)
				if not game.navigation.interaction_at(game.current_map_id, cell).is_empty():
					await walk_to(cell)
		await walk_to(Vector2i(18, 16))
		Motion.walk(game, Vector2i.DOWN)
		await wait_for_door_transition()
		expect(game.current_map_id == route[0] and not game.entering_door, "walk out of interior: " + str(route[2]))
	game.queue_free()
	print("World travel: %d failures; four outdoor routes, four automatic building round trips, indoor aisles and all furniture interactions" % failures)
	quit(1 if failures else 0)


func wait_for_door_transition() -> void:
	var elapsed := 0.0
	while game.entering_door and elapsed < 2.0:
		await create_timer(0.05).timeout
		elapsed += 0.05
	expect(not game.entering_door, "door transition completes within two seconds")

func walk_to(target: Vector2i) -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, game.navigation.get_map_size(game.current_map_id))
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var cell := Vector2i(x,y)
			var blocked: bool = not game.navigation.is_walkable(game.current_map_id, cell)
			# Avoid unrelated area exits while routing to a specific destination.
			blocked = blocked or (cell != target and not game.navigation.exit_at(game.current_map_id, cell).is_empty())
			grid.set_point_solid(cell, blocked)
	var path := grid.get_id_path(game.player_cell, target)
	expect(not path.is_empty(), "route exists to " + str(target))
	for index in range(1, path.size()):
		var next: Vector2i = path[index]
		Motion.walk(game, next - game.player_cell)
		if index < path.size() - 1:
			expect(game.player_cell == next, "physics follows legal route cell " + str(next))
			if game.player_cell != next: return
		await physics_frame
