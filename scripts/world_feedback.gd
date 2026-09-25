extends Node2D

var game
var time := 0.0
var bursts: Array[Dictionary] = []
var hovered := Vector2i(-1, -1)
var use_mouse := false

func _ready() -> void:
	z_index = 2050
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func burst(point: Vector2, text: String, color := Color("f3d16c")) -> void:
	game._set_status(text)
	bursts.append({"point": point, "text": text, "color": color, "age": 0.0})

func _process(delta: float) -> void:
	time += delta
	for effect in bursts: effect.age += delta
	bursts = bursts.filter(func(effect): return effect.age < 1.1)
	queue_redraw()

func _draw() -> void:
	if game == null or game.world == null or game.player == null: return
	var blocked: bool = game.creator == null or game.creator.visible or (game.life_panel != null and game.life_panel.visible) or (game.inventory_panel != null and game.inventory_panel.visible) or (game.festival_hunt != null and game.festival_hunt.active)
	if not blocked and not game.entering_door:
		var target: Vector2i = hovered if use_mouse else game.player_cell + game._facing_delta(game.player.facing)
		var delta: Vector2i = target - game.player_cell
		if absi(delta.x) + absi(delta.y) == 1 and game.navigation.is_in_bounds(game.current_map_id, target):
			var rect := Rect2(game.world.cell_to_screen(target) + Vector2(2, 2), Vector2(28, 28))
			var valid: bool = game._tool_can_target(target)
			var color := Color("fff2a1") if valid else Color("dd9578")
			for corner in [Vector2.ZERO, Vector2(28, 0), Vector2(0, 28), Vector2(28, 28)]:
				var p: Vector2 = rect.position + corner
				draw_line(p, p + Vector2(7 if corner.x == 0 else -7, 0), color, 2)
				draw_line(p, p + Vector2(0, 7 if corner.y == 0 else -7), color, 2)
	for effect in bursts:
		var age: float = effect.age
		var color: Color = effect.color
		color.a = 1.0 - age / 1.1
		for index in 7:
			var angle := float(index) * TAU / 7
			var p: Vector2 = effect.point + Vector2(cos(angle) * age * 24, -sin(angle) * age * 14 - 12 * age)
			draw_rect(Rect2(p, Vector2(3, 3)), color)
