extends Control

const VALLEY_MAP_ART: Texture2D = preload("res://assets/art/runtime_generated/valley_map_v1.png")
const ValleyWorld = preload("res://scripts/valley_world_builder.gd")

var navigation: MapData
var map_id := ""
var current_map_id := ""
var player_cell := Vector2i.ZERO
var show_player := false
var player_position := Vector2(-1, -1)
var resident_positions: Array[Vector2] = []
var forage_positions: Array[Vector2] = []
var request_positions: Array[Vector2] = []

func _ready() -> void:
	custom_minimum_size = Vector2(680, 250 if map_id == "valley_world" else 245)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if navigation == null: return
	var frame_height := 240.0 if map_id == "valley_world" else 236.0
	draw_rect(Rect2(Vector2(8, 5), Vector2(652, frame_height)), Color("6d5036"))
	draw_rect(Rect2(Vector2(11, 8), Vector2(646, frame_height - 6.0)), Color("efe0bc"))
	draw_rect(Rect2(Vector2(15, 12), Vector2(638, frame_height - 14.0)), Color("b59664"), false, 2)
	if map_id == "valley_world":
		_draw_valley_overview()
		return
	var dimensions := navigation.get_map_size(map_id)
	var map_area := Rect2(Vector2(24, 34), Vector2(620, 170))
	var scale_factor := minf(map_area.size.x / dimensions.x, map_area.size.y / dimensions.y)
	var offset := map_area.position + (map_area.size - Vector2(dimensions) * scale_factor) * 0.5
	var colors := {"grass": Color("819b63"), "sand": Color("d6bc83"), "cave_floor": Color("69645c"), "path": Color("d7bd89"), "boardwalk": Color("9d7048"), "tillable": Color("977250"), "solid": Color("5d6457"), "water": Color("5f9eaa"), "interaction": Color("eacb79"), "exit": Color("cb8274")}
	for y in dimensions.y:
		for x in dimensions.x:
			var cell := Vector2i(x, y)
			draw_rect(Rect2(offset + Vector2(cell) * scale_factor, Vector2.ONE * scale_factor), colors.get(navigation.get_cell_class(map_id, cell), Color("8c9d67")))
	# Tiny illustrated accents make each paper map identifiable without adding
	# labels to the walkable world itself.
	if map_id == "beach":
		for x in range(4):
			var wave_y := offset.y + (25.0 + float(x % 2)) * scale_factor
			draw_line(Vector2(offset.x + 2 * scale_factor, wave_y), Vector2(offset.x + 53 * scale_factor, wave_y), Color("9ac9bf", 0.72), maxf(1.0, scale_factor * 0.16))
	elif map_id in ["cave", "mine_2", "mine_3"]:
		_draw_cave_ore_landmarks(offset, scale_factor)
	_draw_local_landmarks(offset, scale_factor, map_id)
	if show_player:
		var position := player_position if player_position.x >= 0.0 else Vector2(player_cell) + Vector2.ONE * 0.5
		_draw_player_marker(offset + position * scale_factor)
	for resident_position in resident_positions:
		_draw_resident_marker(offset + resident_position * scale_factor)
	for forage_position in forage_positions:
		_draw_forage_marker(offset + forage_position * scale_factor)
	for request_position in request_positions:
		_draw_request_marker(offset + request_position * scale_factor)
	if map_id == "valley_world":
		var landmarks := [[Vector2i(32, 42), "花溪镇"], [Vector2i(69, 38), "溪桥林道"], [Vector2i(116, 48), "农场"], [Vector2i(167, 18), "北湖"], [Vector2i(211, 43), "河畔"], [Vector2i(177, 95), "南湖"]]
		for landmark in landmarks:
			var point := offset + (Vector2(landmark[0]) + Vector2(1, 0)) * scale_factor
			var label_rect := Rect2(point - Vector2(26, 13), Vector2(86, 20))
			draw_rect(label_rect, Color("f6e7c8", 0.88))
			draw_string(ThemeDB.fallback_font, point, landmark[1], HORIZONTAL_ALIGNMENT_CENTER, 86, 13, Color("483b34"))
	var map_title: String = str({"farm_outdoor": "农场田园", "countryside": "郊区林道", "town_square": "花溪小镇", "beach": "风铃海岸", "cave": "青石洞窟", "mine_2": "矿洞 · 二层", "mine_3": "矿洞 · 三层", "riverside": "溪畔与湖岸"}.get(map_id, "花溪谷路线图"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 28), map_title, HORIZONTAL_ALIGNMENT_LEFT, 300, 16, Color("493829"))
	_draw_marker_legend()
	if map_id != "valley_world":
		_draw_exit_markers(offset, scale_factor, dimensions)
	draw_rect(Rect2(Vector2(24, 208), Vector2(12, 12)), Color("819b63"))
	draw_string(ThemeDB.fallback_font, Vector2(43, 219), "田野", HORIZONTAL_ALIGNMENT_LEFT, 60, 14, Color("483b34"))
	draw_rect(Rect2(Vector2(104, 208), Vector2(12, 12)), Color("5f9eaa"))
	draw_string(ThemeDB.fallback_font, Vector2(123, 219), "水域", HORIZONTAL_ALIGNMENT_LEFT, 60, 14, Color("483b34"))
	draw_rect(Rect2(Vector2(184, 208), Vector2(12, 12)), Color("d7bd89"))
	draw_string(ThemeDB.fallback_font, Vector2(203, 219), "道路", HORIZONTAL_ALIGNMENT_LEFT, 60, 14, Color("483b34"))


