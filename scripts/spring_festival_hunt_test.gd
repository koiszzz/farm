extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")
const Village = preload("res://scripts/village_life.gd")
const Hunt = preload("res://scripts/spring_festival_hunt.gd")

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
	game.save_path = "user://spring-hunt-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://spring-hunt-display-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.farm.day = 13
	game._change_map("town_square", Vector2i(41, 22))
	game._open_festival()
	expect(game.life_panel.visible, "spring festival starts from the physical town notice board")
	expect(game.life_panel.heading.text == "花溪镇公告板", "spring hunt keeps the festival's town-board entry point")
	game._start_spring_festival_hunt()
	var hunt = game.festival_hunt
	expect(hunt is Hunt and hunt.active, "starting the board activity opens the playable hunt")
	expect(hunt.token_cells.size() == 6 and hunt.found_cells.is_empty(), "a fresh hunt places six collectible flower stamps")
	for cell in hunt.token_cells:
		expect(game.navigation.is_walkable("town_square", cell), "each flower uses a walkable town cell")
		expect(game.navigation.interaction_at("town_square", cell).is_empty(), "flowers do not cover authored facilities")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/festivals")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-24/festivals/spring-hunt.png")
	var cursor: Vector2i = game.player_cell
	for flower_cell in hunt.token_cells:
		if not hunt.active: break
		var checkpoints: Array[Vector2i] = [cursor, flower_cell]
		var route: Array[Vector2i] = game.navigation.patrol_route("town_square", checkpoints)
		expect(not route.is_empty(), "each spring token remains reachable from the current route")
		for index in range(1, route.size()):
			if not hunt.active: break
			Motion.walk(game, route[index] - route[index - 1])
			hunt._collect_under_player()
		cursor = game.player_cell
	expect(hunt.found_cells.size() == 6 and not hunt.active, "walking over all six flowers completes the challenge")
	expect(game.village.festival_hunt_complete(game.farm.day), "completed hunt is recorded in festival progress")
	var reward_before: int = game.farm.gold
	game._join_festival()
	expect(game.farm.gold == reward_before + 180 and game.village.claimed.has("13"), "returning to the board grants the spring reward once")
	game._join_festival()
	expect(game.farm.gold == reward_before + 180, "the spring reward cannot be claimed twice")
	var restored = Village.new()
	restored.restore(JSON.parse_string(JSON.stringify(game.village.snapshot())))
	expect(restored.festival_hunt_complete(13) and restored.claimed.has("13"), "hunt completion and reward survive save-state round trip")
	game.queue_free()
	await process_frame

	var retry_game = preload("res://Main.tscn").instantiate()
	retry_game.autosave_enabled = false
	retry_game.save_path = "user://spring-hunt-timeout-%d.json" % Time.get_ticks_usec()
	retry_game.display_config_path = "user://spring-hunt-timeout-display-unused.cfg"
	root.add_child(retry_game)
	await physics_frame
	retry_game.farm.day = 13
	retry_game._change_map("town_square", Vector2i(41, 22))
	retry_game._start_spring_festival_hunt()
	var failed_hunt = retry_game.festival_hunt
	failed_hunt.elapsed = Hunt.LIMIT_SECONDS - 0.01
	failed_hunt._physics_process(0.02)
	expect(not failed_hunt.active and not retry_game.village.festival_hunt_complete(13), "timeout ends an incomplete hunt without awarding completion")
	retry_game._start_spring_festival_hunt()
	var cancel_hunt = retry_game.festival_hunt
	cancel_hunt.cancel()
	expect(retry_game.festival_hunt == null and not retry_game.village.festival_hunt_complete(13), "leaving with Esc permits a retry without recording a win")
	retry_game.queue_free()
	await process_frame
	print("Spring festival hunt: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
