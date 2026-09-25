extends SceneTree

const ArtActorScript = preload("res://scripts/art_actor.gd")
const OUTPUT_DIR := "res://design/qa/2026-09-25/npc-animation"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game._change_map("town_square", Vector2i(20, 20))
	game.player.hide()
	game.world.hide()
	for child in game.get_children():
		if child is CanvasLayer: child.hide()
	var display := CanvasLayer.new()
	display.layer = 10
	root.add_child(display)
	var backdrop := ColorRect.new()
	backdrop.color = Color("43553f")
	backdrop.size = Vector2(1280, 720)
	display.add_child(backdrop)
	var actors: Array = []
	var actor_ids: Array = game.VillageScript.PEOPLE.keys()
	for index in actor_ids.size():
		var actor_id: String = actor_ids[index]
		var actor = ArtActorScript.new()
		var walk_columns := 8 if actor_id in ["mayor", "carpenter", "doctor", "cook", "ranger", "teacher", "child"] else 4
		actor.configure(game._npc_walk_texture(actor_id), game._npc_idle_texture(actor_id), 0.195, game._npc_idle_column(actor_id), 10, 3, game.NPC_WALK_TINTS.get(actor_id, Color.WHITE), not game.NPC_ART.has(actor_id), walk_columns, 4)
		actor.position = Vector2(640 + (index - 4.5) * 95, 360)
		actor.z_index = 1
		display.add_child(actor)
		actors.append(actor)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for facing in ["down", "left", "right", "up"]:
		for actor in actors:
			actor.set_pose(facing, "idle")
		await create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path: String = OUTPUT_DIR + "/resident_cast_" + facing + ".png"
		image.save_png(path)
		print("NPC_IDLE_FRAMEBUFFER " + path)
	for actor in actors:
		actor.running = false
		actor.stride = 1.0
		actor.set_pose("down", "walk_a")
	await process_frame
	await RenderingServer.frame_post_draw
	var walking_image := root.get_texture().get_image()
	var walking_path := OUTPUT_DIR + "/resident_walk_down_phase.png"
	walking_image.save_png(walking_path)
	print("NPC_WALK_FRAMEBUFFER " + walking_path)
	game.queue_free()
	quit()
