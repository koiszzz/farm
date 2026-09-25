extends RefCounted
class_name FarmUISkin

const JOURNAL_FRAME: Texture2D = preload("res://assets/art/runtime_generated/journal_frame_v1.svg")
const JOURNAL_HEADER: Texture2D = preload("res://assets/art/runtime_generated/journal_header_v1.svg")

static func frame() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = JOURNAL_FRAME
	style.texture_margin_left = 12
	style.texture_margin_top = 12
	style.texture_margin_right = 12
	style.texture_margin_bottom = 12
	style.content_margin_left = 22
	style.content_margin_top = 13
	style.content_margin_right = 22
	style.content_margin_bottom = 13
	return style

static func header() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = JOURNAL_HEADER
	style.texture_margin_left = 8
	style.texture_margin_top = 8
	style.texture_margin_right = 8
	style.texture_margin_bottom = 8
	style.content_margin_left = 10
	style.content_margin_top = 3
	style.content_margin_right = 10
	style.content_margin_bottom = 3
	return style

static func card(background := Color("efe2c2"), border := Color("ae8958")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.shadow_color = Color("4b3825", 0.20)
	style.shadow_size = 2
	style.set_content_margin_all(7)
	return style
