extends SceneTree

var checks := 0
var failures := 0
var game


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://character-settings-ui-test-%d.json" % Time.get_ticks_usec()
	var isolated_config_path := "user://character-settings-ui-test-%d.cfg" % Time.get_ticks_usec()
	game.display_config_path = isolated_config_path
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	game.set_physics_process(false)

	game._open_character_card()
	await process_frame
	await process_frame
	var panel: Control = game.life_panel.panel
	var scroll: ScrollContainer = game.life_panel.scroll
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var viewport := root.get_window().get_visible_rect()
	var skill_grid: GridContainer = game.life_panel.content.get_children().back()
	var profile_row: HBoxContainer = game.life_panel.content.get_child(0)
	expect(panel.get_global_rect().position.y >= viewport.position.y, "Character panel starts inside the 1280x720 viewport")
	expect(panel.get_global_rect().end.y <= viewport.end.y, "Character panel fits inside the 1280x720 viewport")
	expect(profile_row.get_combined_minimum_size().x <= game.life_panel.content.size.x + 0.1, "Character portrait and status cards fit without horizontal clipping")
	expect(skill_grid.columns == 2 and skill_grid.get_child_count() == 5, "Character card shows all five skills in a two-column grid")
	expect((skill_grid.get_child(0) as Control).size.x >= 300.0, "Character skill cards use the available panel width")
	expect(bar.max_value <= bar.page + 0.1, "All character card content fits without vertical scrolling")
	game.life_panel.close()

	game._open_display_settings()
	await process_frame
	await process_frame
	panel = game.life_panel.panel
	scroll = game.life_panel.scroll
	bar = scroll.get_v_scroll_bar()
	expect(panel.get_global_rect().position.y >= viewport.position.y, "Settings panel starts inside the 1280x720 viewport")
	expect(panel.get_global_rect().end.y <= viewport.end.y, "Settings panel fits inside the 1280x720 viewport")
	expect(bar.max_value <= bar.page + 0.1, "Settings controls fit without vertical scrolling")
	expect(game.camera_zoom_index == 2 and is_equal_approx(game.game_camera.zoom.x, 2.0), "Settings starts with the closer camera distance")
	var zoom_buttons: Array[Node] = game.life_panel.content.find_children("", "Button", true, false).filter(func(button: Node) -> bool: return button.has_meta("camera_zoom_index"))
	expect(zoom_buttons.size() == 3, "Settings presents far, standard, and near camera choices")
	if zoom_buttons.size() == 3:
		expect((zoom_buttons[2] as Button).text.begins_with("近景"), "The closest framing is identified as the near view")
		(zoom_buttons[0] as Button).pressed.emit()
		await process_frame
		expect(game.camera_zoom_index == 0 and is_equal_approx(game.game_camera.zoom.x, 1.5), "Choosing far view updates the live camera immediately")
	var sliders: Array[Node] = game.life_panel.content.find_children("", "HSlider", true, false)
	expect(sliders.size() == 2, "Settings separates background music and action sound effects")
	if sliders.size() == 2:
		(sliders[0] as HSlider).value = 40
		(sliders[1] as HSlider).value = 70
		await process_frame
		var config := ConfigFile.new()
		var result := config.load(game.display_config_path)
		expect(result == OK, "Changing either volume writes the isolated display config")
		if result == OK:
			expect(int(config.get_value("audio", "music_volume_percent", -1)) == 40, "Saved music level matches its slider")
			expect(int(config.get_value("audio", "sfx_volume_percent", -1)) == 70, "Saved sound effect level matches its slider")
			expect(int(config.get_value("audio", "volume_percent", -1)) == 40, "Legacy volume field tracks music for older builds")
			expect(int(config.get_value("display", "camera_zoom_index", -1)) == 0, "Saved camera preference matches the selected zoom")
			expect(game.audio_volume_percent == 40 and game.sfx_volume_percent == 70, "Both visible sliders update their live levels")
			expect(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.4)), "Music bus receives the selected gain")
			expect(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), linear_to_db(0.7)), "SFX bus receives the selected gain")

	game.queue_free()
	await process_frame
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://character-settings-ui-reload-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = isolated_config_path
	root.add_child(game)
	await process_frame
	expect(game.audio_volume_percent == 40 and game.sfx_volume_percent == 70 and game.display_size_index == 1 and game.camera_zoom_index == 0, "A fresh game instance restores both sound levels, window size, and camera preference")
	expect(is_equal_approx(game.game_camera.zoom.x, 1.5), "Restored camera preference is applied to the gameplay camera")
	game.queue_free()
	await process_frame
	var legacy_config_path := "user://character-settings-ui-legacy-%d.cfg" % Time.get_ticks_usec()
	var legacy_config := ConfigFile.new()
	legacy_config.set_value("audio", "volume_percent", 35)
	legacy_config.save(legacy_config_path)
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://character-settings-ui-legacy-%d.json" % Time.get_ticks_usec()
	game.display_config_path = legacy_config_path
	root.add_child(game)
	await process_frame
	expect(game.audio_volume_percent == 35 and game.sfx_volume_percent == 35, "Legacy single-volume preferences migrate to both new sound controls")

	print("CHARACTER_SETTINGS_UI_TEST %d checks, %d failures" % [checks, failures])
	game.queue_free()
	quit(1 if failures > 0 else 0)
