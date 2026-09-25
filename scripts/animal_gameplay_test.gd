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
	game.save_path = "user://animal-gameplay-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://animal-gameplay-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	expect(not game.animals.coop_built and game.animals.chickens.is_empty(), "new farm begins without livestock infrastructure")
	expect(game.animals.structure_cells().is_empty(), "unbuilt coop occupies no world cells")
	expect(not game._inventory_items().has("food:egg"), "empty animal inventory adds no phantom egg")

	game._change_map("general_store_interior", Vector2i(18, 15))
	game.farm.gold = game.Animals.COOP_COST.gold
	game.homestead.resources.wood = game.Animals.COOP_COST.wood
	game.homestead.resources.stone = game.Animals.COOP_COST.stone - 1
	game._build_coop()
	expect(not game.animals.coop_built, "missing one building material blocks construction")
	expect(game.farm.gold == game.Animals.COOP_COST.gold and game.homestead.resources.wood == game.Animals.COOP_COST.wood, "failed construction is atomic")
	game.homestead.resources.stone += 1
	game._build_coop()
	expect(game.animals.coop_built, "carpenter service builds the real coop")
	expect(game.farm.gold == 0 and game.homestead.resources.wood == 0 and game.homestead.resources.stone == 0, "construction consumes exact quoted cost")
	expect(game.animals.is_solid(game.Animals.COOP_RECT.position), "coop footprint becomes solid")
	expect(not game.animals.is_solid(game.Animals.GATE_CELLS[0]), "pen leaves a physical gate opening")
	var site_clear := true
	for cell in game.animals.structure_cells():
		if not game.navigation.is_walkable("farm_outdoor", cell): site_clear = false
	expect(site_clear, "coop construction does not overlap authored ponds, trees or buildings")
	var path_clear := true
	for cell in game.animals.roam_cells():
		if str(game.navigation.get_cell_layers("farm_outdoor", cell).get("surface", "")) == "path": path_clear = false
	expect(path_clear, "chicken yard does not cover the farm road")

	game.farm.gold = game.Animals.CHICKEN_PRICE * game.Animals.CAPACITY + game.Animals.HAY_PRICE * 5
	for index in game.Animals.CAPACITY:
		game._buy_chicken()
	expect(game.animals.chickens.size() == game.Animals.CAPACITY, "coop accepts four purchased chickens")
	expect(game.chicken_actors.size() == game.Animals.CAPACITY, "each saved chicken has a world actor")
	var money_after_capacity: int = game.farm.gold
	game._buy_chicken()
	expect(game.animals.chickens.size() == game.Animals.CAPACITY and game.farm.gold == money_after_capacity, "full coop rejects extra chicken without charging")
	game._buy_hay()
	expect(game.animals.hay == 5 and game.farm.gold == 0, "hay purchase spends exact money and enters feed storage")

	game._change_map("farm_outdoor", game.Animals.GATE_CELLS[0] + Vector2i.DOWN)
	expect(game.active_collision_cells.has(game.Animals.COOP_RECT.position), "built coop participates in player collision")
	expect(not game.active_collision_cells.has(game.Animals.GATE_CELLS[0]), "open gate remains walkable")
	expect(game.pet.grid.is_point_solid(game.Animals.COOP_RECT.position), "farm companion avoids the coop")
	for actor in game.chicken_actors.values(): expect(actor.visible, "chicken appears in the outdoor pen")
	var first_id := str(game.animals.chickens[0].id)
	var first_actor = game.chicken_actors[first_id]
	expect(first_actor._sprite.texture.resource_path.ends_with("chicken_walk_v1.png"), "chicken uses the authored pixel animal atlas")
	var start_position: Vector2 = first_actor.position
	for frame in 360: first_actor.tick(1.0 / 60.0, game.animals.roam_cells(), 600, "晴")
	expect(first_actor.position.distance_to(start_position) > 8.0, "chicken roams through the fenced yard")
	expect(game.animals.PEN_RECT.has_point(first_actor.local_cell), "roaming chicken stays inside pen bounds")

	var feed_result: Dictionary = game.animals.feed_all(game.farm.day)
	expect(feed_result.ok and game.animals.hay == 1, "feed-all consumes one hay per hungry chicken")
	var repeated_feed: Dictionary = game.animals.feed_all(game.farm.day)
	expect(not repeated_feed.ok and game.animals.hay == 1, "daily feeding cannot consume twice")
	game.player_body.position = first_actor.position + Vector2(0, 24)
	game.player_cell = game._cell_from_world_position(game.player_body.position)
	game._pet_chicken(first_id)
	expect(game.actor_action.kind == "pet", "nearby chicken starts the pet animation")
	game.actor_action.advance(2.0)
	expect(int(game.animals.chicken(first_id).affection) == 20, "pet contact grants daily affection")
	game._pet_chicken(first_id)
	game.actor_action.advance(2.0)
	expect(int(game.animals.chicken(first_id).affection) == 20, "pet reward cannot repeat on the same day")

	game._advance_day(false)
	expect(game.animals.nest_eggs == 0 and int(game.animals.chicken(first_id).age) == 1, "new chicks mature after their first cared-for night")
	var day_two_feed: Dictionary = game.animals.feed(first_id, game.farm.day)
	expect(day_two_feed.ok and game.animals.hay == 0, "single chicken feeding consumes the final hay")
	var second_id := str(game.animals.chickens[1].id)
	game._pet_chicken_in_coop(second_id)
	expect(int(game.animals.chicken(second_id).petted_day) == game.farm.day, "coop panel allows indoor care on rainy days and evenings")
	game.life_panel.close()
	game._advance_day(false)
	expect(game.animals.nest_eggs == 1, "fed adult chicken leaves one egg after sleep")
	game._collect_eggs()
	expect(game.animals.nest_eggs == 0 and game.animals.eggs == 1, "coop collection moves egg from nest to backpack")
	expect(game._inventory_items().has("food:egg"), "collected egg appears in real inventory source")
	game.energy = 50
	game._eat_inventory_item("food:egg")
	expect(game.animals.eggs == 0 and game.energy == 62, "egg can be eaten for configured energy")

	game.animals.eggs = 2
	var shipping_cell := Vector2i(22, 11)
	game._change_map("farm_outdoor", shipping_cell)
	var gold_before_shipping: int = game.farm.gold
	game._interact()
	expect(game.animals.eggs == 0 and game.farm.gold == gold_before_shipping + game.Animals.EGG_PRICE * 2, "shipping box sells collected eggs")
	game._change_map("farm_outdoor", game.Animals.COOP_INTERACTION_CELL + Vector2i.DOWN)
	game.player.set_pose("up", "idle")
	var target: Dictionary = game._interaction_target()
	expect(str(target.get("record", {}).get("target", "")) == "coop", "coop door is a physical context interaction")
	game._interact()
	expect(game.life_panel.visible, "coop interaction opens husbandry panel")
	game.life_panel.close()

	game.animals.hay = 3
	game.animals.eggs = 2
	game.autosave_enabled = true
	expect(game._save_game(), "animal state writes to isolated real save")
	var saved = game._read_save(game.save_path)
	expect(game._valid_save(saved), "animal save passes full validator")
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("animals")
	expect(game._valid_save(old_save), "legacy save without animals remains valid")
	var invalid: Dictionary = saved.duplicate(true)
	invalid.animals.chickens[1].id = invalid.animals.chickens[0].id
	expect(not game._valid_save(invalid), "duplicate animal ids are rejected")
	game.animals.restore({})
	game._load_game()
	expect(game.animals.coop_built and game.animals.chickens.size() == game.Animals.CAPACITY, "real reload restores coop and chickens")
	expect(game.animals.hay == 3 and game.animals.eggs == 2, "real reload restores feed and products")

	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		game._change_map("farm_outdoor", Vector2i(44, 25))
		game.clock_minutes = 600
		for actor in game.chicken_actors.values(): actor.tick(0.1, game.animals.roam_cells(), 600, "晴")
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-22/animals")
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/animal-art")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/animal-art/chicken-pen.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Animal gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
