extends SceneTree

const ArtActorScript = preload("res://scripts/art_actor.gd")
const OUTPUT_DIR := "res://design/qa/2026-09-09/npc-idle"
const WALK_ART := {
	"florist": preload("res://assets/art/runtime_generated/florist_walk_v2.png"),
	"shopkeeper": preload("res://assets/art/runtime_generated/shopkeeper_walk_v2.png"),
	"fisherman": preload("res://assets/art/runtime_generated/fisherman_walk_v2.png"),
}
const IDLE_ART := {
	"florist": preload("res://assets/art/runtime_generated/florist_idle_v1.png"),
	"shopkeeper": preload("res://assets/art/runtime_generated/shopkeeper_idle_v1.png"),
	"fisherman": preload("res://assets/art/runtime_generated/fisherman_idle_v1.png"),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game._change_map("farm_outdoor", Vector2i(8, 13))
	game.player.hide()
	game.game_camera.zoom = Vector2.ONE * 3.0
	game.game_camera.reset_smoothing()
	var actors: Array = []
	for index in WALK_ART.keys().size():
		var actor_id: String = WALK_ART.keys()[index]
		var actor = ArtActorScript.new()
		actor.configure(WALK_ART[actor_id], IDLE_ART[actor_id], 0.13)
		actor.position = game.player_body.position + Vector2((index - 1) * 58, 0)
		actor.z_index = 10
		game.add_child(actor)
		actors.append(actor)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for facing in ["down", "left", "right", "up"]:
		for actor in actors:
			actor.set_pose(facing, "idle")
		await create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path: String = OUTPUT_DIR + "/npc_idle_" + facing + ".png"
		image.save_png(path)
		print("NPC_IDLE_FRAMEBUFFER " + path)
	game.queue_free()
	quit()
