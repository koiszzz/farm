extends SceneTree

const Skill = preload("res://scripts/skill_state.gd")
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


func mine_hit(cell: Vector2i) -> void:
	var positions := [{"cell": cell + Vector2i.DOWN, "facing": "up"}, {"cell": cell + Vector2i.UP, "facing": "down"}, {"cell": cell + Vector2i.LEFT, "facing": "right"}, {"cell": cell + Vector2i.RIGHT, "facing": "left"}]
	var position: Dictionary = positions[0]
	for candidate in positions:
		if game.navigation.is_walkable("cave", candidate.cell):
			position = candidate
			break
	game._change_map("cave", position.cell)
	game.player.set_pose(position.facing, "idle")
	game.current_tool = "pickaxe"
	game._farm_action()
	game.actor_action.advance(2.0)


func _run() -> void:
	var state := Skill.new()
	expect(state.level("farming") == 0, "skills begin at level zero")
	var first: Dictionary = state.gain("farming", 99)
	expect(first.ok and not first.level_up and state.level("farming") == 0, "99 xp remains below level one")
	var level_up: Dictionary = state.gain("farming", 1)
	expect(level_up.level_up and level_up.new_level == 1, "100 xp reaches level one exactly")
	state.gain("farming", 14900)
	expect(state.level("farming") == 10 and state.progress("farming").needed == 0, "skill level caps at ten")
	expect(is_equal_approx(state.crop_price_multiplier(), 1.2), "max farming grants twenty percent crop value")
	state.gain("fishing", 380)
	expect(state.level("fishing") == 2 and is_equal_approx(state.fishing_window_bonus(), 0.08), "fishing levels extend reel time")
	state.gain("mining", 770)
	expect(state.level("mining") == 3 and state.mining_energy_cost() == 1, "mining level three reduces pickaxe energy")
	state.gain("foraging", 770)
	expect(state.level("foraging") == 3 and state.forage_amount() == 2, "foraging level three doubles gathered items")
	expect(state.combat_damage() == 1, "combat begins at one sword damage")
	state.gain("combat", 770)
	expect(state.level("combat") == 3 and state.combat_damage() == 2, "combat level three increases sword damage")
	state.gain("combat", 4030)
	expect(state.level("combat") == 7 and state.combat_damage() == 3, "combat level seven grants the second damage increase")
	expect(not Skill.valid({"experience": {"alchemy": 10}}), "unknown skill save is rejected")
	expect(not Skill.valid({"experience": {"farming": -1}}), "negative skill experience is rejected")

	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://skill-progression-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://skill-progression-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	var plot := Vector2i(4, 15)
	game.farm.restore({"day": 1, "gold": 100, "seeds": {}, "harvest": {}, "plots": [{"x": plot.x, "y": plot.y, "state": {"tilled": true, "seed": "parsnip", "watered": false, "growth": 4, "mature": true}}]})
	game._commit_farm_action(plot, "harvest", "parsnip")
	expect(game.skills.experience.farming == 23, "real harvest awards value-scaled farming experience")

	var pickup: Dictionary = game.homestead.available("farm_outdoor", game.farm.day, game.navigation)[0]
	game._change_map("farm_outdoor", pickup.cell)
	game._collect_pickup(pickup)
	game.actor_action.advance(2.0)
	expect(game.skills.experience.foraging == 7, "real pickup awards foraging experience")

	game.hooked_fish = {"id": "creek_fish"}
	game.fishing_stage = "reeling"
	game._catch_fish()
	expect(game.skills.experience.fishing == 26, "real catch awards fish-value experience")

	mine_hit(game.Mining.CELLS[1])
	mine_hit(game.Mining.CELLS[1])
	expect(game.skills.experience.mining == 15, "completed vein awards mining experience once")

	game.skills.gain("farming", 77)
	game.farm.harvest_inventory.parsnip = 10
	for kind in game.homestead.resources:
		if kind not in ["copper_ore", "iron_ore", "coal"]: game.homestead.resources[kind] = 0
	game.fishing.inventory.clear()
	var gold_before: int = game.farm.gold
	game._change_map("farm_outdoor", Vector2i(22, 11))
	game._interact()
	expect(game.farm.gold == gold_before + 357, "level-one farming bonus applies to the real shipping box")

	game.skills.gain("fishing", 354)
	game._change_map("beach", Vector2i(24, 16))
	game.player.set_pose("down", "idle")
	game.current_tool = "fish"
	game.clock_minutes = 600
	game._farm_action()
	var fish_difficulty := float(game.Fishing.DEFINITIONS[str(game.hooked_fish.id)].difficulty)
	var expected_bar := clampf(0.39 - fish_difficulty * 0.22 + 0.08 * 0.30, 0.15, 0.52)
	expect(is_equal_approx(game.fishing_bar_height, expected_bar), "real cast receives level-two tracking-bar bonus")
	game._cancel_fishing()

	game.skills.gain("mining", 755)
	game.energy = 20
	mine_hit(game.Mining.CELLS[2])
	expect(game.energy == 19, "level-three mining spends one energy per real strike")

	game.skills.gain("foraging", 763)
	var second: Dictionary = game.homestead.available("countryside", game.farm.day, game.navigation)[0]
	var before_amount: int = int(game.homestead.resources[second.kind])
	game._change_map("countryside", second.cell)
	game._collect_pickup(second)
	game.actor_action.advance(2.0)
	expect(int(game.homestead.resources[second.kind]) == before_amount + 2, "level-three foraging doubles a real pickup")

	game.skills.gain("farming", 280)
	for recipe_id in ["field_salad", "sea_skewer", "miner_rice", "berry_tart"]:
		expect(game.crafting.is_unlocked(recipe_id, game.village, game.mining, game.skills), "level-two skill recipe unlocks: " + recipe_id)
	game.farm.harvest_inventory.parsnip = 1
	game.farm.harvest_inventory.turnip = 1
	game._craft_recipe("field_salad")
	expect(game.crafting.meals.field_salad == 1 and game.farm.get_harvest_count("parsnip") == 0 and game.farm.get_harvest_count("turnip") == 0, "skill recipe consumes real ingredients and creates a meal")
	game.life_panel.close()
	var key := InputEventKey.new()
	key.keycode = KEY_L
	key.pressed = true
	game._unhandled_input(key)
	expect(game.life_panel.visible and game.life_panel.heading.text == "生活技能", "L opens the visible skill panel")
	game.life_panel.close()

	game.autosave_enabled = true
	expect(game._save_game(), "skill experience saves")
	game.skills.restore({})
	game._load_game()
	expect(game.skills.level("farming") == 2 and game.skills.level("fishing") == 2 and game.skills.level("mining") == 3 and game.skills.level("foraging") == 3, "real reload restores all skill levels")
	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		game._open_skills()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-21/skills")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-21/skills/panel.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Skill progression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