func _draw_local_landmarks(offset: Vector2, scale_factor: float, source_map: String) -> void:
	for entry in navigation.get_objects(source_map):
		var visual_rect: Array = entry.get("visual_rect", [])
		if visual_rect.size() < 4: continue
		var rect := Rect2(
		offset + Vector2(float(visual_rect[0]), float(visual_rect[1])) * scale_factor,
			Vector2(float(visual_rect[2]), float(visual_rect[3])) * scale_factor
		)
		if rect.size.x < 2.0 or rect.size.y < 2.0: continue
		var object_id := str(entry.get("id", ""))
		var atlas := str(entry.get("atlas", ""))
		var atlas_index: Array = entry.get("index", [])
		if atlas == "buildings" or atlas == "community_center":
			_draw_map_house(rect, object_id)
		elif object_id.contains("tree"):
			_draw_map_tree(rect)
		elif object_id.contains("fountain") or object_id.contains("tide_pool"):
			_draw_map_water_landmark(rect)
		elif object_id.contains("bench"):
			_draw_map_bench(rect)
		elif object_id.contains("lamp"):
			_draw_map_lamp(rect)
		elif object_id.contains("notice_board"):
			_draw_map_notice_board(rect)
		elif atlas == "beach_props" or atlas == "beach_collectibles":
			_draw_map_beach_prop(rect, object_id, atlas_index)
		elif object_id.contains("shipping_box") or object_id.contains("well"):
			_draw_map_farm_prop(rect, object_id)
		elif object_id.contains("bush") or object_id.contains("shrub"):
			_draw_map_bush(rect)


func _draw_map_house(rect: Rect2, landmark_id: String) -> void:
	var shadow := Rect2(rect.position + Vector2(1, rect.size.y * 0.83), Vector2(rect.size.x, rect.size.y * 0.12))
	draw_rect(shadow, Color("514435", 0.28))
	var body := Rect2(rect.position + Vector2(rect.size.x * 0.12, rect.size.y * 0.36), Vector2(rect.size.x * 0.76, rect.size.y * 0.57))
	draw_rect(body, Color("e7d4a7"))
	draw_rect(body, Color("79563c"), false, 1.0)
	var roof_color := Color("536a55")
	if landmark_id.contains("clinic"): roof_color = Color("7d8177")
	elif landmark_id.contains("cafe"): roof_color = Color("9b5844")
	elif landmark_id.contains("farmhouse"): roof_color = Color("527276")
	var roof := PackedVector2Array([
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.38),
		Vector2(rect.position.x + rect.size.x * 0.16, rect.position.y + rect.size.y * 0.12),
		Vector2(rect.position.x + rect.size.x * 0.84, rect.position.y + rect.size.y * 0.12),
		Vector2(rect.end.x, rect.position.y + rect.size.y * 0.38),
		Vector2(rect.position.x + rect.size.x * 0.83, rect.position.y + rect.size.y * 0.49),
		Vector2(rect.position.x + rect.size.x * 0.17, rect.position.y + rect.size.y * 0.49),
	])
	draw_colored_polygon(roof, roof_color)
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2], roof[3], roof[4], roof[5], roof[0]]), Color("49382d"), 1.0, true)
	var door := Rect2(Vector2(body.get_center().x - maxf(1.0, rect.size.x * 0.055), body.end.y - rect.size.y * 0.26), Vector2(maxf(2.0, rect.size.x * 0.11), rect.size.y * 0.26))
	draw_rect(door, Color("70482f"))
	var window_size := Vector2(maxf(2.0, rect.size.x * 0.11), maxf(2.0, rect.size.y * 0.11))
	for side in [-1.0, 1.0]:
		var window_position := Vector2(body.get_center().x + side * rect.size.x * 0.23 - window_size.x * 0.5, body.position.y + rect.size.y * 0.16)
		draw_rect(Rect2(window_position, window_size), Color("8bb3a8"))
		draw_rect(Rect2(window_position, window_size), Color("704d35"), false, 1.0)


