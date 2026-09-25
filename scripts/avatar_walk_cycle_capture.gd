extends SceneTree

const OUTPUT_PATH := "res://design/qa/2026-09-24/avatar-walk-v3/live-cycle.png"
const RUN_OUTPUT_PATH := "res://design/qa/2026-09-24/avatar-walk-v3/live-run-cycle.png"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1280, 1040)
	root.content_scale_size = Vector2i(1280, 1040)
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("d5d8bc")
	background.size = Vector2(1280, 1040)
	stage.add_child(background)
	var Avatar = preload("res://scripts/avatar_renderer.gd")
	var directions := ["down", "left", "right", "up"]
	var actors: Array[AvatarRenderer] = []
	for row in directions.size():
		var title := Label.new()
		title.text = directions[row]
		title.position = Vector2(12, 206 + row * 210)
		title.modulate = Color("35473f")
		stage.add_child(title)
		for column in 8:
			var actor = Avatar.new()
			actor.pixel_scale = 0.13
			actor.scale = Vector2.ONE * 1.8
			actor.position = Vector2(115 + column * 155, 100 + row * 210)
			actor.stride = float(column)
			actor.z_index = 1
			stage.add_child(actor)
			actor.set_pose(directions[row], "walk_a")
			actors.append(actor)
	DirAccess.make_dir_recursive_absolute("res://design/qa/2026-09-24/avatar-walk-v3")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	capture.save_png(OUTPUT_PATH)
	print("Captured walk atlas runtime frames: " + OUTPUT_PATH + " size=" + str(capture.get_size()))
	for actor in actors: actor.running = true
	await process_frame
	await RenderingServer.frame_post_draw
	var run_capture := root.get_texture().get_image()
	run_capture.save_png(RUN_OUTPUT_PATH)
	print("Captured run bob/lean frames: " + RUN_OUTPUT_PATH + " size=" + str(run_capture.get_size()))
	quit()
