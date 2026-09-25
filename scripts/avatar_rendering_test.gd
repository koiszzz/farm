extends SceneTree

const Avatar = preload("res://scripts/avatar_renderer.gd")
const WALK_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_walk_v5.png")
const RUN_ART: Texture2D = preload("res://assets/art/runtime_generated/farmer_run_v3.png")
const SpriteAtlas = preload("res://scripts/sprite_atlas.gd")
const DIRECTIONS := ["down", "left", "right", "up"]

var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	expect(WALK_ART.get_width() % 8 == 0 and WALK_ART.get_height() % 4 == 0, "Walk atlas divides evenly into eight phases and four directions")
	expect(WALK_ART.get_size() == Vector2(1536, 1024), "Walk atlas uses a consistent 192 by 256 pixel cell")
	expect(RUN_ART.get_size() == Vector2(1536, 1024), "Run atlas uses the same eight-phase four-direction contract")
	var avatar = Avatar.new()
	root.add_child(avatar)
	await process_frame
	avatar.pixel_scale = 0.13
	avatar.set_pose("down", "walk")
	expect(avatar._body.texture.resource_path.ends_with("farmer_walk_v5.png") and avatar._body.region_filter_clip_enabled and avatar._body.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "runtime stride sheet is clipped to nearest-filtered frame regions")
	var target_height := 44.0
	for direction in DIRECTIONS:
		avatar.set_pose(direction, "walk")
		var row := DIRECTIONS.find(direction)
		var reference_anchor := Vector2.ZERO
		for phase in 8:
			avatar.stride = float(phase)
			avatar._apply_pose()
			var visible_height: float = avatar._body.region_rect.size.y * avatar._body.scale.y
			expect(absf(visible_height - target_height) <= 0.01, "%s phase %d keeps the same visible body height" % [direction, phase])
			var anchored_frame := SpriteAtlas.row_anchored_frame(WALK_ART, Vector2i(8, 4), phase, row)
			var cell_origin := Vector2(phase * 192, row * 256)
			var local_region_origin: Vector2 = anchored_frame.region.position - cell_origin
			var rendered_anchor: Vector2 = local_region_origin - anchored_frame.offset
			if phase == 0: reference_anchor = rendered_anchor
			expect(rendered_anchor.distance_to(reference_anchor) < 0.001, "%s phase %d preserves the fixed body anchor" % [direction, phase])
	avatar.running = true
	avatar.set_pose("down", "walk")
	expect(avatar._body.texture == RUN_ART and avatar._body.region_filter_clip_enabled, "running selects its dedicated clipped atlas")
	var run_image := RUN_ART.get_image()
	var vertical_seam_pixels := 0
	var horizontal_seam_pixels := 0
	for column in range(1, 8):
		for y in run_image.get_height():
			if run_image.get_pixel(column * 192, y).a > 0.05: vertical_seam_pixels += 1
	for row in range(1, 4):
		for x in run_image.get_width():
			if run_image.get_pixel(x, row * 256).a > 0.05: horizontal_seam_pixels += 1
	expect(vertical_seam_pixels <= 12 and horizontal_seam_pixels == 0, "run poses stay clear of atlas seams")
	for direction in DIRECTIONS:
		avatar.set_pose(direction, "walk")
		var row := DIRECTIONS.find(direction)
		var reference_anchor := Vector2.ZERO
		for phase in 8:
			avatar.stride = float(phase)
			avatar._apply_pose()
			var visible_height: float = avatar._body.region_rect.size.y * avatar._body.scale.y
			expect(absf(visible_height - target_height) <= 0.01, "run %s phase %d keeps the same visible body height" % [direction, phase])
			var anchored_frame: Dictionary = SpriteAtlas.row_anchored_frame(RUN_ART, Vector2i(8, 4), phase, row)
			var cell_origin := Vector2(phase * 192, row * 256)
			var local_region_origin: Vector2 = anchored_frame.region.position - cell_origin
			var rendered_anchor: Vector2 = local_region_origin - anchored_frame.offset
			if phase == 0: reference_anchor = rendered_anchor
			expect(rendered_anchor.distance_to(reference_anchor) < 0.001, "run %s phase %d preserves the fixed body anchor" % [direction, phase])
	avatar.running = false
	avatar.set_pose("down", "walk")
	expect(avatar._body.texture == WALK_ART, "walking selects its separate walk atlas")
	print("Avatar rendering: %d checks, %d failures" % [checks, failures])
	avatar.queue_free()
	quit(1 if failures > 0 else 0)
