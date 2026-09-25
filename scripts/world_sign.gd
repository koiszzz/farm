extends Node2D

var arrow := 1

func _draw() -> void:
	# Physical post and board, deliberately without world-space text.
	draw_ellipse_shadow()
	draw_rect(Rect2(-3, -27, 6, 29), Color("66452d"))
	draw_rect(Rect2(-1, -25, 2, 26), Color("b48348"))
	draw_rect(Rect2(-19, -36, 38, 19), Color("5b3c29"))
	draw_rect(Rect2(-17, -34, 34, 15), Color("c79450"))
	draw_line(Vector2(-16, -33), Vector2(16, -33), Color("e5ba72"), 2)
	var tip := Vector2(10 * arrow, -26)
	draw_line(Vector2(-10 * arrow, -26), tip, Color("59412d"), 3)
	draw_line(tip, tip + Vector2(-5 * arrow, -5), Color("59412d"), 3)
	draw_line(tip, tip + Vector2(-5 * arrow, 5), Color("59412d"), 3)
	for x in [-14, 14]: draw_rect(Rect2(x, -30, 2, 2), Color("71512f"))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.3))
	draw_circle(Vector2.ZERO, 13, Color(0.12, 0.16, 0.12, 0.22))
	draw_set_transform(Vector2.ZERO)
