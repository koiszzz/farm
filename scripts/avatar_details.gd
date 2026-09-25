extends Node2D

## Small selectable garment/hair details stay on the same foot-anchored rig.
## Base anatomy and action poses come from the authored raster sheets.
var avatar
var head := Vector2(0, -32)

func _draw() -> void:
	if avatar == null: return
	var data: Dictionary = avatar.customization
	var back: bool = avatar.facing == "up"
	var side: bool = avatar.facing in ["left", "right"]
	var facing_sign := -1.0 if avatar.facing == "left" else 1.0
	var cloth := Color.html({"overalls": "285d73", "gardener": "648445", "cozy": "a76468", "traveler": "826a47", "apron": "c9a679", "raincoat": "ddb141", "worker": "526577", "formal": "484157"}.get(data.clothes, "285d73"))
	var torso := Vector2(head.x, head.y + 12)
	var trim := cloth.lightened(0.28)
	match str(data.clothes):
		"cozy":
			draw_colored_polygon(PackedVector2Array([torso+Vector2(-4,-4),torso+Vector2(4,-4),torso+Vector2(6,4),torso+Vector2(4,7),torso+Vector2(-4,7),torso+Vector2(-6,4)]), cloth.darkened(0.1))
			draw_line(torso + Vector2(-3,-2), torso + Vector2(3,-2), trim, 1)
			draw_line(torso + Vector2(-6,7), torso + Vector2(6,7), trim, 2)
		"traveler":
			if back:
				draw_colored_polygon(PackedVector2Array([torso+Vector2(-3,-4),torso+Vector2(3,-4),torso+Vector2(5,-2),torso+Vector2(5,6),torso+Vector2(3,8),torso+Vector2(-3,8),torso+Vector2(-5,6),torso+Vector2(-5,-2)]), Color("70513b"))
				draw_rect(Rect2(torso + Vector2(-3,-3), Vector2(6,3)), Color("b48c58"))
				draw_line(torso + Vector2(0,-2), torso + Vector2(0,7), Color("e1c397"), 2)
			else: draw_line(torso + Vector2(-6,-4), torso + Vector2(6,8), Color("b48c58"), 2)
		"apron":
			if back:
				draw_line(torso + Vector2(-6,-5), torso + Vector2(5,6), trim, 2)
				draw_line(torso + Vector2(6,-5), torso + Vector2(-5,6), trim, 2)
				draw_line(torso + Vector2(-5,6), torso + Vector2(5,6), Color("f0d9b5"), 2)
			else:
				draw_colored_polygon(PackedVector2Array([torso+Vector2(-3,-4),torso+Vector2(3,-4),torso+Vector2(6,8),torso+Vector2(4,10),torso+Vector2(-4,10),torso+Vector2(-6,8)]), Color("c8b68e"))
				draw_line(torso+Vector2(-3,9),torso+Vector2(3,9),Color("e0d1ab"),1)
				draw_rect(Rect2(torso + Vector2(-3,3), Vector2(6,4)), Color("b9a47f"))
		"raincoat":
			draw_colored_polygon(PackedVector2Array([torso+Vector2(-4,-4),torso+Vector2(4,-4),torso+Vector2(6,7),torso+Vector2(4,10),torso+Vector2(-4,10),torso+Vector2(-6,7)]), cloth.darkened(0.12))
			draw_line(torso+Vector2(4,0),torso+Vector2(5,8),cloth.darkened(0.32),2)
			if back: draw_arc(torso + Vector2(0,-5), 6, 0, PI, 10, trim, 3)
			else: draw_line(torso + Vector2(0,-4), torso + Vector2(0,11), trim, 1)
		"worker":
			draw_line(torso + Vector2(-6,2), torso + Vector2(6,2), Color("c5b36d"), 2)
		"formal":
			draw_rect(Rect2(torso + Vector2(-6,-4), Vector2(12,11)), cloth)
			if not back:
				draw_colored_polygon(PackedVector2Array([torso+Vector2(-4,-4),torso+Vector2(4,-4),torso+Vector2(0,3)]), Color("ebdfc5"))
				draw_line(torso + Vector2(-3,-2), torso + Vector2(3,-2), Color("76565c"), 2)
		"gardener":
			draw_line(torso + Vector2(-6,7), torso + Vector2(6,7), Color("80613d"), 3)
	var hair: Color = avatar._palette_color("hair_color", str(data.hair_color))
	var dark := hair.darkened(0.50)
	var bounce := _walking_bounce()
	var tail := head + Vector2((-7 if avatar.facing == "right" else 7) if side else 0, 4)
	match str(data.hair):
		"long":
			if back:
				draw_colored_polygon(PackedVector2Array([head+Vector2(-7,1),head+Vector2(7,1),head+Vector2(7,10),head+Vector2(4,15),head+Vector2(-3,14),head+Vector2(-7,10)]), dark)
				draw_line(head + Vector2(-3,3), head + Vector2(-2,12), hair.darkened(0.20), 1)
				draw_line(head + Vector2(3,3), head + Vector2(3,12), hair.darkened(0.25), 1)
			else:
				for x in [-7,7]: draw_line(head + Vector2(x,2), head + Vector2(x+bounce,11), dark, 3)
		"ponytail", "braid":
			if back or side:
				for index in 5:
					var point := tail + Vector2(bounce * index / 4 + (index % 2 if data.hair == "braid" else 0), index * 2.5)
					draw_circle(point, 2.5 - index * 0.25, dark)
					draw_circle(point + Vector2(-0.5,-0.5), 1.3, hair.darkened(0.2))
				draw_rect(Rect2(tail + Vector2(-2,2), Vector2(5,2)), Color("b96d68"))
		"bun":
			draw_circle(head + Vector2(0,-6), 3, dark)
			draw_circle(head + Vector2(-0.5,-6.5), 2, hair.darkened(0.2))
		"curly":
			for index in 7:
				var angle := PI + index * PI / 6
				var point := head + Vector2(cos(angle)*7, sin(angle)*6)
				draw_circle(point, 2, dark)
				draw_circle(point + Vector2(-0.5,-0.5), 1, hair.darkened(0.2))
		"spiky":
			for index in 5:
				var point := head + Vector2(index * 4 - 8, -5)
				draw_colored_polygon(PackedVector2Array([point+Vector2(-3,0),point+Vector2(0,-6),point+Vector2(3,0)]), hair)
		"side_part":
			if not back: draw_line(head + Vector2(-6*facing_sign,-5), head + Vector2(4*facing_sign,0), dark, 3)


func _walking_bounce() -> float:
	if avatar == null or avatar.action not in ["walk_a", "walk_b", "walk", "run"]:
		return 0.0
	var amplitude := 2.0 if avatar.action == "run" else 1.5
	return sin(avatar.stride * PI / 4.0) * amplitude
