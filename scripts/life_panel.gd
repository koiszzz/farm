extends CanvasLayer

var backdrop: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var heading: Label
var scroll: ScrollContainer

func _ready() -> void:
	layer = 20
	backdrop = ColorRect.new()
	backdrop.color = Color(0.07, 0.12, 0.16, 0.65)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -380
	panel.offset_right = 380
	panel.offset_top = -254
	panel.offset_bottom = 254
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff3d7")
	style.border_color = Color("805b40")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", Color("483b34"))
	column.add_child(heading)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	scroll.add_child(content)
	var close_button := Button.new()
	close_button.text = "返回游戏  ·  Esc"
	close_button.custom_minimum_size.y = 38
	close_button.pressed.connect(close)
	column.add_child(close_button)
	close()

func open(title: String) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	heading.text = title
	scroll.scroll_vertical = 0
	show()

func close() -> void:
	hide()

func paragraph(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("483b34"))
	content.add_child(label)

func action(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.pressed.connect(callback)
	content.add_child(button)
