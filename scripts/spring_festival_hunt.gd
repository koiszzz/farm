extends Node2D

const REQUIRED_FLOWERS := 6
const LIMIT_SECONDS := 60.0
const TOKEN_CELLS := [Vector2i(9, 13), Vector2i(16, 14), Vector2i(24, 10), Vector2i(27, 15), Vector2i(39, 13), Vector2i(24, 25)]

var game
var token_cells: Array[Vector2i] = []
var found_cells: Array[Vector2i] = []
var elapsed := 0.0
var active := false
var finished := false
var _hud: CanvasLayer
var _progress_label: Label
var _timer_label: Label
var _closing_timer: Timer


func _ready() -> void:
	z_index = 0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_hud()


func start() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(game.farm.day) * 1907 + 313
	token_cells.clear()
	for cell in TOKEN_CELLS:
		token_cells.append(cell)
	token_cells.shuffle()
	active = true
	finished = false
	elapsed = 0.0
	found_cells.clear()
	_refresh_hud()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not active or game == null or game.current_map_id != "town_square": return
	_collect_under_player()
	if not active: return
	elapsed += delta
	_refresh_hud()
	if elapsed >= LIMIT_SECONDS:
		_finish(found_cells.size() >= REQUIRED_FLOWERS)
	else:
		queue_redraw()


func _collect_under_player() -> void:
	var player_position: Vector2 = game.player_body.global_position
	for cell in token_cells:
		if cell in found_cells: continue
		var target: Vector2 = game.world.cell_center_to_screen(cell)
		if player_position.distance_to(target) <= 14.0:
			found_cells.append(cell)
			game.farm_audio.play("harvest")
			_refresh_hud()
			if found_cells.size() >= REQUIRED_FLOWERS:
				_finish(true)
			return


func cancel() -> void:
	if not active: return
	active = false
	finished = true
	if game != null:
		if game.festival_hunt == self: game.festival_hunt = null
		game._stop_player()
		game._set_status("寻花挑战已暂时离开；今天可以返回公告板重新开始。")
	queue_free()


func _finish(success: bool) -> void:
	if finished: return
	active = false
	finished = true
	var final_text := "找齐六朵！返回公告板领取春日会奖励。" if success else "时间到了，今天仍可回公告板再试一次。"
	_progress_label.text = final_text
	_timer_label.text = "挑战结束"
	if game != null:
		if game.festival_hunt == self: game.festival_hunt = null
		game._on_spring_hunt_finished(success, found_cells.size(), elapsed)
		game._stop_player()
	_closing_timer = Timer.new()
	_closing_timer.one_shot = true
	_closing_timer.wait_time = 2.8
	add_child(_closing_timer)
	_closing_timer.timeout.connect(queue_free)
	_closing_timer.start()


func _draw() -> void:
	if not active or game == null or game.world == null: return
	for cell in token_cells:
		if cell in found_cells: continue
		var center: Vector2 = game.world.cell_center_to_screen(cell) + Vector2(0, -5 - sin(elapsed * 4.0 + cell.x) * 1.5)
		draw_rect(Rect2(center + Vector2(-7, 7), Vector2(14, 4)), Color(0.18, 0.15, 0.09, 0.38))
		var glow := Color("fff1b2", 0.17 + sin(elapsed * 5.0 + cell.y) * 0.04)
		draw_rect(Rect2(center + Vector2(-10, -7), Vector2(20, 16)), glow)
		for petal in [Vector2(-7, -2), Vector2(-4, -7), Vector2(2, -7), Vector2(6, -2), Vector2(3, 3), Vector2(-4, 3)]:
			draw_rect(Rect2(center + petal, Vector2(5, 5)), Color("ef9ca2"))
		draw_rect(Rect2(center + Vector2(-2, -2), Vector2(5, 5)), Color("f7d779"))
		draw_rect(Rect2(center + Vector2(0, 5), Vector2(2, 7)), Color("66874c"))
		draw_rect(Rect2(center + Vector2(-6, 7), Vector2(5, 2)), Color("85a75d"))
		draw_rect(Rect2(center + Vector2(2, 8), Vector2(5, 2)), Color("85a75d"))
		draw_rect(Rect2(center + Vector2(-10, -10), Vector2(3, 3)), Color("fff1b2", 0.75))
		draw_rect(Rect2(center + Vector2(8, -7), Vector2(2, 2)), Color("fff1b2", 0.75))


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 20
	add_child(_hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 96)
	panel.custom_minimum_size = Vector2(318, 76)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f2e4c5", 0.97)
	style.border_color = Color("815a37")
	style.set_border_width_all(3)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	_hud.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 17)
	_progress_label.add_theme_color_override("font_color", Color("543c2e"))
	column.add_child(_progress_label)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 14)
	_timer_label.add_theme_color_override("font_color", Color("76583b"))
	column.add_child(_timer_label)
	_refresh_hud()


func _refresh_hud() -> void:
	if _progress_label == null: return
	if active:
		_progress_label.text = "春日寻花 · %d / %d" % [found_cells.size(), REQUIRED_FLOWERS]
		_timer_label.text = "还剩 %02d 秒 · WASD移动 / Shift跑步 · Esc离开" % ceili(maxf(0.0, LIMIT_SECONDS - elapsed))
