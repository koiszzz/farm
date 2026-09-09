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
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
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
	game._change_map("farm_outdoor", Vector2i(15,10))
	await physics_frame
	game.transition_lock_frames = 0
	var phase: float = game.player.stride
	key(KEY_W, true)
	for frame in 10: game._physics_process(1.0/60.0)
	key(KEY_W, false)
	expect(game.player.facing == "up" and not game.moving, "blocked input turns toward north without moving")
	expect(game.player.stride == phase, "blocked movement cannot advance foot cycle")
	game._change_map("town_square", Vector2i(41,22))
	game.clock_minutes = 1080
	game._update_npcs(0.1)
	expect(game.npcs.florist.node.running, "evening NPC uses running gait")
	game.queue_free()
	print("Movement inputs: %d failures; walk %.2f px, run %.2f px" % [failures,distances[0],distances[1]])
	quit(1 if failures else 0)
