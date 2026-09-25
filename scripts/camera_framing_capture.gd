extends SceneTree

const OUTPUT_DIR := "res://design/qa/2026-09-25/camera-2x"
const MAPS := ["farm_outdoor", "beach", "town_square", "cave", "countryside"]


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = false
	var token := str(Time.get_ticks_usec())
	game.save_path = "user://camera-framing-unused-%s.json" % token
	game.display_config_path = "user://camera-framing-unused-%s.cfg" % token
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1536, 864)
	await process_frame
	game.set_physics_process(false)
	game.creator.hide()
	if game.hud_status_panel != null: game.hud_status_panel.hide()
	if game.hud_context != null: game.hud_context.hide()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for map_id in MAPS:
		game._change_map(map_id, game.navigation.get_spawn(map_id))
		game._update_location()
		if game.hud_status_panel != null: game.hud_status_panel.hide()
		if game.hud_context != null: game.hud_context.hide()
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		var path := "%s/%s.png" % [OUTPUT_DIR, map_id]
		var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		if result != OK: push_error("Could not save camera frame: " + path)
		else: print("CAMERA_2X_CAPTURE %s zoom=%.2f" % [path, game.game_camera.zoom.x])
	game.queue_free()
	await process_frame
	quit()
