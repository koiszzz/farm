extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")
const Regions = preload("res://scripts/region_world_builder.gd")
var failures := 0
var checks := 0
var game

func _init() -> void: call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://region-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://region-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	expect(not game.continuous_world_enabled, "normal play uses regional maps")
	expect(game.navigation.load_errors.is_empty(), "region geometry validates")
	game._change_map("countryside", game.navigation.get_spawn("countryside"))
	await physics_frame
	expect(game.world._sign_nodes.size() == 2, "both countryside direction signs are present in the world scene")
	expect(not game.world.has_node("BeachWaterAmbience") and not game.world.has_node("CaveTorchAmbience"), "non-coastal starts do not allocate region animation layers")
	game._change_map("beach", game.navigation.get_spawn("beach"))
	await physics_frame
	expect(game.game_camera.offset == Vector2.ZERO, "beach framing centers the player with its shore landmarks")
	var beach_ambience: Node = game.world.get_node("BeachWaterAmbience")
	expect(beach_ambience.is_processing(), "beach water ambience runs in the active beach")
	game._change_map("countryside", game.navigation.get_spawn("countryside"))
	await physics_frame
	expect(not beach_ambience.is_processing(), "cached beach ambience pauses outside the beach")
	game._change_map("cave", game.navigation.get_spawn("cave"))
	await physics_frame
	var cave_ambience: Node = game.world.get_node("CaveTorchAmbience")
	expect(cave_ambience.is_processing(), "cave torches animate on the entrance level")
	game._change_map("mine_2", game.navigation.get_spawn("mine_2"))
	await physics_frame
	var second_floor_ambience: Node = game.world.get_node("CaveTorchAmbience")
	expect(second_floor_ambience.is_processing(), "cave torches animate on the second floor")
	game._change_map("mine_3", game.navigation.get_spawn("mine_3"))
	await physics_frame
	var third_floor_ambience: Node = game.world.get_node("CaveTorchAmbience")
	expect(third_floor_ambience.is_processing(), "cave torches animate on the deepest floor")
	game._change_map("countryside", game.navigation.get_spawn("countryside"))
	await physics_frame
	var cached_cave_paused := true
	for ambience in [cave_ambience, second_floor_ambience, third_floor_ambience]:
		if is_instance_valid(ambience) and ambience.is_processing(): cached_cave_paused = false
	expect(cached_cave_paused, "cached cave torches pause or their level is evicted outside mine maps")
	expect(game.navigation.get_objects("countryside").size() >= 24, "countryside has a layered tree belt and roadside props")
	expect(game.navigation.get_map_size("countryside") == Vector2i(80, 48), "countryside has enough east-side camera margin at the farm entrance")
	expect(game.navigation.get_spawn("countryside") == Vector2i(61, 24), "countryside spawn lands on the extended farm approach road")
	expect(game.navigation.get_signposts("countryside").size() == 2, "countryside keeps the central and farm-approach signposts as readable landmarks")
	expect(game.navigation.interaction_at("countryside", Vector2i(60, 23)).get("target", "") == "signpost", "farm-approach signpost is readable without ground labels")
	game._change_map("countryside", Vector2i(60, 23))
	await physics_frame
	expect(game._interaction_target().get("kind", "") == "facility" and game._interaction_target().get("record", {}).get("target", "") == "signpost", "player can target the farm-approach signpost")
	game._interact()
	expect(game.life_panel.visible and game.life_panel.heading.text == "郊区林地", "farm-approach signpost opens its location text in the reading panel")
	game.life_panel.close()
	expect(game.navigation.get_cell_layers("countryside", Vector2i(31, 24)).get("surface", "") == "path" and game.navigation.is_walkable("countryside", Vector2i(31, 24)), "creek bridge keeps its authored walkable crossing")
	for sample in [[31, 4], [29, 13], [30, 20], [32, 30], [31, 40]]:
		expect(game.navigation.get_cell_class("countryside", Vector2i(sample[0], sample[1])) == "water", "meandering creek remains continuous through its natural bend")
	expect(game.navigation.get_cell_layers("town_square", Vector2i(17, 14)).get("surface", "") == "path" and game.navigation.get_cell_layers("town_square", Vector2i(30, 19)).get("surface", "") == "path", "expanded plaza paving joins the west approach and southern lane")
	expect(game.navigation.get_objects("town_square").size() >= 11, "town plaza has layered trees, benches and lamps around the central route")
	expect(game.navigation.get_cell_layers("town_square", Vector2i(17, 16)).get("blocked_id", "") == "town_square_tree_west", "town tree artwork has matching solid foot collision")
	expect(game.navigation.interaction_at("town_square", Vector2i(16, 29)).get("target", "") == "community_center", "town community hall has a usable front entrance")
	var community_route_points: Array[Vector2i] = [game.navigation.get_spawn("town_square"), Vector2i(16, 29)]
	expect(not game.navigation.patrol_route("town_square", community_route_points).is_empty(), "community hall remains reachable from the town spawn")
	var beach_objects: Array = game.navigation.get_objects("beach")
	expect(beach_objects.size() >= 10, "beach has layered custom shoreline artwork")
	var custom_beach_props := beach_objects.filter(func(entry: Dictionary) -> bool: return str(entry.get("atlas", "")) == "beach_props")
	expect(custom_beach_props.size() == 8, "beach custom atlas defines hut, dunes, tide pool and shore-life props")
	var beach_collectible_art := beach_objects.filter(func(entry: Dictionary) -> bool: return str(entry.get("atlas", "")) == "beach_collectibles")
	expect(beach_collectible_art.size() == 6, "beach collectible atlas adds pool, grass, crab, seabird and fishing basket details")
	expect(game.navigation.get_cell_class("beach", Vector2i(18, 16)) == "water", "new east tide pool is physical water")
	expect(game.navigation.get_spawn("beach") == Vector2i(27, 12), "beach arrival frames the north-shore landmarks")
	expect(game.navigation.is_walkable("beach", Vector2i(27, 24)), "entry-facing pier stays passable beyond the narrowed shoreline")
	expect(game.homestead.available("beach", game.farm.day, game.navigation).size() == 4, "new shoreline dressing keeps all daily shell spawn cells walkable")
	expect(game.navigation.get_cell_layers("beach", Vector2i(18, 10)).get("blocked_id", "") == "beach_fishing_hut", "fishing hut artwork has a matching solid footprint")
	expect(game.navigation.get_cell_layers("cave", Vector2i(14, 10)).get("blocked_id", "") == "cave_rock_pile", "cave rock details participate in collision")
	var ladder_checkpoints: Array[Vector2i] = [Vector2i(18, 25), Vector2i(18, 4)]
	expect(not game.navigation.patrol_route("cave", ladder_checkpoints).is_empty(), "cave landmark dressing preserves the ladder route")
	for map_id in Regions.REGIONS:
		expect(game.navigation.has_map(map_id), "region exists: " + map_id)
		var destinations := {}
		for cell in game.navigation.get_cells_with_class(map_id, "exit"):
			var exit: Dictionary = game.navigation.exit_at(map_id, cell)
			destinations[str(exit.target)] = cell
		for target in destinations:
			game._change_map(map_id, game.navigation.get_spawn(map_id))
			await physics_frame
			var checkpoints: Array[Vector2i] = [game.player_cell, destinations[target]]
			var route: Array[Vector2i] = game.navigation.patrol_route(map_id, checkpoints)
			expect(not route.is_empty(), "walkable route " + map_id + " -> " + target)
			for index in range(1, route.size()):
				if game.current_map_id != map_id: break
				Motion.walk(game, route[index] - route[index - 1])
				await physics_frame
				expect(not game.entering_door, "regional path avoids unrelated interior doorway")
			expect(game.current_map_id == target, "physical movement reaches " + target)
			expect(game.navigation.exit_at(game.current_map_id, game.player_cell).is_empty(), "arrival cannot bounce back")
	var item: Dictionary = game.homestead.available("beach", 1, game.navigation)[0]
	expect(game.homestead.collect(item, 1), "beach shell can be collected")
	expect(not game.homestead.collect(item, 1), "shell cannot be duplicated same day")
	expect(game.homestead.resources.shell == 1, "shell persists in material inventory")
	expect(game.homestead.available("beach", 2, game.navigation).size() == 4, "beach pickups renew next day")
	game._sync_inventory()
	expect(game._inventory_items().has("material:shell"), "shell visible in inventory")
	game.farm.till(Vector2i(4, 15))
	game.farm.plant(Vector2i(4, 15), "parsnip")
	expect(game.farm.place_structure(Vector2i(5, 15), "sprinkler").ok, "regional save can contain a farm structure")
	expect(game.farm.place_structure(Vector2i(6, 15), "mayo_machine").ok, "regional save can contain a processing machine")
	game.animals.eggs = 1
	expect(game.processing.start(Vector2i(6, 15), "mayo_machine", "egg", game.farm.day, game.farm, game.animals).ok, "regional save can contain an active processing job")
	var data := {"world_layout": 2, "map": "valley_world", "cell": [105, 56], "farm": game.farm.snapshot(), "processing": game.processing.snapshot()}
	for row in data.farm.plots:
		row.x += 88
		row.y += 40
	for row in data.farm.structures:
		row.x += 88
		row.y += 40
	for row in data.processing.jobs:
		row.x += 88
		row.y += 40
	var gold: int = data.farm.gold
	Regions.migrate(data, game.navigation)
	expect(data.world_layout == 3 and data.map == "farm_outdoor" and data.cell == [17, 16], "legacy player position migrates to regional coordinates")
	expect(data.farm.plots[0].x == 4 and data.farm.plots[0].y == 15 and data.farm.gold == gold, "migration preserves crops and economy")
	expect(data.farm.structures[0].x == 5 and data.farm.structures[0].y == 15, "migration preserves structure coordinates")
	expect(data.processing.jobs[0].x == 6 and data.processing.jobs[0].y == 15, "migration keeps active job aligned with its machine")
	Regions.migrate(data, game.navigation)
	expect(data.farm.plots[0].x == 4, "migration is idempotent")
	game._change_map("cave", Vector2i(18, 25))
	game.autosave_enabled = true
	expect(game._save_game(), "regional save writes successfully")
	game._change_map("farm_outdoor", Vector2i(17, 16))
	game.homestead.resources.shell = 0
	game._load_game()
	expect(game.current_map_id == "cave" and game.homestead.resources.shell == 1, "reload restores cave position and beach inventory")
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	legacy.world_layout = 2
	legacy.map = "valley_world"
	legacy.cell = [105, 56]
	for row in legacy.farm.plots:
		row.x += 88
		row.y += 40
	for row in legacy.farm.structures:
		row.x += 88
		row.y += 40
	for row in legacy.processing.jobs:
		row.x += 88
		row.y += 40
	FileAccess.open(game.save_path, FileAccess.WRITE).store_string(JSON.stringify(legacy))
	game._load_game()
	expect(game.current_map_id == "farm_outdoor" and game.player_cell == Vector2i(17, 16), "real legacy file loads into region")
	expect(game.farm.is_crop_occupied(Vector2i(4, 15)) and game.farm.structure_at(Vector2i(5, 15)) == "sprinkler" and game.farm.structure_at(Vector2i(6, 15)) == "mayo_machine" and game.homestead.resources.shell == 1, "real migration retains farm, structures and gathered materials")
	expect(not game.processing.job_at(Vector2i(6, 15)).is_empty(), "real migration retains active processing job on its machine")
	expect(game._save_game(), "migrated save can be written")
	game._load_game()
	expect(game.farm.is_crop_occupied(Vector2i(4, 15)), "second load never shifts crops twice")
	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		for sample in [["farm", "farm_outdoor", Vector2i(17, 16)], ["town-square", "town_square", Vector2i(24, 9)], ["town-plaza", "town_square", Vector2i(24, 15)], ["community-center", "town_square", Vector2i(17, 25)], ["countryside", "countryside", Vector2i(32, 24)], ["beach", "beach", Vector2i(27, 18)], ["beach-entry", "beach", game.navigation.get_spawn("beach")], ["beach-landing", "beach", Vector2i(27, 16)], ["beach-hut", "beach", Vector2i(21, 13)], ["cave", "cave", Vector2i(18, 17)], ["cave-ladder", "cave", Vector2i(15, 8)], ["mine-2", "mine_2", Vector2i(18, 17)], ["mine-3", "mine_3", Vector2i(18, 17)]]:
			game._change_map(sample[1], sample[2])
			await create_timer(0.2).timeout
			await RenderingServer.frame_post_draw
			var folder := "res://design/qa/2026-09-24/stardew-reference"
			DirAccess.make_dir_recursive_absolute(folder)
			var filename := "beach-scene.png" if sample[0] == "beach" else str(sample[0]) + ".png"
			root.get_texture().get_image().save_png(folder + "/" + filename)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Regional world: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
