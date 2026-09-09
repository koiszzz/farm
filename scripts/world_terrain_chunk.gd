extends Node2D

var renderer
var cell_bounds := Rect2i()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	if renderer != null:
		renderer.draw_terrain_chunk(self, cell_bounds)
