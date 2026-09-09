extends SceneTree

const Calendar = preload("res://scripts/life_calendar.gd")
const Farm = preload("res://scripts/farm_state.gd")
const Village = preload("res://scripts/village_life.gd")
const Maps = preload("res://scripts/map_data.gd")
var failures := 0
var checks := 0

func _init() -> void:
	call_deferred("_run")

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	expect(Calendar.date(28).season == 0 and Calendar.date(28).day == 28, "last spring day")
	expect(Calendar.date(29).season == 1 and Calendar.date(29).day == 1, "summer rolls over")
	expect(Calendar.date(113).year == 2 and Calendar.date(113).season == 0, "new year rolls over")
	expect(Calendar.festival(13).id == "blossom", "spring festival date")
	expect(Calendar.festival(125).id == "blossom", "festival repeats annually")
	expect(Calendar.festival(14).is_empty(), "festival only on authored day")
	expect(Calendar.weather(3) == "雨" and Calendar.weather(90) == "雪", "seasonal weather")
	var maps = Maps.new()
	expect(maps.load_data(), "real navigation loads")
	var farm = Farm.new()
	farm.bind(maps)
	var cell := Vector2i(3, 15)
	farm.till(cell)
	expect(not farm.plant(cell, "tomato").ok, "summer crop rejected in spring")
	expect(farm.get_seed_count("tomato") == 4, "failed planting preserves seeds")
	farm.water(cell)
	farm.plant(cell, "parsnip")
	expect(farm.get_cell_state(cell).watered, "planting preserves watered soil")
	farm.advance_day()
	expect(farm.get_cell_state(cell).growth == 1, "watered crop grows once")
	farm.advance_day()
	expect(farm.get_cell_state(cell).growth == 1, "dry departing day does not grow")
	expect(farm.get_cell_state(cell).watered, "arriving rain waters crops")
	farm.advance_day(true)
	expect(farm.get_cell_state(cell).growth == 2, "rain grows on following day settlement")
	farm.day = 28
	farm.water(cell)
	var rollover: Dictionary = farm.advance_day()
	expect(farm.day == 29 and rollover.expired_cells.size() == 1 and not farm.is_crop_occupied(cell), "out of season crop clears at rollover")
	expect(farm.plant(cell, "tomato").ok, "tomato plants in summer")
	for index in 5:
		farm.water(cell)
		farm.advance_day(true)
	expect(farm.harvest(cell).ok and farm.is_crop_occupied(cell), "tomato harvest retains living plant")
	for index in 3: farm.advance_day(true)
	expect(farm.harvest(cell).ok and farm.get_harvest_count("tomato") == 2, "tomato regrows after three watered days")
	var previous_gold: int = farm.gold
	expect(farm.buy_seed("parsnip").ok and farm.gold == previous_gold - 15, "shop charges seed price")
	var seeds: int = farm.get_seed_count("pumpkin")
	expect(not farm.buy_seed("pumpkin", 99).ok and farm.get_seed_count("pumpkin") == seeds, "poor purchase preserves inventory")
	expect(not farm.buy_seed("pumpkin", -1).ok, "negative purchase rejected")
	var copy = Farm.new()
	copy.bind(maps)
	copy.restore(JSON.parse_string(JSON.stringify(farm.snapshot())))
	expect(copy.snapshot() == farm.snapshot(), "farm JSON round trip preserves crops and inventories")
	var village = Village.new()
	village.talk("florist", 1)
	village.talk("florist", 1)
	expect(village.bond("florist").points == 20, "daily chat cannot be farmed")
	village.talk("florist", 2)
	expect(village.bond("florist").points == 40, "new day chat grants points")
	farm.day = 9
	farm.harvest_inventory["turnip"] = 2
	village.gift("florist", "turnip", farm)
	expect(village.bond("florist").points == 220, "favorite birthday gift grants 180")
	village.gift("florist", "turnip", farm)
	expect(farm.get_harvest_count("turnip") == 1, "duplicate daily gift does not consume item")
	farm.day = 10
	village.gift("florist", "pumpkin", farm)
	expect(village.bond("florist").gift_day == 9, "missing gift does not consume daily allowance")
	farm.day = 13
	previous_gold = farm.gold
	village.join_festival(farm)
	expect(farm.gold == previous_gold, "spring festival requires greeting everyone")
	for actor in Village.PEOPLE: village.talk(actor, farm.day)
	village.join_festival(farm)
	expect(farm.gold == previous_gold + 180, "spring festival awards coins")
	village.join_festival(farm)
	expect(farm.gold == previous_gold + 180, "festival reward cannot be claimed twice")
	farm.day = 42
	farm.harvest_inventory = {"tomato": 1}
	previous_gold = farm.gold
	village.join_festival(farm)
	expect(farm.get_harvest_count("tomato") == 0 and farm.gold == previous_gold + 240, "summer festival consumes one contribution")
	farm.day = 72
	farm.harvest_inventory = {"turnip": 1, "pumpkin": 1}
	previous_gold = farm.gold
	village.join_festival(farm)
	expect(farm.gold == previous_gold and farm.get_harvest_count("turnip") == 1, "incomplete harvest entry consumes nothing")
	farm.harvest_inventory["tomato"] = 1
	village.join_festival(farm)
	expect(farm.gold == previous_gold + 400 and farm.get_harvest_count("pumpkin") == 0, "harvest exhibition accepts three mixed crops")
	farm.day = 109
	for actor in Village.PEOPLE: village.talk(actor, farm.day)
	previous_gold = farm.gold
	village.join_festival(farm)
	expect(farm.gold == previous_gold + 250, "winter blessing event rewards greetings")
	farm.day = 125
	for actor in Village.PEOPLE: village.talk(actor, farm.day)
	previous_gold = farm.gold
	village.join_festival(farm)
	expect(farm.gold == previous_gold + 180, "next year reward becomes available")
	var other = Village.new()
	other.restore(JSON.parse_string(JSON.stringify(village.snapshot())))
	expect(other.snapshot() == village.snapshot(), "relationships and festival claims survive JSON round trip")
	var scene = preload("res://Main.tscn").instantiate()
	scene.autosave_enabled = false
	root.add_child(scene)
	await process_frame
	expect(scene.inventory_state.capacity == 25 and scene.inventory_state.hotbar.size() == 10, "scene starts with a 25-slot backpack and ten-slot hotbar")
	scene.farm.harvest_inventory["parsnip"] = 2
	scene.farm.inventory_changed.emit("harvest", "parsnip", 2)
	expect(scene.inventory_state.assign_hotbar("food:parsnip", 9), "harvest can be assigned to hotbar key 0")
	scene.energy = 50
	scene._use_hotbar(9)
	expect(scene.energy == 70 and scene.farm.get_harvest_count("parsnip") == 1, "hotbar food is eaten immediately")
	scene.homestead.resources.wood = 1
	scene._sync_inventory()
	scene.inventory_state.assign_hotbar("material:wood", 8)
	scene._use_hotbar(8)
	expect(scene.homestead.resources.wood == 1, "non-tool non-food hotbar item cannot be used")
	scene._change_map("farm_outdoor", Vector2i(4, 14))
	scene.player.set_pose("down", "idle")
	scene.current_tool = "hoe"
	scene._farm_action()
	scene.actor_action.advance(1.0)
	scene.current_tool = "seed"
	scene._farm_action()
	scene.actor_action.advance(1.0)
	scene.player.set_pose("left", "idle")
	scene._begin_move(Vector2i.DOWN)
	expect(scene.player.facing == "down" and not scene.moving, "player can face an occupied crop without walking into it")
	for index in 4: scene.farm.advance_day(true)
	scene._change_map("farm_outdoor", Vector2i(4, 14))
	expect(scene.collision_root.has_node("Obstacle_4_15"), "loaded mature crop has collision")
	scene.current_tool = "harvest"
	scene._farm_action()
	scene.actor_action.advance(1.0)
	expect(not scene.collision_root.has_node("Obstacle_4_15"), "harvesting removes crop collision immediately")
	scene.farm.restore(farm.snapshot())
	scene.village.restore(village.snapshot())
	scene._open_calendar()
	expect(scene.life_panel.visible and scene.life_panel.content.get_child_count() >= 3, "calendar opens in real scene")
	var old_clock: int = scene.clock_minutes
	scene._physics_process(8.0)
	expect(scene.clock_minutes == old_clock, "calendar pauses time")
	scene._open_inventory()
	expect(scene.inventory_panel.visible and scene.inventory_panel.backpack_grid.get_child_count() == scene.inventory_state.capacity, "inventory opens as a grid with every backpack slot")
	var tool_slot: int = scene.inventory_state.backpack.find("tool:hoe")
	scene.inventory_panel.cursor_area = "backpack"
	scene.inventory_panel.cursor_index = tool_slot
	var info_key := InputEventKey.new()
	info_key.keycode = KEY_I
	info_key.pressed = true
	scene.inventory_panel.handle_key(info_key)
	expect(scene.inventory_panel.detail_card.visible and scene.inventory_panel.detail_title.text == "锄头", "I opens details only for the hovered or selected item")
	expect(scene._hotbar_index_for_key(KEY_1) == 0 and scene._hotbar_index_for_key(KEY_0) == 9, "number keys map from 1 through 0 across all ten hotbar slots")
	scene.inventory_panel.close()
	scene._open_people()
	scene._open_shop()
	scene._open_dialogue("florist")
	scene.life_panel.close()
	scene._change_map("farmhouse_interior", scene.navigation.get_spawn("farmhouse_interior"))
	scene._ask_sleep()
	expect(scene.life_panel.visible, "sleep confirmation works inside farmhouse")
	scene.life_panel.close()
	scene._advance_day(false)
	expect(scene.farm.day == 126 and scene.energy == 100 and scene.clock_minutes == 360, "sleep integrates date, clock, and energy")
	scene._change_map("town_square", Vector2i(34, 20))
	scene._interact()
	expect(scene.life_panel.visible, "authored town board opens festival panel")
	scene.life_panel.close()
	for npc_state in scene.npcs.values():
		var legal_route := true
		for index in npc_state.route.size():
			var from: Vector2i = npc_state.route[index]
			var to: Vector2i = npc_state.route[(index + 1) % npc_state.route.size()]
			legal_route = legal_route and scene.navigation.is_walkable("town_square", from) and from.distance_to(to) <= 1.0
		expect(legal_route, "NPC full loop uses adjacent walkable cells")
	for index in 500: scene._update_npcs(0.016)
	expect(scene.npcs.size() == Village.PEOPLE.size(), "expanded festival population remains valid")
	var actor: String = "florist"
	scene.player_body.position = scene.npcs[actor].node.position + Vector2(0, 30)
	expect(scene._nearby_npc_actor() == actor, "NPC interaction follows actual moving position")
	scene.player_cell = scene._cell_from_world_position(scene.player_body.position)
	scene._interact()
	expect(scene.life_panel.visible and scene.village.bond(actor).talk_day == scene.farm.day, "in-world interaction grants daily conversation")
	scene.life_panel.close()
	scene.clock_minutes = 1430
	scene.clock_elapsed = 0
	scene.transition_lock_frames = 0
	scene._physics_process(7)
	expect(scene.current_map_id == "farm_outdoor" and scene.clock_minutes == 360 and scene.farm.day == 127, "midnight returns player home and settles one day")
	scene._change_map("town_square", Vector2i(34, 20))
	scene.save_path = "user://life_system_test_%d.json" % Time.get_ticks_usec()
	scene.autosave_enabled = true
	scene.energy = 42
	scene.clock_minutes = 820
	var saved_farm: Dictionary = scene.farm.snapshot()
	var saved_village: Dictionary = scene.village.snapshot()
	var saved_inventory: Dictionary = scene.inventory_state.snapshot()
	expect(scene._save_game(), "save writes successfully")
	expect(scene._save_game(), "save replaces atomically with backup")
	var legacy_save: Dictionary = scene._read_save(scene.save_path)
	legacy_save.erase("inventory_layout")
	expect(scene._valid_save(legacy_save), "older saves without a grid layout remain compatible")
	scene.farm.reset()
	scene.village.bonds.clear()
	scene._load_game()
	expect(scene.farm.snapshot() == saved_farm and scene.village.snapshot() == saved_village, "disk load restores farm and relationships")
	expect(scene.inventory_state.snapshot() == saved_inventory, "disk load restores backpack positions, expansion and hotbar assignments")
	expect(scene.energy == 42 and scene.clock_minutes == 820 and scene.current_map_id == "town_square", "disk load restores time, energy and location")
	var damaged := FileAccess.open(scene.save_path, FileAccess.WRITE)
	damaged.store_string("{broken")
	damaged.close()
	scene.farm.reset()
	scene._load_game()
	expect(scene.farm.snapshot() == saved_farm, "corrupt main save recovers backup")
	DirAccess.remove_absolute(scene.save_path)
	DirAccess.remove_absolute(scene.save_path + ".bak")
	scene.autosave_enabled = false
	scene.queue_free()
	await process_frame
	print("Life systems: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)
