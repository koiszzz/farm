class_name AvatarRenderer
extends Node2D

## Four-direction locomotion and authored action poses share measured foot
## anchors, palette customization, garment details and hand-mounted tools.

const LOGICAL_SIZE := Vector2i(32, 48)
const IDLE_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_idle_v1.png")
const ACTION_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_walk_v2.png")
const PALETTE_SHADER = preload("res://assets/art/character_creator/avatar_palette.gdshader")
const SWING_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_swing_v2.png")
const CROUCH_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_crouch_v2.png")
const OFFER_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_offer_v2.png")
const Atlas = preload("res://scripts/sprite_atlas.gd")

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
var stride := 0.0
var running := false
var action_progress := 0.0
var _palette := ShaderMaterial.new()
var _details = preload("res://scripts/avatar_details.gd").new()
var _tools = preload("res://scripts/actor_tools.gd").new()


func _process(_delta: float) -> void:
	_apply_pose()
	queue_redraw()
	_details.queue_redraw()
	_tools.z_index = -1 if facing == "up" else 2
	_tools.queue_redraw()


func advance_stride(distance: float) -> void:
	stride = fmod(stride + distance * 8.0 / (80.0 if running else 64.0), 8.0)


func _draw() -> void:
	# Grounded shadow is independent of the head/body animation.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 10, Color(0.12, 0.17, 0.16, 0.24))
	draw_set_transform(Vector2.ZERO)


func draw_tools(canvas: Node2D) -> void:
	if not action in ["hoe", "seed", "water", "harvest", "scythe", "gift", "fish"]: return
	var direction: Vector2 = {"down": Vector2.DOWN, "up": Vector2.UP, "left": Vector2.LEFT, "right": Vector2.RIGHT}.get(facing, Vector2.DOWN)
	var hand: Vector2 = {"down": Vector2(0,-17), "up": Vector2(0,-24), "left": Vector2(-13,-22), "right": Vector2(13,-22)}.get(facing, Vector2(0,-17))
	var reach := sin(action_progress * PI)
	var target := direction * 32.0
	var tip := hand + direction * 9.0
	match action:
		"hoe", "scythe":
			var overhead := Vector2(0,-39)
			var contact := Vector2(direction.x * 12, -5)
			var strike := smoothstep(0.28,0.48,action_progress)
			hand = overhead.lerp(contact, strike)
			if action_progress < 0.25: hand = Vector2(0,-17).lerp(overhead, action_progress/0.25)
			if action_progress > 0.75: hand = contact.lerp(Vector2(0,-17), (action_progress-0.75)/0.25)
			var end := Vector2(0,-57).lerp(target, strike)
			var shaft := end - hand
			canvas.draw_line(hand, end, Color("785035"), 3)
			var edge := shaft.normalized().orthogonal() * 10.0
			if action == "hoe":
				canvas.draw_line(hand + shaft - edge, hand + shaft + edge, Color("c1d3d6"), 5)
			else:
				var angle := shaft.angle()
				canvas.draw_arc(end, 10, angle-0.6, angle+1.5, 12, Color("dae7df"), 3)
		"water":
			canvas.draw_style_box(_can_style(), Rect2(hand - Vector2(5, 1), Vector2(10, 9)))
			canvas.draw_arc(hand + Vector2(-3, 1), 4, PI/2, PI*1.5, 8, Color("88bccc"), 2)
			canvas.draw_line(hand + Vector2(0,3), tip, Color("88bccc"), 3)
			if action_progress > 0.35 and action_progress < 0.8:
				for i in 6:
					var travel := fmod(action_progress * 3 + i / 6.0, 1.0)
					var drop := tip.lerp(target, travel) + Vector2(sin(i * 2.1) * 3, 0)
					canvas.draw_line(drop, drop + Vector2(0, 3), Color("a8e5f1"), 2)
		"seed":
			for i in 4:
				canvas.draw_circle(Vector2(direction.x*12,-5).lerp(target, clampf((action_progress-0.25)*2,0,1)) + Vector2(i * 2 - 3, i % 2 * 2), 1, Color("dbb77a"))
		"harvest":
			if action_progress >= 0.48:
				var crop := Vector2(direction.x*11,-4).lerp(hand, clampf((action_progress-0.48)*2,0,1))
				canvas.draw_circle(crop, 4, Color("e9b35d"))
				canvas.draw_line(crop - Vector2(0, 2), crop - Vector2(2, 7), Color("8cac58"), 2)
		"gift":
			var box := hand + direction * reach * 2
			canvas.draw_rect(Rect2(box - Vector2(5, 4), Vector2(10, 8)), Color("c67978"))
			canvas.draw_line(box + Vector2(0, -4), box + Vector2(0, 4), Color("f3d7a0"), 2)
			canvas.draw_line(box + Vector2(-5, -1), box + Vector2(5, -1), Color("f3d7a0"), 2)
		"fish":
			var rod := hand + direction * 22 - Vector2(0, 28 * (1 - reach))
			canvas.draw_line(hand, rod, Color("a98456"), 3)
			canvas.draw_line(rod, direction * 38, Color("e4dfc9"), 1)
			canvas.draw_circle(direction * 38, 3, Color("d97465"))


