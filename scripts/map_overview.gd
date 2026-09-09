extends Control

var navigation: MapData
var map_id := ""
var player_cell := Vector2i.ZERO
var show_player := false

func _ready() -> void:
	custom_minimum_size = Vector2(680, 350)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if navigation == null: return
	var dimensions := navigation.get_map_size(map_id)
	var scale_factor := minf(620.0 / dimensions.x, 310.0 / dimensions.y)
	var offset := Vector2(24, 12)
	var colors := {"grass": Color("8c9d67"), "path": Color("d7bd89"), "tillable": Color("977250"), "solid": Color("5d6457"), "water": Color("6caaac"), "interaction": Color("ecce83"), "exit": Color("cb8274")}
	for y in dimensions.y:
		for x in dimensions.x:
			var cell := Vector2i(x, y)
			draw_rect(Rect2(offset + Vector2(cell) * scale_factor, Vector2.ONE * scale_factor), colors.get(navigation.get_cell_class(map_id, cell), Color("8c9d67")))
	if show_player:
		var point := offset + (Vector2(player_cell) + Vector2.ONE * 0.5) * scale_factor
		draw_circle(point, 6, Color("fff1cb"))
		draw_circle(point, 3, Color("874a3c"))
	if map_id == "valley_world":
		var landmarks := [[Vector2i(32, 42), "花溪镇"], [Vector2i(69, 38), "溪桥林道"], [Vector2i(116, 48), "农场"], [Vector2i(167, 18), "北湖"], [Vector2i(211, 43), "河畔"], [Vector2i(177, 95), "南湖"]]
		for landmark in landmarks:
			var point := offset + Vector2(landmark[0]) * scale_factor
			draw_string(ThemeDB.fallback_font, point, landmark[1], HORIZONTAL_ALIGNMENT_CENTER, 70, 13, Color("483b34"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 342), "● 当前位置    金色：道路与设施    蓝色：河流湖泊    深绿：森林边界", HORIZONTAL_ALIGNMENT_LEFT, 640, 16, Color("483b34"))
