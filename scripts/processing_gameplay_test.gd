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
	game.save_path = "user://processing-gameplay-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://processing-gameplay-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	expect(not game.crafting.is_unlocked("mayo_machine", game.village, game.mining, game.skills), "mayonnaise machine begins skill locked")
	expect(game.Processing.valid({}), "empty processing state remains a valid legacy default")
	expect(not game.crafting.is_unlocked("preserves_jar", game.village, game.mining, game.skills), "preserves jar begins skill locked")
	game.skills.gain("farming", 1300)
	expect(game.crafting.is_unlocked("mayo_machine", game.village, game.mining, game.skills), "farming level unlocks mayonnaise machine")
	expect(game.crafting.is_unlocked("preserves_jar", game.village, game.mining, game.skills), "farming level four unlocks preserves jar")

	game.homestead.resources.wood = 20
	game.homestead.resources.stone = 13
	game.homestead.resources.copper_ore = 1
	game.homestead.resources.coal = 1
	game._craft_recipe("mayo_machine")
	expect(game.crafting.crafted_items.is_empty(), "missing copper keeps machine craft atomic")
	expect(game.homestead.resources.wood == 20 and game.homestead.resources.stone == 13, "failed machine craft consumes nothing")
	game.homestead.resources.copper_ore = 2
	game._craft_recipe("mayo_machine")
	game._craft_recipe("preserves_jar")
	expect(game.crafting.crafted_items.mayo_machine == 1 and game.crafting.crafted_items.preserves_jar == 1, "both crafted machines enter facility inventory")
	expect(game.homestead.resources.wood == 0 and game.homestead.resources.stone == 0 and game.homestead.resources.copper_ore == 0 and game.homestead.resources.coal == 0, "machine recipes consume exact resources")
	expect(game._inventory_items().has("placeable:mayo_machine") and game._inventory_items().has("placeable:preserves_jar"), "machines appear in backpack source")
	game.life_panel.close()

	var mayo_cell := Vector2i(7, 18)
	var jar_cell := Vector2i(10, 18)
	game._change_map("farm_outdoor", mayo_cell + Vector2i.UP)
	game.player.set_pose("down", "idle")
	game._place_structure("mayo_machine")
	expect(game.farm.structure_at(mayo_cell) == "mayo_machine", "mayonnaise machine installs in faced field cell")
	expect(game.active_collision_cells.has(mayo_cell), "installed machine has world collision")
	game._change_map("farm_outdoor", jar_cell + Vector2i.UP)
	game.player.set_pose("down", "idle")
	game._place_structure("preserves_jar")
	expect(game.farm.structure_at(jar_cell) == "preserves_jar", "preserves jar installs independently")
	expect(not game._inventory_items().has("placeable:mayo_machine") and not game._inventory_items().has("placeable:preserves_jar"), "installed machines are not duplicated in backpack")

	game.animals.eggs = 1
	game._start_processing(mayo_cell, "mayo_machine", "egg")
	expect(game.animals.eggs == 0 and not game.processing.job_at(mayo_cell).is_empty(), "mayonnaise machine consumes exactly one egg")
	expect(not bool(game.processing.job_at(mayo_cell).ready), "new job is not instantly complete")
	game._change_map("farm_outdoor", mayo_cell + Vector2i.DOWN)
	game.player.set_pose("up", "idle")
	game.current_tool = "pickaxe"
	var energy_before: int = game.energy
	game._farm_action()
	expect(game.actor_action.kind.is_empty() and game.farm.structure_at(mayo_cell) == "mayo_machine" and game.energy == energy_before, "busy machine cannot be dismantled")
	game.life_panel.close()
	game._advance_day(false)
	expect(bool(game.processing.job_at(mayo_cell).ready), "overnight tick completes mayonnaise")
	game._collect_processed(mayo_cell)
	expect(game.processing.job_at(mayo_cell).is_empty() and int(game.processing.products.mayonnaise) == 1, "collection clears job and stores mayonnaise")
	expect(game._inventory_items().has("food:artisan:mayonnaise"), "mayonnaise appears in inventory")
	game.energy = 40
	game._eat_inventory_item("food:artisan:mayonnaise")
	expect(game.energy == 75 and int(game.processing.products.mayonnaise) == 0, "mayonnaise is edible with configured energy")

	game.farm.harvest_inventory.parsnip = 1
	game._start_processing(jar_cell, "preserves_jar", "parsnip")
	expect(game.farm.get_harvest_count("parsnip") == 0 and str(game.processing.job_at(jar_cell).output) == "pickles:parsnip", "preserves jar consumes chosen crop")
	game._advance_day(false)
	game._collect_processed(jar_cell)
	var pickles: Dictionary = game.processing.product_definition("pickles:parsnip", game.farm)
	expect(int(pickles.price) == 120 and int(game.processing.products["pickles:parsnip"]) == 1, "pickles use crop value formula and enter inventory")

	game.processing.products.mayonnaise = 2
	var shipping_cell := Vector2i(22, 11)
	game._change_map("farm_outdoor", shipping_cell)
	var shipping_gold: int = game.farm.gold
	game._interact()
	expect(game.farm.gold == shipping_gold + 500, "shipping box sells mayonnaise and pickles at artisan prices")
	expect(int(game.processing.products.mayonnaise) == 0 and int(game.processing.products["pickles:parsnip"]) == 0, "shipping clears only shipped artisan stock")

	game._change_map("farm_outdoor", jar_cell + Vector2i.DOWN)
	game.player.set_pose("up", "idle")
	game.current_tool = "pickaxe"
	game._farm_action()
	expect(game.actor_action.kind == "pickaxe", "idle processing machine starts removal action")
	game.actor_action.advance(2.0)
	expect(game.farm.structure_at(jar_cell).is_empty(), "pickaxe removes idle preserves jar")
	expect(game.crafting.crafted_items.preserves_jar == 1, "removed jar returns to backpack")

	game.animals.eggs = 1
	game._start_processing(mayo_cell, "mayo_machine", "egg")
	game.processing.products.mayonnaise = 1
	game.autosave_enabled = true
	expect(game._save_game(), "busy machine and products save to real file")
	var saved = game._read_save(game.save_path)
	expect(game._valid_save(saved), "processing save passes full validator")
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("processing")
	expect(game._valid_save(old_save), "legacy save without processing remains valid")
	var mismatch: Dictionary = saved.duplicate(true)
	mismatch.processing.jobs[0].machine = "preserves_jar"
	expect(not game._valid_save(mismatch), "job on wrong machine is rejected")
	var unknown_product: Dictionary = saved.duplicate(true)
	unknown_product.processing.products["pickles:not_a_crop"] = 1
	expect(not game._valid_save(unknown_product), "unknown crop product is rejected")
	game.processing.restore({})
	game.farm.remove_structure(mayo_cell)
	game._load_game()
	expect(game.farm.structure_at(mayo_cell) == "mayo_machine" and not game.processing.job_at(mayo_cell).is_empty(), "real reload restores machine and active job")
	expect(int(game.processing.products.mayonnaise) == 1, "real reload restores finished product inventory")

	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		game.farm.place_structure(jar_cell, "preserves_jar")
		game.processing.jobs.clear()
		game.animals.eggs = 1
		game.processing.start(mayo_cell, "mayo_machine", "egg", game.farm.day - 1, game.farm, game.animals)
		game.processing.advance_day(game.farm.day)
		game.farm.harvest_inventory.parsnip = 1
		game.processing.start(jar_cell, "preserves_jar", "parsnip", game.farm.day, game.farm, game.animals)
		game.world.queue_redraw()
		game.life_panel.close()
		game._change_map("farm_outdoor", Vector2i(8, 21))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-22/processing")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-22/processing/machines.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Processing gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
