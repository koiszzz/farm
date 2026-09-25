extends SceneTree

const OUTPUT := "res://design/qa/2026-09-24/inventory-rework/"
var failures := 0
var checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.farm.harvest_inventory["parsnip"] = 12
	game.farm.harvest_inventory["tomato"] = 4
	game.homestead.resources.wood = 18
	game.homestead.resources.stone = 9
	game.homestead.resources.berry = 6
	game.homestead.resources.mushroom = 3
	game.fish_count = 2
	game.fishing.bait_count = 5
	game.fishing.cork_bobber_owned = true
	game.orchard.saplings = {"apple": 1, "orange": 1, "peach": 1, "pomegranate": 1}
	game.orchard.fruits = {"apple": 1, "orange": 1, "peach": 1, "pomegranate": 1}
	game.animals.eggs = 1
	game.animals.duck_eggs = 1
	game.animals.milk = 1
	game.crafting.meals = {"trail_mix": 1, "fish_stew": 1, "pumpkin_soup": 1, "miner_lunch": 1, "field_salad": 1, "sea_skewer": 1, "miner_rice": 1, "berry_tart": 1}
	game.crafting.crafted_items = {"sprinkler": 1, "mayo_machine": 1, "preserves_jar": 1, "cheese_press": 1}
	game.processing.products = {"mayonnaise": 1, "cheese": 1, "pickles:parsnip": 1}
	game._sync_inventory()
	game.inventory_state.assign_hotbar("food:parsnip", 6)
	game.inventory_state.assign_hotbar("food:berry", 7)
	game.inventory_state.assign_hotbar("material:wood", 8)
	game.inventory_state.assign_hotbar("food:fish", 9)
	game._update_farm_hud()
	game._open_inventory()
	await process_frame
	await process_frame
	var items: Dictionary = game._inventory_items()
	for item_key in ["tool:scythe", "tool:fish", "material:wood", "material:stone", "food:berry", "food:mushroom", "food:fish"]:
		var icon = items.get(item_key, {}).get("icon")
		expect(icon is Texture2D, "%s has a real thumbnail" % item_key)
		if icon is Texture2D:
			var image: Image = icon.get_image()
			expect(image != null and image.get_pixel(0, 0).a < 0.1, "%s thumbnail preserves transparent padding" % item_key)
	var goods_keys := [
		"sapling:apple", "sapling:orange", "sapling:peach", "sapling:pomegranate",
		"food:fruit:apple", "food:fruit:orange", "food:fruit:peach", "food:fruit:pomegranate",
		"food:meal:trail_mix", "food:meal:fish_stew", "food:meal:pumpkin_soup", "food:meal:miner_lunch",
		"food:meal:field_salad", "food:meal:sea_skewer", "food:meal:miner_rice", "food:meal:berry_tart",
		"food:egg", "food:milk", "food:artisan:mayonnaise", "food:artisan:cheese", "food:artisan:pickles:parsnip",
		"placeable:sprinkler", "placeable:mayo_machine", "placeable:preserves_jar", "placeable:cheese_press",
		"bait", "tackle:cork_bobber",
	]
	for item_key in goods_keys:
		var icon = game._inventory_items().get(item_key, {}).get("icon")
		expect(icon is AtlasTexture, "%s uses its own illustrated goods tile" % item_key)
		if icon is AtlasTexture:
			expect(icon.region.size == Vector2(32, 32), "%s clips to one 32-pixel icon tile" % item_key)
	expect(game._inventory_items()["food:duck_egg"].icon is Texture2D, "duck egg keeps its existing dedicated thumbnail")
	var expected_atlas_tiles: int = game.GOODS_ICON_INDEX.size()
	expect(expected_atlas_tiles == 28, "goods atlas maps every fruit, animal product, meal, machine, sapling, and fishing accessory")
	var mapped_tiles: Array = game.GOODS_ICON_INDEX.values()
	mapped_tiles.sort()
	expect(mapped_tiles == range(expected_atlas_tiles), "goods atlas uses every tile exactly once without gaps")
	var backpack_size: Vector2 = game.inventory_panel.backpack_grid.get_child(0).size
	expect(game.inventory_panel.backpack_grid.columns == 7, "backpack uses a compact seven-column satchel grid")
	expect(game.inventory_panel.detail_card.visible, "item details remain in a dedicated side panel")
	expect(not game.inventory_panel.backpack_grid.get_global_rect().intersects(game.inventory_panel.detail_card.get_global_rect()), "item details never overlap inventory slots")
	for slot in game.inventory_panel.backpack_grid.get_children():
		expect(slot.size == backpack_size, "all backpack cells have identical dimensions")
		expect(slot.text.is_empty(), "backpack cells hide permanent text")
	var hotbar_size: Vector2 = game.inventory_panel.hotbar_grid.get_child(0).size
	for slot in game.inventory_panel.hotbar_grid.get_children():
		expect(slot.size == hotbar_size, "all inventory hotbar cells have identical dimensions")
		expect(slot.text.find("\n") < 0, "hotbar cells show only their number at rest")
	await process_frame
	expect(game.inventory_panel.detail_title.text == "锄头" and game.inventory_panel.detail_icon.texture is Texture2D, "selected tool appears in the fixed item inspector")
	var wood_slot: int = game.inventory_state.backpack.find("material:wood")
	var wood_button: Button = game.inventory_panel.backpack_grid.get_child(wood_slot)
	var wood_count: Label = wood_button.get_node_or_null("StackCount") as Label
	expect(wood_count != null and wood_count.text == "18", "backpack stack badge shows the wood quantity in the slot")
	var empty_slot: Button = game.inventory_panel.backpack_grid.get_child(game.inventory_state.backpack.find(""))
	expect(empty_slot.get_node_or_null("StackCount") == null, "empty backpack slots have no quantity badge")
	var berry_count: Label = game.inventory_panel.hotbar_grid.get_child(7).get_node_or_null("StackCount") as Label
	expect(berry_count != null and berry_count.text == "6", "hotbar stack badge shows the selected berry quantity")
	game.inventory_panel._hover("backpack", wood_slot)
	await process_frame
	expect(game.inventory_panel.detail_title.text == "木材" and game.inventory_panel.detail_text.text.contains("数量 18"), "hovered item updates the fixed inspector without covering slots")
	await _capture("backpack-grid.png")
	var backpack_scroll: ScrollContainer = game.inventory_panel.backpack_grid.get_parent()
	backpack_scroll.scroll_vertical = int(backpack_scroll.get_v_scroll_bar().max_value)
	await process_frame
	await _capture("backpack-goods.png")
	backpack_scroll.scroll_vertical = 0
	game.inventory_panel._unhover("backpack", wood_slot)
	game.inventory_panel.cursor_area = "backpack"
	game.inventory_panel.cursor_index = game.inventory_state.backpack.find("food:parsnip")
	game.inventory_panel.refresh()
	game.inventory_panel._toggle_detail()
	expect(game.inventory_panel.detail_expanded, "I expands the complete item description in the inspector")
	await _capture("item-details.png")
	game.inventory_panel.close()
	await _capture("ten-slot-hotbar.png")
	game.queue_free()
	await process_frame
	print("Inventory visual: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)


func _capture(filename: String) -> void:
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUTPUT + filename)
	if result != OK:
		push_error("Could not save inventory capture: " + filename)
		quit(1)


func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition: return
	failures += 1
	push_error(message)