func _draw_map_tree(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.63), Vector2(rect.size.x * 0.4, rect.size.y * 0.35)), Color("80583a"))
	var crown := PackedVector2Array([
		Vector2(rect.get_center().x, rect.position.y), Vector2(rect.end.x, rect.position.y + rect.size.y * 0.23),
		Vector2(rect.end.x - rect.size.x * 0.12, rect.position.y + rect.size.y * 0.78),
		Vector2(rect.position.x + rect.size.x * 0.12, rect.position.y + rect.size.y * 0.78),
		Vector2(rect.position.x, rect.position.y + rect.size.y * 0.23),
	])
	draw_colored_polygon(crown, Color("557846"))
	draw_rect(Rect2(rect.position + rect.size * Vector2(0.25, 0.25), rect.size * Vector2(0.2, 0.13)), Color("89a65d"))
	draw_rect(Rect2(rect.position + rect.size * Vector2(0.56, 0.48), rect.size * Vector2(0.16, 0.12)), Color("76964f"))


func _draw_map_bush(rect: Rect2) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.position.y + rect.size.y * 0.48),
		Vector2(rect.position.x + rect.size.x * 0.25, rect.position.y), rect.get_center(),
		Vector2(rect.end.x, rect.position.y + rect.size.y * 0.34), Vector2(rect.end.x, rect.end.y),
	]), Color("6b8c4e"))
	draw_rect(Rect2(rect.position + rect.size * Vector2(0.22, 0.48), rect.size * Vector2(0.19, 0.13)), Color("9ab66a"))


func _draw_map_water_landmark(rect: Rect2) -> void:
	draw_rect(rect.grow(1.0), Color("7c7658"))
	draw_rect(rect, Color("4f9eaa"))
	draw_line(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.3), rect.position + Vector2(rect.size.x * 0.64, rect.size.y * 0.3), Color("a8d3c1"), 1.0)
	draw_line(rect.position + Vector2(rect.size.x * 0.34, rect.size.y * 0.68), rect.position + Vector2(rect.size.x * 0.82, rect.size.y * 0.68), Color("8bc0b8"), 1.0)


func _draw_map_bench(rect: Rect2) -> void:
	var seat := Rect2(rect.position + Vector2(0, rect.size.y * 0.28), Vector2(rect.size.x, maxf(2.0, rect.size.y * 0.35)))
	draw_rect(seat, Color("a96d3e"))
	draw_rect(seat, Color("65452f"), false, 1.0)
	var leg_width := maxf(1.0, minf(2.0, rect.size.x * 0.16))
	var leg_height := maxf(1.0, minf(2.0, rect.size.y * 0.24))
	for leg_center_x in [0.18, 0.82]:
		var leg_x := rect.position.x + rect.size.x * float(leg_center_x) - leg_width * 0.5
		draw_rect(Rect2(Vector2(leg_x, rect.end.y - leg_height), Vector2(leg_width, leg_height)), Color("65452f"))


func _draw_map_lamp(rect: Rect2) -> void:
	# A light marker reads clearly at schematic scale; drawing its multi-tile
	# pole here can compete with the route and stretch into the legend.
	var lamp_point := Vector2(rect.get_center().x, rect.position.y + minf(3.0, rect.size.y * 0.25))
	draw_circle(lamp_point, 2.0, Color("e5b653"))
	draw_rect(Rect2(lamp_point - Vector2.ONE * 0.5, Vector2.ONE), Color("fff0b2"))


func _draw_cave_ore_landmarks(offset: Vector2, scale_factor: float) -> void:
	# Mine maps need the layered, mineral-rich read of a cave rather than a
	# single flat charcoal field. Keep each cluster small at local-map scale.
	var deposits := [
		{"cell": Vector2i(8, 7), "color": Color("a88459")},
		{"cell": Vector2i(26, 8), "color": Color("a97855")},
		{"cell": Vector2i(9, 18), "color": Color("8e7863")},
		{"cell": Vector2i(27, 19), "color": Color("b1945f")},
	]
	for deposit in deposits:
		var point: Vector2i = deposit["cell"]
		var center := offset + (Vector2(point) + Vector2.ONE * 0.5) * scale_factor
		var size := maxf(2.0, scale_factor * 0.42)
		var color: Color = deposit["color"]
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-size, 0), center + Vector2(-size * 0.25, -size * 0.72),
			center + Vector2(size * 0.8, -size * 0.35), center + Vector2(size, size * 0.45),
			center + Vector2(-size * 0.35, size * 0.75),
		]), color)
		draw_line(center + Vector2(-size * 0.2, -size * 0.35), center + Vector2(size * 0.24, -size * 0.12), Color("e1c592", 0.9), 1.0)


