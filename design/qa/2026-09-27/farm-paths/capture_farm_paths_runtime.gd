extends SceneTree

const MainScene = preload("res://Main.tscn")
const OUTPUT := "res://design/qa/2026-09-27/farm-paths/farm-paths-runtime.png"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	Engine.max_fps = 30
	var game = MainScene.instantiate()
	game.set("autosave_enabled", false)
	root.add_child(game)
	for _frame in 6:
		await process_frame
	game.farm.reset()
	game._seed_starter_patch()
	game.player_cell = game.navigation.get_spawn("farm_outdoor")
	game.player_body.position = game._avatar_position_for(game.player_cell)
	game._apply_scene_camera_profile()
	game.game_camera.reset_smoothing()
	if game.hud_status_panel != null:
		game.hud_status_panel.hide()
	game.world.queue_redraw()
	for _frame in 4:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("farm paths runtime capture=%s size=%s error=%s" % [OUTPUT, image.get_size(), error])
	quit(0 if error == OK else 1)
