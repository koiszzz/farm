extends SceneTree

const MainScene = preload("res://Main.tscn")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	print("capture start")
	var game = MainScene.instantiate()
	game.set("autosave_enabled", false)
	root.add_child(game)
	await process_frame
	await process_frame
	print("game ready map=", game.current_map_id, " spawn=", game.player_cell, " map_errors=", game.navigation.load_errors)
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("res://design/qa/2026-09-26/character-farm-live/farm-outdoor-after.png")
	game.call("_change_map", "farmhouse_interior", Vector2i(18, 16))
	await create_timer(0.3).timeout
	image = root.get_viewport().get_texture().get_image()
	image.save_png("res://design/qa/2026-09-26/character-farm-live/farmhouse-interior-after.png")
	quit()
