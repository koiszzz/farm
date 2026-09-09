class_name ArtActor
extends Node2D
const Atlas = preload("res://scripts/sprite_atlas.gd")

## Four-direction NPC animation with distance-driven stride and foot anchors.

var _sprite := Sprite2D.new()
var _walk_texture: Texture2D
var _idle_texture: Texture2D
var _scale_factor := 0.08
var _facing := "down"
var facing: String:
	get: return _facing
var _action := "idle"
var stride := 0.0
var running := false


func _process(_delta: float) -> void:
	_update_region()


func advance_stride(distance: float) -> void:
	stride = fmod(stride + distance * 4.0 / (42.0 if running else 36.0), 4.0)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 10, Color(0.12, 0.17, 0.16, 0.24))


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	add_child(_sprite)


func configure(source_texture: Texture2D, source_idle_texture: Texture2D, scale_factor := 0.08) -> void:
	_walk_texture = source_texture
	_idle_texture = source_idle_texture
	_scale_factor = scale_factor
	_sprite.texture = _idle_texture
	_sprite.region_enabled = true
	_sprite.region_filter_clip_enabled = true
	_update_region()


func set_pose(next_facing: String, next_action: String = "idle") -> void:
	_facing = next_facing if next_facing in ["down", "left", "right", "up"] else "down"
	_action = next_action if next_action in ["idle", "walk_a", "walk_b", "use"] else "idle"
	_update_region()


func _update_region() -> void:
	if _walk_texture == null or _idle_texture == null:
		return
	var facing_rows := {"down": 0, "left": 1, "right": 2, "up": 3}
	var row: int = int(facing_rows.get(_facing, 0))
	var walking := _action in ["walk_a", "walk_b", "walk", "run"]
	var grid := Vector2i(4, 4) if walking else Vector2i(1, 4)
	var column: int = int(stride) if walking else 0
	_sprite.texture = _walk_texture if walking else _idle_texture
	_sprite.scale = Vector2.ONE * (44.0 / (_sprite.texture.get_height() / 4.0)) * (_scale_factor / 0.13)
	var frame := Atlas.frame(_sprite.texture, grid, column, row)
	_sprite.region_rect = frame.region
	_sprite.position = Vector2(frame.offset) * _sprite.scale
	_sprite.position.y -= absf(sin(stride * PI / 2)) * 1.5 if running else 0.0
