extends SceneTree

var failures := 0
var checks := 0
var game


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition: return
	failures += 1
	push_error(message)


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func tap(code: Key) -> void:
	key(code, true)
	await process_frame
	key(code, false)
	await process_frame


func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await tap(KEY_I)
	expect(game.inventory_panel.visible, "physical I input opens the backpack")
	expect(game.inventory_panel.detail_card.visible, "the fixed item inspector stays visible beside the backpack")
	await tap(KEY_I)
	expect(game.inventory_panel.detail_expanded and game.inventory_panel.detail_title.text == "锄头", "physical I expands selected item details")
	await tap(KEY_ESCAPE)
	expect(game.inventory_panel.visible and not game.inventory_panel.detail_expanded, "first Escape collapses item details")
	await tap(KEY_DOWN)
	expect(game.inventory_panel.cursor_area == "backpack" and game.inventory_panel.cursor_index == 7, "down key follows the seven-column backpack layout")
	await tap(KEY_UP)
	expect(game.inventory_panel.cursor_index == 0, "up key returns to the matching backpack column")
	await tap(KEY_ESCAPE)
	expect(not game.inventory_panel.visible, "second Escape closes the backpack")
	game._change_map("farm_outdoor", Vector2i(4, 14))
	game.player.set_pose("down", "idle")
	await tap(KEY_1)
	expect(game.current_tool == "hoe" and game.actor_action.kind == "hoe", "number 1 immediately uses the tool in hotbar slot one")
	game.actor_action.advance(1.0)
	expect(game.farm.get_cell_state(Vector2i(4, 15)).get("tilled", false), "number-key tool use commits its game action")
	game.farm.harvest_inventory["parsnip"] = 1
	game.farm.inventory_changed.emit("harvest", "parsnip", 1)
	game.inventory_state.assign_hotbar("food:parsnip", 9)
	game.energy = 50
	await tap(KEY_0)
	expect(game.energy == 70 and game.farm.get_harvest_count("parsnip") == 0, "number 0 immediately eats assigned food")
	game.homestead.resources.wood = 1
	game._sync_inventory()
	game.inventory_state.assign_hotbar("material:wood", 8)
	await tap(KEY_9)
	expect(game.homestead.resources.wood == 1, "ordinary material cannot be used from its number key")
	game.queue_free()
	await process_frame
	print("Inventory inputs: %d checks, %d failures." % [checks, failures])
	quit(1 if failures else 0)
