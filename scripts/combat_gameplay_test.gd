extends SceneTree

const Combat = preload("res://scripts/combat_state.gd")
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
	game.save_path = "user://combat-gameplay-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://combat-gameplay-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	expect(game._inventory_items().has("tool:sword"), "sword is included in starting inventory")
	expect(game.inventory_state.hotbar[7] == "tool:sword", "sword occupies the eighth starting hotbar slot")
	var state := Combat.new()
	var cave_first := state.ensure_map("cave", 1)
	var cave_repeat := state.ensure_map("cave", 1)
	expect(cave_first.size() == 3 and cave_repeat == cave_first, "first floor generates three deterministic monsters")
	for entry in cave_first:
		var spawn := Vector2i(int(entry.x), int(entry.y))
		expect(game.navigation.is_walkable("cave", spawn) and game.mining.vein("cave", spawn, 1).is_empty(), "cave monster spawns on open walkable ground")
	expect(state.ensure_map("mine_2", 1).size() == 4, "second floor generates four monsters")
	expect(state.ensure_map("mine_3", 1).size() == 5, "third floor generates five monsters")
	var first_id := str(cave_first[0].id)
	var first_type := str(cave_first[0].type)
	for index in int(Combat.DEFINITIONS[first_type].health): state.strike(first_id, 1)
	expect(state.monster(first_id).is_empty() and state.ensure_map("cave", 1).size() == 2, "defeated monster does not respawn on same day")
	expect(state.ensure_map("cave", 2).size() == 3, "new day replenishes cave encounters")

	game._change_map("cave", Vector2i(10, 10))
	game.life_panel.close()
	expect(game.monster_actors.size() == 3, "entering cave creates visible monster actors")
	game.current_tool = "sword"
	game.player.set_pose("right", "idle")
	var actor = game.monster_actors.values()[0]
	actor.position = game.player_body.position + Vector2(38, 0)
	var id := str(actor.monster_id)
	var health_before: int = int(game.combat.monster(id).health)
	game._farm_action()
	game.actor_action.advance(0.1)
	expect(int(game.combat.monster(id).health) == health_before, "sword windup has no early damage")
	game.actor_action.advance(1.0)
	expect(int(game.combat.monster(id).health) == health_before - 1, "sword contact damages monster in forward arc")
	actor.position = game.player_body.position + Vector2(-38, 0)
	game._farm_action()
	game.actor_action.advance(1.0)
	expect(int(game.combat.monster(id).health) == health_before - 1, "sword arc excludes monster behind player")
	actor.position = game.player_body.position + Vector2(38, 0)
	var material_total: int = game.homestead.resources.stone + game.homestead.resources.coal + game.homestead.resources.quartz
	while game.combat.monster(id).has("health"):
		game._farm_action()
		game.actor_action.advance(1.0)
	expect(not game.monster_actors.has(id), "defeated actor leaves active encounter")
	expect(game.homestead.resources.stone + game.homestead.resources.coal + game.homestead.resources.quartz > material_total, "defeated monster drops a mine resource")
	expect(game.skills.experience.combat > 0, "defeating monster awards combat experience")

	var contact = game.monster_actors.values()[0]
	contact.position = game.player_body.position
	var player_health: int = game.combat.health
	game.combat_invulnerability = 0.0
	game._tick_monsters(0.0)
	expect(game.combat.health < player_health, "monster contact damages player health")
	var damaged_health: int = game.combat.health
	game._tick_monsters(0.1)
	expect(game.combat.health == damaged_health, "contact invulnerability prevents rapid repeated damage")

	game.farm.gold = 500
	game.combat.health = 1
	game.combat_invulnerability = 0.0
	contact.position = game.player_body.position
	game._tick_monsters(0.0)
	expect(game.current_map_id == "farm_outdoor" and game.combat.health == 50, "zero health faints player back to farm at half health")
	expect(game.farm.gold == 450, "fainting loses ten percent gold under the cap")
	game._change_map("clinic_interior", Vector2i(18, 16))
	game.farm.gold = 100
	game.energy = 100
	game._open_service("clinic")
	var button: Button
	for child in game.life_panel.content.get_children():
		if child is Button:
			button = child
			break
	button.pressed.emit()
	expect(game.combat.health == Combat.MAX_HEALTH and game.farm.gold == 70, "clinic heals health even when energy is already full")

	game._change_map("cave", Vector2i(10, 10))
	var saved_actor = game.monster_actors.values()[0]
	var saved_id := str(saved_actor.monster_id)
	game.combat.strike(saved_id, 1)
	var saved_monster_health := int(game.combat.monster(saved_id).health)
	game.combat.health = 73
	game.autosave_enabled = true
	expect(game._save_game(), "combat state saves to real file")
	var saved = game._read_save(game.save_path)
	expect(game._valid_save(saved), "combat save passes full validator")
	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("combat")
	expect(game._valid_save(legacy), "legacy save without combat remains valid")
	var invalid: Dictionary = saved.duplicate(true)
	invalid.combat.health = 101
	expect(not game._valid_save(invalid), "out-of-range combat health is rejected")
	game.combat.restore({})
	game._load_game()
	expect(game.combat.health == 73 and int(game.combat.monster(saved_id).health) == saved_monster_health, "health and damaged encounters survive reload")

	if DisplayServer.get_name() != "headless":
		game.life_panel.close()
		game._change_map("mine_2", Vector2i(18, 15))
		game.current_tool = "sword"
		game.player.set_pose("right", "idle")
		var visual_actor = game.monster_actors.values()[0]
		visual_actor.position = game.player_body.position + Vector2(42, 0)
		game._farm_action()
		game.actor_action.advance(0.24)
		game.player.action_progress = game.actor_action.progress()
		game.player.set_pose("right", "sword")
		game._update_farm_hud()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-22/combat")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-22/combat/mine-encounter.png")

	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Combat gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
