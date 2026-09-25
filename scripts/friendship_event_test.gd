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

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://friendship-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://friendship-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.fishing.inventory.sardine = 1
	game.homestead.resources.berry = 1
	game.orchard.fruits.apple = 1
	game.crafting.meals.field_salad = 1
	game.animals.duck_eggs = 1
	game._sync_inventory()
	game.clock_minutes = 600
	game._change_map("beach", Vector2i(15, 16))
	var fisherman_before: int = int(game.village.bond("fisherman").points)
	expect(game._nearby_npc_actor() == "fisherman", "resident can be physically approached at the scheduled beach location")
	game._open_gifts("fisherman")
	var fish_gift_visible := false
	var fish_gift_button: Button
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text).contains("沙丁鱼") and str(child.text).contains("最爱"):
			fish_gift_visible = true
			fish_gift_button = child
	expect(fish_gift_visible, "gift menu offers a favorite fish from the real backpack")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		var capture_dir := "res://design/qa/2026-09-24/gift-preferences"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
		var save_result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(capture_dir + "/mixed-gifts.png"))
		expect(save_result == OK, "gift preference menu framebuffer is captured")
	fish_gift_button.pressed.emit()
	expect(game.actor_action.kind == "gift" and not game.life_panel.visible, "choosing a gift starts its character action")
	game.actor_action.advance(0.5)
	expect(int(game.fishing.inventory.get("sardine", 0)) == 0 and int(game.village.bond("fisherman").points) == fisherman_before + 80, "fish gift is consumed and awards loved-gift friendship")
	game.actor_action.advance(0.5)
	expect(game.life_panel.visible and game.life_panel.heading.text == "居民的回应", "gift response appears after the action recovery")
	game._commit_gift("fisherman", "food:berry")
	expect(game.homestead.resources.berry == 1, "second gift that day is rejected without consuming forage")
	var fisherman_birthday_gift: Dictionary = game.village.gift_value("fisherman", "sardine", 76)
	expect(fisherman_birthday_gift.points == 640, "fisherman birthday multiplies a loved gift by eight")
	game.farm.day = 1
	game._sync_inventory()
	game._commit_gift("florist", "food:fruit:apple")
	expect(game.orchard.fruits.apple == 0 and int(game.village.bond("florist").points) == 80, "orchard fruit gift consumes the real fruit and applies resident preference")
	for actor in game.VillageScript.PEOPLE:
		expect(game.VillageScript.MILESTONE_EVENTS.has(actor), actor + " has two relationship events")
		expect(game.VillageScript.MILESTONE_EVENTS[actor].size() == 2, actor + " event count is complete")
		for event_index in range(2):
			var event: Dictionary = game.VillageScript.MILESTONE_EVENTS[actor][event_index]
			var scene: Dictionary = game.VillageScript.MILESTONE_SCENES[actor][event_index]
			expect(not str(event.title).is_empty() and not str(event.text).is_empty() and event.reward.size() == 3, actor + " event is authored")
			expect(scene.beats.size() >= 2 and scene.choices.size() == 2, actor + " event has a personal scene and two responses")
			for choice in scene.choices:
				expect(not str(choice.label).is_empty() and not str(choice.reply).is_empty() and choice.reward.size() == 3, actor + " response has authored dialogue and reward")
				var reward: Array = choice.reward
				match str(reward[0]):
					"seed": expect(not game.farm.get_crop_definition(str(reward[1])).is_empty(), actor + " response grants a real seed")
					"resource": expect(game.Homestead.RESOURCE_NAMES.has(str(reward[1])), actor + " response grants a real material")
					"gold", "energy": expect(int(reward[2]) > 0, actor + " response grants a positive amount")
					"perk": expect(str(reward[1]) in ["seed_discount", "fishing_window", "energy_cap"], actor + " response grants a supported perk")
					_: expect(false, actor + " response reward kind is supported")

	game._change_map("town_square", Vector2i(20, 20))
	var turnips_before: int = game.farm.get_seed_count("turnip")
	game.village.bond("florist").points = 180
	game._open_dialogue("florist")
	expect(game.village.bond("florist").points == 200 and not game.village.has_milestone("florist", 1), "daily talk opens the 200-point scene without claiming it")
	expect(game.farm.get_seed_count("turnip") == turnips_before, "relationship scene waits for the player's response before granting a reward")
	expect(game.life_panel.heading.text.contains("花圃的谢意"), "eligible resident opens a named personal event scene")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture_dir := "res://design/qa/2026-09-24/relationship-events"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
		var save_result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(capture_dir + "/florist-choice.png"))
		expect(save_result == OK, "friendship event choice framebuffer is captured")
	var postpone_button: Button
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text) == "稍后再聊": postpone_button = child
	expect(postpone_button != null, "relationship event can be postponed")
	postpone_button.pressed.emit()
	expect(not game.village.has_milestone("florist", 1) and game.farm.get_seed_count("turnip") == turnips_before, "postponing keeps the scene and reward available")
	game._open_dialogue("florist")
	var selected_response: Button
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text).contains("收下芜菁种子"): selected_response = child
	expect(selected_response != null, "first authored relationship response is available")
	selected_response.pressed.emit()
	expect(game.village.has_milestone("florist", 1), "choosing an event response records the milestone")
	expect(game.farm.get_seed_count("turnip") == turnips_before + 3, "chosen florist response grants its exact seeds")
	expect(game.life_panel.content.get_child_count() > 2, "relationship event appears in dialogue panel")
	game._open_dialogue("florist")
	expect(game.farm.get_seed_count("turnip") == turnips_before + 3, "reopening dialogue cannot duplicate event reward")
	game.farm.day = 2
	game.village.bond("florist").points = 480
	var strawberries_before: int = game.farm.get_seed_count("strawberry")
	game._open_dialogue("florist")
	expect(not game.village.has_milestone("florist", 2) and game.farm.get_seed_count("strawberry") == strawberries_before, "second event also waits for a player response")
	var second_response: Button
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text).contains("请她把花种分给镇上的孩子"): second_response = child
	expect(second_response != null, "second event presents its community-minded response")
	second_response.pressed.emit()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var reward_capture := "res://design/qa/2026-09-24/relationship-events/florist-reward.png"
		var reward_capture_result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(reward_capture))
		expect(reward_capture_result == OK, "friendship event reward framebuffer is captured")
	expect(game.village.has_milestone("florist", 2) and game.farm.get_seed_count("strawberry") == strawberries_before + 6, "alternative response selects its distinct reward")

	game.village.milestones.shopkeeper = 2
	game.farm.gold = 100
	var parsnips_before: int = game.farm.get_seed_count("parsnip")
	expect(game._seed_price("parsnip") == 13, "shopkeeper friendship applies floor-rounded ten-percent discount")
	game._buy_seed("parsnip")
	expect(game.farm.gold == 87 and game.farm.get_seed_count("parsnip") == parsnips_before + 1, "discounted purchase spends displayed price")

	game.village.milestones.fisherman = 2
	game._change_map("beach", Vector2i(24, 16))
	game.player.set_pose("down", "idle")
	game.current_tool = "fish"
	game.clock_minutes = 600
	game._farm_action()
	var fish_id: String = game.hooked_fish.id
	var expected_bar := minf(0.55, clampf(0.39 - float(game.Fishing.DEFINITIONS[fish_id].difficulty) * 0.22 + game.skills.fishing_window_bonus() * 0.30, 0.15, 0.52) + 0.06)
	expect(is_equal_approx(game.fishing_bar_height, expected_bar), "fisherman event widens the real tracking bar")
	game._cancel_fishing()

	game.village.milestones.doctor = 2
	game.energy = 100
	expect(game._energy_cap() == 110, "doctor event raises energy cap")
	game._advance_day(false)
	expect(game.energy == 110, "sleep restores raised maximum")
	game.energy = 105
	game.homestead.resources.berry = 1
	game._sync_inventory()
	game._eat_inventory_item("food:berry")
	expect(game.energy == 110, "food clamps to friendship energy cap")

	game.autosave_enabled = true
	expect(game._save_game(), "relationship events save")
	game.village.milestones.clear()
	game._load_game()
	expect(game.village.has_milestone("florist", 2) and game.village.has_milestone("doctor", 2), "real reload restores event claims and perks")
	expect(game.energy == 110, "reload validates energy against restored perk")
	game.autosave_enabled = false
	var invalid: Dictionary = game.village.snapshot()
	invalid.milestones = {"unknown": 2}
	var saved: Dictionary = game._read_save(game.save_path)
	saved.village = invalid
	expect(not game._valid_save(saved), "unknown milestone actor is rejected")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Friendship events: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