func _draw_map_notice_board(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.08, rect.size.y * 0.1), Vector2(rect.size.x * 0.84, rect.size.y * 0.56)), Color("a97543"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.2), Vector2(rect.size.x * 0.64, rect.size.y * 0.32)), Color("ead9af"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.18, rect.size.y * 0.66), Vector2(maxf(1.0, rect.size.x * 0.15), rect.size.y * 0.34)), Color("69472f"))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.67, rect.size.y * 0.66), Vector2(maxf(1.0, rect.size.x * 0.15), rect.size.y * 0.34)), Color("69472f"))


func _draw_map_farm_prop(rect: Rect2, landmark_id: String) -> void:
	if landmark_id.contains("well"):
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.12, rect.size.y * 0.38), Vector2(rect.size.x * 0.76, rect.size.y * 0.52)), Color("927654"))
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.23, rect.size.y * 0.46), Vector2(rect.size.x * 0.54, rect.size.y * 0.28)), Color("4c8992"))
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.19, rect.size.y * 0.23), Vector2(rect.size.x * 0.62, rect.size.y * 0.17)), Color("684c34"))
	else:
		draw_rect(rect, Color("8f5b32"))
		draw_rect(rect.grow(-maxf(1.0, minf(rect.size.x, rect.size.y) * 0.18)), Color("c58b48"))


func _draw_map_beach_prop(rect: Rect2, object_id: String, atlas_index: Array) -> void:
	if object_id.contains("fishing_hut"):
		_draw_map_house(rect, object_id)
	elif object_id.contains("pier"):
		draw_rect(rect, Color("875b38"))
		for plank in range(1, 4):
			var x := rect.position.x + rect.size.x * float(plank) / 4.0
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("d0a167"), 1.0)
	elif object_id.contains("grass") or object_id.contains("shrub") or object_id.contains("seagrass"):
		_draw_map_bush(rect)
	else:
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.55), Vector2(rect.size.x, rect.size.y * 0.3)), Color("94633b"))
		var shell_color := Color("e9d8b1") if atlas_index.size() > 1 and int(atlas_index[0]) != 1 else Color("d7ad71")
		draw_colored_polygon(PackedVector2Array([
			Vector2(rect.position.x, rect.position.y + rect.size.y * 0.6), Vector2(rect.position.x + rect.size.x * 0.28, rect.position.y + rect.size.y * 0.15),
			Vector2(rect.position.x + rect.size.x * 0.72, rect.position.y + rect.size.y * 0.15), Vector2(rect.end.x, rect.position.y + rect.size.y * 0.6),
		]), shell_color)


func _draw_exit_markers(offset: Vector2, scale_factor: float, dimensions: Vector2i) -> void:
	var color := Color("f7e5ae")
	for y in dimensions.y:
		for x in dimensions.x:
			if navigation.get_cell_class(map_id, Vector2i(x, y)) != "exit": continue
			var rect := Rect2(offset + Vector2(x, y) * scale_factor, Vector2.ONE * scale_factor)
			draw_rect(rect, color)


