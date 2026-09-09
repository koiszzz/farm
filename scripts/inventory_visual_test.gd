extends SceneTree

const OUTPUT := "res://design/qa/2026-09-08/inventory/"
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
	var backpack_size: Vector2 = game.inventory_panel.backpack_grid.get_child(0).size
	for slot in game.inventory_panel.backpack_grid.get_children():
		expect(slot.size == backpack_size, "all backpack cells have identical dimensions")
		expect(slot.text.is_empty(), "backpack cells hide permanent text")
	var hotbar_size: Vector2 = game.inventory_panel.hotbar_grid.get_child(0).size
	for slot in game.inventory_panel.hotbar_grid.get_children():
		expect(slot.size == hotbar_size, "all inventory hotbar cells have identical dimensions")
		expect(slot.text.find("\n") < 0, "hotbar cells show only their number at rest")
	expect(game.inventory_panel.hover_card.visible and game.inventory_panel.hover_label.text.contains("锄头"), "selected item shows lightweight floating information")
	var wood_slot: int = game.inventory_state.backpack.find("material:wood")
	game.inventory_panel._hover("backpack", wood_slot)
	await process_frame
	expect(game.inventory_panel.hover_label.text.contains("木材") and game.inventory_panel.hover_label.text.contains("×18"), "hovered item replaces the selected-item floating information")
	await _capture("backpack-grid.png")
	game.inventory_panel._unhover("backpack", wood_slot)
	game.inventory_panel.cursor_area = "backpack"
	game.inventory_panel.cursor_index = game.inventory_state.backpack.find("food:parsnip")
	game.inventory_panel.refresh()
	game.inventory_panel._toggle_detail()
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
