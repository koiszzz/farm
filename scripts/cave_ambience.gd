extends Node2D

## Distinct ambient color and animated torch light for the active mine floor.
const TILE_SIZE := 32.0
const TORCH_CELLS := [Vector2i(3, 8), Vector2i(18, 8), Vector2i(32, 8), Vector2i(12, 15), Vector2i(23, 16)]
const FLOOR_ACCENTS := {
	"cave": Color("d89a50"),
	"mine_2": Color("80b7bd"),
	"mine_3": Color("b28acd"),
}
const FLOOR_AMBIENT := {
	"cave": Color("291b1b", 0.12),
	"mine_2": Color("14242b", 0.16),
	"mine_3": Color("22182f", 0.20),
}
var _map_id := ""
var _map_size := Vector2i.ZERO
var _elapsed := 0.0
var _redraw_clock := 0.0


func configure(map_id: String, origin: Vector2, map_size: Vector2i) -> void:
	_map_id = map_id
	_map_size = map_size
	position = origin
	_elapsed = 0.0
	_redraw_clock = 0.0
	queue_redraw()


func set_animation_active(active: bool) -> void:
	set_process(active and _map_id in FLOOR_ACCENTS)


func _process(delta: float) -> void:
	_elapsed += delta
	_redraw_clock += delta
	if _redraw_clock >= 0.10:
		_redraw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	var flame_color: Color = FLOOR_ACCENTS.get(_map_id, Color("d89a50"))
	if _map_id not in FLOOR_ACCENTS:
		return
	var ambient_tint: Color = FLOOR_AMBIENT.get(_map_id, Color.TRANSPARENT)
	draw_rect(Rect2(Vector2.ZERO, Vector2(_map_size) * TILE_SIZE), ambient_tint)
	for index in TORCH_CELLS.size():
		var cell: Vector2i = TORCH_CELLS[index]
		var phase := _elapsed * 4.1 + float(index) * 1.73
		var flicker := sin(phase) * 0.5 + cos(phase * 1.67) * 0.25
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE + Vector2(sin(phase * 0.6), 0)
		draw_circle(center + Vector2(0, 2), 39.0 + flicker * 3.5, Color(flame_color.r, flame_color.g, flame_color.b, 0.035))
		draw_circle(center + Vector2(0, 2), 27.0 + flicker * 2.5, Color(flame_color.r, flame_color.g, flame_color.b, 0.055))
		draw_circle(center + Vector2(0, 3), 17.0 + flicker * 2.0, Color(flame_color.r, flame_color.g, flame_color.b, 0.075))
		draw_circle(center, 8.0 + flicker, Color(flame_color.r, flame_color.g, flame_color.b, 0.13))
		draw_line(center + Vector2(0, 5), center + Vector2(0, 17), Color("765039"), 4)
		var half_width := 5.0 + flicker * 0.45
		var height := 13.0 + flicker * 1.2
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-half_width, 5),
			center + Vector2(0.8 + flicker, -height),
			center + Vector2(half_width, 4),
			center + Vector2(0, 9),
		]), flame_color)
		draw_circle(center + Vector2(0, 1), 2.5 + maxf(flicker, 0) * 0.5, Color("ffe7ae"))
