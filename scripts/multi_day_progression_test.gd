extends SceneTree

var game
var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func grow(seed_id: String, count: int, days: int, cells: Array[Vector2i]) -> void:
	for index in count:
		var cell := cells[index]
		if not bool(game.farm.get_cell_state(cell).get("tilled", false)):
			expect(bool(game.farm.till(cell).ok), "soil can be tilled for " + seed_id)
		expect(bool(game.farm.plant(cell, seed_id).ok), seed_id + " can be planted from starting seed stock")
	for _day in days:
		for index in count:
			if not bool(game.farm.get_cell_state(cells[index]).get("watered", false)):
				expect(bool(game.farm.water(cells[index]).ok), seed_id + " can be watered on a dry growth day")
			expect(bool(game.farm.get_cell_state(cells[index]).get("watered", false)), seed_id + " is watered by the player or rain")
		expect(bool(game.farm.advance_day(false).ok), "sleep advances a watered crop day")
	for index in count:
		expect(bool(game.farm.harvest(cells[index]).ok), seed_id + " matures on its authored schedule")


func mine_nodes(map_id: String, indices: Array[int], strikes_per_node: int) -> void:
	for index in indices:
		for _strike in strikes_per_node:
			var result: Dictionary = game.mining.strike(map_id, game.Mining.cells_for_floor(map_id)[index], game.farm.day)
			expect(bool(result.ok), "reachable %s deposit accepts the equipped pickaxe" % map_id)
			if bool(result.complete):
				game.homestead.resources[result.material] += int(result.amount)


func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://multi-day-progression-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://multi-day-progression-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	expect(game.farm.gold == 100, "progression starts with the real new-game gold")
	expect(game.homestead.resources.values().all(func(amount): return int(amount) == 0), "progression starts without injected materials")
	var plots: Array[Vector2i] = game.navigation.get_cells_with_class("farm_outdoor", "tillable")
	plots.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	expect(plots.size() >= 6, "farm provides enough authored soil for the opening crop")

	# The first free parsnips fund the copper upgrade while the cave supplies
	# every required material. No gold, ore, coal, crops, or fish are injected.
	grow("parsnip", 6, 4, plots)
	var parsnip_shipping: Dictionary = game.farm.ship_all()
	expect(int(parsnip_shipping.earned) == 210 and game.farm.gold == 310, "six opening parsnips earn 210g")
	mine_nodes("cave", [0, 1, 2, 4], 2)
	expect(game.homestead.resources.copper_ore == 6 and game.homestead.resources.coal == 2, "first cave run supplies the copper recipe")
	expect(game.mining.upgrade("pickaxe", game.farm, game.homestead.resources), "natural earnings buy the copper pickaxe")
	expect(game.farm.gold == 160 and game.mining.tools.pickaxe == 1, "copper pickaxe leaves the expected 160g balance")

	# Reuse four cleared plots, then combine crops with renewable beach and
	# fishing income to reach the 400g iron upgrade without selling upgrade ore.
	grow("turnip", 4, 3, plots)
	var turnip_shipping: Dictionary = game.farm.ship_all()
	expect(int(turnip_shipping.earned) == 112 and game.farm.gold == 272, "four starting turnips add 112g")
	var shells: Array[Dictionary] = game.homestead.available("beach", game.farm.day, game.navigation)
	expect(shells.size() == 4, "the beach offers four daily shell pickups")
	for shell in shells:
		expect(game.homestead.collect(shell, game.farm.day), "each visible shell can be collected once")
	var forage_income: int = game.homestead.ship()
	game.farm.gold += forage_income
	expect(forage_income == 88 and game.farm.gold == 360, "beach gathering adds 88g while preserving ore")
	expect(game.fishing.catch_fish("sardine"), "an ordinary spring daytime ocean catch enters inventory")
	var fishing_income: int = game.fishing.ship()
	game.farm.gold += fishing_income
	expect(fishing_income == 40 and game.farm.gold == 400, "one common sardine reaches the iron-upgrade budget")

	game._change_map("cave", Vector2i(18, 4))
	game._interact()
	expect(game.current_map_id == "mine_2" and game.mining.deepest == 2, "the copper pickaxe physically unlocks mine floor two")
	mine_nodes("mine_2", [0, 1, 2, 3, 4], 2)
	expect(game.homestead.resources.iron_ore == 6 and game.homestead.resources.coal == 4, "floor two supplies the complete iron recipe")
	expect(game.mining.upgrade("pickaxe", game.farm, game.homestead.resources), "the earned 400g and mined materials buy the iron pickaxe")
	expect(game.farm.gold == 0 and game.mining.tools.pickaxe == 2, "natural opening loop reaches the iron tool with exact spending")
	expect(game.homestead.resources.copper_ore == 1 and game.homestead.resources.iron_ore == 1 and game.homestead.resources.coal == 1, "upgrades consume exact materials and retain the surplus")

	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix):
			DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Multi-day progression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