func _can_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("659da9")
	style.border_color = Color("b9d3d3")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	return style


func _init() -> void:
	_body.centered = false
	_body.region_enabled = true
	_body.region_filter_clip_enabled = true
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_palette.shader = PALETTE_SHADER
	_body.material = _palette
	add_child(_body)
	_details.avatar = self
	add_child(_details)
	_tools.avatar = self
	add_child(_tools)


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
	action = next_action
	_apply_pose()


func get_logical_size() -> Vector2i:
	return LOGICAL_SIZE


func _apply_pose() -> void:
	var texture := IDLE_ART
	var grid := Vector2i(1, 4)
	var row := _facing_row()
	var column := 0
	if action in ["walk_a", "walk_b", "walk", "run"]:
		texture = ACTION_ART
		grid = Vector2i(8, 4)
		column = int(stride)
	elif action in ["hoe", "scythe", "seed", "harvest", "water", "gift", "fish", "pet"]:
		grid = Vector2i(4, 4)
		column = mini(int(action_progress * 4), 3)
		if action in ["hoe", "scythe"]:
			texture = SWING_ART
			row = int({"down": 0, "left": 2, "right": 1, "up": 3}.get(facing, 0))
		elif action in ["seed", "harvest", "pet"]: texture = CROUCH_ART
		else: texture = OFFER_ART
	_body.texture = texture
	_palette.set_shader_parameter("columns", float(grid.x))
	var frame := Atlas.frame(texture, grid, column, row)
	_body.region_rect = frame.region
	_body.scale = Vector2.ONE * (44.0 / (texture.get_height() / 4.0)) * (pixel_scale / 0.13)
	_body.position = Vector2(frame.offset) * _body.scale
	_body.rotation = 0.0
	if action in ["walk_a", "walk_b", "walk", "run"]:
		_body.position.y -= absf(sin(stride * PI / 4.0)) * (2.0 if running else 0.5)
		if running and facing in ["left", "right"]:
			_body.rotation = -0.07 if facing == "left" else 0.07
	var detail_scale := pixel_scale / 0.13
	_details.scale = Vector2(detail_scale, detail_scale * clampf(_body.region_rect.size.y * _body.scale.y / (40.0 * detail_scale), 0.45, 1.0))
	_details.head = Vector2(0, _body.position.y / _details.scale.y + 9.0)


func _apply_customization() -> void:
	if _body == null:
		return
	# Palette changes apply to every authored sheet, including the back row.
	_body.modulate = Color.WHITE
	_palette.set_shader_parameter("hair_color", _palette_color("hair_color", str(customization.hair_color)))
	_palette.set_shader_parameter("skin_color", _palette_color("skin", str(customization.skin)))
	var clothes := {"overalls": "285d73", "gardener": "648445", "cozy": "a76468", "traveler": "826a47", "apron": "c9a679", "raincoat": "ddb141", "worker": "526577", "formal": "484157"}
	_palette.set_shader_parameter("cloth_color", Color.html(clothes.get(customization.clothes, "285d73")))
	_apply_scale()


func _apply_scale() -> void:
	_body.scale = Vector2.ONE * (44.0 / (ACTION_ART.get_height() / 4.0)) * (pixel_scale / 0.13)


func _grid_region(texture: Texture2D, grid: Vector2i, column: int, row: int) -> Rect2:
	var source_size := texture.get_size()
	var cell := Vector2(source_size.x / grid.x, source_size.y / grid.y)
	return Rect2(Vector2(column * cell.x, row * cell.y), cell)


func _facing_row() -> int:
	return int({"down": 0, "left": 1, "right": 2, "up": 3}.get(facing, 0))


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
