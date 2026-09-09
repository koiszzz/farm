extends Node2D

var avatar

func _draw() -> void:
	if avatar != null: avatar.draw_tools(self)
