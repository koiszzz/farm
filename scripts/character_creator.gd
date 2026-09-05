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
	"eyes": ["round", "bright", "sleepy", "sparkle", "wide", "calm", "sharp", "soft"],
	"eye_color": ["brown", "hazel", "green", "blue", "gray", "violet"],
	"nose": ["soft", "button", "straight", "freckled"],
	"mouth": ["smile", "neutral", "open", "smirk"],
	"ears": ["rounded", "pointed", "pierced", "hidden", "small", "wide", "high", "low"],
	"clothes": ["overalls", "gardener", "cozy", "traveler", "apron", "raincoat", "worker", "formal"],
}

const LABELS := {
	"skin": "肤色", "hair": "发型", "hair_color": "发色", "eyes": "眼睛", "eye_color": "瞳色",
	"nose": "鼻子", "mouth": "嘴巴", "ears": "耳朵", "clothes": "基础服饰",
}

var customization: Dictionary = AvatarRenderer.DEFAULT_CUSTOMIZATION.duplicate(true)
var preview: AvatarRenderer
var _selectors: Dictionary = {}
var _panel: Control


func _ready() -> void:
	_build_ui()
	# Character appearance is optional at the start of a game.  Keep the farm
	# interactive until the player explicitly presses C to open this modal.
	visible = false


func open(initial_data: Dictionary = {}) -> void:
	customization = _normalise(initial_data)
	if _panel == null:
		_build_ui()
	visible = true
	_sync_controls()


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
	card.position = Vector2(56, 32)
	card.size = Vector2(848, 476)
	card.add_theme_stylebox_override("panel", _stylebox(Color("#f5e6c8"), Color("#5a4335"), 5, 12))
	_panel.add_child(card)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	card.add_child(columns)

	var preview_column := VBoxContainer.new()
	preview_column.custom_minimum_size = Vector2(258, 0)
	preview_column.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(preview_column)
	var title := Label.new()
	title.text = "创建你的农夫"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#3f3432"))
	preview_column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "外观不影响数值，可随时重新编辑"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("#786154"))
	preview_column.add_child(subtitle)
	var preview_holder := CenterContainer.new()
	preview_holder.custom_minimum_size = Vector2(258, 220)
	preview_column.add_child(preview_holder)
	preview = AvatarRendererScript.new()
	preview.pixel_scale = 0.38
	preview.customization = customization
	preview.position = Vector2(129, 108)
	preview_holder.add_child(preview)
	var pose_row := HBoxContainer.new()
	pose_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for pose in [["下", "down"], ["左", "left"], ["右", "right"], ["后", "up"]]:
		var pose_button := Button.new()
		pose_button.text = pose[0]
		pose_button.tooltip_text = "预览%s朝向" % pose[0]
		pose_button.pressed.connect(_set_preview_pose.bind(str(pose[1])))
		pose_row.add_child(pose_button)
	preview_column.add_child(pose_row)

	var separator := VSeparator.new()
	columns.add_child(separator)
	var controls_column := VBoxContainer.new()
	controls_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_column.add_theme_constant_override("separation", 5)
	columns.add_child(controls_column)
	var heading := Label.new()
	heading.text = "外观"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color", Color("#3f3432"))
	controls_column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_column.add_child(scroll)
	var fields := GridContainer.new()
	fields.columns = 2
	fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fields.add_theme_constant_override("h_separation", 16)
	fields.add_theme_constant_override("v_separation", 8)
	scroll.add_child(fields)
	for key: String in OPTIONS:
		_add_selector(fields, key)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	controls_column.add_child(buttons)
	var reset := Button.new()
	reset.text = "恢复默认"
	reset.pressed.connect(_reset)
	buttons.add_child(reset)
	var confirm := Button.new()
	confirm.text = "开始农场生活"
	confirm.add_theme_font_size_override("font_size", 16)
	confirm.add_theme_stylebox_override("normal", _stylebox(Color("#6d9254"), Color("#3f633c"), 3, 8))
	confirm.add_theme_color_override("font_color", Color.WHITE)
	confirm.pressed.connect(_confirm)
	buttons.add_child(confirm)
	_sync_controls()


func _add_selector(parent: GridContainer, key: String) -> void:
	var label := Label.new()
	label.text = str(LABELS.get(key, key))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#4c3d38"))
	parent.add_child(label)
	var selector := OptionButton.new()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for choice: String in OPTIONS[key]:
		selector.add_item(_display_name(choice))
	selector.item_selected.connect(func(index: int) -> void: _set_choice(key, index))
	parent.add_child(selector)
	_selectors[key] = selector


func _set_choice(key: String, index: int) -> void:
	var choices: Array = OPTIONS[key]
	if index < 0 or index >= choices.size():
		return
	customization[key] = choices[index]
	preview.customization = customization
	customization_changed.emit(get_customization())


func _set_preview_pose(next_facing: String) -> void:
	if preview != null:
		preview.set_pose(next_facing, "walk_a")


func _sync_controls() -> void:
	if preview != null:
		preview.customization = customization
	for key: String in _selectors:
		var choices: Array = OPTIONS[key]
		var index := choices.find(customization[key])
		(_selectors[key] as OptionButton).select(maxi(index, 0))


func _reset() -> void:
	customization = AvatarRenderer.DEFAULT_CUSTOMIZATION.duplicate(true)
	_sync_controls()
	customization_changed.emit(get_customization())


func _confirm() -> void:
	customization_confirmed.emit(get_customization())
	close()


func _normalise(data: Dictionary) -> Dictionary:
	var result := AvatarRenderer.DEFAULT_CUSTOMIZATION.duplicate(true)
	for key: String in OPTIONS:
		if data.has(key) and data[key] in OPTIONS[key]:
			result[key] = data[key]
	return result


func _display_name(value: String) -> String:
	return value.replace("_", " ").capitalize()


func _stylebox(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
