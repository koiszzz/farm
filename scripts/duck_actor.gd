extends Node2D

const TILE := 32.0
const DUCK_ART: Texture2D = preload("res://assets/art/runtime_generated/duck_walk_v1.png")
const Atlas = preload("res://scripts/sprite_atlas.gd")

var _sprite := Sprite2D.new()
var animal_id := ""
var local_cell := Vector2i.ZERO
var target_cell := Vector2i.ZERO
var local_position := Vector2.ZERO
var map_offset := Vector2i.ZERO
var elapsed := 0.0
var wait_time := 0.0
var step_index := 0
var moving := false
var facing := "down"
var affection := 0.0
var stride := 0.0


func _init() -> void:
	_sprite.texture = DUCK_ART
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	_sprite.region_enabled = true
	_sprite.region_filter_clip_enabled = true
	_sprite.show_behind_parent = true
	_sprite.z_index = -1
	add_child(_sprite)


func configure(id: String, index: int, offset: Vector2i) -> void:
	animal_id = id
	map_offset = offset
	if local_cell == Vector2i.ZERO:
		local_cell = Vector2i(53 - (index % 3) * 2, 29 + int(index / 3) * 2)
		target_cell = local_cell
		local_position = Vector2(local_cell) * TILE + Vector2.ONE * TILE * 0.5
	_update_position()
	_update_sprite()
	queue_redraw()


func set_map_offset(offset: Vector2i) -> void:
	map_offset = offset
	_update_position()


func tick(delta: float, roam_cells: Array[Vector2i], minutes: int, weather: String) -> void:
	elapsed += delta
	affection = maxf(0.0, affection - delta)
	visible = minutes < 1200 and weather != "雨" and not roam_cells.is_empty()
	if not visible: return
	wait_time -= delta
	if local_cell == target_cell and wait_time <= 0.0:
		step_index += 1
		var seed := absi(animal_id.hash()) + step_index * 19
		target_cell = roam_cells[posmod(seed, roam_cells.size())]
		wait_time = 1.0 + float(posmod(seed, 6)) * 0.24
	var target_position := Vector2(target_cell) * TILE + Vector2.ONE * TILE * 0.5
	moving = local_position.distance_to(target_position) > 1.0
	if moving:
		var direction := target_position - local_position
		facing = "left" if absf(direction.x) > absf(direction.y) and direction.x < 0.0 else "right" if absf(direction.x) > absf(direction.y) else "up" if direction.y < 0.0 else "down"
		var previous_position := local_position
		local_position = local_position.move_toward(target_position, 23.0 * delta)
		stride = fmod(stride + previous_position.distance_to(local_position) * 4.0 / 24.0, 4.0)
		local_cell = Vector2i(floori(local_position.x / TILE), floori(local_position.y / TILE))
	_update_position()
	_update_sprite()
	queue_redraw()


func show_affection() -> void:
	affection = 1.2
	queue_redraw()


func _update_sprite() -> void:
	var rows := {"down": 0, "left": 1, "right": 2, "up": 3}
	var column := int(stride) if moving else 0
	var frame: Dictionary = Atlas.frame(DUCK_ART, Vector2i(4, 4), column, int(rows.get(facing, 0)))
	var sprite_scale := 24.0 / maxf(frame.region.size.y, 1.0)
	_sprite.region_rect = frame.region
	_sprite.scale = Vector2.ONE * sprite_scale
	_sprite.position = Vector2(frame.offset) * sprite_scale
	_sprite.position.y -= 1.0 if moving and int(elapsed * 8.0) % 2 == 0 else 0.0


func _update_position() -> void:
	if local_position == Vector2.ZERO: local_position = Vector2(local_cell) * TILE + Vector2.ONE * TILE * 0.5
	position = local_position + Vector2(map_offset) * TILE
	z_index = int(position.y)


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2(0, 5), 10, Color(0.14, 0.15, 0.14, 0.24))
	draw_set_transform(Vector2.ZERO)
	if affection > 0.0:
		var heart := Vector2(-4, -34.0 - sin(elapsed * 6.0) * 2.0)
		draw_colored_polygon(PackedVector2Array([heart, heart + Vector2(4, -3), heart + Vector2(8, 0), heart + Vector2(8, 4), heart + Vector2(4, 9), heart + Vector2(0, 4)]), Color("ed7891"))
