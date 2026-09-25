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

func interaction_cell(map_id: String, target: String) -> Vector2i:
	var size: Vector2i = game.navigation.get_map_size(map_id)
	for y in size.y:
		for x in size.x:
			if game.navigation.interaction_at(map_id, Vector2i(x, y)).get("target", "") == target: return Vector2i(x, y)
	return Vector2i(-1, -1)

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://crafting-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://crafting-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	expect(game.crafting.is_unlocked("trail_mix", game.village, game.mining), "basic forage recipe starts unlocked")
	expect(not game.crafting.is_unlocked("fish_stew", game.village, game.mining), "friend recipe starts hidden")
	expect(not game.crafting.is_unlocked("miner_lunch", game.village, game.mining), "mine recipe starts hidden")
	game.homestead.resources.berry = 1
	game.homestead.resources.mushroom = 0
	game._craft_recipe("trail_mix")
	expect(game.homestead.resources.berry == 1 and game.crafting.meals.is_empty(), "missing ingredient craft is atomic")
	game.homestead.resources.mushroom = 1
	game._craft_recipe("trail_mix")
	expect(game.homestead.resources.berry == 0 and game.homestead.resources.mushroom == 0, "craft consumes exact ingredients")
	expect(game.crafting.meals.trail_mix == 1, "crafted meal enters meal inventory")
	expect(game._inventory_items().has("food:meal:trail_mix"), "crafted meal appears in backpack source")
	game.energy = 10
	game._eat_inventory_item("food:meal:trail_mix")
	expect(game.energy == 55 and game.crafting.meals.trail_mix == 0, "meal restores authored energy and is consumed")

	game.village.milestones.cook = 1
	game.farm.harvest_inventory.pumpkin = 1
	game.homestead.resources.mushroom = 1
	game._craft_recipe("pumpkin_soup")
	expect(game.crafting.meals.pumpkin_soup == 1 and game.farm.get_harvest_count("pumpkin") == 0, "cook friendship unlocks pumpkin soup")
	game.village.milestones.fisherman = 1
	game.fishing.catch_fish("creek_fish")
	game.farm.harvest_inventory.tomato = 1
	game._craft_recipe("fish_stew")
	expect(game.crafting.meals.fish_stew == 1 and game.fishing.total_count() == 0, "fisher friendship recipe consumes fish and crop")
	game.mining.deepest = 2
	game.fishing.catch_fish("sardine")
	game.farm.harvest_inventory.potato = 1
	game._craft_recipe("miner_lunch")
	expect(game.crafting.meals.miner_lunch == 1, "second mine floor unlocks miner lunch")

	game.life_panel.close()
	var key := InputEventKey.new()
	key.keycode = KEY_K
	key.pressed = true
	game._unhandled_input(key)
	expect(game.life_panel.visible and game.life_panel.heading.text == "随身制作与炉灶", "K opens crafting menu")
	game.life_panel.close()
	var fireplace := interaction_cell("farmhouse_interior", "fireplace")
	expect(fireplace != Vector2i(-1, -1), "farmhouse has authored fireplace")
	game._change_map("farmhouse_interior", fireplace)
	game._interact()
	expect(game.life_panel.visible and game.life_panel.heading.text == "随身制作与炉灶", "fireplace opens same crafting menu")

	game.autosave_enabled = true
	expect(game._save_game(), "crafted food saves")
	game.crafting.restore({})
	game._load_game()
	expect(game.crafting.meals.pumpkin_soup == 1 and game.crafting.meals.miner_lunch == 1, "real reload restores every meal type")
	game.autosave_enabled = false
	expect(not game.Crafting.valid({"meals": {"unknown": 1}}), "unknown recipe save rejected")
	expect(not game.Crafting.valid({"meals": {"trail_mix": -1}}), "negative meal save rejected")
	if DisplayServer.get_name() != "headless":
		game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
		game._open_crafting()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-21/crafting")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-21/crafting/menu.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Crafting gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
