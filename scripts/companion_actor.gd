extends Node2D

const Atlas = preload("res://scripts/sprite_atlas.gd")
var art: Texture2D
var model
var navigation
var farm
var home_cell := Vector2i(21, 11)
var world_map_id := "farm_outdoor"
var cell := Vector2i(21, 11)
var target := Vector2.ZERO
var facing := "down"
var elapsed := 0.0
var affection := 0.0
var step_clock := 0.0
var walking := false
var sleeping := false
var grid := AStarGrid2D.new()
var sprite := Sprite2D.new()
var cached_path: Array[Vector2i] = []
var cached_path_index := 0
var cached_goal := Vector2i(-999, -999)
var cached_mode := ""

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.region_enabled = true
	add_child(sprite)
	art = load("res://assets/art/runtime_generated/farm_dog_v1.png") if ResourceLoader.exists("res://assets/art/runtime_generated/farm_dog_v1.png") else null
	sprite.texture = art
	position = Vector2(home_cell) * 32 + Vector2(16, 16)
	target = position

func rebuild_grid() -> void:
	grid.region = Rect2i(Vector2i.ZERO, navigation.get_map_size(world_map_id))
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var p := Vector2i(x, y)
			grid.set_point_solid(p, not navigation.is_walkable(world_map_id, p, farm.is_crop_occupied(p)))
	_clear_cached_path()

func reset_home() -> void:
	cell = home_cell
	position = Vector2(cell) * 32 + Vector2(16, 16)
	target = position
	walking = false
	_clear_cached_path()

func tick(delta: float, player_position: Vector2, minutes: int) -> void:
	elapsed += delta
	affection = maxf(0, affection - delta)
	sleeping = minutes >= 1200
	if affection > 0:
		walking = false
	elif position.distance_to(target) > 0.5:
		var target_cell := Vector2i(floori(target.x / 32), floori(target.y / 32))
		if grid.is_point_solid(target_cell):
			position = Vector2(cell) * 32 + Vector2(16, 16)
			target = position
			walking = false
			return
		walking = true
		var direction := target - position
		facing = "left" if direction.x < -1 else "right" if direction.x > 1 else "up" if direction.y < 0 else "down"
		position = position.move_toward(target, 88 * delta)
	else:
		walking = false
		cell = Vector2i(floori(position.x / 32), floori(position.y / 32))
		step_clock -= delta
		if step_clock <= 0:
			step_clock = 0.35
			var goal := home_cell
			var mode := "home"
			if model.following and not sleeping:
				mode = "follow"
				if position.distance_to(player_position) < 58: goal = cell
				else: goal = Vector2i(floori(player_position.x / 32), floori(player_position.y / 32))
			if grid.is_in_boundsv(cell) and grid.is_in_boundsv(goal) and not grid.is_point_solid(goal):
				var needs_replan := cached_mode != mode or cached_path_index >= cached_path.size() or cached_goal.distance_to(goal) >= 4.0
				if needs_replan:
					cached_path = grid.get_id_path(cell, goal)
					cached_path_index = 1
					cached_goal = goal
					cached_mode = mode
				while cached_path_index < cached_path.size() and cached_path[cached_path_index] == cell:
					cached_path_index += 1
				if cached_path_index < cached_path.size():
					target = Vector2(cached_path[cached_path_index]) * 32 + Vector2(16, 16)
					cached_path_index += 1
	z_index = int(position.y)
	if art != null:
		var row := int({"down": 0, "left": 1, "right": 2, "up": 3}[facing])
		var frame: Dictionary = Atlas.frame(art, Vector2i(4, 4), int(elapsed * 9) % 4 if walking else 0, row)
		sprite.region_rect = frame.region
		var pixel_scale := 36.0 / (art.get_height() / 4.0)
		sprite.scale = Vector2(pixel_scale, pixel_scale * 0.72 if sleeping and cell == home_cell else pixel_scale)
		sprite.position = frame.offset * sprite.scale
	queue_redraw()


func _clear_cached_path() -> void:
	cached_path.clear()
	cached_path_index = 0
	cached_goal = Vector2i(-999, -999)
	cached_mode = ""

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 13, Color(0.15, 0.19, 0.08, 0.25))
	draw_set_transform(Vector2.ZERO)
	if affection > 0:
		var p := Vector2(-4, -38 - sin(elapsed * 6) * 2)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(4, -3), p + Vector2(8, 0), p + Vector2(8, 4), p + Vector2(4, 9), p + Vector2(0, 4)]), Color("ed7891"))
	if sleeping and cell == home_cell and not walking:
		draw_string(ThemeDB.fallback_font, Vector2(5, -24), "z Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("fff2c9"))
