class_name CharacterCreator
extends CanvasLayer

## Runtime-only character creator.  It creates its own controls and preview so a
## scene can add it without requiring any particular node names or Theme asset.

signal customization_confirmed(data: Dictionary)
signal customization_changed(data: Dictionary)

const AvatarRendererScript = preload("res://scripts/avatar_renderer.gd")

const OPTIONS := {
	"skin": ["porcelain", "warm_beige", "golden", "olive", "chestnut", "umber", "deep_umber", "rose_brown"],
	"hair": ["short", "long", "curly", "ponytail", "side_part", "braid", "bun", "spiky"],
	"hair_color": ["platinum", "blonde", "chestnut", "auburn", "black", "silver", "violet", "teal"],
	"clothes": ["overalls", "gardener", "cozy", "traveler", "apron", "raincoat", "worker", "formal"],
}

const LABELS := {
	"skin": "肤色", "hair": "发型", "hair_color": "发色", "clothes": "基础服饰",
}

const DISPLAY_NAMES := {
	"skin": {"porcelain": "瓷白", "warm_beige": "暖米", "golden": "金棕", "olive": "橄榄", "chestnut": "栗棕", "umber": "深褐", "deep_umber": "浓褐", "rose_brown": "玫瑰棕"},
	"hair": {"short": "短发", "long": "长发", "curly": "卷发", "ponytail": "马尾", "side_part": "偏分", "braid": "辫子", "bun": "发髻", "spiky": "短刺发"},
	"hair_color": {"platinum": "铂金", "blonde": "金色", "chestnut": "栗棕", "auburn": "赤褐", "black": "黑色", "silver": "银灰", "violet": "紫色", "teal": "青绿"},
	"clothes": {"overalls": "工装背带裤", "gardener": "园丁服", "cozy": "针织衫", "traveler": "旅行装", "apron": "围裙", "raincoat": "雨衣", "worker": "工装", "formal": "礼服"},
}

var customization: Dictionary = AvatarRenderer.DEFAULT_CUSTOMIZATION.duplicate(true)
var preview: AvatarRenderer
var _selectors: Dictionary = {}
var _swatches: Dictionary = {}
var _panel: Control
var _new_game_mode := false
var _name_row: Control
var _player_name_field: LineEdit
var _farm_name_field: LineEdit
var _validation_label: Label
var _title_label: Label
var _confirm_button: Button


func _ready() -> void:
	_build_ui()
	visible = false


func open(initial_data: Dictionary = {}) -> void:
	_new_game_mode = false
	customization = _normalise(initial_data)
	if _panel == null:
		_build_ui()
	visible = true
	_sync_controls()
	_refresh_mode_labels()


func open_new_game(initial_data: Dictionary = {}) -> void:
	_new_game_mode = true
	customization = _normalise(initial_data)
	if _panel == null:
		_build_ui()
	_player_name_field.text = ""
	_farm_name_field.text = ""
	_validation_label.text = ""
	visible = true
	_sync_controls()
	_refresh_mode_labels()


func close() -> void:
	visible = false


func get_customization() -> Dictionary:
	return customization.duplicate(true)


