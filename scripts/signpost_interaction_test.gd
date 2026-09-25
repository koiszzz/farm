extends SceneTree

var failures := 0
var checks := 0
var game

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
	game.force_continuous_world_for_qa = true
	game.save_path = "user://signpost-test-unused.json"
	game.display_config_path = "user://signpost-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	expect(game.navigation.load_errors.is_empty(), "signposts do not conflict with authored maps")
	for map_id in ["farm_outdoor", "town_square", "riverside", "valley_world"]:
		var signs: Array = game.navigation.get_signposts(map_id)
		expect(not signs.is_empty(), "signposts exist in " + map_id)
		for entry in signs:
			var post := Vector2i(entry.post[0], entry.post[1])
			var stand := Vector2i(entry.stand[0], entry.stand[1])
			expect(not game.navigation.is_walkable(map_id, post), "post has physical footprint: " + entry.id)
			expect(game.navigation.is_walkable(map_id, stand), "reader can stand in front: " + entry.id)
			var points: Array[Vector2i] = [game.navigation.get_spawn(map_id), stand]
			expect(stand == game.navigation.get_spawn(map_id) or not game.navigation.patrol_route(map_id, points).is_empty(), "sign reachable from spawn: " + entry.id)
			game._change_map(map_id, stand)
			await physics_frame
			game.player.set_pose("up", "idle")
			expect(game._interaction_target().get("kind", "") == "facility", "sign wins contextual selection")
			expect(game._context_text().contains("阅读路标"), "hint describes reading")
			game._interact()
			expect(game.life_panel.visible and game.life_panel.heading.text == entry.title, "F reads matching place: " + entry.id)
			expect(game.life_panel.content.get_child(0).text == entry.text, "reading contains authored location information")
			game._process(0)
			expect(game.hud_context.text.is_empty(), "context hint hides while reading")
			game.life_panel.close()
	game.continuous_world_enabled = false
	game._change_map("town_square", Vector2i(41, 22))
	await physics_frame
	var actor: String = game.npcs.keys()[0]
	for state in game.npcs.values(): state.node.position = Vector2(10000, 10000)
	var found_wall := false
	var size: Vector2i = game.navigation.get_map_size("town_square")
	for y in range(1, size.y - 1):
		for x in range(1, size.x - 1):
			var cell := Vector2i(x, y)
			if game.navigation.is_walkable("town_square", cell): continue
			var center: Vector2 = game.world.cell_center_to_screen(cell)
			var left := center - Vector2(25, 0)
			var right := center + Vector2(25, 0)
			if not game.navigation.is_walkable("town_square", game.navigation.world_to_cell(left)) or not game.navigation.is_walkable("town_square", game.navigation.world_to_cell(right)): continue
			game.player_body.position = left
			game.npcs[actor].node.position = right
			expect(game._nearby_npc_actor().is_empty(), "NPC within talking distance cannot be reached through obstacle")
			game.npcs[actor].node.position = left
			expect(game._nearby_npc_actor() == actor, "unobstructed NPC remains selectable")
			found_wall = true
			break
		if found_wall: break
	expect(found_wall, "test exercises a real separating map obstacle")
	game.feedback.burst(game.player_body.position, "测试收获", Color.WHITE)
	expect(game.hud_status.text.contains("测试收获"), "action feedback goes to fixed HUD")
	if DisplayServer.get_name() != "headless":
		game.continuous_world_enabled = true
		game._change_map("farm_outdoor", Vector2i(2, 13))
		game.player.set_pose("up", "idle")
		await create_timer(0.3).timeout
		await capture("sign-in-world")
		game._interact()
		await capture("reading-sign")
		game.life_panel.close()
	game._set_status("临时提示生命周期测试")
	expect(game.hud_status_panel.visible, "status feedback appears as a temporary toast")
	if DisplayServer.get_name() != "headless":
		await capture("toast-visible", "res://design/qa/2026-09-24/hud-toast")
	await create_timer(5.0).timeout
	expect(not game.hud_status_panel.visible, "status toast fades after feedback is no longer current")
	if DisplayServer.get_name() != "headless":
		await capture("toast-hidden", "res://design/qa/2026-09-24/hud-toast")
	game.queue_free()
	await process_frame
	print("Signpost interaction: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func capture(label: String, folder := "res://design/qa/2026-09-21/signposts") -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder + "/" + label + ".png")
