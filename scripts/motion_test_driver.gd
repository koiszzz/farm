extends RefCounted

## Exercises the same held keyboard state as gameplay, without grid commands.
static func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

static func hold(direction: Vector2i) -> void:
	key(KEY_A, direction.x < 0)
	key(KEY_D, direction.x > 0)
	key(KEY_W, direction.y < 0)
	key(KEY_S, direction.y > 0)

static func walk(game, direction: Vector2i, seconds := 0.25) -> void:
	hold(direction)
	var remaining := seconds
	while remaining > 0.000001 and not game.entering_door:
		var delta := minf(remaining, 1.0 / 60.0)
		game._update_player_movement(delta)
		remaining -= delta
	hold(Vector2i.ZERO)
	game._update_player_movement(0.0)
