extends SceneTree

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


func find_center() -> Vector2i:
	for cell in game.navigation.get_cells_with_class("farm_outdoor", "tillable"):
		var valid := true
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not game.navigation.is_tillable("farm_outdoor", cell + offset): valid = false
		if valid: return cell
	return Vector2i(-1, -1)


func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://sprinkler-gameplay-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://sprinkler-gameplay-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	expect(not game.crafting.is_unlocked("sprinkler", game.village, game.mining, game.skills), "sprinkler begins locked")
	game.skills.gain("farming", 380)
	expect(game.crafting.is_unlocked("sprinkler", game.village, game.mining, game.skills), "farming level two unlocks sprinkler")
	game.homestead.resources.copper_ore = 2
	game.homestead.resources.iron_ore = 0
	game._craft_recipe("sprinkler")
	expect(game.homestead.resources.copper_ore == 2 and game.crafting.crafted_items.is_empty(), "missing iron craft is atomic")
	game.homestead.resources.iron_ore = 1
	game._craft_recipe("sprinkler")
	expect(game.homestead.resources.copper_ore == 0 and game.homestead.resources.iron_ore == 0, "sprinkler consumes exact ore")
	expect(game.crafting.crafted_items.sprinkler == 1, "crafted sprinkler enters facility inventory")
	expect(game._inventory_items().has("placeable:sprinkler"), "sprinkler appears in backpack source")

	var center := find_center()
	expect(center != Vector2i(-1, -1), "farm has a five-cell sprinkler footprint")
	game._sync_inventory()
	expect(game.inventory_state.assign_hotbar("placeable:sprinkler", 7), "facility can be assigned to hotbar")
	game._change_map("farm_outdoor", center + Vector2i.UP)
	game.player.set_pose("down", "idle")
	game._use_hotbar(7)
	expect(game.farm.structure_at(center) == "sprinkler", "hotbar use installs sprinkler in facing cell")
	expect(int(game.crafting.crafted_items.get("sprinkler", 0)) == 0, "placement consumes one carried sprinkler")
	expect(game.active_collision_cells.has(center), "installed sprinkler has world collision")
	expect(game.pet.grid.is_point_solid(center), "pet navigation avoids sprinkler")

	var crops: Array[Vector2i] = []
	for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var cell: Vector2i = center + offset
		crops.append(cell)
		expect(game.farm.till(cell).ok, "adjacent soil can be tilled")
		expect(game.farm.plant(cell, "parsnip").ok, "adjacent soil can be planted")
	game.farm.advance_day(false)
	for cell in crops:
		var plot: Dictionary = game.farm.get_cell_state(cell)
		expect(int(plot.growth) == 1 and bool(plot.watered), "sprinkler grows and leaves adjacent crop watered")
	expect(not bool(game.farm.get_cell_state(center).watered), "sprinkler does not water its own occupied cell")

	game._change_map("farm_outdoor", center + Vector2i.DOWN)
	game.player.set_pose("up", "idle")
	game.current_tool = "pickaxe"
	var energy_before: int = game.energy
	game._farm_action()
	expect(game.actor_action.kind == "pickaxe", "pickaxe starts facility removal action")
	game.actor_action.advance(2.0)
	expect(game.farm.structure_at(center).is_empty(), "pickaxe removes installed sprinkler")
	expect(game.crafting.crafted_items.sprinkler == 1, "removed sprinkler returns to backpack")
	expect(game.energy == energy_before - 2, "removal spends current mining energy cost")
	expect(not game.active_collision_cells.has(center), "removal clears world collision")
	expect(not game.pet.grid.is_point_solid(center), "pet navigation reopens removed cell")

	game._change_map("farm_outdoor", center + Vector2i.UP)
	game.player.set_pose("down", "idle")
	game._place_structure("sprinkler")
	game.autosave_enabled = true
	expect(game._save_game(), "installed sprinkler saves")
	game.farm.remove_structure(center)
	game.crafting.restore({})
	game._load_game()
	expect(game.farm.structure_at(center) == "sprinkler", "real reload restores installed sprinkler")
	expect(not game._inventory_items().has("placeable:sprinkler"), "installed facility is not duplicated in backpack after reload")
	expect(not game.Crafting.valid({"meals": {}, "items": {"unknown": 1}}), "unknown facility save is rejected")

	game.autosave_enabled = false
	if DisplayServer.get_name() != "headless":
		game.life_panel.close()
		game._change_map("farm_outdoor", center + Vector2i(2, 2))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-21/sprinkler")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-21/sprinkler/field.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Sprinkler gameplay: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
