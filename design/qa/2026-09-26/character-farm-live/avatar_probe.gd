extends SceneTree

const Avatar = preload("res://scripts/avatar_renderer.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var avatar = Avatar.new()
	avatar.pixel_scale = 0.52
	root.add_child(avatar)
	await process_frame
	for direction in ["down", "left", "right", "up"]:
		avatar.set_pose(direction, "idle")
		await process_frame
		print("PROBE %s region=%s body_pos=%s body_scale=%s detail_scale=%s detail_head=%s" % [direction, avatar._body.region_rect, avatar._body.position, avatar._body.scale, avatar._details.scale, avatar._details.head])
	avatar.queue_free()
	quit()
