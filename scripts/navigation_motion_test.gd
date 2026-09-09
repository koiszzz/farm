extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	# Exercise the real physics footprint, not just the map lookup.
	for entry in [["farm_outdoor", Vector2i(3, 23), Vector2i.RIGHT], ["farm_outdoor", Vector2i(1, 14), Vector2i.LEFT], ["town_square", Vector2i(10, 12), Vector2i.UP]]:
		game._change_map(entry[0], entry[1])
		await physics_frame
		game._begin_move(entry[2])
		for frame in 30:
			game._update_player_movement(1.0 / 60.0)
		var reached: bool = game.player_cell == entry[1] + entry[2] or game.current_map_id != entry[0]
		if not reached:
			failures += 1
			push_error("Physical route blocked: %s %s -> %s (at %s)" % [entry[0], entry[1], entry[1] + entry[2], game.player_cell])
		if game.current_map_id != entry[0] and not game.navigation.exit_at(game.current_map_id, game.player_cell).is_empty():
			failures += 1
			push_error("Arrival is on return exit; next step can bounce back")
	game.queue_free()
	print("Navigation motion: %d failures" % failures)
	quit(1 if failures else 0)
