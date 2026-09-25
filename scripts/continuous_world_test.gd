extends SceneTree

var checks := 0
var failures := 0
var game
var visual := false
const OUTPUT := "res://design/qa/2026-09-08/continuous-world/"

func _init() -> void: call_deferred("_run")

func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _run() -> void:
	visual = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://continuous-world-qa-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://continuous-display-qa-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	expect(game.current_map_id == "valley_world", "game starts in one continuous outdoor world")
	expect(game.navigation.get_map_size("valley_world") == Vector2i(248, 112), "continuous world has expanded bounds")
	var farm_spawn: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(17, 16))
	expect(game.player_cell == farm_spawn, "farm spawn translated into continuous coordinates")
	var world_map: Dictionary = game.navigation.get_map("valley_world")
	var exit_count := 0
	var water_edges := 0
	for cell in world_map.cells:
		if world_map.cells[cell].has("exit_record"): exit_count += 1
		if game.navigation.get_cell_class("valley_world", cell) == "water":
			for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if game.navigation.get_cell_class("valley_world", cell + direction) != "water": water_edges += 1; break
	expect(exit_count == 0, "outdoor regions have no scene-switch exits")
	expect(water_edges > 80, "lakes and streams expose shaped shoreline edges")
	var town_gate: Vector2i = game.navigation.to_contiguous_world("town_square", Vector2i(41, 22))
	var farm_gate: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(1, 14))
	var river_gate: Vector2i = game.navigation.to_contiguous_world("riverside", Vector2i(2, 15))
	var town_farm_points: Array[Vector2i] = [town_gate, farm_gate]
	var farm_river_points: Array[Vector2i] = [farm_gate, river_gate]
	var to_farm: Array[Vector2i] = game._npc_walk_route(town_farm_points)
	var to_river: Array[Vector2i] = game._npc_walk_route(farm_river_points)
	expect(to_farm.size() > 30, "town and farm connect through a real buffer route")
	expect(to_river.size() > 30, "farm and river connect through eastern countryside")
	expect(game.navigation.get_cell_layers("valley_world", Vector2i(69, 54)).surface == "path", "western stream has a walkable bridge")
	expect(game.world.object_nodes.size() < world_map.objects.size(), "renderer loads nearby objects instead of whole world")
	expect(game.collision_root.get_child_count() < 3000, "collision streaming keeps only nearby cells")
	var map_before: String = game.current_map_id
	for point in [town_gate, Vector2i(72, 54), farm_gate, river_gate]:
		game.player_cell = point
		game.player_body.position = game._avatar_position_for(point)
		game._stream_world(true)
		expect(game.current_map_id == map_before, "streaming across region keeps one map")
	await _capture_at("farm", farm_spawn)
	await _capture_at("forest_bridge", Vector2i(70, 54))
	await _capture_at("town", game.navigation.to_contiguous_world("town_square", Vector2i(24, 16)))
	await _capture_at("north_lake", Vector2i(167, 41))
	await _capture_at("river", game.navigation.to_contiguous_world("riverside", Vector2i(18, 17)))
	game.clock_minutes = 360
	game._change_map("valley_world", game.navigation.to_contiguous_world("town_square", Vector2i(24, 16)))
	expect(game.npcs.size() >= 7, "expanded town population is present in the shared world")
	for state in game.npcs.values():
		for child in state.node.get_children(): expect(not child is Label, "resident names are not drawn above characters")
	await _capture_at("town_population", game.player_cell)
	expect(game.farm.crop_definitions.size() >= 20, "crop catalog covers broad seasonal variety")
	var season_counts := [0, 0, 0, 0]
	for crop in game.farm.crop_definitions.values():
		for season in crop.seasons: season_counts[season] += 1
	for season in 4: expect(season_counts[season] >= 4, "season %d has at least four crop choices" % season)
	expect(game.hud_status.text.find("格子") == -1, "normal HUD no longer exposes coordinate boxes")
	var plot: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(4, 15))
	expect(game.farm.get_cell_state(plot).is_empty() or not game.farm.get_cell_state(plot).get("tilled", false), "field begins untilled")
	game.farm.till(plot)
	expect(game.farm.get_cell_state(plot).tilled and not game.farm.get_cell_state(plot).watered, "tilled dry state exists")
	game.farm.water(plot)
	expect(game.farm.get_cell_state(plot).tilled and game.farm.get_cell_state(plot).watered, "tilled wet state exists")
	game.farm.plant(plot, "parsnip")
	expect(not str(game.farm.get_cell_state(plot).seed).is_empty() and game.farm.get_cell_state(plot).watered, "crop wet state exists")
	game.farm.advance_day(false)
	expect(not game.farm.get_cell_state(plot).watered and not str(game.farm.get_cell_state(plot).seed).is_empty(), "crop dry state exists")
	game.farm.reset(500, {})
	game.farm.day = 56
	game.farm.add_seeds("corn", 1)
	game.farm.till(plot)
	game.farm.plant(plot, "corn")
	game.farm.water(plot)
	game.farm.advance_day(true)
	expect(game.farm.get_cell_state(plot).seed == "corn", "summer-fall crop survives the season boundary")
	game.farm.day = 90
	game.world.refresh_season()
	await _capture_at("winter_snow", farm_spawn)
	game._open_world_map()
	await _capture("global_map")
	game.life_panel.close()
	game._open_display_settings()
	expect(game.life_panel.content.get_child_count() >= 5, "display panel exposes three sizes and fullscreen")
	await _capture("display_settings")
	game.life_panel.close()
	if visual:
		var compact_button := _display_button("1280 × 720")
		expect(compact_button != null, "compact display button is wired")
		compact_button.pressed.emit()
		await process_frame
		expect(DisplayServer.window_get_size() == Vector2i(1280, 720), "compact pixel window size applies")
		var fullscreen_button := _display_button("全屏游戏")
		expect(fullscreen_button != null, "fullscreen display button is wired")
		fullscreen_button.pressed.emit()
		await process_frame
		expect(DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED, "fullscreen mode applies")
		var exit_fullscreen_button := _display_button("退出全屏")
		expect(exit_fullscreen_button != null, "exit fullscreen button is wired")
		exit_fullscreen_button.pressed.emit()
		await process_frame
		var recommended_button := _display_button("1536 × 864")
		expect(recommended_button != null, "recommended display button is wired")
		recommended_button.pressed.emit()
		await process_frame
		expect(DisplayServer.window_get_size() == Vector2i(1536, 864), "recommended pixel window size restores")
		expect(game.display_apply_error.is_empty(), "display changes complete without a false success state")
	expect(game.tool_buttons.size() == 10, "ten-slot item hotbar remains usable at expanded viewport")
	expect(game.WINDOW_SIZES == [Vector2i(1280, 720), Vector2i(1536, 864), Vector2i(1920, 1080)], "three window sizes are configured")
	game.autosave_enabled = true
	expect(game._save_game(), "continuous coordinates save to isolated disk path")
	var data = game._read_save(game.save_path)
	expect(data.world_layout == 2 and data.map == "valley_world", "save records continuous world layout")
	var legacy: Dictionary = data.duplicate(true)
	legacy.world_layout = 1
	legacy.map = "farm_outdoor"
	legacy.cell = [17, 16]
	legacy.farm.plots = [{"x": 4, "y": 15, "state": {"tilled": true, "watered": false, "seed": "", "growth": 0, "mature": false}}]
	legacy.farm.structures = [{"x": 6, "y": 15, "id": "mayo_machine"}]
	legacy.processing.jobs = [{"x": 6, "y": 15, "machine": "mayo_machine", "input": "egg", "output": "mayonnaise", "ready_day": 2, "ready": false}]
	game._migrate_save_to_contiguous(legacy)
	expect(legacy.map == "valley_world" and Vector2i(legacy.cell[0], legacy.cell[1]) == farm_spawn, "legacy outdoor save location migrates once")
	expect(Vector2i(legacy.farm.plots[0].x, legacy.farm.plots[0].y) == game.navigation.to_contiguous_world("farm_outdoor", Vector2i(4, 15)), "legacy farm plots migrate without being discarded")
	expect(Vector2i(legacy.farm.structures[0].x, legacy.farm.structures[0].y) == game.navigation.to_contiguous_world("farm_outdoor", Vector2i(6, 15)), "legacy processing machine migrates with farm structures")
	expect(Vector2i(legacy.processing.jobs[0].x, legacy.processing.jobs[0].y) == Vector2i(legacy.farm.structures[0].x, legacy.farm.structures[0].y), "legacy processing job stays aligned with migrated machine")
	game.autosave_enabled = false
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(game.display_config_path)
	game.queue_free()
	print("Continuous world: %d checks, %d failures; visual=%s" % [checks, failures, visual])
	quit(1 if failures else 0)

func _display_button(prefix: String) -> Button:
	for child in game.life_panel.content.get_children():
		if child is Button and child.text.begins_with(prefix): return child
	return null

func _capture_at(label: String, cell: Vector2i) -> void:
	game.player_cell = cell
	game.player_body.position = game._avatar_position_for(cell)
	game._stream_world(true)
	game._update_location()
	await _capture(label)

func _capture(label: String) -> void:
	if not visual: return
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + label + ".png")
	print("CONTINUOUS FRAMEBUFFER " + label)
