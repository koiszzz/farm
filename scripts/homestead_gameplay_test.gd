extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")

var game
var checks := 0
var failures := 0
var visual := false
const OUTPUT := "res://design/qa/2026-09-08/gameplay/"

func _init() -> void:
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _settle_action() -> void:
	game.actor_action.advance(2.0)
	game.player.set_pose(game.player.facing, "idle")

func _interaction_cell(map_id: String, target: String) -> Vector2i:
	var size: Vector2i = game.navigation.get_map_size(map_id)
	for y in size.y:
		for x in size.x:
			if game.navigation.interaction_at(map_id, Vector2i(x, y)).get("target", "") == target: return Vector2i(x, y)
	return Vector2i(-1, -1)

func _run() -> void:
	visual = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://homestead-qa-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	expect(game.pet.art != null, "dog asset is imported")
	expect(game.pet.visible, "companion appears on farm")
	expect(not game.pet.grid.is_point_solid(game.pet.home_cell), "pet home is on authored walkable ground")
	for map_id in game.Homestead.PICKUPS:
		var items: Array = game.homestead.available(map_id, game.farm.day, game.navigation)
		expect(items.size() == game.Homestead.PICKUPS[map_id].size(), "all authored pickups accessible on " + map_id)
	game._change_map("farm_outdoor", Vector2i(4, 14))
	game.player.set_pose("down", "idle")
	var plot := Vector2i(4, 15)
	game._select_tool(0)
	if visual:
		await create_timer(0.2).timeout
		await _click_at(game.tool_buttons[1].get_global_rect().get_center())
		expect(game.current_tool == "seed", "actual hotbar button click selects seed tool")
		await _click_at(game.tool_buttons[0].get_global_rect().get_center())
		expect(game.current_tool == "hoe", "actual hotbar click returns to hoe")
	expect(game._tool_can_target(plot), "target preview recognizes unworked field")
	if visual:
		await create_timer(0.3).timeout
		var screen: Vector2 = game.get_viewport_transform() * game.world.cell_center_to_screen(plot)
		var move := InputEventMouseMotion.new()
		move.position = screen
		Input.parse_input_event(move)
		await process_frame
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = screen
		click.pressed = true
		Input.parse_input_event(click)
		Input.flush_buffered_events()
		await process_frame
		click = click.duplicate()
		click.pressed = false
		Input.parse_input_event(click)
		expect(game.actor_action.kind == "hoe", "real left mouse input starts hoe action")
	else: game._farm_action()
	expect(not game.farm.get_cell_state(plot).tilled, "mouse/keyboard action waits for contact")
	_settle_action()
	expect(game.farm.get_cell_state(plot).tilled, "hoe contact changes actual field")
	game._select_tool(1)
	game._farm_action()
	_settle_action()
	expect(game.farm.get_cell_state(plot).seed == "parsnip", "seed slot plants into worked field")
	game._select_tool(2)
	game._farm_action()
	game._select_tool(0)
	expect(game.current_tool == "water", "tool selection cannot change an active transaction")
	_settle_action()
	expect(game.homestead.water == 23 and game.farm.get_cell_state(plot).watered, "successful watering spends one charge")
	game._farm_action()
	_settle_action()
	expect(game.homestead.water == 23, "duplicate watering spends no charge")
	game.homestead.water = 0
	game._farm_action()
	expect(game.actor_action.kind.is_empty(), "empty can blocks new watering")
	var well := _interaction_cell("farm_outdoor", "well")
	expect(well != Vector2i(-1, -1), "well exists in actual navigation")
	game._change_map("farm_outdoor", well)
	game._interact()
	expect(game.homestead.water == 24, "authored well interaction refills can")
	game._change_map("farm_outdoor", Vector2i(5, 14))
	await physics_frame
	game._select_tool(0)
	Motion.hold(Vector2i.DOWN)
	game._update_player_movement(1.0 / 60.0)
	game._farm_action()
	expect(game.queued_use == "tool" and game.actor_action.kind.is_empty(), "tool input buffers while walking")
	var action_position: Vector2 = game.player_body.position
	game._update_player_movement(1.0 / 60.0)
	Motion.hold(Vector2i.ZERO)
	expect(game.player_body.position == action_position and game.actor_action.kind == "hoe", "buffered action stops at current position on next tick")
	_settle_action()
	expect(game.farm.get_cell_state(Vector2i(5, 15)).tilled, "buffered action works the intended adjacent cell")
	game._open_inventory()
	expect(game.inventory_panel.visible and game.inventory_panel.backpack_grid.get_child_count() == game.inventory_state.capacity, "inventory exposes the complete slot grid")
	await _capture("inventory")
	game.inventory_panel.close()
	var berry: Dictionary = {}
	for item in game.homestead.available("farm_outdoor", game.farm.day, game.navigation):
		if item.kind == "berry": berry = item
	expect(not berry.is_empty(), "farm berry is reachable")
	game._change_map("farm_outdoor", berry.cell)
	game._interact()
	expect(game.homestead.resources.berry == 0, "pickup waits for crouch contact")
	_settle_action()
	expect(game.homestead.resources.berry == 1, "context interaction collects real scene pickup")
	expect(not game.homestead.collect(berry, game.farm.day), "pickup cannot be duplicated on same day")
	game._change_map("farm_outdoor", Vector2i(21, 12))
	game._pet_dog()
	expect(game.player.action == "pet", "pet interaction uses crouch animation")
	game.actor_action.advance(0.55)
	game.player.action_progress = 0.55
	expect(game.homestead.pet_points == 20, "pet affection commits at animation contact")
	await _capture("petting")
	_settle_action()
	game._pet_dog()
	_settle_action()
	expect(game.homestead.pet_points == 20, "daily pet reward cannot repeat")
	game.homestead.feed(game.farm.day)
	expect(game.homestead.pet_points == 50 and game.homestead.resources.berry == 0, "feeding spends one gathered berry")
	game.homestead.feed(game.farm.day)
	expect(game.homestead.pet_points == 50, "daily feed reward cannot repeat")
	game._open_pet()
	await _capture("pet_panel")
	game.life_panel.close()
	game.pet.affection = 0
	var start: Vector2 = game.pet.position
	var target_position: Vector2 = game.world.cell_center_to_screen(Vector2i(17, 16))
	for frame in 360: game.pet.tick(1.0 / 60, target_position, 720)
	expect(game.pet.position.distance_to(start) > 60, "companion follows along the navigation grid")
	expect(game.pet.position.distance_to(target_position) < 70, "companion catches up and leaves personal space")
	expect(game.navigation.is_walkable("farm_outdoor", game.pet.cell, game.farm.is_crop_occupied(game.pet.cell)), "pet never stands in a solid or occupied crop")
	game.homestead.following = false
	for frame in 600: game.pet.tick(1.0 / 60, target_position, 720)
	expect(game.pet.cell == game.pet.home_cell, "stay command returns companion home")
	game.pet.tick(0.1, target_position, 1260)
	expect(game.pet.sleeping, "pet sleeps after 20:00")
	for day in 4: game.farm.advance_day(true)
	game._change_map("farm_outdoor", Vector2i(4, 14))
	game.player.set_pose("down", "idle")
	game._select_tool(3)
	game._farm_action()
	_settle_action()
	expect(game.farm.get_harvest_count("parsnip") == 1, "grown crop harvested through real action")
	var money: int = game.farm.gold
	game.village.deliver("florist", game.farm)
	expect(game.farm.get_harvest_count("parsnip") == 0 and game.farm.gold > money, "request exchanges grown crop for reward")
	money = game.farm.gold
	game.village.deliver("florist", game.farm)
	expect(game.farm.gold == money, "daily request cannot reward twice")
	game.clock_minutes = 600
	game._change_map("general_store_interior", Vector2i(18, 15))
	expect(game.npcs.has("shopkeeper"), "shopkeeper is actually present at work")
	expect(not game.pet.visible, "outdoor companion does not appear inside other buildings")
	var npc = game.npcs.get("shopkeeper", {}).get("node")
	if npc != null:
		game.player_body.position = npc.position + Vector2(0, 24)
		game.player_cell = game._cell_from_world_position(game.player_body.position)
		game._update_npcs(0.1)
		expect(npc.facing == "down", "resident faces approaching player")
		game._open_dialogue("shopkeeper")
		await _capture("resident_dialogue", 2.0)
		game.life_panel.close()
	game._change_map("beach", Vector2i(28, 14))
	expect(game.npcs.has("fisherman"), "fisherman's daytime schedule appears at beach")
	await _capture("beach_day")
	game.clock_minutes = 1260
	game._change_map("cafe_interior", Vector2i(18, 15))
	expect(game.npcs.has("florist") and game.npcs.has("fisherman"), "evening residents gather in cafe")
	var counter := _interaction_cell("cafe_interior", "cafe_counter")
	game._change_map("cafe_interior", counter)
	game._interact()
	var before_energy: int = game.energy
	money = game.farm.gold
	game.life_panel.content.get_child(1).pressed.emit()
	expect(game.energy == mini(100, before_energy + 35) and game.farm.gold == money - 15, "cafe purchase exchanges money for recovery")
	game.life_panel.close()
	game._change_map("farm_outdoor", Vector2i(21, 12))
	await _capture("farm_evening")
	game.autosave_enabled = true
	expect(game._save_game(), "upgraded state writes to isolated save")
	var saved = game._read_save(game.save_path)
	expect(game._valid_save(saved), "new saved state passes full validator")
	var old: Dictionary = saved.duplicate(true)
	old.erase("homestead")
	old.village.erase("request_days")
	expect(game._valid_save(old), "legacy save without upgrades remains valid")
	var broken: Dictionary = saved.duplicate(true)
	broken.homestead.water = "oops"
	expect(not game._valid_save(broken), "malformed new state is rejected before restore")
	game.homestead.water = 1
	game.homestead.pet_points = 0
	game._load_game()
	expect(game.homestead.water == 24 and game.homestead.pet_points == 50, "water and relationship reload from disk")
	expect(game.village.request("florist", game.farm.day).done, "completed request survives reload")
	game.autosave_enabled = false
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(game.save_path + ".bak")
	game.queue_free()
	print("Homestead gameplay: %d checks, %d failures; visual=%s" % [checks, failures, visual])
	quit(1 if failures else 0)

func _capture(label: String, delay := 0.3) -> void:
	if not visual: return
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + label + ".png")
	print("GAMEPLAY FRAMEBUFFER " + label)

func _click_at(point: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	Input.parse_input_event(move)
	var click := InputEventMouseButton.new()
	click.position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	await process_frame
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	Input.flush_buffered_events()
	await process_frame
