class_name ArtActor
extends Node2D

## Displays the generated 3×4 NPC source sheets at runtime.  All rows/columns
## use the same shared character animation contract as the player.

var _sprite := Sprite2D.new()
var _grid := Vector2i(4, 3)
var _facing := "down"
var facing: String:
	get: return _facing
var _action := "idle"


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true
	add_child(_sprite)


func configure(source_texture: Texture2D, scale_factor := 0.08) -> void:
	_sprite.texture = source_texture
	_sprite.region_enabled = true
	_sprite.scale = Vector2.ONE * scale_factor
	_update_region()


func set_pose(next_facing: String, next_action: String = "idle") -> void:
	_facing = next_facing if next_facing in ["down", "left", "right", "up"] else "down"
	_action = next_action if next_action in ["idle", "walk_a", "walk_b", "use"] else "idle"
	_update_region()


func _update_region() -> void:
	if _sprite.texture == null:
		return
	var source_size := _sprite.texture.get_size()
	var frame_size := Vector2(source_size.x / _grid.x, source_size.y / _grid.y)
	var facing_rows := {"down": 0, "left": 1, "right": 2, "up": 1}
	var action_columns := {"idle": 0, "walk_a": 1, "walk_b": 2, "use": 3}
	var row: int = int(facing_rows.get(_facing, 0))
	var column: int = int(action_columns.get(_action, 0))
	_sprite.region_rect = Rect2(Vector2(column * frame_size.x, row * frame_size.y), frame_size)
