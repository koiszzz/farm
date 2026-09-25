extends SceneTree

var game
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func hit(map_id: String, cell: Vector2i) -> void:
	var positions := [{"cell": cell + Vector2i.DOWN, "facing": "up"}, {"cell": cell + Vector2i.UP, "facing": "down"}, {"cell": cell + Vector2i.LEFT, "facing": "right"}, {"cell": cell + Vector2i.RIGHT, "facing": "left"}]
	var position: Dictionary = positions[0]
	for candidate in positions:
		if game.navigation.is_walkable(map_id, candidate.cell):
			position = candidate
			break
	game._change_map(map_id, position.cell)
	game.life_panel.close()
	game._select_tool(6)
	game.player.set_pose(position.facing, "idle")
	game._farm_action()
	expect(game.actor_action.kind == "pickaxe", "mining starts contact action")
	game.actor_action.advance(1.0)

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://mining-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://mining-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	expect(game._inventory_items().has("tool:pickaxe"), "pickaxe available from starting inventory")
	var ore_art: Texture2D = load("res://assets/art/runtime_generated/ore_deposits_v1.svg")
	expect(ore_art != null and ore_art.get_size() == Vector2(256, 32), "ore and gem deposits use an eight-cell transparent pixel atlas")
	var represented_ores := {}
	for map_id in ["cave", "mine_2", "mine_3"]:
		for ore_cell in game.Mining.cells_for_floor(map_id):
			var ore_node: Dictionary = game.mining.vein(map_id, ore_cell, game.farm.day)
			represented_ores[str(ore_node.material)] = true
	expect(represented_ores.size() == 8, "mine levels visibly represent four ores and four rare gems")
	var cell := Vector2i(18, 12)
	game._change_map("cave", cell + Vector2i.DOWN)
	game.current_tool = "pickaxe"
	game.player.set_pose("up", "idle")
	game._farm_action()
	game.actor_action.advance(0.1)
	expect(game.energy == 100 and game.mining.damage.is_empty(), "windup has no gameplay effects")
	game.actor_action.cancel()
	expect(game.energy == 100, "cancel before contact spends no energy")
	hit("cave", cell)
	expect(game.energy == 98 and game.homestead.resources.copper_ore == 0, "first strike costs energy without premature loot")
	hit("cave", cell)
	expect(game.homestead.resources.copper_ore == 2, "second strike yields copper")
	expect(not game.active_collision_cells.has(cell), "broken deposit removes physical collision")
	game.actor_action.advance(1.0)
	expect(game.homestead.resources.copper_ore == 2, "contact cannot award twice")
	game._change_map("cave", cell + Vector2i.DOWN)
	expect(game.mining.vein("cave", cell, game.farm.day).is_empty() and not game.active_collision_cells.has(cell), "reentering never respawns mined deposit")
	game._change_map("cave", Vector2i(18, 4))
	game._interact()
	expect(game.current_map_id == "cave", "ordinary pickaxe cannot descend")
	game._change_map("general_store_interior", Vector2i(18, 16))
	var gold: int = game.farm.gold
	game._upgrade_tool("pickaxe")
	expect(game.farm.gold == gold and game.mining.tools.pickaxe == 0 and game.homestead.resources.copper_ore == 2, "failed upgrade is atomic")
	for index in [0, 2, 3, 4, 6]:
		hit("cave", game.Mining.CELLS[index])
		hit("cave", game.Mining.CELLS[index])
	game.farm.gold = 1000 # Isolate purchase costs from the crop growth test suite.
	game._change_map("general_store_interior", Vector2i(18, 16))
	game._upgrade_tool("pickaxe")
	expect(game.mining.tools.pickaxe == 1 and game.farm.gold == 850, "copper upgrade spends exact gold")
	expect(game.homestead.resources.copper_ore == 1 and game.homestead.resources.coal == 4, "upgrade consumes exact ore and coal")
	game.life_panel.close()
	game._change_map("cave", Vector2i(18, 4))
	game._interact()
	expect(game.current_map_id == "mine_2" and game.mining.deepest == 2, "copper pickaxe unlocks second floor")
	for index in [1, 2, 4]:
		hit("mine_2", game.Mining.cells_for_floor("mine_2")[index])
		hit("mine_2", game.Mining.cells_for_floor("mine_2")[index])
	expect(game.homestead.resources.iron_ore == 6, "second floor provides iron for further growth")
	game._change_map("mine_2", Vector2i(18, 24))
	game._interact()
	expect(game.current_map_id == "cave" and game.player_cell == Vector2i(18, 25), "return ladder safely leaves deep mine")
	game._change_map("general_store_interior", Vector2i(18, 16))
	game._upgrade_tool("pickaxe")
	expect(game.mining.tools.pickaxe == 2 and game.farm.gold == 450, "iron upgrade spends second tier cost")
	game.life_panel.close()
	game._change_map("mine_2", Vector2i(18, 4))
	game._interact()
	expect(game.current_map_id == "mine_3", "iron pickaxe reaches third floor")
	hit("mine_3", game.Mining.cells_for_floor("mine_3")[1])
	expect(game.homestead.resources.quartz == 2, "deep mine provides sellable quartz")
	var ore_before: int = game.homestead.resources.iron_ore
	var income: int = game.homestead.ship()
	expect(income == 120 and game.homestead.resources.iron_ore == ore_before, "shipping sells quartz and preserves upgrade materials")
	for gem in [{"map": "cave", "cell": Vector2i(17, 6), "id": "earth_crystal"}, {"map": "mine_2", "cell": Vector2i(30, 15), "id": "amethyst"}, {"map": "mine_2", "cell": Vector2i(26, 23), "id": "frozen_tear"}, {"map": "mine_3", "cell": Vector2i(30, 21), "id": "fire_quartz"}]:
		hit(str(gem.map), gem.cell)
		expect(int(game.homestead.resources[str(gem.id)]) == 1, "%s is awarded through the real mining action" % gem.id)
		var gem_item: Dictionary = game._inventory_items().get("material:" + str(gem.id), {})
		expect(gem_item.get("icon") is Texture2D and str(gem_item.get("description", "")).contains("出货"), "%s has an inventory icon and sale information" % gem.id)
	game.autosave_enabled = true
	expect(game._save_game(), "mining progress saves")
	game.mining.restore({})
	game._load_game()
	expect(game.mining.tools.pickaxe == 2 and game.mining.deepest == 3, "upgrades and discovery survive real reload")
	expect(game.homestead.resources.earth_crystal == 1 and game.homestead.resources.amethyst == 1 and game.homestead.resources.frozen_tear == 1 and game.homestead.resources.fire_quartz == 1, "rare gems survive real reload")
	expect(game.mining.vein("mine_3", game.Mining.cells_for_floor("mine_3")[1], game.farm.day).is_empty(), "reload preserves depleted ore")
	var gem_income: int = game.homestead.ship()
	expect(gem_income == 425, "the four rare gems ship for their configured values")
	expect(game.Mining.cells_for_floor("mine_2") != game.Mining.CELLS and game.Mining.cells_for_floor("mine_3") != game.Mining.cells_for_floor("mine_2"), "each mine level places deposits in a different layout")
	for map_id in ["cave", "mine_2", "mine_3"]:
		for ore_cell in game.Mining.cells_for_floor(map_id):
			var adjacent_reachable := false
			for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var stand_cell: Vector2i = ore_cell + offset
				if not game.navigation.is_walkable(map_id, stand_cell): continue
				var checkpoints: Array[Vector2i] = [game.navigation.get_spawn(map_id), stand_cell]
				var route: Array[Vector2i] = game.navigation.patrol_route(map_id, checkpoints)
				if not route.is_empty():
					adjacent_reachable = true
					break
			expect(adjacent_reachable, "%s ore site has an approach path" % map_id)
	game.autosave_enabled = false
	game.mining.tools.water = 1
	game._change_map("farm_outdoor", Vector2i(4, 14))
	game.farm.till(Vector2i(4, 15))
	game.energy = 1
	game.current_tool = "water"
	game.player.set_pose("down", "idle")
	game._farm_action()
	game.actor_action.advance(1.0)
	expect(game.energy == 0 and game.farm.get_cell_state(Vector2i(4, 15)).watered, "upgraded watering works with one energy")
	expect(not game.Mining.valid({"damage": {"bad": -1}}), "invalid mining save is rejected")
	expect(not game.mining.vein("cave", cell, game.farm.day + 1).is_empty(), "deposits replenish on next day")
	if DisplayServer.get_name() != "headless":
		game._change_map("mine_2", Vector2i(18, 15))
		game._select_tool(6)
		game._update_farm_hud()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/mining-floor-layouts")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/mining-floor-layouts/mine-2.png")
		game._change_map("mine_3", Vector2i(18, 17))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/mining-floor-layouts/mine-3.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Mining gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
