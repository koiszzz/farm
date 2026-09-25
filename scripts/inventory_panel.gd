class_name InventoryPanel
extends CanvasLayer

const UISkin = preload("res://scripts/farm_ui_skin.gd")

signal layout_changed

var game
var backdrop: ColorRect
var panel: PanelContainer
var backpack_grid: GridContainer
var hotbar_grid: GridContainer
var detail_card: PanelContainer
var detail_title: Label
var detail_text: Label
var detail_icon: TextureRect
var capacity_label: Label
var held_label: Label
var journal_status: Label
var cursor_area := "backpack"
var cursor_index := 0
var hovered_area := ""
var hovered_index := -1
var held_area := ""
var held_index := -1
var detail_expanded := false


func _ready() -> void:
	layer = 25
	backdrop = ColorRect.new()
	backdrop.color = Color(0.10, 0.13, 0.12, 0.78)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -570
	panel.offset_right = 570
	panel.offset_top = -330
	panel.offset_bottom = 330
	panel.add_theme_stylebox_override("panel", UISkin.frame())
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title_row := HBoxContainer.new()
	var title_band := PanelContainer.new()
	title_band.custom_minimum_size.y = 40
	title_band.add_theme_stylebox_override("panel", UISkin.header())
	column.add_child(title_band)
	title_band.add_child(title_row)
	var heading := Label.new()
	heading.text = "农场背包"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("fff0c7"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(heading)
	var chapter_mark := Label.new()
	chapter_mark.text = "  ✿  花溪旅行手册  ✿  "
	chapter_mark.add_theme_font_size_override("font_size", 15)
	chapter_mark.add_theme_color_override("font_color", Color("eacb91"))
	title_row.add_child(chapter_mark)
	journal_status = Label.new()
	journal_status.add_theme_font_size_override("font_size", 16)
	journal_status.add_theme_color_override("font_color", Color("f1d9a7"))
	title_row.add_child(journal_status)
	capacity_label = Label.new()
	capacity_label.add_theme_font_size_override("font_size", 18)
	capacity_label.add_theme_color_override("font_color", Color("f1d9a7"))
	title_row.add_child(capacity_label)
	var expand_button := Button.new()
	expand_button.text = "+ 扩展 5 格"
	expand_button.custom_minimum_size = Vector2(126, 38)
	expand_button.pressed.connect(_expand)
	title_row.add_child(expand_button)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 5)
	column.add_child(tab_row)
	var tabs := [["行囊", "inventory"], ["角色", "character"], ["地图", "map"], ["技能", "skills"], ["居民", "people"], ["设置", "settings"]]
	for tab_index in tabs.size():
		var tab: Array = tabs[tab_index]
		var tab_button := Button.new()
		tab_button.text = str(tab[0])
		tab_button.custom_minimum_size = Vector2(104, 34)
		tab_button.focus_mode = Control.FOCUS_NONE
		var is_current_tab: bool = tab_index == 0
		tab_button.add_theme_stylebox_override("normal", _panel_style(Color("c99553") if is_current_tab else Color("e5d2a8"), Color("71452c") if is_current_tab else Color("9a794b"), 3 if is_current_tab else 2, 0))
		tab_button.add_theme_stylebox_override("hover", _panel_style(Color("f6e6bf"), Color("c0823e"), 2, 0))
		tab_button.add_theme_color_override("font_color", Color("533c28"))
		tab_button.pressed.connect(_navigate_tab.bind(str(tab[1])))
		tab_row.add_child(tab_button)
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
	backpack_grid.columns = 7
	backpack_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_grid.add_theme_constant_override("h_separation", 7)
	backpack_grid.add_theme_constant_override("v_separation", 7)
	scroll.add_child(backpack_grid)
	detail_card = PanelContainer.new()
	detail_card.custom_minimum_size = Vector2(250, 0)
	detail_card.size_flags_horizontal = Control.SIZE_SHRINK_END
	detail_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_card.add_theme_stylebox_override("panel", UISkin.card(Color("f2ddb0"), Color("bd9250")))
	content_row.add_child(detail_card)
	var detail_column := VBoxContainer.new()
	detail_column.add_theme_constant_override("separation", 10)
	detail_card.add_child(detail_column)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_title.add_theme_color_override("font_color", Color("493526"))
	detail_column.add_child(detail_title)
	detail_icon = TextureRect.new()
	detail_icon.custom_minimum_size = Vector2(76, 76)
	detail_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	detail_column.add_child(detail_icon)
	detail_text = Label.new()
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_text.add_theme_font_size_override("font_size", 17)
	detail_text.add_theme_color_override("font_color", Color("684b35"))
	detail_column.add_child(detail_text)
	detail_title.text = "物品说明"
	detail_text.text = "选择或悬停物品查看用途、数量与价值。\n\n按 I 展开完整说明。"
	detail_card.show()
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
	hide()


