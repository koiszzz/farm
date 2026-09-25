extends SceneTree

const OUTPUT_DIR := "res://design/qa/2026-09-25/locomotion"
const DIRECTIONS := ["down", "left", "right", "up"]


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
	var actors: Array[AvatarRenderer] = []
	for row in DIRECTIONS.size():
		var title := Label.new()
		title.text = DIRECTIONS[row]
		title.position = Vector2(12, 206 + row * 210)
		title.modulate = Color("35473f")
		stage.add_child(title)
		for phase in 8:
			var actor = Avatar.new()
			actor.pixel_scale = 0.13
			actor.scale = Vector2.ONE * 1.8
			actor.position = Vector2(115 + phase * 155, 100 + row * 210)
			actor.stride = float(phase)
			actor.z_index = 1
			stage.add_child(actor)
			actor.set_pose(DIRECTIONS[row], "walk")
			actors.append(actor)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var walk_path := OUTPUT_DIR + "/fixed-anchor-walk.png"
	root.get_texture().get_image().save_png(walk_path)
	for actor in actors: actor.running = true
	await process_frame
	await RenderingServer.frame_post_draw
	var run_path := OUTPUT_DIR + "/fixed-anchor-run.png"
	root.get_texture().get_image().save_png(run_path)
	print("Captured fixed-anchor locomotion: " + walk_path + " and " + run_path)
	quit()
