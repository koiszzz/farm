extends SceneTree

var game
const OUTPUT := "res://design/qa/2026-09-08/continuous-world/"
const SHOWCASE := [["spring", 1, ["parsnip", "cauliflower", "green_bean", "strawberry"]], ["summer", 29, ["tomato", "blueberry", "corn", "melon"]], ["fall", 57, ["pumpkin", "cranberry", "eggplant", "bok_choy"]], ["winter", 85, ["powdermelon", "winter_root", "snow_yam", "crystal_berry"]]]

func _init() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://seasonal-showcase-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://seasonal-display-unused-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for showcase in SHOWCASE:
		game.farm.reset(5000, {})
		game.farm.day = showcase[1]
		var cells: Array[Vector2i] = []
		for index in 4:
			for row in 2:
				var cell: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(7 + index * 2, 15 + row))
				cells.append(cell)
				game.farm.add_seeds(showcase[2][index], 1)
				game.farm.till(cell)
				game.farm.plant(cell, showcase[2][index])
				game.farm.water(cell)
		for day in 14: game.farm.advance_day(true)
		game.world.refresh_season()
		var view_cell: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(17, 16))
		game.player_cell = view_cell
		game.player_body.position = game._avatar_position_for(view_cell)
		game._stream_world(true)
		game._update_location()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + "crops_" + showcase[0] + ".png")
		print("SEASON FRAMEBUFFER " + showcase[0])
	game.queue_free()
	quit()