func open(owner) -> void:
	game = owner
	held_area = ""
	held_index = -1
	detail_expanded = false
	hovered_area = ""
	hovered_index = -1
	show()
	refresh()


func close() -> void:
	hide()
	detail_expanded = false
	held_area = ""
	held_index = -1


func refresh() -> void:
	if game == null: return
	_clear(backpack_grid)
	_clear(hotbar_grid)
	capacity_label.text = "%d 格" % game.inventory_state.capacity
	journal_status.text = "第 %d 天  ·  %d 金" % [game.farm.day, game.farm.gold]
	for index in game.inventory_state.hotbar.size():
		hotbar_grid.add_child(_slot_button("hotbar", index, str(game.inventory_state.hotbar[index]), Vector2(96, 60)))
	for index in game.inventory_state.backpack.size():
		backpack_grid.add_child(_slot_button("backpack", index, str(game.inventory_state.backpack[index]), Vector2(98, 64)))
	_update_held_label()
	call_deferred("_refresh_hover_info")


func _navigate_tab(tab: String) -> void:
	var owner = game
	close()
	match tab:
		"character": owner._open_character_card()
		"map": owner._open_world_map()
		"skills": owner._open_skills()
		"people": owner._open_people()
		"settings": owner._open_display_settings()
		_: owner._open_inventory()


func handle_key(event: InputEventKey) -> void:
	if not visible or not event.pressed or event.echo: return
	match event.keycode:
		KEY_ESCAPE:
			if detail_expanded:
				detail_expanded = false
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
	var stack_count := int(meta.get("count", 1))
	if not item_key.is_empty() and stack_count > 1:
		var count_label := Label.new()
		count_label.name = "StackCount"
		count_label.text = str(stack_count)
		count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		count_label.offset_left = -31
		count_label.offset_top = -20
		count_label.offset_right = -4
		count_label.offset_bottom = -2
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count_label.add_theme_font_size_override("font_size", 13 if area == "backpack" else 12)
		count_label.add_theme_color_override("font_color", Color("30261b"))
		count_label.add_theme_color_override("font_outline_color", Color("fff0ca"))
		count_label.add_theme_constant_override("outline_size", 2)
		button.add_child(count_label)
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
	var area := hovered_area if not hovered_area.is_empty() else cursor_area
	var index := hovered_index if not hovered_area.is_empty() else cursor_index
	var item_key := _item_at(area, index)
	if item_key.is_empty(): return
	var meta: Dictionary = game._inventory_items().get(item_key, {})
	if meta.is_empty(): return
	detail_expanded = not detail_expanded
	_refresh_hover_info()


func _move_cursor(direction: Vector2i) -> void:
	var columns := 10 if cursor_area == "hotbar" else backpack_grid.columns
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
	if not visible or game == null:
		return
	var area := hovered_area if not hovered_area.is_empty() else cursor_area
	var index := hovered_index if not hovered_area.is_empty() else cursor_index
	var item_key := _item_at(area, index)
	if item_key.is_empty():
		detail_title.text = "物品说明"
		detail_icon.texture = null
		detail_text.text = "选择或悬停物品查看用途、数量与价值。\n\n按 I 展开完整说明。"
		return
	var meta: Dictionary = game._inventory_items().get(item_key, {})
	if meta.is_empty():
		return
	var count := int(meta.get("count", 1))
	detail_title.text = str(meta.get("name", item_key))
	detail_icon.texture = meta.get("icon") as Texture2D
	var summary := "%s · 数量 %d" % [str(meta.get("type_label", "普通物品")), count]
	var description := str(meta.get("description", "暂无说明。"))
	if not detail_expanded and description.length() > 64:
		description = description.substr(0, 64) + "…"
	detail_text.text = "%s\n\n%s\n\n按 I %s说明。" % [summary, description, "收起" if detail_expanded else "查看完整"]


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
	style.set_corner_radius_all(0)
	style.shadow_color = Color("352b20", 0.34)
	style.shadow_size = 5
	style.set_content_margin_all(7)
	return style
