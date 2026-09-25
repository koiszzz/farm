extends SceneTree

const OUTPUT := "res://design/qa/2026-09-25/ui-restyle"
const CAPTURES := ["gameplay-hud", "gameplay-hud-clear", "inventory", "character", "map", "region-map", "settings", "shop"]
var game


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://ui-style-capture-unused-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://ui-style-capture-unused-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	root.get_window().mode = Window.MODE_WINDOWED
	root.get_window().size = Vector2i(1280, 720)
	await process_frame
	game.set_physics_process(false)
	for capture in CAPTURES:
		match capture:
			"gameplay-hud", "gameplay-hud-clear": pass
			"inventory": game._open_inventory()
			"character": game._open_character_card()
			"map": game._open_world_map("valley_world")
			"region-map": game._open_world_map("farm_outdoor")
			"settings": game._open_display_settings()
			"shop": game._open_shop()
		await create_timer(0.16).timeout
		if capture == "gameplay-hud-clear": await create_timer(5.1).timeout
		await RenderingServer.frame_post_draw
		if capture == "character" or capture == "settings":
			await process_frame
			var panel: Control = game.life_panel.panel
			var scroll: ScrollContainer = game.life_panel.scroll
			var column: Control = panel.get_child(0)
			var close_button: Control = column.get_child(2)
			var vertical_scroll: VScrollBar = scroll.get_v_scroll_bar()
			print("UI_LAYOUT %s panel=%s scroll=%s content_min=%s scroll_max=%.1f scroll_page=%.1f close=%s viewport=%s" % [capture, panel.get_global_rect(), scroll.get_global_rect(), game.life_panel.content.get_combined_minimum_size(), vertical_scroll.max_value, vertical_scroll.page, close_button.get_global_rect(), root.get_window().get_visible_rect()])
		var image := root.get_texture().get_image()
		var path: String = OUTPUT + "/" + capture + ".png"
		var result := image.save_png(ProjectSettings.globalize_path(path))
		if result != OK: push_error("Failed to capture %s: %d" % [capture, result])
		else: print("UI_CAPTURE " + path)
		game.inventory_panel.close()
		game.life_panel.close()
	game.queue_free()
	quit()
