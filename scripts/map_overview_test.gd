extends SceneTree

const MapOverviewScript = preload("res://scripts/map_overview.gd")
var game
var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func _overview():
	for child in game.life_panel.content.get_children():
		if child.get_script() == MapOverviewScript: return child
	return null


func _has_exit(source: String, target: String) -> bool:
	for cell in game.navigation.get_cells_with_class(source, "exit"):
		if str(game.navigation.exit_at(source, cell).get("target", "")) == target: return true
	return false


func _visible_request_count() -> int:
	var count := 0
	for actor in game.npcs:
		var request: Dictionary = game.village.request(str(actor), game.farm.day)
		if not request.is_empty() and not bool(request.get("done", false)): count += 1
	return count


func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://map-overview-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://map-overview-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.clock_minutes = 360
	game._change_map("town_square", game.navigation.get_spawn("town_square"))
	var player_before_map: Vector2 = game.player_body.position
	game._open_world_map()
	var overview = _overview()
	expect(overview != null and overview.map_id == "valley_world", "travel handbook opens the full illustrated valley map by default")
	if overview != null:
		expect(overview.current_map_id == "town_square" and overview._region_for_map(overview.current_map_id) == "town_square", "current town receives the active-region marker")
		expect(overview.show_player and overview.player_position.x >= 0 and overview.player_position.y >= 0, "full map plots the player's current coordinate")
		expect(overview.resident_positions.size() == game.npcs.size() and not overview.resident_positions.is_empty(), "full map plots active residents in their live locations")
		var full_forage_count: int = game.homestead.available("farm_outdoor", game.farm.day, game.navigation).size() + game.homestead.available("town_square", game.farm.day, game.navigation).size() + game.homestead.available("riverside", game.farm.day, game.navigation).size()
		expect(overview.forage_positions.size() == full_forage_count, "full map plots currently available forage spots from its connected regions")
		expect(overview.request_positions.size() == _visible_request_count(), "full map plots active requests at the requesting residents")
		expect(game.player_body.position == player_before_map, "opening the map never moves the player")
		expect(overview._region_for_map("general_store_interior") == "town_square", "town building interiors resolve to the town marker")
		expect(overview._region_for_map("mine_3") == "cave", "deep-mine floors resolve to the cave marker")
	var map_regions := ["farm_outdoor", "countryside", "town_square", "cave", "beach"]
	for region in map_regions:
		expect(game.navigation.has_map(region), "travel map region exists: %s" % region)
	for edge in [["farm_outdoor", "countryside"], ["countryside", "town_square"], ["countryside", "cave"], ["countryside", "beach"]]:
		expect(_has_exit(str(edge[0]), str(edge[1])), "illustrated route matches authored exit %s → %s" % [str(edge[0]), str(edge[1])])
	game._open_world_map("town_square")
	var town_overview = _overview()
	expect(town_overview != null and town_overview.show_player and town_overview.resident_positions.size() == game.npcs.size(), "town map locates the player and active residents at local scale")
	if town_overview != null:
		expect(town_overview.forage_positions.size() == game.homestead.available("town_square", game.farm.day, game.navigation).size(), "town map shows only its available forage spots")
		expect(town_overview.request_positions.size() == _visible_request_count(), "town map plots today's unfinished requests")
		var first_pickup: Dictionary = game.homestead.available("town_square", game.farm.day, game.navigation)[0]
		var pickup_count_before: int = town_overview.forage_positions.size()
		var request_count_before: int = town_overview.request_positions.size()
		var request_actor := ""
		for actor in game.npcs:
			var request: Dictionary = game.village.request(str(actor), game.farm.day)
			if not request.is_empty() and not bool(request.get("done", false)):
				request_actor = str(actor)
				break
		game.homestead.collect(first_pickup, game.farm.day)
		if not request_actor.is_empty(): game.village.request_days[request_actor] = game.farm.day
		game._open_world_map("town_square")
		var refreshed_town = _overview()
		if refreshed_town != null:
			expect(refreshed_town.forage_positions.size() == pickup_count_before - 1, "collecting a town pickup removes its marker for the day")
			expect(refreshed_town.request_positions.size() == request_count_before - 1, "completing a request removes its town marker for the day")
	game._open_world_map("beach")
	var beach_overview = _overview()
	expect(beach_overview != null and beach_overview.map_id == "beach" and not beach_overview.show_player and beach_overview.resident_positions.is_empty(), "region button opens an unoccupied region's detailed map without moving the player")
	if beach_overview != null:
		expect(beach_overview.forage_positions.size() == game.homestead.available("beach", game.farm.day, game.navigation).size(), "beach map shows its live shell pickups even when the player is elsewhere")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(game.save_path + suffix): DirAccess.remove_absolute(game.save_path + suffix)
	game.queue_free()
	await process_frame
	print("Map overview: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
