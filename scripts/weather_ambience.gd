extends CanvasLayer

var game
var paint := Node2D.new()
var elapsed := 0.0

func _ready() -> void:
	layer = 4
	add_child(paint)
	paint.draw.connect(_draw_weather)

func _process(delta: float) -> void:
	elapsed += delta
	paint.queue_redraw()

func _draw_weather() -> void:
	if game == null or game.farm == null: return
	var size: Vector2 = get_viewport().get_visible_rect().size
	if game.current_map_id.ends_with("_interior"):
		paint.draw_rect(Rect2(Vector2.ZERO, size), Color(0.55, 0.30, 0.10, 0.045))
		return
	var minutes: int = game.clock_minutes
	var night := clampf(float(minutes - 1080) / 240.0, 0, 1)
	if night > 0:
		paint.draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.17, 0.37, night * 0.48))
		for index in 14:
			var point := Vector2(fmod(index * 137.0 + sin(elapsed + index) * 20 + size.x, size.x), size.y * 0.4 + fmod(index * 71.0 + cos(elapsed * 0.4 + index) * 14, size.y * 0.5))
			paint.draw_rect(Rect2(point, Vector2(2, 2)), Color(0.94, 0.92, 0.51, night * (0.5 + sin(elapsed * 2 + index) * 0.4)))
	var weather: String = game.Calendar.weather(game.farm.day)
	if weather == "雨":
		paint.draw_rect(Rect2(Vector2.ZERO, size), Color(0.20, 0.29, 0.40, 0.13))
		for index in 90:
			var p := Vector2(fposmod(index * 97.0 - elapsed * 80, size.x), fposmod(index * 53.0 + elapsed * 330, size.y))
			paint.draw_line(p, p + Vector2(-4, 12), Color(0.73, 0.87, 0.91, 0.42), 1)
	elif weather == "雪":
		for index in 55:
			var p := Vector2(fposmod(index * 97.0 + sin(elapsed + index) * 12, size.x), fposmod(index * 53.0 + elapsed * 32, size.y))
			paint.draw_rect(Rect2(p, Vector2(3, 3)), Color(0.95, 0.98, 1, 0.8))
