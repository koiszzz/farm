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
	game.force_continuous_world_for_qa = true
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var entrances := {
		"farmhouse_interior": ["farm_outdoor", Vector2i(15, 10)],
		"general_store_interior": ["town_square", Vector2i(10, 11)],
		"clinic_interior": ["town_square", Vector2i(24, 9)],
		"cafe_interior": ["town_square", Vector2i(38, 11)],
	}
	var animations: Array[String] = []
	var rug_widths: Array[float] = []
	for target in entrances:
		var source_map: String = entrances[target][0]
		var local_cell: Vector2i = entrances[target][1]
		var world_cell: Vector2i = game.navigation.to_contiguous_world(source_map, local_cell)
		var target_record: Dictionary = game.navigation.interaction_at("valley_world", world_cell)
		expect(str(target_record.get("target", "")) == target, "continuous-world entrance keeps target: " + target)
		var rect: Rect2 = game.world.door_visual_rect(world_cell)
		var trigger_top: float = game.world.cell_to_screen(world_cell).y
		expect(rect.size.x >= 30.0 and rect.size.y >= 50.0, "door uses facade-scale artwork: " + target)
		expect(rect.end.y < trigger_top, "door remains in the building facade above its trigger: " + target)
		var source: Rect2 = game.world.door_source_rect(target)
		expect(source.size.x > 50.0 and source.size.y > 100.0, "door animation crops the authored building texture: " + target)
		animations.append(str(game.world.door_profile(target).animation))
		rug_widths.append(game.world.entrance_rug_size(target).x)
	expect(_unique_count(animations) == 4, "all four facade styles use different opening animations")
	expect(_unique_count(rug_widths) >= 3, "interior rug widths follow the exterior door proportions")

	var farm_door: Vector2i = game.navigation.to_contiguous_world("farm_outdoor", Vector2i(15, 10))
	game._change_map("valley_world", farm_door)
	game._enter_door("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"), farm_door)
	await create_timer(0.12).timeout
	expect(game.entering_door and game.current_map_id == "valley_world", "exterior door visibly opens before the map swap")
	expect(not game.scene_transition.overlay.visible, "black cover waits for the facade animation")
	await create_timer(0.20).timeout
	expect(game.world.door_open > 0.0, "facade animation advances before the map swap")
	expect(game.scene_transition.overlay.visible, "entering is covered by the black transition")
	await create_timer(0.70).timeout
	expect(game.current_map_id == "farmhouse_interior" and not game.entering_door, "centre-light reveal completes inside")
	expect(game.world._door_cells.is_empty(), "interiors have no animated exit door")
	expect(not game.world._object_cache["rug"].visible, "legacy universal rug is hidden")

	game._enter_door("farm_outdoor", Vector2i(15, 11), Vector2i(18, 17))
	await create_timer(0.10).timeout
	expect(game.world.door_open == 0.0 and game.scene_transition.overlay.visible, "leaving has black cover without an indoor door animation")
	await create_timer(0.68).timeout
	expect(game.current_map_id == "valley_world" and not game.entering_door, "centre-light reveal completes outside")
	game.queue_free()
	print("Door transition: %d failures; facade anchors, four animations, proportional rugs and centre-light round trip" % failures)
	quit(1 if failures else 0)


func _unique_count(values: Array) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()