func _draw_valley_overview() -> void:
	var map_rect := Rect2(Vector2(73, 30), Vector2(520, 202))
	var valley_scale := map_rect.size / Vector2(ValleyWorld.SIZE)
	draw_texture_rect(VALLEY_MAP_ART, map_rect, false)
	draw_string(ThemeDB.fallback_font, Vector2(28, 28), "花溪谷旅行图", HORIZONTAL_ALIGNMENT_LEFT, 260, 16, Color("493829"))
	var tags := [
		{"id": "farm_outdoor", "label": "农场", "anchor": Vector2(0.13, 0.53), "width": 54.0},
		{"id": "countryside", "label": "郊区林地", "anchor": Vector2(0.49, 0.45), "width": 82.0},
		{"id": "town_square", "label": "花溪小镇", "anchor": Vector2(0.84, 0.52), "width": 82.0},
		{"id": "cave", "label": "青石山洞", "anchor": Vector2(0.51, 0.10), "width": 82.0},
		{"id": "beach", "label": "风铃沙滩", "anchor": Vector2(0.50, 0.88), "width": 82.0},
	]
	var active_region := _region_for_map(current_map_id)
	for entry in tags:
		var anchor: Vector2 = entry.anchor
		var center := map_rect.position + map_rect.size * anchor
		var tag_width := float(entry.width)
		var tag_rect := Rect2(center - Vector2(tag_width * 0.5, 8), Vector2(tag_width, 18))
		var is_current := str(entry.id) == active_region
		draw_rect(tag_rect.grow(1), Color("684b35", 0.78))
		draw_rect(tag_rect, Color("f5e8c9", 0.95))
		draw_rect(tag_rect, Color("b04b3b") if is_current else Color("846a4b"), false, 2 if is_current else 1)
		draw_string(ThemeDB.fallback_font, Vector2(tag_rect.position.x, tag_rect.end.y - 4), str(entry.label), HORIZONTAL_ALIGNMENT_CENTER, tag_rect.size.x, 12, Color("493829"))
		if is_current:
			var pin := Vector2(center.x, tag_rect.position.y - 8)
			draw_circle(pin, 6, Color("a94e43"))
			draw_circle(pin, 2, Color("fff0c5"))
	if show_player:
		var position := player_position if player_position.x >= 0.0 else Vector2(player_cell) + Vector2.ONE * 0.5
		_draw_player_marker(map_rect.position + position * valley_scale)
	for resident_position in resident_positions:
		_draw_resident_marker(map_rect.position + resident_position * valley_scale)
	for forage_position in forage_positions:
		_draw_forage_marker(map_rect.position + forage_position * valley_scale)
	for request_position in request_positions:
		_draw_request_marker(map_rect.position + request_position * valley_scale)
	_draw_marker_legend()


func _draw_player_marker(point: Vector2) -> void:
	draw_circle(point, 6.0, Color("fff0c5"))
	draw_circle(point, 4.1, Color("a94e43"))
	draw_circle(point, 1.4, Color("fff0c5"))


func _draw_resident_marker(point: Vector2) -> void:
	draw_circle(point, 3.6, Color("f2e7ce"))
	draw_circle(point, 2.4, Color("805c91"))
	draw_circle(point, 0.9, Color("493b53"))


func _draw_forage_marker(point: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		point + Vector2(0, -4), point + Vector2(3, -1), point + Vector2(0, 4), point + Vector2(-3, -1),
	]), Color("f1ce74"))
	draw_circle(point, 0.9, Color("6d8c4d"))


func _draw_request_marker(point: Vector2) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		var radius := 5.0 if index % 2 == 0 else 2.4
		points.append(point + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color("e7ae4e"))
	draw_colored_polygon(PackedVector2Array([
		point + Vector2(0, -2.2), point + Vector2(0.7, -0.6), point + Vector2(2.1, -0.4),
		point + Vector2(1.0, 0.6), point + Vector2(1.3, 2.0), point + Vector2(0, 1.2),
		point + Vector2(-1.3, 2.0), point + Vector2(-1.0, 0.6), point + Vector2(-2.1, -0.4),
		point + Vector2(-0.7, -0.6),
	]), Color("ffe9a6"))


func _draw_marker_legend() -> void:
	draw_circle(Vector2(459, 21), 4.5, Color("a94e43"))
	draw_circle(Vector2(459, 21), 1.4, Color("fff0c5"))
	draw_string(ThemeDB.fallback_font, Vector2(468, 25), "你", HORIZONTAL_ALIGNMENT_LEFT, 16, 12, Color("493829"))
	draw_circle(Vector2(497, 21), 3.2, Color("805c91"))
	draw_string(ThemeDB.fallback_font, Vector2(504, 25), "人", HORIZONTAL_ALIGNMENT_LEFT, 16, 12, Color("493829"))
	_draw_forage_marker(Vector2(535, 21))
	draw_string(ThemeDB.fallback_font, Vector2(542, 25), "采", HORIZONTAL_ALIGNMENT_LEFT, 16, 12, Color("493829"))
	_draw_request_marker(Vector2(572, 21))
	draw_string(ThemeDB.fallback_font, Vector2(579, 25), "委", HORIZONTAL_ALIGNMENT_LEFT, 16, 12, Color("493829"))


func _region_for_map(source_map: String) -> String:
	if source_map in ["farm_outdoor", "farmhouse_interior", "riverside"]: return "farm_outdoor"
	if source_map in ["countryside"]: return "countryside"
	if source_map in ["town_square", "general_store_interior", "clinic_interior", "cafe_interior"]: return "town_square"
	if source_map == "beach": return "beach"
	if source_map in ["cave", "mine_2", "mine_3"]: return "cave"
	return ""
