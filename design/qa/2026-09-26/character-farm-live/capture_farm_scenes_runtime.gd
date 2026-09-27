extends SceneTree

const MainScene = preload("res://Main.tscn")
const OUTPUT_DIR := "res://design/qa/2026-09-27/farm-paths"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game = MainScene.instantiate()
	game.set("autosave_enabled", false)
	root.add_child(game)
	for _frame in 8:
		await process_frame
	await create_timer(4.9).timeout
	await RenderingServer.frame_post_draw
	_save_viewport("%s/farm-outdoor-runtime.png" % OUTPUT_DIR)
	for y in range(13, 19):
		for x in range(16, 22):
			var local_cell := Vector2i(x, y)
			var cell: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", local_cell) if game.current_map_id == "valley_world" else local_cell
			var has_crop := posmod(x - 16, 2) == 0 and posmod(y - 13, 2) == 0
			var seed_id := "parsnip" if has_crop else ""
			game.farm._plots[cell] = {"tilled": true, "seed": seed_id, "watered": true, "growth": 4, "mature": false}
			print("plant preview map=%s cell=%s tillable=%s state=%s" % [game.world.map_id, cell, game.farm.navigation.is_tillable(game.farm.map_id, cell), game.farm.get_cell_state(cell)])
	game.player_cell = Vector2i(30, 14)
	game.player_body.position = game._avatar_position_for(game.player_cell)
	game._stream_world(true)
	game._apply_scene_camera_profile()
	game.game_camera.reset_smoothing()
	game.world.queue_redraw()
	await create_timer(4.9).timeout
	await RenderingServer.frame_post_draw
	_save_viewport("%s/farm-plants-preview-runtime.png" % OUTPUT_DIR)
	game.animals.coop_built = true
	game.animals.barn_built = true
	game.animals.chickens.append({"id": "qa_hen", "name": "小满", "gender": "female", "age": 3, "affection": 0, "petted_day": 0, "fed_day": 0})
	game.animals.chickens.append({"id": "qa_rooster", "name": "栗子", "gender": "male", "age": 3, "affection": 0, "petted_day": 0, "fed_day": 0})
	game.animals.ducks.append({"id": "qa_duck", "name": "泡泡", "gender": "female", "age": 2, "affection": 0, "petted_day": 0, "fed_day": 0})
	game.animals.ducks.append({"id": "qa_drake", "name": "麦芽", "gender": "male", "age": 2, "affection": 0, "petted_day": 0, "fed_day": 0})
	game.animals.cows.append({"id": "qa_cow", "name": "花花", "gender": "female", "age": 2, "affection": 0, "petted_day": 0, "fed_day": 0, "milked_day": 0})
	game.animals.cows.append({"id": "qa_bull", "name": "奶糖", "gender": "male", "age": 2, "affection": 0, "petted_day": 0, "fed_day": 0, "milked_day": 0})
	game.player_cell = Vector2i(52, 32)
	game.player_body.position = game._avatar_position_for(game.player_cell)
	game._stream_world(true)
	game._refresh_animal_collisions()
	game._sync_chicken_actors()
	game._sync_duck_actors()
	game._sync_cow_actors()
	game._apply_scene_camera_profile()
	game.game_camera.zoom = Vector2.ONE * 0.8
	game.game_camera.offset = Vector2.ZERO
	game.game_camera.reset_smoothing()
	game.world.queue_redraw()
	game.pet.set_variant("dog", "male")
	game.pet.global_position = game.player_body.global_position + Vector2(40, 0)
	game.pet.target = game.pet.position
	game.pet.cell = Vector2i(floori(game.pet.position.x / 32), floori(game.pet.position.y / 32))
	game.pet.affection = 1.0
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	_save_viewport("%s/farm-built-animals-runtime.png" % OUTPUT_DIR)
	game.pet.set_variant("cat", "female")
	game.pet.global_position = game.player_body.global_position + Vector2(40, 0)
	game.pet.target = game.pet.position
	game.pet.cell = Vector2i(floori(game.pet.position.x / 32), floori(game.pet.position.y / 32))
	game.world.queue_redraw()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	_save_viewport("%s/farm-pet-cat-runtime.png" % OUTPUT_DIR)
	game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
	for _frame in 8:
		await process_frame
	await create_timer(4.9).timeout
	await RenderingServer.frame_post_draw
	_save_viewport("%s/farmhouse-interior-runtime.png" % OUTPUT_DIR)
	quit()


func _save_viewport(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("capture path=%s size=%s error=%s" % [path, image.get_size(), error])
