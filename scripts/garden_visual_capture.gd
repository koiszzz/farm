extends SceneTree

var game
const OUTPUT := "res://design/qa/2026-09-08/gameplay/"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	# Use the normal starting purse, seed shop, planting and day settlement.
	for count in 2: game.farm.buy_seed("parsnip")
	for count in 4: game.farm.buy_seed("turnip")
	for day in 4:
		for column in 4:
			var cell := Vector2i(10 + column, 15 + day)
			game.farm.till(cell)
			game.farm.plant(cell, "parsnip" if column < 2 else "turnip")
			game.farm.water(cell)
		if day < 3: game.farm.advance_day(true)
	game._change_map("farm_outdoor", Vector2i(17, 16))
	game.pet.affection = 0
	for frame in 200: game.pet.tick(1.0 / 60, game.player_body.position, 720)
	game.world.queue_redraw()
	await _capture("garden_growth")
	game.farm.advance_day(true)
	game.world.queue_redraw()
	await _capture("garden_ready")
	while game.Calendar.weather(game.farm.day) != "雨": game.farm.advance_day(false)
	game._update_farm_hud()
	game.world.queue_redraw()
	await _capture("garden_rain")
	game.queue_free()
	quit()

func _capture(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + label + ".png")
	print("GARDEN FRAMEBUFFER " + label)
