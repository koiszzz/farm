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


func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://barn-gameplay-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://barn-gameplay-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	expect(not game.animals.barn_built and game.animals.cows.is_empty(), "new farm begins without a barn")
	expect(not game._inventory_items().has("food:milk"), "empty barn adds no phantom milk")

	game._change_map("general_store_interior", Vector2i(18, 15))
	game.animals.build_coop(game.farm, {"wood": 0, "stone": 0})
	game.farm.gold = game.Animals.BARN_COST.gold
	game.homestead.resources.wood = game.Animals.BARN_COST.wood
	game.homestead.resources.stone = game.Animals.BARN_COST.stone - 1
	game._build_barn()
	expect(not game.animals.barn_built, "missing one building material blocks barn construction")
	expect(game.farm.gold == game.Animals.BARN_COST.gold and game.homestead.resources.wood == game.Animals.BARN_COST.wood, "failed barn construction is atomic")
	game.homestead.resources.stone += 1
	game._build_barn()
	expect(game.animals.barn_built, "carpenter service builds the real barn")
	expect(game.farm.gold == 0 and game.homestead.resources.wood == 0 and game.homestead.resources.stone == 0, "barn construction consumes exact quoted cost")
	expect(game.animals.is_solid(game.Animals.BARN_RECT.position), "barn footprint becomes solid")
	expect(not game.animals.is_solid(game.Animals.BARN_GATE_CELLS[0]), "barn pen leaves a physical gate opening")
	var site_clear := true
	for cell in game.animals.barn_structure_cells():
		if not game.navigation.is_walkable("farm_outdoor", cell): site_clear = false
	expect(site_clear, "barn construction does not overlap authored ponds, trees or buildings")
	var overlap_free := true
	for cell in game.animals.barn_structure_cells():
		if game.animals.COOP_RECT.has_point(cell) or game.animals.PEN_RECT.has_point(cell): overlap_free = false
	expect(overlap_free, "barn does not overlap the existing coop or pen")

	game.farm.gold = game.Animals.COW_PRICE * game.Animals.BARN_CAPACITY + game.Animals.HAY_PRICE * 10
	for index in game.Animals.BARN_CAPACITY:
		game._buy_cow()
	expect(game.animals.cows.size() == game.Animals.BARN_CAPACITY, "barn accepts two purchased cows")
	expect(game.cow_actors.size() == game.Animals.BARN_CAPACITY, "each saved cow has a world actor")
	var money_after_capacity: int = game.farm.gold
	game._buy_cow()
	expect(game.animals.cows.size() == game.Animals.BARN_CAPACITY and game.farm.gold == money_after_capacity, "full barn rejects extra cow without charging")
	game._buy_hay()
	game._buy_hay()
	expect(game.animals.hay == 10, "hay purchases stack into shared feed storage")

	game._change_map("farm_outdoor", game.Animals.BARN_GATE_CELLS[0] + Vector2i.DOWN)
	expect(game.active_collision_cells.has(game.Animals.BARN_RECT.position), "built barn participates in player collision")
	expect(not game.active_collision_cells.has(game.Animals.BARN_GATE_CELLS[0]), "barn gate remains walkable")
	for actor in game.cow_actors.values(): expect(actor.visible, "cow appears in the outdoor pen")
	var first_id := str(game.animals.cows[0].id)
	var first_actor = game.cow_actors[first_id]
	expect(first_actor._sprite.texture.resource_path.ends_with("cow_walk_v1.png"), "live cow uses the dedicated pixel-art atlas")
	expect(first_actor._sprite.visible and first_actor._sprite.region_enabled, "cow sprite region renders independently from the shadow")
	var start_position: Vector2 = first_actor.position
	for frame in 360: first_actor.tick(1.0 / 60.0, game.animals.barn_roam_cells(), 600, "晴")
	expect(first_actor.position.distance_to(start_position) > 6.0, "cow roams through the fenced yard")
	expect(first_actor.stride > 0.0, "cow walk frames advance from actual roaming distance")
	expect(game.animals.BARN_PEN_RECT.has_point(first_actor.local_cell), "roaming cow stays inside pen bounds")

	var calf_milk: Dictionary = game.animals.milk_cow(first_id, game.farm.day)
	expect(not calf_milk.ok and game.animals.milk == 0, "calf cannot be milked on purchase day")
	var feed_result: Dictionary = game.animals.feed_all_cows(game.farm.day)
	expect(feed_result.ok and game.animals.hay == 8, "feed-all consumes one hay per hungry cow")
	var repeated_feed: Dictionary = game.animals.feed_all_cows(game.farm.day)
	expect(not repeated_feed.ok and game.animals.hay == 8, "daily feeding cannot consume twice")
	game.player_body.position = first_actor.position + Vector2(0, 30)
	game.player_cell = game._cell_from_world_position(game.player_body.position)
	game._interact_cow(first_id)
	expect(game.actor_action.kind == "pet", "nearby cow starts the care action")
	game.actor_action.advance(2.0)
	expect(int(game.animals.cow(first_id).affection) == 20 and game.animals.milk == 0, "unfed adult-age care grants affection without milk")
	game._interact_cow(first_id)
	game.actor_action.advance(2.0)
	expect(int(game.animals.cow(first_id).affection) == 20, "cow care reward cannot repeat on the same day")

	game._advance_day(false)
	expect(int(game.animals.cow(first_id).age) == 1, "new cows mature after their first cared-for night")
	var milk_result: Dictionary = game.animals.milk_cow(first_id, game.farm.day)
	expect(milk_result.ok and game.animals.milk == 1, "fed adult cow gives one milk the next day")
	var repeat_milk: Dictionary = game.animals.milk_cow(first_id, game.farm.day)
	expect(not repeat_milk.ok and game.animals.milk == 1, "milking cannot repeat on the same day")
	expect(game._inventory_items().has("food:milk"), "milked milk appears in real inventory source")
	game.energy = 40
	game._eat_inventory_item("food:milk")
	expect(game.animals.milk == 0 and game.energy == 40 + game.Animals.MILK_ENERGY, "milk is edible for configured energy")

	var second_id := str(game.animals.cows[1].id)
	game._advance_day(false)
	var hungry_milk: Dictionary = game.animals.milk_cow(second_id, game.farm.day)
	expect(not hungry_milk.ok and game.animals.milk == 0, "cow that skipped feeding gives no milk")
	game.animals.feed_cow(second_id, game.farm.day)
	expect(game.animals.milk_cow(second_id, game.farm.day).ok, "cow fed today can be milked today")

	game.animals.milk = 2
	var shipping_cell := Vector2i(22, 11)
	game._change_map("farm_outdoor", shipping_cell)
	var gold_before_shipping: int = game.farm.gold
	game._interact()
	expect(game.animals.milk == 0 and game.farm.gold == gold_before_shipping + game.Animals.MILK_PRICE * 2, "shipping box sells milk at the animal price")
	game._change_map("farm_outdoor", game.Animals.BARN_INTERACTION_CELL + Vector2i.DOWN)
	game.player.set_pose("up", "idle")
	var target: Dictionary = game._interaction_target()
	expect(str(target.get("record", {}).get("target", "")) == "barn", "barn door is a physical context interaction")
	game._interact()
	expect(game.life_panel.visible, "barn interaction opens husbandry panel")
	game.life_panel.close()

	# Cheese press processing chain.
	expect(not game.crafting.is_unlocked("cheese_press", game.village, game.mining, game.skills), "cheese press begins skill locked")
	game.skills.gain("farming", 770)
	expect(game.crafting.is_unlocked("cheese_press", game.village, game.mining, game.skills), "farming level three unlocks cheese press")
	game.homestead.resources.wood = 10
	game.homestead.resources.stone = 6
	game.homestead.resources.copper_ore = 3
	game._craft_recipe("cheese_press")
	expect(int(game.crafting.crafted_items.get("cheese_press", 0)) == 1, "crafted cheese press enters facility inventory")
	var press_cell := Vector2i(5, 20)
	game._change_map("farm_outdoor", press_cell + Vector2i.UP)
	game.player.set_pose("down", "idle")
	game._place_structure("cheese_press")
	expect(game.farm.structure_at(press_cell) == "cheese_press", "cheese press installs in faced field cell")
	expect(game.active_collision_cells.has(press_cell), "installed cheese press has world collision")
	game.animals.milk = 1
	game._start_processing(press_cell, "cheese_press", "milk")
	expect(game.animals.milk == 0 and str(game.processing.job_at(press_cell).output) == "cheese", "cheese press consumes exactly one milk")
	game._change_map("farm_outdoor", press_cell + Vector2i.DOWN)
	game.player.set_pose("up", "idle")
	game.current_tool = "pickaxe"
	var energy_before: int = game.energy
	game._farm_action()
	expect(game.farm.structure_at(press_cell) == "cheese_press" and game.energy == energy_before, "busy cheese press cannot be dismantled")
	game.life_panel.close()
	game._advance_day(false)
	expect(bool(game.processing.job_at(press_cell).ready), "overnight tick completes cheese")
	game._collect_processed(press_cell)
	expect(int(game.processing.products.get("cheese", 0)) == 1, "collection stores finished cheese")
	expect(game._inventory_items().has("food:artisan:cheese"), "cheese appears in inventory")
	game.energy = 30
	game._eat_inventory_item("food:artisan:cheese")
	expect(game.energy == 30 + game.Processing.CHEESE_ENERGY and int(game.processing.products.cheese) == 0, "cheese is edible for configured energy")
	game.processing.products.cheese = 1
	game._change_map("farm_outdoor", shipping_cell)
	var cheese_gold: int = game.farm.gold
	game._interact()
	expect(game.farm.gold == cheese_gold + game.Processing.CHEESE_PRICE, "shipping box sells cheese at artisan price")

	# Save / restore / validation.
	game.animals.hay = 4
	game.animals.milk = 1
	game.autosave_enabled = true
	expect(game._save_game(), "barn state writes to isolated real save")
	var saved = game._read_save(game.save_path)
	expect(game._valid_save(saved), "barn save passes full validator")
	var old_save: Dictionary = saved.duplicate(true)
	old_save.animals.erase("cows")
	old_save.animals.erase("barn_built")
	old_save.animals.erase("milk")
	expect(game._valid_save(old_save), "legacy save without barn fields remains valid")
	var invalid: Dictionary = saved.duplicate(true)
	invalid.animals.cows[1].id = invalid.animals.cows[0].id
	expect(not game._valid_save(invalid), "duplicate cow ids are rejected")
	var orphan: Dictionary = saved.duplicate(true)
	orphan.animals.barn_built = false
	expect(not game._valid_save(orphan), "cows without a barn are rejected")
	game.animals.restore({})
	game._load_game()
	expect(game.animals.barn_built and game.animals.cows.size() == game.Animals.BARN_CAPACITY, "real reload restores barn and cows")
	expect(game.animals.hay == 4 and game.animals.milk == 1, "real reload restores feed and milk")
	expect(game.cow_actors.size() == game.Animals.BARN_CAPACITY, "real reload respawns cow actors")

	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		game.life_panel.close()
		game._change_map("farm_outdoor", Vector2i(53, 43))
		game.clock_minutes = 600
		for actor in game.cow_actors.values(): actor.tick(0.1, game.animals.barn_roam_cells(), 600, "晴")
		for actor in game.chicken_actors.values(): actor.tick(0.1, game.animals.roam_cells(), 600, "晴")
		game.world.queue_redraw()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/animal-art")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/animal-art/cow-pen.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Barn gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
