extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")

var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition: return
	failures += 1
	push_error(message)


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://npc-scene-dialogue-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://npc-scene-dialogue-display-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.farm.day = 1
	game.clock_minutes = 600
	game._change_map("beach", Vector2i(15, 16))
	expect(game.npcs.has("fisherman"), "fisherman is present for the scheduled beach shift")
	var beach_text: String = game.village.talk("fisherman", 1, 600, "beach")
	var town_text: String = game.village.talk("fisherman", 1, 600, "town_square")
	expect(beach_text.contains("潮池") or beach_text.contains("栈台") or beach_text.contains("渔屋"), "beach conversation mentions a visible coastal landmark")
	expect(not town_text.contains("潮池") and not town_text.contains("栈台") and not town_text.contains("渔屋"), "scene details follow the player's actual meeting place")
	expect(beach_text.contains("在沙滩照看潮水"), "location dialogue preserves the daily activity line")
	var birthday_text: String = game.village.talk("fisherman", 76, 600, "beach")
	expect(birthday_text.contains("生日") and not birthday_text.contains("潮池"), "birthday dialogue keeps priority over ordinary location chatter")

	var fisherman = game.npcs["fisherman"].node
	var fisherman_cell: Vector2i = game._cell_from_world_position(fisherman.position)
	var player_cell: Vector2i = game.player_cell
	var approached := false
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var target_cell: Vector2i = fisherman_cell + direction
		if not game.navigation.is_walkable("beach", target_cell): continue
		var checkpoints: Array[Vector2i] = [player_cell, target_cell]
		var route: Array[Vector2i] = game.navigation.patrol_route("beach", checkpoints)
		if route.is_empty(): continue
		for index in range(1, route.size()):
			Motion.walk(game, route[index] - route[index - 1])
		var resolved: Dictionary = game._interaction_target()
		if resolved.get("kind", "") == "npc" and resolved.get("actor", "") == "fisherman":
			approached = true
			break
		player_cell = game.player_cell
	expect(approached, "real walking brings the player within F-interaction range of the fisherman")
	var interact_target: Dictionary = game._interaction_target()
	expect(interact_target.get("kind", "") == "npc" and interact_target.get("actor", "") == "fisherman", "F resolves the nearby scheduled resident through the shared interaction picker")
	expect(game._interaction_npc_actor() == "fisherman", "G resolves the same resident currently shown by the interaction prompt")
	game._interact()
	expect(game.life_panel.dialogue_text != null and (game.life_panel.dialogue_text.text.contains("潮池") or game.life_panel.dialogue_text.text.contains("栈台") or game.life_panel.dialogue_text.text.contains("渔屋")), "the real F interaction panel uses the current beach scene context")
	var facing_delta: Vector2 = game.player_body.position - fisherman.position
	var facing_axis := Vector2i(0, signi(int(facing_delta.y))) if absf(facing_delta.y) > absf(facing_delta.x) else Vector2i(signi(int(facing_delta.x)), 0)
	expect(fisherman.facing == game._facing_for(facing_axis) and game.player.facing == game._facing_for(-facing_axis), "resident and player face one another when the conversation opens")
	expect(game.life_panel.dialogue_text.visible_characters == 0, "dialogue opens with its typewriter reveal at the first character")
	var dialogue_clock: int = game.clock_minutes
	var dialogue_resident_position: Vector2 = fisherman.position
	game._physics_process(0.1)
	expect(game.clock_minutes == dialogue_clock and fisherman.position == dialogue_resident_position, "conversation pauses the day clock and the resident's schedule movement")
	var reveal_key := InputEventKey.new()
	reveal_key.keycode = KEY_SPACE
	reveal_key.physical_keycode = KEY_SPACE
	reveal_key.pressed = true
	game._unhandled_input(reveal_key)
	expect(game.life_panel.dialogue_text.visible_characters == -1, "space reveals the complete current conversation line immediately")
	game.life_panel.dialogue_text.visible_characters = 0
	game.life_panel.reveal = 0
	var click_dialogue := InputEventMouseButton.new()
	click_dialogue.button_index = MOUSE_BUTTON_LEFT
	click_dialogue.pressed = true
	game.life_panel._on_dialogue_gui_input(click_dialogue)
	expect(game.life_panel.dialogue_text.visible_characters == -1, "clicking the conversation text also completes the typewriter reveal")
	var has_rod_shop := false
	for child in game.life_panel.content.get_children():
		if child is Button and str(child.text).contains("海边渔具铺"): has_rod_shop = true
	expect(has_rod_shop, "physically approaching and talking to the beach fisherman exposes the rod shop")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var output_dir := ProjectSettings.globalize_path("res://design/qa/2026-09-24/resident-location-dialogue")
		DirAccess.make_dir_recursive_absolute(output_dir)
		var capture_error := root.get_texture().get_image().save_png(output_dir.path_join("fisherman-beach-dialogue.png"))
		expect(capture_error == OK, "current-location dialogue framebuffer is captured")
	var close_key := InputEventKey.new()
	close_key.keycode = KEY_ESCAPE
	close_key.physical_keycode = KEY_ESCAPE
	close_key.pressed = true
	game._unhandled_input(close_key)
	expect(not game.life_panel.visible, "Escape dismisses a conversation and returns control to exploration")
	var signpost_cell := Vector2i(-1, -1)
	var beach_size: Vector2i = game.navigation.get_map_size("beach")
	for y in beach_size.y:
		for x in beach_size.x:
			var record: Dictionary = game.navigation.interaction_at("beach", Vector2i(x, y))
			if str(record.get("target", "")) == "signpost": signpost_cell = Vector2i(x, y)
	if signpost_cell != Vector2i(-1, -1):
		game.player_cell = signpost_cell
		game.player_body.position = game.world.cell_center_to_screen(signpost_cell)
		game.npcs["fisherman"].node.position = game.player_body.position + Vector2(22, 0)
		var facility_target: Dictionary = game._interaction_target()
		expect(facility_target.get("kind", "") == "facility" and str(facility_target.record.get("target", "")) == "signpost", "an authored signpost keeps priority over a nearby resident")
		expect(game._interaction_npc_actor().is_empty(), "gift targeting follows the visible signpost prompt instead of silently selecting a resident")
		var gift_key := InputEventKey.new()
		gift_key.keycode = KEY_G
		gift_key.pressed = true
		game._unhandled_input(gift_key)
		expect(not game.life_panel.visible, "pressing G cannot open a gift list when the active interaction target is a signpost")
	else:
		expect(false, "beach map contains a signpost target for interaction-priority verification")

	game.queue_free()
	await process_frame

	var continuous_game = preload("res://Main.tscn").instantiate()
	continuous_game.force_continuous_world_for_qa = true
	continuous_game.autosave_enabled = false
	continuous_game.save_path = "user://npc-scene-dialogue-continuous-test-%d.json" % Time.get_ticks_usec()
	continuous_game.display_config_path = "user://npc-scene-dialogue-continuous-display-unused.cfg"
	root.add_child(continuous_game)
	await physics_frame
	continuous_game.set_physics_process(false)
	continuous_game.farm.day = 1
	continuous_game.clock_minutes = 600
	continuous_game._change_map("riverside", continuous_game.navigation.get_spawn("riverside"))
	expect(continuous_game.current_map_id == "valley_world", "continuous-world test enters the shared regional map")
	continuous_game._open_dialogue("fisherman")
	expect(continuous_game.life_panel.dialogue_text.text.contains("潮池") or continuous_game.life_panel.dialogue_text.text.contains("栈台") or continuous_game.life_panel.dialogue_text.text.contains("渔屋"), "continuous-world zone resolves to the same beach conversation")
	continuous_game.queue_free()
	await process_frame
	print("NPC scene dialogue: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
