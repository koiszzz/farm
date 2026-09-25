extends Node2D

## Lightweight, visual-only coastline motion. Navigation and collision remain in MapData.
const TILE_SIZE := 32.0
var _navigation: MapData
var _map_id := ""
var _segments: Array[Dictionary] = []
var _elapsed := 0.0
var _redraw_clock := 0.0


func configure(navigation: MapData, map_id: String, _origin: Vector2) -> void:
	_navigation = navigation
	_map_id = map_id
	position = _origin
	_segments.clear()
	_elapsed = 0.0
	_redraw_clock = 0.0
	if map_id == "beach" and navigation != null and navigation.has_map(map_id):
		var size := navigation.get_map_size(map_id)
		for y in range(size.y):
			for x in range(size.x):
				var water_cell := Vector2i(x, y)
				if navigation.get_cell_class(map_id, water_cell) != "water":
					continue
				for direction_value in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var direction: Vector2i = direction_value
					var shore_cell: Vector2i = water_cell + direction
					if navigation.is_in_bounds(map_id, shore_cell) and navigation.get_cell_class(map_id, shore_cell) == "water":
						continue
					_segments.append({"center": (Vector2(water_cell) + Vector2.ONE * 0.5) * TILE_SIZE, "normal": Vector2(direction), "seed": float(posmod(x * 17 + y * 31, 23)) / 23.0})
	queue_redraw()


func set_animation_active(active: bool) -> void:
	set_process(active and _map_id == "beach" and not _segments.is_empty())


func _process(delta: float) -> void:
	_elapsed += delta
	_redraw_clock += delta
	if _redraw_clock >= 0.12:
		_redraw_clock = 0.0
		queue_redraw()


func _draw() -> void:
	if _map_id != "beach":
		return
	for segment in _segments:
		var normal: Vector2 = segment.normal
		var tangent := normal.orthogonal()
		var seed: float = segment.seed
		var phase := _elapsed * 1.35 + seed * TAU
		var edge: Vector2 = segment.center + normal * 14.0
		var offset := sin(phase) * 2.0
		var alpha := 0.48 + (sin(phase * 0.72) + 1.0) * 0.18
		var foam := Color(0.82, 0.95, 0.86, alpha)
		var start := edge + tangent * (-11.0 + fposmod(_elapsed * 9.0 + seed * 18.0, 12.0)) + normal * offset
		var finish := start + tangent * 10.0
		draw_line(start, finish, foam, 3.0, false)
		var glint_phase := fposmod(_elapsed * 7.0 + seed * 20.0, 20.0) - 10.0
		var glint := edge + tangent * glint_phase + normal * (2.0 + offset * 0.45)
		draw_circle(glint, 2.0, Color(0.94, 0.98, 0.88, alpha))
