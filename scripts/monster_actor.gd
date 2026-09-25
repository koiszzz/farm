extends Node2D

const TILE := 32.0
var monster_id := ""
var monster_type := "slime"
var map_id := ""
var navigation
var mining
var combat
var home_position := Vector2.ZERO
var target_position := Vector2.ZERO
var elapsed := 0.0
var wander_clock := 0.0
var hit_flash := 0.0


func configure(entry: Dictionary, next_navigation, next_mining, next_combat) -> void:
	monster_id = str(entry.id)
	monster_type = str(entry.type)
	map_id = str(entry.map)
	navigation = next_navigation
	mining = next_mining
	combat = next_combat
	position = Vector2(int(entry.x), int(entry.y)) * TILE + Vector2.ONE * TILE * 0.5
	home_position = position
	target_position = position
	z_index = int(position.y)
	queue_redraw()


func tick(delta: float, player_position: Vector2, day: int) -> void:
	elapsed += delta
	hit_flash = maxf(0.0, hit_flash - delta)
	wander_clock -= delta
	var distance := position.distance_to(player_position)
	if distance < 220.0:
		target_position = player_position
	elif wander_clock <= 0.0:
		wander_clock = 1.2 + float(posmod(monster_id.hash() + int(elapsed * 10.0), 9)) * 0.16
		var angle := float(posmod(monster_id.hash() + int(elapsed * 19.0), 628)) / 100.0
		target_position = home_position + Vector2(cos(angle), sin(angle)) * 54.0
	var speed := float(combat.DEFINITIONS[monster_type].speed)
	var candidate := position.move_toward(target_position, speed * delta)
	var cell := Vector2i(floori(candidate.x / TILE), floori(candidate.y / TILE))
	if navigation.is_walkable(map_id, cell) and mining.vein(map_id, cell, day).is_empty():
		position = candidate
		combat.update_position(monster_id, cell)
	else:
		target_position = home_position
	z_index = int(position.y)
	queue_redraw()


func show_hit(attacker_position: Vector2) -> void:
	hit_flash = 0.18
	var away := (position - attacker_position).normalized()
	var candidate := position + away * 14.0
	var cell := Vector2i(floori(candidate.x / TILE), floori(candidate.y / TILE))
	if navigation.is_walkable(map_id, cell): position = candidate
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.38))
	draw_circle(Vector2(0, 5), 12, Color(0.10, 0.08, 0.13, 0.28))
	draw_set_transform(Vector2.ZERO)
	var tint := Color("fff1da") if hit_flash > 0 else Color.WHITE
	if monster_type == "slime":
		var bob := sin(elapsed * 5.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-13, 3), Vector2(-11, -8 + bob), Vector2(-5, -16 + bob), Vector2(6, -16 + bob), Vector2(12, -7 + bob), Vector2(14, 4), Vector2(8, 9), Vector2(-8, 9)]), Color("78a85c") * tint)
		draw_circle(Vector2(-5, -7 + bob), 2, Color("263329"))
		draw_circle(Vector2(5, -7 + bob), 2, Color("263329"))
		draw_line(Vector2(-5, 1), Vector2(5, 1), Color("496440"), 2)
	else:
		var flap := sin(elapsed * 11.0) * 5.0
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -8), Vector2(-21, -15 - flap), Vector2(-15, 2), Vector2(-5, 5)]), Color("665776") * tint)
		draw_colored_polygon(PackedVector2Array([Vector2(2, -8), Vector2(21, -15 - flap), Vector2(15, 2), Vector2(5, 5)]), Color("665776") * tint)
		draw_circle(Vector2(0, -5), 8, Color("4b4059") * tint)
		draw_circle(Vector2(-3, -7), 1.5, Color("e7c75b"))
		draw_circle(Vector2(3, -7), 1.5, Color("e7c75b"))
	var entry: Dictionary = combat.monster(monster_id)
	if not entry.is_empty() and int(entry.health) < int(entry.max_health):
		draw_rect(Rect2(Vector2(-13, -29), Vector2(26, 4)), Color("332c35"))
		draw_rect(Rect2(Vector2(-12, -28), Vector2(24.0 * float(entry.health) / float(entry.max_health), 2)), Color("d85b4b"))
