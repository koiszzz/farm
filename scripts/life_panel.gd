extends CanvasLayer

const UISkin = preload("res://scripts/farm_ui_skin.gd")

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
	backdrop.color = Color(0.10, 0.13, 0.12, 0.68)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -380
	panel.offset_right = 380
	panel.offset_top = -280
	panel.offset_bottom = 280
	panel.add_theme_stylebox_override("panel", UISkin.frame())
	var theme := Theme.new()
	for state in ["normal", "hover", "pressed", "focus"]:
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("ead5a7") if state == "normal" else Color("f8e3aa")
		button_style.border_color = Color("9b7545")
		button_style.set_border_width_all(2)
		button_style.set_corner_radius_all(0)
		theme.set_stylebox(state, "Button", button_style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", Color("493829"))
	panel.theme = theme
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title_band := PanelContainer.new()
	title_band.custom_minimum_size.y = 34
	title_band.add_theme_stylebox_override("panel", UISkin.header())
	column.add_child(title_band)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color("fff0c7"))
	title_band.add_child(heading)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
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

func section(text: String) -> void:
	var band := PanelContainer.new()
	band.custom_minimum_size.y = 24
	band.add_theme_stylebox_override("panel", UISkin.header())
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("fff0c7"))
	band.add_child(label)
	content.add_child(band)

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
	dialogue_text.gui_input.connect(_on_dialogue_gui_input)
	row.add_child(dialogue_text)
	action("显示全部对话  ·  空格", reveal_dialogue)


func reveal_dialogue() -> void:
	if not is_instance_valid(dialogue_text): return
	reveal = float(dialogue_text.get_total_character_count())
	dialogue_text.visible_characters = -1


func _on_dialogue_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		reveal_dialogue()
		dialogue_text.accept_event()

func story_dialogue(texture: Texture2D, region: Rect2, speaker: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var portrait := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(82, 92)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(portrait)
	var story := RichTextLabel.new()
	story.text = "%s：%s" % [speaker, text]
	story.fit_content = true
	story.scroll_active = false
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.custom_minimum_size = Vector2(0, 92)
	story.add_theme_color_override("default_color", Color("483b34"))
	story.add_theme_font_size_override("normal_font_size", 17)
	row.add_child(story)

func item_card(icon: Texture2D, title: String, details: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UISkin.card(Color("f4e2bd"), Color("c8a876")))
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
