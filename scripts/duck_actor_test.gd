extends SceneTree

const DuckScript = preload("res://scripts/duck_actor.gd")
const DUCK_ART: Texture2D = preload("res://assets/art/runtime_generated/duck_walk_v1.png")
const DIRECTIONS := ["down", "left", "right", "up"]
const OUTPUT_PATH := "res://design/qa/2026-09-24/animal-art/duck-directions.png"

var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func _run() -> void:
	if DisplayServer.get_name() != "headless":
		root.content_scale_size = Vector2i(1280, 720)
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://duck-actor-test-unused.json"
	game.display_config_path = "user://duck-actor-test-unused.cfg"
	game.set_physics_process(false)
	root.add_child(game)
	await process_frame
	for child in game.get_children():
		if child is CanvasLayer: child.hide()
	game.animals.coop_built = true
	game.animals.ducks.append({"id": "duck_live", "name": "青豆", "age": 1, "affection": 0, "petted_day": 0, "fed_day": 0})
	game._sync_duck_actors()
	var live_duck = game.duck_actors.get("duck_live")
	_expect(live_duck != null, "farm creates a duck actor from saved livestock")
	_expect(live_duck._sprite.texture.resource_path.ends_with("duck_walk_v1.png"), "live farm duck uses the pixel atlas")
	_expect(live_duck.visible, "live duck remains visible in a clear daytime farm scene")
	var live_target: Vector2i = live_duck.local_cell + Vector2i.RIGHT
	var live_roam_cells: Array[Vector2i] = [live_target]
	live_duck.target_cell = live_target
	live_duck.tick(0.25, live_roam_cells, 600, "晴")
	live_duck.tick(0.25, live_roam_cells, 600, "晴")
	_expect(live_duck.facing == "right" and live_duck.stride > 0.0, "live duck animation follows its real movement direction")
	live_duck.show_affection()
	_expect(live_duck.affection > 0.0, "live duck retains the affection response")
	var stage := CanvasLayer.new()
	stage.layer = 100
	root.add_child(stage)
	if DisplayServer.get_name() != "headless":
		var backdrop := ColorRect.new()
		backdrop.color = Color("d5d8bc")
		backdrop.size = Vector2(1280, 720)
		stage.add_child(backdrop)
	for row in DIRECTIONS.size():
		if DisplayServer.get_name() != "headless":
			var label := Label.new()
			label.text = DIRECTIONS[row]
			label.position = Vector2(12, 44 + row * 156)
			label.modulate = Color("35473f")
			stage.add_child(label)
		for column in 4:
			var duck = DuckScript.new()
			duck.configure("duck_%d_%d" % [row, column], 0, Vector2i.ZERO)
			duck.facing = DIRECTIONS[row]
			duck.moving = true
			duck.stride = float(column)
			duck._update_sprite()
			duck.position = Vector2(160 + column * 275, 82 + row * 156)
			stage.add_child(duck)
			_expect(duck._sprite.texture.resource_path.ends_with("duck_walk_v1.png"), "duck uses the authored walk atlas")
			_expect(duck._sprite.region_rect.size.x > 0 and duck._sprite.region_rect.size.y > 0, "duck frame slices to a visible region")

	var moving_duck = DuckScript.new()
	moving_duck.configure("duck_stride_probe", 0, Vector2i.ZERO)
	root.add_child(moving_duck)
	var target: Vector2i = moving_duck.local_cell + Vector2i.RIGHT
	moving_duck.target_cell = target
	moving_duck.tick(0.25, [target], 600, "晴")
	moving_duck.tick(0.25, [target], 600, "晴")
	_expect(moving_duck.facing == "right", "duck faces its actual direction of travel")
	_expect(moving_duck.stride > 0.0, "duck walk phase advances from distance travelled")
	moving_duck.show_affection()
	_expect(moving_duck.affection > 0.0, "duck affection feedback remains available")

	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://design/qa/2026-09-24/animal-art"))
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT_PATH)
		print("Duck directions: " + OUTPUT_PATH)
	print("Duck actor: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