func _build_ui() -> void:
	if _panel != null:
		return
	layer = 20
	_panel = Control.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var dim := ColorRect.new()
	dim.color = Color("#182030", 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	card.size = Vector2(1120, 660)
	card.add_theme_stylebox_override("panel", _stylebox(Color("#f3e3be"), Color("#5a4335"), 4, 12))
	_panel.add_child(card)
	get_viewport().size_changed.connect(_layout_card.bind(card))
	_layout_card(card)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	content.add_child(top_row)
	_title_label = Label.new()
	_title_label.text = "新农场角色创建"
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color("#3f3432"))
	top_row.add_child(_title_label)
	var top_hint := Label.new()
	top_hint.text = "先定下角色的样子，再开始新的农场生活。"
	top_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_hint.add_theme_color_override("font_color", Color("#786154"))
	top_row.add_child(top_hint)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	content.add_child(columns)

	var preview_column := VBoxContainer.new()
	preview_column.custom_minimum_size = Vector2(380, 0)
	preview_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_column.add_theme_constant_override("separation", 8)
	columns.add_child(preview_column)
	var preview_stage := Panel.new()
	preview_stage.custom_minimum_size = Vector2(380, 390)
	preview_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_stage.add_theme_stylebox_override("panel", _stylebox(Color("#9fbd70"), Color("#66834a"), 3, 8))
	preview_column.add_child(preview_stage)
	var stage_title := Label.new()
	stage_title.text = "角色预览"
	stage_title.position = Vector2(14, 10)
	stage_title.add_theme_font_size_override("font_size", 17)
	stage_title.add_theme_color_override("font_color", Color("#f8f0d9"))
	preview_stage.add_child(stage_title)
	var stage_hint := Label.new()
	stage_hint.text = "四个方向即时预览"
	stage_hint.position = Vector2(14, 34)
	stage_hint.add_theme_color_override("font_color", Color("#f3f0d9"))
	preview_stage.add_child(stage_hint)
	var meadow := ColorRect.new()
	meadow.position = Vector2(0, 270)
	meadow.size = Vector2(380, 120)
	meadow.color = Color("#91ad5e")
	preview_stage.add_child(meadow)
	for flower in [Vector2(42, 315), Vector2(76, 353), Vector2(320, 310), Vector2(346, 354), Vector2(110, 370), Vector2(285, 370)]:
		var petal := ColorRect.new()
		petal.position = flower
		petal.size = Vector2(5, 5)
		petal.color = Color("#f0d58a")
		preview_stage.add_child(petal)
	preview = AvatarRendererScript.new()
	preview.pixel_scale = 0.62
	preview.customization = customization
	preview.position = Vector2(190, 290)
	preview_stage.add_child(preview)
	var pose_row := HBoxContainer.new()
	pose_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pose_row.add_theme_constant_override("separation", 8)
	for pose in [["下", "down"], ["左", "left"], ["右", "right"], ["后", "up"]]:
		var pose_button := Button.new()
		pose_button.text = pose[0]
		pose_button.custom_minimum_size = Vector2(52, 38)
		pose_button.add_theme_stylebox_override("normal", _stylebox(Color("#7d6b50"), Color("#594632"), 2, 5))
		pose_button.add_theme_color_override("font_color", Color.WHITE)
		pose_button.tooltip_text = "预览%s朝向" % pose[0]
		pose_button.pressed.connect(_set_preview_pose.bind(str(pose[1])))
		pose_row.add_child(pose_button)
	preview_column.add_child(pose_row)
	_name_row = VBoxContainer.new()
	_name_row.add_theme_constant_override("separation", 6)
	preview_column.add_child(_name_row)
	_player_name_field = _add_name_field(_name_row, "角色名字", "给角色取个名字")
	_farm_name_field = _add_name_field(_name_row, "农场名字", "给新农场取个名字")
	_validation_label = Label.new()
	_validation_label.add_theme_color_override("font_color", Color("#a34636"))
	_name_row.add_child(_validation_label)

	var separator := VSeparator.new()
	columns.add_child(separator)
	var controls_column := VBoxContainer.new()
	controls_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_column.add_theme_constant_override("separation", 10)
	columns.add_child(controls_column)
	var heading := Label.new()
	heading.text = "调整外观"
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", Color("#3f3432"))
	controls_column.add_child(heading)
	var field_hint := Label.new()
	field_hint.text = "点击左右箭头切换，角色预览会立即更新。"
	field_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	field_hint.add_theme_color_override("font_color", Color("#786154"))
	controls_column.add_child(field_hint)
	var fields := VBoxContainer.new()
	fields.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("separation", 10)
	controls_column.add_child(fields)
	_add_section_label(fields, "角色特征")
	for key: String in OPTIONS:
		_add_selector(fields, key)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 8)
	controls_column.add_child(buttons)
	var reset := Button.new()
	reset.text = "恢复默认外观"
	reset.add_theme_stylebox_override("normal", _stylebox(Color("#d9bd83"), Color("#a38958"), 2, 5))
	reset.add_theme_color_override("font_color", Color("#4c3d38"))
	reset.pressed.connect(_reset)
	buttons.add_child(reset)
	var randomize := Button.new()
	randomize.text = "🎲 随机外观"
	randomize.add_theme_stylebox_override("normal", _stylebox(Color("#c78a48"), Color("#9c6334"), 2, 5))
	randomize.add_theme_color_override("font_color", Color.WHITE)
	randomize.pressed.connect(_randomize_appearance)
	buttons.add_child(randomize)
	_confirm_button = Button.new()
	_confirm_button.text = "开始农场生活　›"
	_confirm_button.custom_minimum_size = Vector2(190, 48)
	_confirm_button.add_theme_font_size_override("font_size", 17)
	_confirm_button.add_theme_stylebox_override("normal", _stylebox(Color("#6d9254"), Color("#3f633c"), 3, 8))
	_confirm_button.add_theme_color_override("font_color", Color.WHITE)
	_confirm_button.pressed.connect(_confirm)
	buttons.add_child(_confirm_button)
	_sync_controls()
	_refresh_mode_labels()


