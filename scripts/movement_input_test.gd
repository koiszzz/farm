extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://movement-input-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://movement-input-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	var grass_step: AudioStreamWAV = game.farm_audio.sounds["step_grass_0"]
	var sand_step: AudioStreamWAV = game.farm_audio.sounds["step_sand_0"]
	var stone_step: AudioStreamWAV = game.farm_audio.sounds["step_stone_0"]
	expect(grass_step.mix_rate == 22050 and grass_step.data.size() == 4410, "footstep synthesis creates a short 22.05 kHz sample")
	expect(grass_step.data != sand_step.data and sand_step.data != stone_step.data, "grass, sand, and stone footsteps have distinct waveforms")
	var distances: Array[float] = []
	for sprint in [false,true]:
		game._change_map("farm_outdoor", Vector2i(17,16))
		await physics_frame
		game.transition_lock_frames = 0
		var start: Vector2 = game.player_body.position
		key(KEY_SHIFT, sprint)
		key(KEY_D, true)
		for frame in 13: game._physics_process(1.0/60.0)
		distances.append(game.player_body.position.distance_to(start))
		expect(game.player.running == sprint, "Shift controls running gait")
		key(KEY_D, false)
		key(KEY_SHIFT, false)
	expect(distances[0] > 20 and distances[1] > distances[0]*1.35, "real input produces distinct walk and run speeds")
	game.player.stride = 2.0
	game.player.set_pose("down", "walk")
	expect(is_equal_approx(game.player._details._walking_bounce(), 1.5), "gameplay walk action animates selected hair details")
	game.player.set_pose("down", "run")
	expect(is_equal_approx(game.player._details._walking_bounce(), 2.0), "gameplay run action gives hair details a stronger swing")
	game.player.set_pose("down", "idle")
	expect(is_zero_approx(game.player._details._walking_bounce()), "idle hair details remain still")
	game.player.running = false
	game.player.set_pose("down", "walk")
	expect(is_equal_approx(game.player._locomotion_bob(), 1.5), "walk cycle has a visible grounded rise phase")
	expect(is_equal_approx(game.player._locomotion_sway(), 1.3), "front-facing walk shifts weight across planted feet")
	game.player.running = true
	expect(is_equal_approx(game.player._locomotion_bob(), 2.5), "run cycle has a stronger rise phase")
	game.player.set_pose("down", "idle")
	expect(is_zero_approx(game.player._locomotion_bob()), "idle pose has no locomotion bob")
	expect(is_zero_approx(game.player._locomotion_sway()), "idle pose has no locomotion weight shift")
	var steps_before: int = game.farm_audio.played_footsteps
	game._change_map("farm_outdoor", Vector2i(17,16))
	await physics_frame
	game.transition_lock_frames = 0
	game.footstep_distance = 0.0
	key(KEY_D, true)
	for frame in 45: game._physics_process(1.0 / 60.0)
	key(KEY_D, false)
	expect(game.farm_audio.played_footsteps - steps_before >= 2, "real player travel triggers distance-timed footsteps")
	expect(game.farm_audio.voices.any(func(voice): return voice.stream == game.farm_audio.last_footstep_stream and voice.bus == "SFX"), "footsteps use a dedicated SFX voice")
	game._change_map("beach", Vector2i(27,12))
	expect(game._footstep_surface(Vector2(10 * 32 + 16, 10 * 32 + 16)) == "sand", "beach sand selects a soft footstep surface")
	expect(game._footstep_surface(Vector2(26 * 32 + 16, 15 * 32 + 16)) == "wood", "beach pier selects wooden footfalls")
	game._change_map("cave", Vector2i(18,25))
	expect(game._footstep_surface(Vector2(18 * 32 + 16, 15 * 32 + 16)) == "stone", "mine floors select stone footfalls")
	game._change_map("farm_outdoor", Vector2i(17,16))
	expect(game._footstep_surface(Vector2(3 * 32 + 16, 15 * 32 + 16)) == "soil", "tilled farm plots select soft soil footfalls")
	game._change_map("farm_outdoor", Vector2i(15,10))
	await physics_frame
	game.transition_lock_frames = 0
	game.player.stride = 5.5
	key(KEY_W, true)
	for frame in 10: game._physics_process(1.0/60.0)
	var phase: float = game.player.stride
	for frame in 10: game._physics_process(1.0/60.0)
	key(KEY_W, false)
	expect(game.player.facing == "up" and not game.moving, "blocked input turns toward north without moving")
	expect(game.player.stride == phase and is_zero_approx(phase), "blocked movement settles at the planted first foot pose")
	var contact_point: Vector2 = game.player_body.position
	key(KEY_W, true)
	key(KEY_D, true)
	for frame in 5: game._physics_process(1.0 / 60.0)
	key(KEY_W, false)
	key(KEY_D, false)
	expect(game.player_body.position.x > contact_point.x + 5, "diagonal input slides along wall")
	expect(absf(game.player_body.position.y - contact_point.y) < 0.2, "wall sliding cannot enter solid footprint")
	game._change_map("farm_outdoor", Vector2i(17, 16))
	await physics_frame
	game.transition_lock_frames = 0
	key(KEY_D, true)
	game._physics_process(1.0 / 60.0)
	var stopping_point: Vector2 = game.player_body.position
	key(KEY_D, false)
	game._physics_process(1.0 / 60.0)
	expect(game.player_body.position == stopping_point and not game.moving, "release stops immediately between grid centers")
	expect(is_zero_approx(game.player.stride), "release returns the walk cycle to its planted first pose")
	key(KEY_A, true)
	game._physics_process(1.0 / 60.0)
	expect(game.player_body.position.x < stopping_point.x and game.player.facing == "left", "reverse direction responds next tick")
	key(KEY_A, false)
	var lengths: Array[float] = []
	for diagonal in [false, true]:
		game._change_map("farm_outdoor", Vector2i(17, 16))
		await physics_frame
		game.transition_lock_frames = 0
		var start: Vector2 = game.player_body.position
		key(KEY_D, true)
		key(KEY_S, diagonal)
		for frame in 6: game._physics_process(1.0 / 60.0)
		lengths.append(game.player_body.position.distance_to(start))
		if diagonal: expect(game.player_body.position.y > start.y, "diagonal movement includes both axes")
		key(KEY_D, false)
		key(KEY_S, false)
	expect(absf(lengths[0] - lengths[1]) < 0.02, "diagonal and cardinal speeds match")
	var neutral_position: Vector2 = game.player_body.position
	key(KEY_A, true)
	key(KEY_D, true)
	game._physics_process(1.0 / 60.0)
	key(KEY_A, false)
	key(KEY_D, false)
	expect(game.player_body.position == neutral_position, "opposite directions cancel without left priority")
	expect(game.game_camera.zoom == Vector2(2.0, 2.0), "world camera uses closer framing")
	game._change_map("town_square", Vector2i(41,22))
	game.clock_minutes = 1080
	game._update_npcs(0.1)
	expect(game.npcs.florist.node.running, "evening NPC uses running gait")
	game.queue_free()
	print("Movement inputs: %d failures; walk %.2f px, run %.2f px" % [failures,distances[0],distances[1]])
	quit(1 if failures else 0)
