extends SceneTree

const Calendar = preload("res://scripts/life_calendar.gd")

var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if condition: return
	failures += 1
	push_error(message)


func _run() -> void:
	var game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://resident-request-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://resident-request-display-unused.cfg"
	root.add_child(game)
	await physics_frame
	game.set_physics_process(false)

	var kinds := {}
	var captured_request_ui := false
	for actor in game.VillageScript.PEOPLE:
		var pool: Array = game.VillageScript.REQUEST_POOLS.get(actor, [])
		expect(pool.size() == 4, actor + " has a four-step resident-specific request rotation")
		for offer in pool:
			kinds[str(offer.kind)] = true
			expect(not str(offer.label).is_empty() and int(offer.reward) > 0, actor + " request has a display name and positive reward")
			_grant_request_item(game, offer)
			var entry: Dictionary = game._request_inventory_entry(offer)
			expect(not entry.is_empty(), actor + " request resolves to an actual inventory item")
			if not entry.is_empty(): expect(game._consume_gift_item(str(entry.key), entry.item), actor + " request item uses the shared inventory consumer")
	expect(kinds.size() == 7, "requests cover crops, resources, fruit, fish, meals, animal products and artisan goods")
	var first_florist_request: Dictionary = game.village.request("florist", 5)
	expect(first_florist_request.kind == "crop" and first_florist_request.item == "parsnip" and first_florist_request.reward == 90, "the original first spring crop request keeps its established reward")

	for required_kind in ["crop", "resource", "fruit", "fish", "meal", "animal", "artisan"]:
		var selected_actor := ""
		var selected_day := 0
		var offer: Dictionary = {}
		for day in range(1, 113):
			if not Calendar.festival(day).is_empty(): continue
			for actor in game.VillageScript.PEOPLE:
				var candidate: Dictionary = game.village.request(str(actor), day)
				if str(candidate.get("kind", "")) == required_kind:
					selected_actor = str(actor)
					selected_day = day
					offer = candidate
					break
			if not offer.is_empty(): break
		expect(not offer.is_empty(), "calendar provides a " + required_kind + " delivery opportunity")
		if offer.is_empty(): continue
		game.farm.day = selected_day
		game.clock_minutes = 600
		_grant_request_item(game, offer)
		game._sync_inventory()
		var requested_entry: Dictionary = game._request_inventory_entry(offer)
		expect(not requested_entry.is_empty() and str(requested_entry.item.gift_kind) == required_kind, required_kind + " request resolves to its real backpack stack")
		if requested_entry.is_empty(): continue
		if DisplayServer.get_name() != "headless" and not captured_request_ui:
			game._open_dialogue(selected_actor)
			await process_frame
			await RenderingServer.frame_post_draw
			var capture_dir := ProjectSettings.globalize_path("res://design/qa/2026-09-24/resident-requests")
			DirAccess.make_dir_recursive_absolute(capture_dir)
			expect(root.get_texture().get_image().save_png(capture_dir.path_join("request-dialogue.png")) == OK, "resident request is captured in the styled dialogue panel")
			captured_request_ui = true
			game.life_panel.close()

		var activity: Dictionary = game.village.activity(selected_actor, selected_day, game.clock_minutes)
		var map_id := str(activity.map)
		game._change_map(map_id, game.navigation.get_spawn(map_id))
		await process_frame
		expect(game.npcs.has(selected_actor), selected_actor + " is present at the scheduled request location")
		if not game.npcs.has(selected_actor): continue
		var resident = game.npcs[selected_actor].node
		game.player_body.position = resident.position + Vector2(3, 3)
		game.player_cell = game._cell_from_world_position(game.player_body.position)
		expect(game._nearby_npc_actor() == selected_actor, selected_actor + " can receive the request at close range")
		var gold_before: int = game.farm.gold
		game._open_dialogue(selected_actor)
		var request_button: Button
		for child in game.life_panel.content.get_children():
			if child is Button and str(child.text).begins_with("今日委托 ·"):
				request_button = child
				break
		expect(request_button != null, required_kind + " request is an actionable button in the dialogue panel")
		var relation_before: int = int(game.village.bond(selected_actor).points)
		var expected_friendship_gain := 40 if int(game.village.bond(selected_actor).talk_day) == selected_day else 60
		var stack_before: int = int(requested_entry.item.count)
		var reward := int(offer.reward)
		if request_button != null: request_button.pressed.emit()
		expect(game.village.request(selected_actor, selected_day).done, required_kind + " delivery completes the daily request")
		expect(game.farm.gold == gold_before + reward, required_kind + " delivery grants its displayed gold reward")
		expect(int(game.village.bond(selected_actor).points) >= relation_before + expected_friendship_gain, required_kind + " delivery grants request and any unclaimed daily-chat friendship")
		var after_entry: Dictionary = game._request_inventory_entry(offer)
		expect(after_entry.is_empty() or int(after_entry.item.count) == stack_before - 1, required_kind + " delivery consumes exactly one requested item")
		var saved_village: Dictionary = game.village.snapshot()
		var restored = game.VillageScript.new()
		restored.restore(JSON.parse_string(JSON.stringify(saved_village)))
		expect(restored.request(selected_actor, selected_day).done, required_kind + " request completion survives save-state round trip")
		game.life_panel.close()

	for voice in game.farm_audio.voices: voice.stop()
	game.queue_free()
	await process_frame
	await process_frame
	print("Resident requests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _grant_request_item(game, offer: Dictionary) -> void:
	var item := str(offer.item)
	match str(offer.kind):
		"crop": game.farm.harvest_inventory[item] = int(game.farm.harvest_inventory.get(item, 0)) + 1
		"resource": game.homestead.resources[item] = int(game.homestead.resources.get(item, 0)) + 1
		"fruit": game.orchard.fruits[item] = int(game.orchard.fruits.get(item, 0)) + 1
		"fish": game.fishing.inventory[item] = int(game.fishing.inventory.get(item, 0)) + 1
		"meal": game.crafting.meals[item] = int(game.crafting.meals.get(item, 0)) + 1
		"animal":
			match item:
				"egg": game.animals.eggs += 1
				"duck_egg": game.animals.duck_eggs += 1
				"milk": game.animals.milk += 1
		"artisan": game.processing.products[item] = int(game.processing.products.get(item, 0)) + 1
