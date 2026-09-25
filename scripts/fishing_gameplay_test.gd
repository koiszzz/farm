extends SceneTree

const Fishing = preload("res://scripts/fishing_state.gd")
var game
var checks := 0
var failures := 0

func _init() -> void: call_deferred("_run")
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func win_reel() -> void:
	game.fishing_direction_change = 10.0
	game.fishing_fish_velocity = 0.0
	for _step in 30:
		if game.fishing_stage != "playing": break
		game.fishing_fish_position = game.fishing_bar_center
		game._advance_fishing_minigame(0.1)
	game.actor_action.advance(2.0)

func homestead_resource_total() -> int:
	var total := 0
	for amount in game.homestead.resources.values(): total += int(amount)
	return total

func action_button(label_part: String) -> Button:
	if game == null or game.life_panel == null: return null
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text).contains(label_part): return child
	return null

func has_label_text(node: Node, fragment: String) -> bool:
	if node is Label and str(node.text).contains(fragment): return true
	for child in node.get_children():
		if has_label_text(child, fragment): return true
	return false

func _run() -> void:
	var state := Fishing.new()
	expect(state.eligible("beach", 1, 600, "晴") == ["flounder", "sardine"], "spring daytime beach has distinct ocean pool")
	expect("catfish" in state.eligible("riverside", 3, 600, "雨"), "rain adds river catfish")
	expect("night_eel" in state.eligible("riverside", 57, 1200, "晴"), "fall night adds eel")
	expect(state.eligible("beach", 85, 1200, "晴") == ["squid"], "winter night beach targets squid")
	var first: Dictionary = state.prepare("beach", 1, 600, "晴")
	var second: Dictionary = state.prepare("beach", 1, 600, "晴")
	expect(first.id != second.id, "repeated casts rotate eligible fish deterministically")
	expect(float(Fishing.DEFINITIONS.tuna.difficulty) > float(Fishing.DEFINITIONS.sardine.difficulty), "rare valuable fish is more difficult to track")
	expect(state.rod_level == 0 and state.rod().id == "bamboo", "new fishing saves start with the basic bamboo rod")

	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://fishing-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://fishing-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game._change_map("beach", Vector2i(24, 16))
	game._open_dialogue("fisherman")
	var rod_shop_link := action_button("海边渔具铺")
	expect(rod_shop_link != null, "beach fisherman dialogue opens the local rod shop")
	if rod_shop_link != null: rod_shop_link.pressed.emit()
	expect(game.life_panel.heading.text.contains("渔具铺"), "fisherman action opens the rod shop menu")
	game.skills.gain("fishing", 380)
	game.farm.gold = 1000
	game._open_fishing_rod_shop()
	var fiberglass_button := action_button("玻璃纤维鱼竿")
	expect(fiberglass_button != null, "fishing level two unlocks the fiberglass rod offer")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var rod_capture_dir := ProjectSettings.globalize_path("res://design/qa/2026-09-24/fishing-rods")
		DirAccess.make_dir_recursive_absolute(rod_capture_dir)
		var rod_capture_error := root.get_texture().get_image().save_png(rod_capture_dir.path_join("fiberglass-offer.png"))
		expect(rod_capture_error == OK, "live fishing rod shop framebuffer is saved")
	if fiberglass_button != null: fiberglass_button.pressed.emit()
	expect(game.fishing.rod_level == 0 and game.farm.gold == 1000, "failed purchase leaves rod and gold unchanged")
	game.farm.gold = 10000
	game._open_fishing_rod_shop()
	fiberglass_button = action_button("玻璃纤维鱼竿")
	if fiberglass_button != null: fiberglass_button.pressed.emit()
	expect(game.fishing.rod_level == 1 and game.farm.gold == 8200, "fiberglass purchase charges 1800 gold exactly once")
	var locked_iridium: Dictionary = game.fishing.upgrade_rod(game.farm, game.skills.level("fishing"))
	expect(not bool(locked_iridium.ok) and str(locked_iridium.reason) == "skill" and game.farm.gold == 8200, "iridium rod remains locked before fishing level six")
	game.skills.gain("fishing", 2920)
	game._open_fishing_rod_shop()
	var iridium_button := action_button("铱金鱼竿")
	expect(iridium_button != null, "fishing level six unlocks the iridium rod offer")
	if iridium_button != null: iridium_button.pressed.emit()
	expect(game.fishing.rod_level == 2 and game.farm.gold == 700, "iridium purchase charges 7500 gold and equips the top rod")
	game.skills.gain("fishing", 1500)
	game.farm.gold = 1000
	game._open_fishing_rod_shop()
	var bait_button := action_button("购买鱼饵")
	expect(bait_button != null, "fiberglass and iridium rods expose shop bait")
	if bait_button != null: bait_button.pressed.emit()
	expect(game.fishing.bait_count == 10 and game.farm.gold == 950 and game._inventory_items().bait.icon is AtlasTexture, "buying bait spends 50 gold and adds illustrated bait to inventory")
	game.farm.gold = 500
	game._open_fishing_rod_shop()
	var bobber_button := action_button("购买并装上软木浮标")
	expect(bobber_button != null, "fishing level seven unlocks the cork bobber on an iridium rod")
	if bobber_button != null: bobber_button.pressed.emit()
	expect(not game.fishing.cork_bobber_owned and game.farm.gold == 500, "failed tackle purchase does not consume gold or create equipment")
	game.farm.gold = 1200
	game._open_fishing_rod_shop()
	bobber_button = action_button("购买并装上软木浮标")
	if bobber_button != null: bobber_button.pressed.emit()
	expect(game.fishing.cork_bobber_owned and game.fishing.cork_bobber_equipped and game.farm.gold == 450, "cork bobber costs 750 gold and equips only after purchase")
	game._open_character_card()
	var profile_has_rod := has_label_text(game.life_panel.content, "铱金竿")
	expect(profile_has_rod and has_label_text(game.life_panel.content, "浮标") and has_label_text(game.life_panel.content, "饵10"), "character card reports rod, bait and tackle equipment")
	game.life_panel.close()
	var fish_atlas: Texture2D = load("res://assets/art/runtime_generated/fish_icons_v1.svg")
	expect(fish_atlas != null and fish_atlas.get_size() == Vector2(128, 64), "eight fish species fit a transparent 4-by-2 pixel atlas")
	var fish_icon_regions := {}
	for fish_id in Fishing.DEFINITIONS:
		var fish_icon: AtlasTexture = game._fish_icon(str(fish_id))
		fish_icon_regions[str(fish_icon.region.position)] = true
		expect(fish_icon.atlas == fish_atlas and fish_icon.region.size == Vector2(32, 32), "%s uses one in-bounds fish icon frame" % fish_id)
	expect(fish_icon_regions.size() == Fishing.DEFINITIONS.size(), "each species maps to a different illustrated atlas cell")
	game._change_map("beach", Vector2i(24, 16))
	game.player.set_pose("down", "idle")
	game.current_tool = "fish"
	game.clock_minutes = 600
	game._farm_action()
	expect(game.fishing_stage == "casting" and game.hooked_fish.habitat == "ocean", "beach cast prepares ocean fish")
	var selected_id: String = game.hooked_fish.id
	var wait_time: float = game.hooked_fish.wait
	var expected_bar := clampf(0.39 - float(Fishing.DEFINITIONS[selected_id].difficulty) * 0.22 + game.skills.fishing_window_bonus() * 0.30 + float(Fishing.TACKLES.cork_bobber.bar_bonus), 0.15, 0.52)
	expect(is_equal_approx(game.fishing_bar_height, expected_bar), "equipped cork bobber widens the real tracking bar")
	expect(is_equal_approx(wait_time, float(Fishing.DEFINITIONS[selected_id].wait) * 0.5) and game.fishing.bait_count == 9, "equipped bait halves bite wait and is consumed on casting")
	game.actor_action.advance(2.0)
	expect(game.fishing_stage == "waiting" and game.energy == 98, "cast spends energy only at contact")
	game.transition_lock_frames = 0
	game._physics_process(wait_time - 0.01)
	expect(game.fishing_stage == "waiting", "species wait threshold is respected")
	game._physics_process(0.02)
	expect(game.fishing_stage == "playing" and game.fishing_view.visible, "bite opens the visible tracking minigame")
	var resources_before_treasure: Dictionary = game.homestead.resources.duplicate()
	game.fishing_treasure_available = true
	game.fishing_treasure_secured = false
	game.fishing_treasure_position = 0.5
	game.fishing_treasure_progress = 0.0
	game.fishing_fish_velocity = 0.0
	game.fishing_direction_change = 10.0
	for _tick in 10:
		game.fishing_bar_center = 0.5
		game.fishing_bar_velocity = 0.0
		game.fishing_fish_position = 0.5
		game.fishing_treasure_position = 0.5
		game._advance_fishing_minigame(0.1)
	if DisplayServer.get_name() != "headless":
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		var capture_dir := "res://design/qa/2026-09-24/fishing-minigame"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
		var saved_capture := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(capture_dir + "/tracking.png"))
		expect(saved_capture == OK, "live fishing minigame framebuffer is saved")
	for _tick in 10:
		game.fishing_bar_center = 0.5
		game.fishing_bar_velocity = 0.0
		game.fishing_fish_position = 0.5
		game.fishing_treasure_position = 0.5
		game._advance_fishing_minigame(0.1)
	expect(game.fishing_treasure_secured and not game.fishing_treasure_available, "holding the fish and chest together fills the separate treasure meter")
	var hold_key := InputEventKey.new()
	hold_key.keycode = KEY_E
	hold_key.pressed = true
	game._unhandled_input(hold_key)
	expect(game.fishing_reel_held, "holding E controls the fishing bar")
	hold_key.pressed = false
	game._unhandled_input(hold_key)
	expect(not game.fishing_reel_held, "releasing E lets the fishing bar fall")
	var mouse_hold := InputEventMouseButton.new()
	mouse_hold.button_index = MOUSE_BUTTON_LEFT
	mouse_hold.pressed = true
	game._unhandled_input(mouse_hold)
	expect(game.fishing_reel_held, "holding the left mouse button also controls the bar")
	mouse_hold.pressed = false
	game._unhandled_input(mouse_hold)
	expect(not game.fishing_reel_held, "releasing the left mouse button lets the bar fall")
	win_reel()
	expect(int(game.fishing.inventory[selected_id]) == 1 and game.fish_count == 1, "timely reel stores selected species and aggregate count")
	expect(game.fishing.treasure_chests == 1 and homestead_resource_total() > 0, "secured chest awards real mine resources")
	var treasure_material := ""
	for material in game.homestead.resources:
		if int(game.homestead.resources[material]) > int(resources_before_treasure.get(material, 0)):
			treasure_material = str(material)
			break
	var treasure_item: Dictionary = game._inventory_items().get("material:" + treasure_material, {})
	expect(not treasure_material.is_empty() and treasure_item.get("icon") is AtlasTexture, "chest reward appears in the backpack with its material icon")
	expect(game.fishing_stage.is_empty() and not game.fishing_view.visible, "successful reel closes the minigame after the catch animation")
	var item_key := "food:fish" if selected_id == "creek_fish" else "food:fish:" + selected_id
	expect(game._inventory_items().has(item_key), "caught species has individual backpack entry")
	var caught_item: Dictionary = game._inventory_items().get(item_key, {})
	expect(caught_item.get("icon") is AtlasTexture, "caught fish uses its own illustrated icon frame")
	if caught_item.get("icon") is AtlasTexture:
		expect((caught_item.icon as AtlasTexture).region.size == Vector2(32, 32), "fish icon frame stays inside its pixel atlas cell")
	expect(game.fishing.caught.has(selected_id), "catch updates discovery record")

	game._farm_action()
	var missed_id: String = game.hooked_fish.id
	game.actor_action.advance(2.0)
	game._physics_process(float(game.hooked_fish.wait) + 0.01)
	var resources_before_miss := homestead_resource_total()
	game.fishing_treasure_available = true
	game.fishing_treasure_secured = false
	game.fishing_treasure_progress = 0.7
	game.fishing_treasure_position = 0.5
	game.fishing_direction_change = 10.0
	game.fishing_fish_velocity = 0.0
	game.fishing_fish_position = 1.0
	game.fishing_catch_progress = 0.01
	game.fishing_bar_center = 0.5
	game._advance_fishing_minigame(0.1)
	expect(game.fishing_stage.is_empty() and game.fish_count == 1, "letting the fish escape awards no fish")
	expect(game.fishing.treasure_chests == 1 and homestead_resource_total() == resources_before_miss, "an escaping fish forfeits the partly opened treasure chest")
	expect(int(game.fishing.inventory.get(missed_id, 0)) <= 1, "miss cannot duplicate inventory")

	game.energy = 1
	game._eat_inventory_item(item_key)
	expect(game.energy == mini(100, 1 + int(Fishing.DEFINITIONS[selected_id].energy)), "species restores authored energy")
	expect(game.fish_count == 0, "eating removes only consumed fish")
	game.fishing.catch_fish("red_snapper")
	game.fishing.catch_fish("sardine")
	var gold_before: int = game.farm.gold
	game._change_map("farm_outdoor", Vector2i(22, 11))
	game._interact()
	expect(game.farm.gold == gold_before + 140 and game.fish_count == 0, "shipping box sells fish at per-species values")
	expect(game.fishing.caught.has("red_snapper") and game.fishing.caught.has("sardine"), "shipping preserves collection record")
	game._open_fish_guide()
	expect(game.life_panel.heading.text.contains("%d / 8" % game.fishing.caught.size()), "fish guide counts discovered species")
	expect(game.fishing.total_caught() == 3 and str(game.life_panel.content.get_child(1).text).contains("开启宝箱 1 个"), "fish guide retains lifetime catches and opened-treasure statistics after shipping")
	expect(game.life_panel.content.get_child_count() == Fishing.DEFINITIONS.size() + 3, "fish guide shows equipment, statistics, illustrated entries and return action for all eight species")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		var guide_dir := "res://design/qa/2026-09-24/fish-catalog"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(guide_dir))
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(guide_dir + "/guide.png"))

	game.fishing.catch_fish("squid")
	game.autosave_enabled = true
	expect(game._save_game(), "species inventory and collection save")
	game.fishing.restore({})
	game._load_game()
	expect(int(game.fishing.inventory.squid) == 1 and game.fishing.caught.has("red_snapper") and game.fishing.treasure_chests == 1 and game.fishing.rod_level == 2 and game.fishing.bait_count == 8 and game.fishing.cork_bobber_owned and game.fishing.cork_bobber_equipped, "real reload restores fish inventory, equipment, treasure record and rod")
	game.autosave_enabled = false
	var legacy: Dictionary = game.fishing.snapshot()
	game.fishing.restore({})
	game.fish_count = 4
	expect(game.fishing.inventory.creek_fish == 4 and game.fish_count == 4, "legacy aggregate migrates to creek fish")
	game.fishing.restore(legacy)
	expect(not Fishing.valid({"inventory": {"unknown": 2}}), "unknown fish save is rejected")
	expect(not Fishing.valid({"inventory": {"sardine": -1}}), "negative fish save is rejected")
	expect(not Fishing.valid({"inventory": {}, "treasure_chests": -1}), "negative treasure statistic is rejected")
	expect(not Fishing.valid({"inventory": {}, "rod_level": 2.5}), "fractional rod tier is rejected")
	expect(not Fishing.valid({"inventory": {}, "rod_level": 3}), "unknown rod tier is rejected")
	expect(not Fishing.valid({"inventory": {}, "cork_bobber_equipped": true}), "equipped tackle cannot exist without being owned")
	expect(Fishing.valid({"inventory": {}, "caught": {}, "cast_serial": 2}), "older fishing saves without treasure statistic remain compatible")
	var old_fishing := Fishing.new()
	old_fishing.restore({"inventory": {}, "caught": {}, "cast_serial": 2})
	expect(old_fishing.rod_level == 0, "older fishing saves without a rod tier receive the basic rod")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Fishing gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
