extends SceneTree

var failures := 0

func expect(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game._change_map("farm_outdoor", Vector2i(4, 14))
	game.player.set_pose("down")
	game.current_tool = "hoe"
	game._farm_action()
	expect(not game.farm.get_cell_state(Vector2i(4, 15)).get("tilled", false), "till must wait for contact")
	game._farm_action()
	game.actor_action.advance(0.20)
	expect(game.energy == 100, "windup cannot spend energy")
	game.actor_action.advance(0.20)
	expect(game.farm.get_cell_state(Vector2i(4, 15)).get("tilled", false), "contact tills target")
	expect(game.energy == 98, "contact spends exactly two energy")
	game.actor_action.advance(1.0)
	expect(game.energy == 98 and game.actor_action.kind.is_empty(), "recovery does not commit twice")
	game.farm.plant(Vector2i(4,15), "parsnip")
	for day in 4: game.farm.advance_day(true)
	game.current_tool = "scythe"
	game._farm_action()
	expect(game.player.action == "scythe", "sickle selects its own swing animation")
	game.actor_action.advance(1.0)
	expect(game.farm.get_harvest_count("parsnip") == 1, "sickle contact collects mature crop")
	game.current_tool = "fish"
	game._farm_action()
	expect(game.fishing_stage.is_empty(), "cannot fish on dry land")
	game._change_map("farm_outdoor", Vector2i(26, 18))
	game.player.set_pose("right")
	game._farm_action()
	expect(game.fishing_stage == "casting", "facing water casts the line")
	game.actor_action.advance(1.3)
	expect(game.fishing_stage == "waiting", "casting settles into waiting")
	game.player.set_pose("up")
	expect(game.player._facing_row() == 3, "north uses an independent back row")
	game._change_map("farm_outdoor", Vector2i(15, 11))
	game.player.set_pose("up")
	game._interact()
	expect(game.entering_door, "facing adjacent door starts opening")
	expect(game.current_map_id == "farm_outdoor", "door must open before switching scenes")
	await create_timer(1.05).timeout
	expect(game.current_map_id == "farmhouse_interior", "door enters the actual interior")
	expect(not game.entering_door and game.world.door_open == 0.0 and game.player.modulate.a == 1.0, "arrival closes door and restores player")
	game._change_map("town_square", Vector2i(18,14))
	var npc = game.npcs.florist.node
	game.npcs.florist.route = [game.player_cell]
	game.player_body.position = npc.position + Vector2(0,24)
	npc.position = game.player_body.position + Vector2(0,-24)
	game.player_cell = game._cell_from_world_position(game.player_body.position)
	expect(game._nearby_npc_actor() == "florist", "reachable florist route makes the nearby resident interactable")
	game.farm.harvest_inventory.parsnip = 2
	game._give_gift("florist", "food:parsnip")
	expect(game.farm.get_harvest_count("parsnip") == 2, "gift stays in inventory before contact")
	game.actor_action.advance(0.50)
	expect(game.farm.get_harvest_count("parsnip") == 1, "gift transfers once at hand contact")
	game.actor_action.advance(1.0)
	expect(game.farm.get_harvest_count("parsnip") == 1 and game.life_panel.visible, "gift recovery shows reply without second deduction")
	game.life_panel.close()
	game.fishing.catch_fish("sardine")
	game._sync_inventory()
	game.save_path = "user://action-system-qa-%d.json" % Time.get_ticks_msec()
	game.autosave_enabled = true
	expect(game._save_game(), "fish inventory and appearance save successfully")
	var restored = preload("res://Main.tscn").instantiate()
	restored.save_path = game.save_path
	root.add_child(restored)
	await process_frame
	expect(restored.fish_count == game.fish_count, "fish count survives real disk reload")
	expect(restored.farm.get_harvest_count("parsnip") == 1, "gift deduction survives reload")
	restored.autosave_enabled = false
	game.autosave_enabled = false
	DirAccess.remove_absolute(game.save_path)
	restored.queue_free()
	game.queue_free()
	print("Action system: %d failures" % failures)
	quit(1 if failures else 0)
