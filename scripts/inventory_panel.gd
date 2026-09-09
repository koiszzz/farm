class_name InventoryPanel
extends CanvasLayer

signal layout_changed

var game
var backdrop: ColorRect
var panel: PanelContainer
var backpack_grid: GridContainer
var hotbar_grid: GridContainer
var detail_card: PanelContainer
var detail_title: Label
var detail_text: Label
var hover_card: PanelContainer
var hover_label: Label
var capacity_label: Label
var held_label: Label
var cursor_area := "backpack"
var cursor_index := 0
var hovered_area := ""
var hovered_index := -1
var held_area := ""
var held_index := -1


func _ready() -> void:
	layer = 25
	backdrop = ColorRect.new()
	backdrop.color = Color(0.06, 0.09, 0.12, 0.72)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -570
	panel.offset_right = 570
	panel.offset_top = -330
	panel.offset_bottom = 330
	panel.add_theme_stylebox_override("panel", _panel_style(Color("fff1cf"), Color("79502f"), 4, 14))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var heading := Label.new()
	heading.text = "农场背包"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("493526"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(heading)
	capacity_label = Label.new()
	capacity_label.add_theme_font_size_override("font_size", 18)
	capacity_label.add_theme_color_override("font_color", Color("765033"))
	title_row.add_child(capacity_label)
	var expand_button := Button.new()
	expand_button.text = "+ 扩展 5 格"
	expand_button.custom_minimum_size = Vector2(126, 38)
	expand_button.pressed.connect(_expand)
	title_row.add_child(expand_button)
	var hint := Label.new()
	hint.text = "左键拿起/放下或交换 · 背包物品点选后再点快捷栏即可设置 · 快捷栏右键清空 · 方向键移动选择符 · I 查看说明"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("755b46"))
	column.add_child(hint)
	var hotbar_title := Label.new()
	hotbar_title.text = "快捷物品栏 · 游戏中按 1–9 / 0 直接使用"
	hotbar_title.add_theme_font_size_override("font_size", 19)
	hotbar_title.add_theme_color_override("font_color", Color("493526"))
	column.add_child(hotbar_title)
	hotbar_grid = GridContainer.new()
	hotbar_grid.columns = 10
	hotbar_grid.add_theme_constant_override("h_separation", 5)
	column.add_child(hotbar_grid)
	var separator := HSeparator.new()
	column.add_child(separator)
	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 14)
	column.add_child(content_row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 720
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(scroll)
	backpack_grid = GridContainer.new()
	backpack_grid.columns = 5
	backpack_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_grid.add_theme_constant_override("h_separation", 7)
	backpack_grid.add_theme_constant_override("v_separation", 7)
	scroll.add_child(backpack_grid)
	detail_card = PanelContainer.new()
	detail_card.custom_minimum_size = Vector2(300, 0)
	detail_card.size_flags_horizontal = Control.SIZE_SHRINK_END
	detail_card.add_theme_stylebox_override("panel", _panel_style(Color("f2ddb0"), Color("b17a43"), 2, 9))
	content_row.add_child(detail_card)
	var detail_column := VBoxContainer.new()
	detail_column.add_theme_constant_override("separation", 10)
	detail_card.add_child(detail_column)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_title.add_theme_color_override("font_color", Color("493526"))
	detail_column.add_child(detail_title)
	detail_text = Label.new()
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_text.add_theme_font_size_override("font_size", 17)
	detail_text.add_theme_color_override("font_color", Color("684b35"))
	detail_column.add_child(detail_text)
	detail_card.hide()
	var bottom := HBoxContainer.new()
	column.add_child(bottom)
	held_label = Label.new()
	held_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	held_label.add_theme_color_override("font_color", Color("8a5333"))
	bottom.add_child(held_label)
	var close_button := Button.new()
	close_button.text = "返回游戏 · Esc"
	close_button.custom_minimum_size = Vector2(150, 38)
	close_button.pressed.connect(close)
	bottom.add_child(close_button)
	hover_card = PanelContainer.new()
	hover_card.custom_minimum_size = Vector2(190, 54)
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.z_index = 30
	hover_card.add_theme_stylebox_override("panel", _panel_style(Color("493526", 0.97), Color("efbd6e"), 2, 7))
	add_child(hover_card)
	hover_label = Label.new()
	hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hover_label.add_theme_font_size_override("font_size", 16)
	hover_label.add_theme_color_override("font_color", Color("fff1cf"))
	hover_card.add_child(hover_label)
	hover_card.hide()
	hide()


func open(owner) -> void:
	game = owner
	held_area = ""
	held_index = -1
	hovered_area = ""
	hovered_index = -1
	detail_card.hide()
	show()
	refresh()


func close() -> void:
	hide()
	hover_card.hide()
	held_area = ""
	held_index = -1


func refresh() -> void:
	if game == null: return
	_clear(backpack_grid)
	_clear(hotbar_grid)
	capacity_label.text = "%d 格" % game.inventory_state.capacity
	for index in game.inventory_state.hotbar.size():
		hotbar_grid.add_child(_slot_button("hotbar", index, str(game.inventory_state.hotbar[index]), Vector2(96, 68)))
	for index in game.inventory_state.backpack.size():
		backpack_grid.add_child(_slot_button("backpack", index, str(game.inventory_state.backpack[index]), Vector2(136, 64)))
	_update_held_label()
	call_deferred("_refresh_hover_info")


func handle_key(event: InputEventKey) -> void:
	if not visible or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ESCAPE:
			if detail_card.visible:
				detail_card.hide()
				call_deferred("_refresh_hover_info")
			else: close()
		KEY_I: _toggle_detail()
		KEY_TAB:
			cursor_area = "hotbar" if cursor_area == "backpack" else "backpack"
			cursor_index = clampi(cursor_index, 0, _area_size(cursor_area) - 1)
			refresh()
		KEY_LEFT: _move_cursor(Vector2i.LEFT)
		KEY_RIGHT: _move_cursor(Vector2i.RIGHT)
		KEY_UP: _move_cursor(Vector2i.UP)
		KEY_DOWN: _move_cursor(Vector2i.DOWN)
		KEY_ENTER, KEY_SPACE: _slot_clicked(cursor_area, cursor_index)


func _slot_button(area: String, index: int, item_key: String, minimum: Vector2) -> Button:
	var button := Button.new()
	button.custom_minimum_size = minimum
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.text = _slot_text(area, index, item_key)
	var selected := area == cursor_area and index == cursor_index
	var holding := area == held_area and index == held_index
	var base_color := Color("e8c991") if area == "backpack" else Color("ddbd7f")
	var border := Color("e1883d") if selected else Color("785033")
	if holding: border = Color("d84f45")
	button.add_theme_stylebox_override("normal", _panel_style(base_color, border, 3 if selected or holding else 2, 5))
	button.add_theme_stylebox_override("hover", _panel_style(Color("ffe5a6"), Color("e1883d"), 3, 5))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("f8d486"), Color("c65f32"), 3, 5))
	button.add_theme_color_override("font_color", Color("503824"))
	button.add_theme_color_override("font_hover_color", Color("503824"))
	button.add_theme_color_override("font_pressed_color", Color("503824"))
	button.add_theme_font_size_override("font_size", 22 if area == "backpack" else 16)
	button.add_theme_constant_override("icon_max_width", 38)
	var meta: Dictionary = game._inventory_items().get(item_key, {})
	if meta.get("icon") is Texture2D:
		button.icon = meta.icon
		button.expand_icon = true
	button.mouse_entered.connect(_hover.bind(area, index))
	button.mouse_exited.connect(_unhover.bind(area, index))
	button.gui_input.connect(_slot_input.bind(area, index))
	button.pressed.connect(_slot_clicked.bind(area, index))
	return button


