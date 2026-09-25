extends SceneTree

var game
var checks := 0
var failures := 0

func community_center_frame() -> int:
	for entry in game.world._world_object_entries():
		if str(entry.get("id", "")) == "community_center": return int(entry.index[0])
	return -1

func _init() -> void: call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://community-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://community-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game._change_map("town_square", Vector2i(16, 29))
	expect(game.navigation.interaction_at("town_square", Vector2i(16, 29)).get("target", "") == "community_center", "community center entrance is a physical town interaction")
	expect(community_center_frame() == 0, "incomplete community displays its abandoned facade")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/community-center")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/community-center/abandoned.png")
	game._open_community_center()
	expect(game.life_panel.heading.text == "花溪社区会堂", "visiting the hall explains its restoration goal")
	game._open_community_board()
	expect(game.life_panel.heading.text.contains("0 / 4"), "board displays overall completion")
	var wood_before: int = game.homestead.resources.wood
	game.homestead.resources.wood = 9
	game._donate_bundle("crafts")
	expect(game.homestead.resources.wood == 9 and game.community.completed.is_empty(), "incomplete group is atomic")
	game.homestead.resources.wood = wood_before

	for crop in ["parsnip", "tomato", "pumpkin", "powdermelon"]: game.farm.harvest_inventory[crop] = 1
	var gold_before: int = game.farm.gold
	game._donate_bundle("pantry")
	expect(game.community.completed.has("pantry") and game.farm.gold == gold_before + 500, "pantry consumes crops and grants gold")
	for crop in ["parsnip", "tomato", "pumpkin", "powdermelon"]: expect(game.farm.get_harvest_count(crop) == 0, crop + " donated exactly once")
	game._donate_bundle("pantry")
	expect(game.farm.gold == gold_before + 500, "completed bundle cannot reward twice")

	for fish in ["creek_fish", "sardine", "catfish", "squid"]: game.fishing.catch_fish(fish)
	game._donate_bundle("angler")
	expect(game.farm.gold == gold_before + 900 and game.fish_count == 0, "angler bundle links four fishing conditions")
	for fish in ["creek_fish", "sardine", "catfish", "squid"]: expect(game.fishing.caught.has(fish), "donation preserves " + fish + " discovery")

	game.homestead.resources.wood = 10
	game.homestead.resources.stone = 10
	game.homestead.resources.shell = 3
	game.homestead.resources.mushroom = 2
	var capacity_before: int = game.inventory_state.capacity
	game.homestead.resources.wood = 3
	game._open_community_board()
	var can_donate_wood := false
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text).begins_with("捐献木材"):
			can_donate_wood = true
			break
	expect(can_donate_wood, "board offers an item-wise donation for available inventory")
	game._donate_bundle_item("crafts", 0)
	expect(game.homestead.resources.wood == 0 and game.community.donated_count("crafts", 0) == 3, "partial item donation consumes available stock and records durable progress")
	var partial_restored = game.Community.new()
	partial_restored.restore(game.community.snapshot())
	expect(partial_restored.donated_count("crafts", 0) == 3 and not partial_restored.completed.has("crafts"), "partially donated progress survives snapshot restore")
	expect(game.Community.valid(game.community.snapshot()), "partial community progress is accepted by save validation")
	game.autosave_enabled = true
	expect(game._save_game(), "partial community progress saves to the real save file")
	game.community.restore({})
	game._load_game()
	expect(game.community.donated_count("crafts", 0) == 3 and game.homestead.resources.wood == 0, "real reload restores partial progress and consumed inventory")
	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		game.life_panel.scroll.scroll_vertical = game.life_panel.scroll.get_v_scroll_bar().max_value
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/community-center/partial-board.png")
	game.homestead.resources.wood = 10
	game._donate_bundle("crafts")
	expect(game.inventory_state.capacity == capacity_before + 5, "crafts bundle expands backpack")
	expect(game.homestead.resources.wood == 3 and game.homestead.resources.shell == 0, "previous contributions reduce later material cost")

	for resource in ["copper_ore", "iron_ore", "coal"]: game.homestead.resources[resource] = 5
	game.homestead.resources.quartz = 1
	for actor in game.VillageScript.PEOPLE: game.village.bond(str(actor)).points = 0
	game._donate_bundle("boiler")
	expect(game.community.completed.size() == 4 and game.community.grand_reward, "fourth group completes community restoration")
	expect(community_center_frame() == 1, "finishing every bundle replaces the abandoned facade with its restored art")
	expect(game.farm.gold == gold_before + 2500, "boiler and grand rewards grant exact gold")
	for actor in game.VillageScript.PEOPLE: expect(game.village.bond(str(actor)).points == 100, actor + " receives community friendship")
	game._donate_bundle("boiler")
	expect(game.farm.gold == gold_before + 2500, "grand reward cannot repeat")

	game.autosave_enabled = true
	expect(game._save_game(), "community state saves")
	game.community.restore({})
	game.inventory_state.capacity = 25
	game._load_game()
	expect(game.community.grand_reward and game.community.completed.size() == 4, "real reload restores completed bundles")
	expect(community_center_frame() == 1, "restored facade survives a real save and reload")
	expect(game.inventory_state.capacity == capacity_before + 5, "backpack reward survives reload")
	if DisplayServer.get_name() != "headless":
		game.life_panel.close()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/community-center/restored.png")
	game.autosave_enabled = false
	expect(not game.Community.valid({"completed": {"unknown": true}, "grand_reward": false}), "unknown bundle save rejected")
	expect(not game.Community.valid({"completed": {"pantry": true}, "grand_reward": true}), "premature grand reward rejected")
	expect(game.Community.valid({"completed": {}, "grand_reward": false}), "legacy community save without partial progress remains valid")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Community progress: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
