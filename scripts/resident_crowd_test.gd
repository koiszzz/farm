extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")
const SIMULATION_SECONDS := 180.0
const STEP_SECONDS := 1.0 / 30.0
const CROWD_DISTANCE := 24.0

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _expect(condition: bool, label: String) -> void:
	if condition: return
	failures += 1
	push_error(label)


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.force_continuous_world_for_qa = true
	game.save_path = "user://resident-crowd-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://resident-crowd-display-unused.cfg"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.creator.hide()
	game.farm.day = 1
	game.clock_minutes = 360
	game._change_map("town_square", Vector2i(20, 20))
	_expect(game.npcs.size() == game.VillageScript.PEOPLE.size(), "crowd simulation starts with all ten morning residents")
	_expect(game.NPC_ART.size() == game.VillageScript.PEOPLE.size(), "every resident has an identity-specific walking atlas")
	await physics_frame
	var resident_start_phases := {}
	for actor in game.npcs:
		var phase_actor = game.npcs[actor].node
		if not game.NPC_ART.has(str(actor)):
			_expect(phase_actor._identity_walk and phase_actor._sprite.texture == phase_actor._idle_texture and phase_actor._sprite.material == null, "resident without custom walk art keeps its own cast during movement without fragment artifacts")
		phase_actor.set_pose(phase_actor.facing, "idle")
		phase_actor.set_pose(phase_actor.facing, "walk_a")
		resident_start_phases[snappedf(phase_actor.stride, 0.001)] = true
		phase_actor.set_pose(phase_actor.facing, "idle")
	_expect(resident_start_phases.size() >= 8, "resident walk cycles start at individual phases instead of marching in sync")
	for actor_id in ["mayor", "carpenter", "doctor", "cook", "ranger", "teacher", "child"]:
		_verify_eight_frame_actor(game.npcs[actor_id].node, actor_id)
	var first_resident = game.npcs[game.npcs.keys()[0]].node
	first_resident.stride = 2.5
	first_resident.set_pose(first_resident.facing, "idle")
	_expect(is_zero_approx(first_resident.stride), "resident stopping at a patrol point resets the walk phase to a planted idle stance")
	first_resident.stride = 1.0
	first_resident.set_pose(first_resident.facing, "walk_a")
	_expect(is_equal_approx(first_resident._locomotion_bob(), 0.7), "resident walk cycle adds a gentle body rise on its weight-transfer phase")
	first_resident.running = true
	_expect(is_equal_approx(first_resident._locomotion_bob(), 1.5), "resident rain and evening running use a stronger rise")
	first_resident.set_pose(first_resident.facing, "idle")
	_expect(is_zero_approx(first_resident._locomotion_bob()), "resident idle stance returns to the fixed foot anchor")
	var resident = null
	var resident_id := ""
	var approach_direction := Vector2i.ZERO
	for actor in game.npcs:
		var candidate_resident = game.npcs[actor].node
		var resident_cell: Vector2i = game._cell_from_world_position(candidate_resident.position)
		for candidate in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var approach_cell: Vector2i = resident_cell + candidate
			var approach_position: Vector2 = game._avatar_position_for(approach_cell)
			if not game.navigation.is_walkable("valley_world", approach_cell) or not game.navigation.has_clear_line("valley_world", approach_position, candidate_resident.position): continue
			game.player_cell = approach_cell
			game.player_body.position = approach_position
			var into_resident: Vector2i = -candidate
			game.player.set_pose(game._facing_for(into_resident), "idle")
			var prompt_target: Dictionary = game._interaction_target()
			if str(prompt_target.get("kind", "")) == "npc" and str(prompt_target.get("actor", "")) == str(actor):
				resident = candidate_resident
				resident_id = str(actor)
				approach_direction = into_resident
				break
		if resident != null: break
	_expect(resident != null, "a resident has an open approach where the F prompt resolves dialogue")
	if approach_direction != Vector2i.ZERO:
		Motion.hold(approach_direction)
		for _step in 30:
			game._update_player_movement(1.0 / 60.0)
			if game._resident_bump_elapsed.has(resident_id): break
		Motion.hold(Vector2i.ZERO)
		game._update_player_movement(0.0)
		var player_to_resident: float = game.player_body.position.distance_to(resident.position)
		_expect(player_to_resident >= 15.0 and player_to_resident <= 22.0, "player meets a resident's soft foot collider while remaining close enough to talk")
		_expect(game._interaction_target().get("actor", "") == resident_id, "the visible F prompt still selects the resident at collision distance")
		Motion.hold(approach_direction)
		for _step in 12:
			game._update_player_movement(1.0 / 60.0)
			if int(resident.get_node("ResidentFootBody").collision_layer) == 0: break
		_expect(int(resident.get_node("ResidentFootBody").collision_layer) == 0, "a held bump briefly yields the resident's foot collider")
		for _step in 30:
			game._update_player_movement(1.0 / 60.0)
			game._update_npcs(1.0 / 60.0)
		Motion.hold(Vector2i.ZERO)
		game._update_player_movement(0.0)
		_expect(int(resident.get_node("ResidentFootBody").collision_layer) == 1, "resident collider restores after the player clears the shared space")
	game.player_body.position = Vector2(235 * 32 + 16, 100 * 32 + 16)
	game.player_cell = game._cell_from_world_position(game.player_body.position)

	var minimum_spacing := INF
	var crowded_samples := 0
	var closest_pair := PackedStringArray()
	var frame_count := ceili(SIMULATION_SECONDS / STEP_SECONDS)
	for _frame in frame_count:
		game._update_npcs(STEP_SECONDS)
		var actors: Array = game.npcs.keys()
		var crowded := false
		for first_index in actors.size():
			var first_actor: String = str(actors[first_index])
			var first_position: Vector2 = game.npcs[first_actor].node.position
			for second_index in range(first_index + 1, actors.size()):
				var second_actor: String = str(actors[second_index])
				var second_position: Vector2 = game.npcs[second_actor].node.position
				var spacing := first_position.distance_to(second_position)
				if spacing < minimum_spacing:
					minimum_spacing = spacing
					closest_pair = PackedStringArray([first_actor, second_actor])
				if spacing < CROWD_DISTANCE:
					crowded = true
		if crowded: crowded_samples += 1

	_expect(crowded_samples == 0, "town patrols do not overlap in motion for 180 simulated seconds")
	print("Resident crowd: %d failures; duration=%.0fs residents=%d min_spacing=%.2fpx closest=%s crowded_samples=%d" % [failures, SIMULATION_SECONDS, game.npcs.size(), minimum_spacing, ",".join(closest_pair), crowded_samples])
	game.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _verify_eight_frame_actor(actor, actor_id: String) -> void:
	actor.set_pose("down", "walk_a")
	_expect(not actor._identity_walk and actor._sprite.texture == actor._walk_texture, "%s uses a dedicated walk sheet while retaining the resident cast for idle poses" % actor_id)
	_expect(actor._walk_columns == 8 and actor._walk_rows == 4 and actor._walk_texture.get_width() == 1776 and actor._walk_texture.get_height() == 888, "%s eight-frame four-direction walk atlas uses the packed 8x4 layout" % actor_id)
	actor.stride = 0.0
	actor.advance_stride(4.5)
	_expect(is_equal_approx(actor.stride, 1.0), "%s eight-frame stride advances two poses over the same distance as a four-frame cycle" % actor_id)
	for facing in ["down", "left", "right", "up"]:
		var row := ["down", "left", "right", "up"].find(facing)
		for frame in 8:
			actor.stride = float(frame)
			actor.set_pose(facing, "walk_a")
			actor._update_region()
			var region: Rect2 = actor._sprite.region_rect
			var cell_origin := Vector2(frame * 222, row * 222)
			_expect(region.size.x > 0 and region.size.y > 0 and region.position.x >= cell_origin.x and region.position.y >= cell_origin.y and region.end.x <= cell_origin.x + 222 and region.end.y <= cell_origin.y + 222, "%s walk frame remains inside its atlas cell for %s frame %d" % [actor_id, facing, frame])
