extends SceneTree

var failures := 0
var game

func _init() -> void:
	call_deferred("_run")

func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)
	for facing in ["up", "down", "left", "right"]:
		game.player.set_pose(facing, "idle")
		var idle_texture = game.player._body.texture
		var idle_region = game.player._body.region_rect
		expect(idle_texture.resource_path.ends_with("farmer_idle_v1.png"), "idle uses dedicated standing art: " + facing)
		expect(idle_region.size.x > 0 and idle_region.size.y > 0, "idle direction has opaque pixels: " + facing)
		game.player.stride = 0
		game.player.set_pose(facing, "walk_a")
		expect(game.player._body.texture != idle_texture, "walking does not reuse the standing frame: " + facing)
		expect(game.player._body.region_rect != idle_region, "standing and walking poses are visually distinct: " + facing)
	var npc_art := {
		"florist": [preload("res://assets/art/runtime_generated/florist_walk_v2.png"), preload("res://assets/art/runtime_generated/florist_idle_v1.png")],
		"shopkeeper": [preload("res://assets/art/runtime_generated/shopkeeper_walk_v2.png"), preload("res://assets/art/runtime_generated/shopkeeper_idle_v1.png")],
		"fisherman": [preload("res://assets/art/runtime_generated/fisherman_walk_v2.png"), preload("res://assets/art/runtime_generated/fisherman_idle_v1.png")],
	}
	for actor in npc_art:
		var npc = preload("res://scripts/art_actor.gd").new()
		root.add_child(npc)
		npc.configure(npc_art[actor][0], npc_art[actor][1], 0.13)
		for facing in ["down", "left", "right", "up"]:
			npc.set_pose(facing, "idle")
			var idle_texture: Texture2D = npc._sprite.texture
			var idle_region: Rect2 = npc._sprite.region_rect
			expect(idle_texture.resource_path.ends_with(actor + "_idle_v1.png"), actor + " idle uses dedicated standing art: " + facing)
			expect(idle_region.size.x > 0 and idle_region.size.y > 0, actor + " idle direction has opaque pixels: " + facing)
			npc.stride = 0.0
			npc.set_pose(facing, "walk_a")
			expect(npc._sprite.texture != idle_texture, actor + " walking does not reuse standing art: " + facing)
		npc.queue_free()
	var nav = game.navigation
	expect(not nav.is_walkable("farm_outdoor", Vector2i(4,6)), "tree root blocks")
	expect(nav.is_walkable("farm_outdoor", Vector2i(4,5)), "canopy does not block")
	expect(nav.is_walkable("farm_outdoor", Vector2i(15,4)), "roof projection does not block")
	expect(not nav.is_walkable("farm_outdoor", Vector2i(15,8)), "house ground footprint blocks")
	expect(nav.is_walkable("town_square", Vector2i(23,18)), "fountain upper projection does not block")
	expect(not nav.is_walkable("town_square", Vector2i(23,20)), "fountain basin blocks")
	game._change_map("farm_outdoor", Vector2i(3,5))
	await physics_frame
	game._begin_move(Vector2i.RIGHT)
	for frame in 30: game._update_player_movement(1.0 / 60.0)
	expect(game.player_cell == Vector2i(4,5), "real movement passes underneath canopy")
	game._begin_move(Vector2i.DOWN)
	for frame in 30: game._update_player_movement(1.0 / 60.0)
	expect(game.player_cell == Vector2i(4,5) and not game.moving, "real movement stops at tree root")
	for sample in [["farm_outdoor", Vector2i(4,5)], ["farm_outdoor", Vector2i(15,5)], ["town_square", Vector2i(23,18)], ["farmhouse_interior", Vector2i(12,4)]]:
		game._change_map(sample[0], sample[1])
		game._process(0)
		expect(game.occlusion_shadow.visible, "raised object reveals silhouette: " + str(sample))
	game._change_map("farm_outdoor", Vector2i(4,7))
	game._process(0)
	expect(not game.occlusion_shadow.visible, "standing in front of tree removes silhouette")
	for id in nav.map_ids():
		if not id.ends_with("_interior"): continue
		game._change_map(id, nav.get_spawn(id))
		var reachable := {}
		var pending: Array[Vector2i] = [nav.get_spawn(id)]
		while not pending.is_empty():
			var cell := pending.pop_back() as Vector2i
			if reachable.has(cell): continue
			reachable[cell] = true
			for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
				var next: Vector2i = cell + direction
				if nav.is_walkable(id, next) and not reachable.has(next): pending.append(next)
		var size: Vector2i = nav.get_map_size(id)
		for y in size.y:
			for x in size.x:
				var cell := Vector2i(x,y)
				if nav.is_walkable(id,cell): expect(reachable.has(cell), "%s floor reachable at %s" % [id,cell])
		expect(reachable.size() > 240, "interior has broad connected walking floor: " + id)
		for obj in game.world.raised_objects:
			expect(obj.scale.x > 0 and obj.scale.y > 0, "furniture renders with valid scale")
	game.queue_free()
	print("Spatial consistency: %d failures" % failures)
	quit(1 if failures else 0)
