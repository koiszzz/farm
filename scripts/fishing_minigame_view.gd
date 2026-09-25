extends Control

var active := false
var fish_name := ""
var fish_position := 0.5
var bar_center := 0.5
var bar_height := 0.3
var catch_progress := 0.0
var treasure_available := false
var treasure_position := 0.5
var treasure_progress := 0.0
var treasure_secured := false

const PAPER := Color("f4e8c8")
const INK := Color("493d31")
const TRACK := Color("324a3f")
const BAR := Color("92bd79")
const FISH := Color("f4cf6d")


func set_state(is_active: bool, current_name := "", fish_pos := 0.5, center := 0.5, height := 0.3, progress := 0.0, has_treasure := false, chest_pos := 0.5, chest_progress := 0.0, chest_secured := false) -> void:
	active = is_active
	fish_name = str(current_name)
	fish_position = clampf(float(fish_pos), 0.0, 1.0)
	bar_center = clampf(float(center), 0.0, 1.0)
	bar_height = clampf(float(height), 0.08, 0.55)
	catch_progress = clampf(float(progress), 0.0, 1.0)
	treasure_available = bool(has_treasure)
	treasure_position = clampf(float(chest_pos), 0.0, 1.0)
	treasure_progress = clampf(float(chest_progress), 0.0, 1.0)
	treasure_secured = bool(chest_secured)
	visible = active
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var viewport_size := get_viewport_rect().size
	var panel := Rect2(viewport_size.x - 246.0, viewport_size.y * 0.5 - 225.0, 188.0, 450.0)
	draw_rect(panel, PAPER)
	draw_rect(panel, INK, false, 4.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(15, 26), "垂钓", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(15, 50), fish_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	var track := Rect2(panel.position + Vector2(47, 67), Vector2(56, 330))
	draw_rect(track, TRACK)
	draw_rect(track, INK, false, 2.0)
	var bar_size := track.size.y * bar_height
	var bar_top := track.position.y + (1.0 - bar_center) * track.size.y - bar_size * 0.5
	draw_rect(Rect2(track.position + Vector2(3, bar_top - track.position.y), Vector2(track.size.x - 6, bar_size)), BAR)
	var fish_y := track.position.y + (1.0 - fish_position) * track.size.y
	var fish_x := track.position.x + 18.0
	draw_colored_polygon(PackedVector2Array([Vector2(fish_x, fish_y - 4), Vector2(fish_x + 14, fish_y - 4), Vector2(fish_x + 20, fish_y), Vector2(fish_x + 14, fish_y + 4), Vector2(fish_x, fish_y + 4), Vector2(fish_x - 6, fish_y)]), FISH)
	draw_circle(Vector2(fish_x + 15, fish_y - 1), 1.0, INK)
	if treasure_available or treasure_secured:
		var chest_y := track.position.y + (1.0 - treasure_position) * track.size.y
		var chest_x := track.position.x + 34.0
		var chest_color := Color("e2b84f") if treasure_secured else Color("bd8a3b")
		draw_rect(Rect2(Vector2(chest_x - 8, chest_y - 5), Vector2(16, 12)), chest_color)
		draw_rect(Rect2(Vector2(chest_x - 8, chest_y - 5), Vector2(16, 4)), Color("f2d178") if treasure_secured else Color("e0ad4b"))
		draw_rect(Rect2(Vector2(chest_x - 1, chest_y - 2), Vector2(3, 6)), INK)
		draw_rect(Rect2(Vector2(chest_x - 10, chest_y + 6), Vector2(20, 2)), INK)
	var meter := Rect2(panel.position + Vector2(116, 67), Vector2(20, 330))
	draw_rect(meter, Color("d6c8a6"))
	draw_rect(Rect2(meter.position.x, meter.end.y - meter.size.y * catch_progress, meter.size.x, meter.size.y * catch_progress), Color("78aa66"))
	draw_rect(meter, INK, false, 2.0)
	var treasure_active := treasure_available or treasure_secured
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(141, 63), "宝箱" if treasure_active else "—", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, INK)
	var chest_meter := Rect2(panel.position + Vector2(145, 67), Vector2(20, 330))
	draw_rect(chest_meter, Color("d6c8a6") if treasure_active else Color("d6c8a6", 0.48))
	var visible_chest_progress := 1.0 if treasure_secured else treasure_progress
	if visible_chest_progress > 0.0:
		draw_rect(Rect2(chest_meter.position.x, chest_meter.end.y - chest_meter.size.y * visible_chest_progress, chest_meter.size.x, chest_meter.size.y * visible_chest_progress), Color("dca94d"))
	if treasure_active: draw_rect(chest_meter, INK, false, 2.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(15, 426), "按住 E 追鱼并对准宝箱" if treasure_active and not treasure_secured else "按住 E 追鱼", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
