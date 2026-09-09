extends CanvasLayer

var backdrop: ColorRect
var panel: PanelContainer
var content: VBoxContainer
var heading: Label
var scroll: ScrollContainer
var dialogue_text: RichTextLabel
var reveal := 0.0

func _process(delta: float) -> void:
	if visible and is_instance_valid(dialogue_text):
		reveal += delta * 42
		dialogue_text.visible_characters = int(reveal)

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
	var theme := Theme.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("efd6a6") if state == "normal" else Color("ffe6aa")
		button_style.border_color = Color("af7943")
		button_style.set_border_width_all(2)
		button_style.set_corner_radius_all(3)
		theme.set_stylebox(state, "Button", button_style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", Color("62442e"))
	panel.theme = theme
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
	dialogue_text = null
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

func dialogue(texture: Texture2D, region: Rect2, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	content.add_child(row)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(112, 130)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(portrait)
	dialogue_text = RichTextLabel.new()
	dialogue_text.text = text
	dialogue_text.fit_content = true
	dialogue_text.scroll_active = false
	dialogue_text.custom_minimum_size = Vector2(0, 190)
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_color_override("default_color", Color("483b34"))
	dialogue_text.add_theme_font_size_override("normal_font_size", 18)
	dialogue_text.visible_characters = 0
	reveal = 0
	row.add_child(dialogue_text)
	action("显示全部对话", func(): reveal = 10000)

func item_card(icon: Texture2D, title: String, details: String) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f4e2bd")
	style.border_color = Color("c8a876")
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	content.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	card.add_child(row)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.custom_minimum_size = Vector2(58, 66)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(picture)
	var label := Label.new()
	label.text = title + "\n" + details
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color("62442e"))
	row.add_child(label)

func action(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 38
	button.pressed.connect(callback)
	content.add_child(button)
