class_name AvatarRenderer
extends Node2D

## Runtime avatar uses one complete authored action sheet.  The previous
## implementation overlaid static feature boards onto moving body frames,
## which made opaque source bounds cover the character at runtime.

const LOGICAL_SIZE := Vector2i(32, 48)
const ACTION_ART: Texture2D = preload("res://assets/art/source_generated/farmer_sprite_sheet_source_v1.png")

const DEFAULT_CUSTOMIZATION := {
	"skin": "warm_beige", "hair": "short", "hair_color": "chestnut",
	"eyes": "round", "eye_color": "brown", "nose": "soft", "mouth": "smile",
	"ears": "rounded", "clothes": "overalls",
}

const PALETTES := {
	"skin": {"porcelain": "#f8d8c3", "warm_beige": "#edbc91", "golden": "#d99863", "olive": "#b9784f", "chestnut": "#865039", "umber": "#603528", "deep_umber": "#3e241f", "rose_brown": "#bd765f"},
	"hair_color": {"platinum": "#f4e4b4", "blonde": "#d9a94e", "chestnut": "#77422d", "auburn": "#a4482c", "black": "#26232a", "silver": "#a9adb5", "violet": "#62456f", "teal": "#2f746e"},
	"eye_color": {"brown": "#5a3826", "hazel": "#7a622b", "green": "#3f7d5a", "blue": "#3c6c9d", "gray": "#67737b", "violet": "#76569a"},
}

const HAIR_IDS := ["short", "long", "curly", "ponytail", "side_part", "braid", "bun", "spiky"]
const EYE_IDS := ["round", "bright", "sleepy", "sparkle", "wide", "calm", "sharp", "soft"]
const NOSE_IDS := ["soft", "button", "straight", "freckled"]
const MOUTH_IDS := ["smile", "neutral", "open", "smirk"]
const EAR_IDS := ["rounded", "pointed", "pierced", "hidden", "small", "wide", "high", "low"]
const CLOTHES_IDS := ["overalls", "gardener", "cozy", "traveler", "apron", "raincoat", "worker", "formal"]

@export_range(0.02, 1.0, 0.005) var pixel_scale := 0.085:
	set(value):
		pixel_scale = value
		_apply_scale()

@export var customization: Dictionary = DEFAULT_CUSTOMIZATION.duplicate(true):
	set(value):
		customization = _normalized_customization(value)
		_apply_customization()

@export_enum("down", "left", "right", "up") var facing := "down":
	set(value):
		facing = value
		_apply_pose()

@export_enum("idle", "walk_a", "walk_b", "use") var action := "idle":
	set(value):
		action = value
		_apply_pose()

var _body := Sprite2D.new()


func _init() -> void:
	_body.centered = true
	_body.region_enabled = true
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_body)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_customization()
	_apply_pose()
	_apply_scale()


func set_customization(value: Dictionary) -> void:
	customization = value


func get_customization() -> Dictionary:
	return customization.duplicate(true)


func set_pose(next_facing: String, next_action: String = "idle") -> void:
	facing = next_facing if next_facing in ["down", "left", "right", "up"] else "down"
	action = next_action if next_action in ["idle", "walk_a", "walk_b", "use"] else "idle"
	_apply_pose()


func get_logical_size() -> Vector2i:
	return LOGICAL_SIZE


func _apply_pose() -> void:
	_body.texture = ACTION_ART
	_body.region_rect = _grid_region(ACTION_ART, Vector2i(4, 3), _action_column(), _facing_row())


func _apply_customization() -> void:
	if _body == null:
		return
	# Customization is still persisted by CharacterCreator. Runtime appearance
	# stays on a complete action sheet until every selectable feature has its
	# own matched 4x3 action overlay; never layer static concept boards here.
	_body.modulate = Color.WHITE
	_apply_scale()


func _apply_scale() -> void:
	_body.scale = Vector2.ONE * pixel_scale


func _grid_region(texture: Texture2D, grid: Vector2i, column: int, row: int) -> Rect2:
	var source_size := texture.get_size()
	var cell := Vector2(source_size.x / grid.x, source_size.y / grid.y)
	return Rect2(Vector2(column * cell.x, row * cell.y), cell)


func _facing_row() -> int:
	return int({"down": 0, "left": 1, "right": 2, "up": 1}.get(facing, 0))


func _action_column() -> int:
	return int({"idle": 0, "walk_a": 1, "walk_b": 2, "use": 3}.get(action, 0))


func _choice_index(values: Array, choice: String) -> int:
	return maxi(values.find(choice), 0)


func _palette_color(group: String, key: String) -> Color:
	var values: Dictionary = PALETTES.get(group, {})
	return Color.html(str(values.get(key, values.values()[0])))


func _normalized_customization(value: Dictionary) -> Dictionary:
	var result := DEFAULT_CUSTOMIZATION.duplicate(true)
	for key in result.keys():
		if value.has(key) and value[key] is String and not str(value[key]).is_empty():
			result[key] = value[key]
	return result
