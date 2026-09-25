class_name ArtActor
extends Node2D
const Atlas = preload("res://scripts/sprite_atlas.gd")

## Four-direction NPC animation with distance-driven stride and foot anchors.

var _sprite := Sprite2D.new()
var _walk_texture: Texture2D
var _idle_texture: Texture2D
var _scale_factor := 0.08
var _idle_column := 0
var _idle_columns := 1
var _idle_rows := 4
var _walk_columns := 4
var _walk_rows := 4
var _walk_tint := Color.WHITE
var _walk_phase_offset := 0.0
var _identity_walk := false
var _facing := "down"
var facing: String:
	get: return _facing
var _action := "idle"
var stride := 0.0
var running := false


func _process(_delta: float) -> void:
	_update_region()


func advance_stride(distance: float) -> void:
	stride = fmod(stride + distance * float(_walk_columns) / (42.0 if running else 36.0), float(_walk_columns))


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 10, Color(0.12, 0.17, 0.16, 0.24))


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	add_child(_sprite)


func configure(source_texture: Texture2D, source_idle_texture: Texture2D, scale_factor := 0.08, idle_column := 0, idle_columns := 1, idle_rows := 4, walk_tint := Color.WHITE, identity_walk := false, walk_columns := 4, walk_rows := 4) -> void:
	_walk_texture = source_texture
	_idle_texture = source_idle_texture
	_scale_factor = scale_factor
	_idle_column = clampi(idle_column, 0, maxi(0, idle_columns - 1))
	_walk_columns = maxi(1, walk_columns)
	_walk_rows = maxi(1, walk_rows)
	_walk_phase_offset = fposmod(float(_idle_column) * 0.37, float(_walk_columns))
	_idle_columns = maxi(1, idle_columns)
	_idle_rows = maxi(1, idle_rows)
	_walk_tint = walk_tint
	_identity_walk = identity_walk
	_sprite.material = null
	_sprite.texture = _idle_texture
	_sprite.region_enabled = true
	_sprite.region_filter_clip_enabled = true
	_update_region()


func set_pose(next_facing: String, next_action: String = "idle") -> void:
	var was_walking := _action in ["walk_a", "walk_b"]
	_facing = next_facing if next_facing in ["down", "left", "right", "up"] else "down"
	_action = next_action if next_action in ["idle", "walk_a", "walk_b", "use"] else "idle"
	var walking_now := _action in ["walk_a", "walk_b"]
	if not walking_now:
		stride = 0.0
	elif not was_walking and is_zero_approx(stride):
		stride = _walk_phase_offset
	_update_region()


func _update_region() -> void:
	if _walk_texture == null or _idle_texture == null:
		return
	var facing_rows := {"down": 0, "left": 1, "right": 2, "up": 3}
	var row: int = int(facing_rows.get(_facing, 0))
	var walking := _action in ["walk_a", "walk_b", "walk", "run"]
	var identity_walk := walking and _identity_walk
	var idle_row := 0 if _facing == "down" else 2 if _facing == "up" else 1
	var frame_row: int = row if walking and not identity_walk else idle_row
	var grid := Vector2i(_walk_columns, _walk_rows) if walking and not identity_walk else Vector2i(_idle_columns, _idle_rows)
	var column: int = posmod(int(stride), _walk_columns) if walking and not identity_walk else _idle_column
	_sprite.texture = _idle_texture if identity_walk or not walking else _walk_texture
	_sprite.modulate = _walk_tint if walking and not identity_walk else Color.WHITE
	_sprite.flip_h = _facing == "right" if identity_walk else not walking and _facing == "right"
	var frame_height_divisor := float(_walk_rows) if walking and not identity_walk else float(_idle_rows)
	_sprite.scale = Vector2.ONE * (44.0 / (_sprite.texture.get_height() / frame_height_divisor)) * (_scale_factor / 0.13)
	var frame := Atlas.frame(_sprite.texture, grid, column, frame_row)
	_sprite.region_rect = frame.region
	_sprite.position = Vector2(frame.offset) * _sprite.scale
	_sprite.position.y -= _locomotion_bob()
func _locomotion_bob() -> float:
	if _action not in ["walk_a", "walk_b", "walk", "run"]:
		return 0.0
	return absf(sin(stride * PI / 2.0)) * (1.5 if running else 0.7)
