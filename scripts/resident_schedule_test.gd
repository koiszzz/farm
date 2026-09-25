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
	game.save_path = "user://resident-test-unused.json"
	game.display_config_path = "user://resident-test-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	game.farm.day = 1
	game.clock_minutes = 360
	game._change_map("town_square", Vector2i(20, 20))
	expect(game.npcs.size() == game.VillageScript.PEOPLE.size(), "morning town gathers all residents")
	var town_routes_complete := true
	var minimum_resident_spacing := INF
	var residents: Array = game.npcs.keys()
	for actor in game.npcs:
		var resident = game.npcs[actor].node
		expect(resident._idle_texture.resource_path.ends_with("resident_idle_cast_v1.png"), actor + " spawns with the resident cast atlas")
		expect(resident._idle_column == game._npc_idle_column(str(actor)) and resident._idle_rows == 3, actor + " spawns with its own cast column")
		var town_route: Array[Vector2i] = game.npcs[actor].route
		if town_route.size() < 8:
			town_routes_complete = false
		for cell in town_route:
			if not game.navigation.is_walkable("town_square", cell): town_routes_complete = false
	for first_index in residents.size():
		for second_index in range(first_index + 1, residents.size()):
			var first_position: Vector2 = game.npcs[residents[first_index]].node.position
			var second_position: Vector2 = game.npcs[residents[second_index]].node.position
			minimum_resident_spacing = minf(minimum_resident_spacing, first_position.distance_to(second_position))
	expect(town_routes_complete, "all morning residents have complete, walkable authored town patrols")
	expect(minimum_resident_spacing >= 64.0, "morning residents start at least two tiles apart")
	if DisplayServer.get_name() != "headless":
		root.get_window().size = Vector2i(1280, 720)
		await process_frame
		await RenderingServer.frame_post_draw
		var capture_dir := "res://design/qa/2026-09-25/residents"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
		var capture_error := root.get_texture().get_image().save_png(capture_dir.path_join("town-morning-patrols.png"))
		expect(capture_error == OK, "morning town patrol framebuffer is captured")
	var mayor_node = game.npcs.mayor.node
	var florist_node = game.npcs.florist.node
	game.clock_minutes = 400
	game._spawn_map_npcs()
	expect(game.npcs.mayor.node == mayor_node and game.npcs.florist.node == florist_node, "unchanged schedule retains live NPC nodes")
	game.clock_minutes = 600
	game._spawn_map_npcs()
	expect(game.npcs.has("mayor") and game.npcs.mayor.node == mayor_node, "unaffected resident is not recreated at schedule boundary")
	expect(not game.npcs.has("carpenter") and not game.npcs.has("ranger") and not game.npcs.has("fisherman"), "workers leave town for regional jobs")

	game._change_map("countryside", Vector2i(32, 24))
	expect(game.npcs.has("carpenter") and game.npcs.has("ranger"), "countryside hosts carpenter and ranger")
	for actor in ["carpenter", "ranger"]:
		var route: Array = game.npcs[actor].route
		expect(route.size() > 8, actor + " follows authored countryside patrol")
		for cell in route: expect(game.navigation.is_walkable("countryside", cell), actor + " patrol stays walkable")
	var carpenter_node = game.npcs.carpenter.node
	game.clock_minutes = 610
	game._spawn_map_npcs()
	expect(game.npcs.carpenter.node == carpenter_node, "regional NPC remains continuous between clock updates")

	game.farm.day = 7 # Sunday, deterministic clear weather
	game.clock_minutes = 800
	game._change_map("beach", Vector2i(28, 14))
	expect(game.npcs.has("fisherman") and game.npcs.has("child"), "weekend beach has fisherman and child")
	for actor in ["fisherman", "child"]:
		expect(game.npcs[actor].route.size() > 8, actor + " follows authored beach patrol")
	var line: String = game.village.talk("fisherman", game.farm.day, game.clock_minutes)
	expect(line.contains("沙滩照看潮水"), "dialogue reflects current regional activity")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-21/residents")
		root.get_texture().get_image().save_png("res://design/qa/2026-09-21/residents/beach-schedule.png")

	game.farm.day = 3 # deterministic rain
	game.clock_minutes = 800
	game._change_map("beach", Vector2i(28, 14))
	expect(game.npcs.is_empty(), "rain moves beach residents indoors")
	expect(game.village.activity("fisherman", 3, 800).map == "cafe_interior", "rain schedule names indoor refuge")
	game.queue_free()
	await process_frame
	print("Resident schedules: %d checks, %d failures; morning town minimum spacing %.1f px" % [checks, failures, minimum_resident_spacing])
	quit(1 if failures else 0)
