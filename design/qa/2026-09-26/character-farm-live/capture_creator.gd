extends SceneTree

const CreatorScript = preload("res://scripts/character_creator.gd")


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var creator = CreatorScript.new()
	root.add_child(creator)
	creator.open_new_game()
	for i in 6:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	image.save_png("res://design/qa/2026-09-26/character-farm-live/creator-redesign.png")
	quit()