func _slot_text(area: String, index: int, item_key: String) -> String:
	var prefix := "%d" % (index + 1 if index < 9 else 0) if area == "hotbar" else ""
	if item_key.is_empty(): return prefix
	var meta: Dictionary = game._inventory_items().get(item_key, {})
	if meta.get("icon") is Texture2D: return prefix
	var symbol := _item_symbol(meta)
	return prefix + ("\n" if area == "hotbar" and not symbol.is_empty() else "") + symbol


func _slot_input(event: InputEvent, area: String, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cursor_area = area
		cursor_index = index
		if area == "hotbar":
			game.inventory_state.clear_hotbar(index)
			_layout_changed()
		else:
			refresh()
		get_viewport().set_input_as_handled()


func _slot_clicked(area: String, index: int) -> void:
	cursor_area = area
	cursor_index = index
	if held_area.is_empty():
		var item_key := _item_at(area, index)
		if item_key.is_empty():
			refresh()
			return
		held_area = area
		held_index = index
		refresh()
		return
	if held_area == "backpack" and area == "backpack":
		game.inventory_state.move_backpack(held_index, index)
	elif held_area == "backpack" and area == "hotbar":
		game.inventory_state.assign_hotbar(str(game.inventory_state.backpack[held_index]), index)
	elif held_area == "hotbar" and area == "hotbar":
		game.inventory_state.swap_hotbar(held_index, index)
	elif held_area == "hotbar" and area == "backpack":
		var key := str(game.inventory_state.hotbar[held_index])
		var source: int = game.inventory_state.backpack.find(key)
		if source >= 0: game.inventory_state.move_backpack(source, index)
	held_area = ""
	held_index = -1
	_layout_changed()


func _hover(area: String, index: int) -> void:
	hovered_area = area
	hovered_index = index
	call_deferred("_refresh_hover_info")


func _unhover(area: String, index: int) -> void:
	if hovered_area == area and hovered_index == index:
		hovered_area = ""
		hovered_index = -1
		call_deferred("_refresh_hover_info")


func _toggle_detail() -> void:
	if detail_card.visible:
		detail_card.hide()
		call_deferred("_refresh_hover_info")
		return
	var area := hovered_area if not hovered_area.is_empty() else cursor_area
	var index := hovered_index if not hovered_area.is_empty() else cursor_index
	var item_key := _item_at(area, index)
	if item_key.is_empty(): return
	var meta: Dictionary = game._inventory_items().get(item_key, {})
	if meta.is_empty(): return
	detail_title.text = str(meta.get("name", item_key))
	detail_text.text = "%s\n\n数量：%d\n类型：%s" % [str(meta.get("description", "暂无说明。")), int(meta.get("count", 1)), str(meta.get("type_label", "普通物品"))]
	detail_card.show()
	hover_card.hide()


func _move_cursor(direction: Vector2i) -> void:
	var columns := 10 if cursor_area == "hotbar" else 5
	var next := cursor_index + direction.x + direction.y * columns
	cursor_index = clampi(next, 0, _area_size(cursor_area) - 1)
	refresh()


func _expand() -> void:
	game.inventory_state.expand()
	_layout_changed()


func _layout_changed() -> void:
	refresh()
	layout_changed.emit()


func _item_at(area: String, index: int) -> String:
	var source: Array = game.inventory_state.hotbar if area == "hotbar" else game.inventory_state.backpack
	return str(source[index]) if index >= 0 and index < source.size() else ""


func _area_size(area: String) -> int:
	return game.inventory_state.hotbar.size() if area == "hotbar" else game.inventory_state.backpack.size()


func _update_held_label() -> void:
	if held_area.is_empty():
		held_label.text = ""
		return
	var key := _item_at(held_area, held_index)
	var meta: Dictionary = game._inventory_items().get(key, {})
	held_label.text = "已拿起：%s · 再点一个格子放下" % str(meta.get("name", key))


func _refresh_hover_info() -> void:
	if not visible or detail_card.visible or game == null:
		hover_card.hide()
		return
	var area := hovered_area if not hovered_area.is_empty() else cursor_area
	var index := hovered_index if not hovered_area.is_empty() else cursor_index
	var item_key := _item_at(area, index)
	if item_key.is_empty():
		hover_card.hide()
		return
	var meta: Dictionary = game._inventory_items().get(item_key, {})
	if meta.is_empty():
		hover_card.hide()
		return
	var count := int(meta.get("count", 1))
	hover_label.text = "%s%s\n%s · 按 I 查看说明" % [str(meta.get("name", item_key)), " ×%d" % count if count > 1 else "", str(meta.get("type_label", "普通物品"))]
	var grid := hotbar_grid if area == "hotbar" else backpack_grid
	if index < 0 or index >= grid.get_child_count():
		hover_card.hide()
		return
	var slot: Control = grid.get_child(index)
	var rect := slot.get_global_rect()
	var viewport_size := get_viewport().get_visible_rect().size
	var x := rect.end.x + 8.0
	if x + 230.0 > viewport_size.x: x = rect.position.x - 238.0
	hover_card.position = Vector2(clampf(x, 8.0, viewport_size.x - 238.0), clampf(rect.position.y, 8.0, viewport_size.y - 74.0))
	hover_card.show()


func _item_symbol(meta: Dictionary) -> String:
	var key := str(meta.get("tool_id", meta.get("name", "")))
	return {"scythe": "◒", "fish": "◇", "木材": "▤", "石料": "◆", "野莓": "●", "蘑菇": "♠", "溪鱼": "◇"}.get(key, "◆")


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(7)
	return style
