extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(1280,1400)
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("d5d8bc")
	background.size = Vector2(1280,1400)
	stage.add_child(background)
	var Avatar = preload("res://scripts/avatar_renderer.gd")
	var actions := ["walk_a", "hoe", "seed", "water", "harvest", "scythe", "gift", "fish"]
	for y in actions.size():
		var caption := Label.new()
		caption.text = actions[y]
		caption.position = Vector2(15,65 + y*160)
		caption.modulate = Color("35473f")
		stage.add_child(caption)
		for x in 4:
			var actor = Avatar.new()
			actor.pixel_scale = 0.13
			actor.scale = Vector2.ONE * 2
			actor.position = Vector2(200 + x*270, 105 + y*160)
			actor.z_index = 1
			stage.add_child(actor)
			actor.stride = 2.5
			actor.set_pose(["down","left","right","up"][x], actions[y])
			actor.action_progress = 0.55
	await snap("action_gallery")
	stage.queue_free()
	await process_frame
	stage = Node2D.new()
	root.add_child(stage)
	background = ColorRect.new()
	background.color = Color("d5d8bc")
	background.size = Vector2(1280,1400)
	stage.add_child(background)
	for x in 8:
		for y in 4:
			var actor = Avatar.new()
			actor.pixel_scale = 0.13
			actor.scale = Vector2.ONE * 2.3
			actor.position = Vector2(80+x*155,170+y*225)
			actor.z_index = 1
			stage.add_child(actor)
			actor.set_customization({"hair": Avatar.HAIR_IDS[x], "clothes": Avatar.CLOTHES_IDS[x]})
			actor.set_pose(["down","left","right","up"][y])
		var caption := Label.new()
		caption.text = Avatar.HAIR_IDS[x] + "\n" + Avatar.CLOTHES_IDS[x]
		caption.position = Vector2(22+x*155,30)
		caption.modulate = Color("35473f")
		stage.add_child(caption)
	await snap("appearance_gallery")
	quit()

func snap(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://design/qa/2026-09-06/"+label+".png")
	print("Captured " + label)
