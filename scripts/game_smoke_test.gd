extends SceneTree

const Motion = preload("res://scripts/motion_test_driver.gd")

## Headless integration smoke test for the first playable loop shell.

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node2D = preload("res://Main.tscn").instantiate()
	scene.autosave_enabled = false
	root.add_child(scene)
	await process_frame
	await process_frame
	_expect(scene.farm_music.track_id == "farm_day_spring" and scene.farm_music.active_player.playing, "farm gameplay starts its original spring regional music loop")
	_expect(scene.farm_music.cached_tracks.has("farm_spring"), "farm soundtrack is cached after first play")
	_expect(scene.current_map_id == "farm_outdoor", "game should start on the farm")
	_expect(not scene.navigation.has_map("valley_world"), "regional play should not construct the unused merged world during startup")
	_expect(scene.navigation.has_map("farm_outdoor") and scene.navigation.has_map("countryside") and scene.navigation.has_map("town_square") and scene.navigation.has_map("beach") and scene.navigation.has_map("cave"), "all five regional play spaces remain ready at startup")
	_expect(scene.player_cell == Vector2i(17, 16), "farm player spawn should come from navigation data")
	_expect(not scene.creator.visible, "first launch must leave the farm playable instead of blocking movement with the character creator")
	_expect(scene.hud_location.text == "花溪谷 · 花溪农场", "compact HUD names the game and current region without repeating the farm name")
	_expect(scene.hud_hotbar_info != null and not scene.hud_hotbar_info.visible, "selected hotbar item does not occupy a permanent HUD panel")
	scene._show_hotbar_info(0)
	_expect(scene.hud_hotbar_info.visible and scene.hud_hotbar_info.text == "锄头", "hotbar item name appears on hover")
	scene._show_hotbar_info(-1)
	_expect(not scene.hud_hotbar_info.visible and scene.hud_hotbar_info.text.is_empty(), "hotbar item name clears when hover ends")

	scene.creator.open(scene.player.get_customization())
	scene._on_customization_confirmed({"skin": "golden", "hair": "bun", "hair_color": "silver", "eyes": "bright", "eye_color": "green", "nose": "button", "mouth": "smile", "ears": "pierced", "clothes": "gardener"})
	_expect(not scene.creator.visible, "character creator should close after confirmation")
	_expect(scene.player.get_customization().get("hair", "") == "bun", "confirmed appearance should apply to the player")
	# A normal grass cell must not be mistaken for an exit or interaction.
	_expect(scene.navigation.exit_at("farm_outdoor", Vector2i(18, 16)).is_empty(), "ordinary farm tiles must not return an exit record")
	_expect(scene.navigation.interaction_at("farm_outdoor", Vector2i(18, 16)).is_empty(), "ordinary farm tiles must not return an interaction record")
	# A walk must animate while traversing one cell and remain on its confirmed
	# target cell, rather than being teleported to the map origin.
	Motion.hold(Vector2i.RIGHT)
	scene._update_player_movement(0.06)
	_expect(scene.player.action == "walk" and scene.player.stride > 0, "walking within one cell should advance to a second animation frame")
	scene._update_player_movement(32.0 / scene.WALK_SPEED - 0.06)
	Motion.hold(Vector2i.ZERO)
	scene._update_player_movement(0.0)
	_expect(scene.player_cell == Vector2i(18, 16), "a normal movement must not trigger a scene exit or reset the player position")
	_expect(scene.current_map_id == "farm_outdoor", "a normal movement must remain in the same outdoor scene")
	_expect(not scene.moving and scene.player.action == "idle", "finishing a movement must return to idle")
	_expect(scene.player._body.texture.resource_path.ends_with("farmer_idle_v1.png"), "stopping after movement must show dedicated standing art")
	# The player stands above the authored crop plot and operates on the facing cell.
	scene.player_cell = Vector2i(4, 14)
	scene.player.set_pose("down", "idle")
	scene.current_tool = "hoe"
	scene._farm_action()
	scene.actor_action.advance(1.0)
	_expect(scene.farm.get_cell_state(Vector2i(4, 15)).get("tilled", false), "hoe input should till only the faced authored field cell")
	scene.current_tool = "seed"
	scene._farm_action()
	scene.actor_action.advance(1.0)
	_expect(scene.farm.is_crop_occupied(Vector2i(4, 15)), "seed input should plant on the tilled faced cell")
	scene.current_tool = "water"
	scene._farm_action()
	scene.actor_action.advance(1.0)
	_expect(scene.farm.get_cell_state(Vector2i(4, 15)).get("watered", false), "water input should water the faced planted cell")
	scene._advance_day(false)
	_expect(scene.farm.day == 2, "sleep input should advance the farm day")

	scene._change_map("town_square", Vector2i(41, 22))
	await process_frame
	_expect(scene.farm_music.track_id == "town_day_spring" and scene.farm_music.cached_tracks.has("town_spring"), "entering town crossfades to its own spring music theme")
	_expect(scene.current_map_id == "town_square", "scene transition should enter town")
	_expect(scene.player_cell == Vector2i(41, 22), "town safe arrival must match navigation data")
	_expect(scene.npcs.size() == scene.VillageScript.PEOPLE.size(), "town should spawn the expanded morning population")

	scene._change_map("farm_outdoor", Vector2i(1, 14))
	_expect(scene.current_map_id == "farm_outdoor", "scene transition should return to farm")
	_expect(scene.npcs.is_empty(), "town NPC nodes should clear on farm")

	scene.queue_free()
	if _failed:
		quit(1)
		return
	print("Game smoke test passed.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("Game smoke test failed: %s" % message)