func _add_selector(parent: VBoxContainer, key: String) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size.y = 66
	row.add_theme_stylebox_override("panel", _stylebox(Color("#fff7e7"), Color("#c7ac7d"), 2, 6))
	parent.add_child(row)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	row.add_child(line)
	var label := Label.new()
	label.text = str(LABELS.get(key, key))
	label.custom_minimum_size.x = 90
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("#4c3d38"))
	line.add_child(label)
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(25, 25)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.color = _choice_color(key, str(customization[key]))
	line.add_child(swatch)
	_swatches[key] = swatch
	var value := Label.new()
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color("#4c3d38"))
	line.add_child(value)
	_selectors[key] = value
	var previous := Button.new()
	previous.text = "‹"
	previous.custom_minimum_size = Vector2(46, 42)
	previous.add_theme_stylebox_override("normal", _stylebox(Color("#8a7556"), Color("#634e38"), 2, 5))
	previous.add_theme_color_override("font_color", Color.WHITE)
	previous.tooltip_text = "上一个"
	previous.pressed.connect(_cycle_choice.bind(key, -1))
	line.add_child(previous)
	var next := Button.new()
	next.text = "›"
	next.custom_minimum_size = Vector2(46, 42)
	next.add_theme_stylebox_override("normal", _stylebox(Color("#8a7556"), Color("#634e38"), 2, 5))
	next.add_theme_color_override("font_color", Color.WHITE)
	next.tooltip_text = "下一个"
	next.pressed.connect(_cycle_choice.bind(key, 1))
	line.add_child(next)


func _add_section_label(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color("#786154"))
	parent.add_child(label)


func _add_name_field(parent: VBoxContainer, title: String, placeholder: String) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 86
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#4c3d38"))
	row.add_child(label)
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.max_length = 16
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 38
	row.add_child(field)
	return field


func _layout_card(card: Control) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	card.size = Vector2(minf(1120.0, viewport_size.x - 40.0), minf(660.0, viewport_size.y - 32.0))
	card.position = (viewport_size - card.size) / 2.0


func _choice_color(key: String, choice: String) -> Color:
	if key == "skin":
		return Color(AvatarRenderer.PALETTES["skin"][choice])
	if key == "hair_color":
		return Color(AvatarRenderer.PALETTES["hair_color"][choice])
	if key == "clothes":
		return Color("#7c9a82")
	return Color("#987056")


func _cycle_choice(key: String, direction: int) -> void:
	var choices: Array = OPTIONS[key]
	var index := choices.find(customization[key])
	index = posmod(index + direction, choices.size())
	_set_choice(key, index)


func _set_choice(key: String, index: int) -> void:
	var choices: Array = OPTIONS[key]
	if index < 0 or index >= choices.size():
		return
	customization[key] = choices[index]
	preview.customization = customization
	_sync_controls()
	customization_changed.emit(get_customization())


func _set_preview_pose(next_facing: String) -> void:
	if preview != null:
		preview.set_pose(next_facing, "idle")


func _sync_controls() -> void:
	if preview != null:
		preview.customization = customization
	for key: String in _selectors:
		var choices: Array = OPTIONS[key]
		var index := choices.find(customization[key])
		(_selectors[key] as Label).text = _display_name(key, choices[maxi(index, 0)])
		(_swatches[key] as ColorRect).color = _choice_color(key, choices[maxi(index, 0)])


func _reset() -> void:
	customization = AvatarRenderer.DEFAULT_CUSTOMIZATION.duplicate(true)
	_sync_controls()
	customization_changed.emit(get_customization())


func _randomize_appearance() -> void:
	for key: String in OPTIONS:
		var choices: Array = OPTIONS[key]
		customization[key] = choices[randi_range(0, choices.size() - 1)]
	_sync_controls()
	customization_changed.emit(get_customization())


func _confirm() -> void:
	var result := get_customization()
	if _new_game_mode:
		var player_name := _player_name_field.text.strip_edges()
		var farm_name := _farm_name_field.text.strip_edges()
		if player_name.is_empty() or farm_name.is_empty():
			_validation_label.text = "请填写角色名字和农场名字。"
			return
		if player_name.length() > 16 or farm_name.length() > 16:
			_validation_label.text = "名字最多 16 个字符。"
			return
		result["player_name"] = player_name
		result["farm_name"] = farm_name
		result["new_game"] = true
	customization_confirmed.emit(result)
	close()


func _refresh_mode_labels() -> void:
	if _title_label == null:
		return
	_title_label.text = "开始新的农场生活" if _new_game_mode else "调整角色外观"
	_confirm_button.text = "确认角色并开始" if _new_game_mode else "保存外观"
	_player_name_field.editable = _new_game_mode
	_farm_name_field.editable = _new_game_mode
	_name_row.visible = _new_game_mode


func _normalise(data: Dictionary) -> Dictionary:
	var result := AvatarRenderer.DEFAULT_CUSTOMIZATION.duplicate(true)
	for key: String in OPTIONS:
		if data.has(key) and data[key] in OPTIONS[key]:
			result[key] = data[key]
	return result


func _display_name(field: String, value: String) -> String:
	var names: Dictionary = DISPLAY_NAMES.get(field, {})
	return str(names.get(value, value.replace("_", " ").capitalize()))


func _stylebox(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("#30291f", 0.42)
	style.shadow_size = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
