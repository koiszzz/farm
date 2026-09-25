extends SceneTree

var checks := 0
var failures := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var game: Node = preload("res://Main.tscn").instantiate()
	game.autosave_enabled = false
	game.save_path = "user://farm-music-test-%d.json" % Time.get_ticks_usec()
	game.display_config_path = "user://farm-music-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	await process_frame
	expect(game.farm_music.track_id == "farm_day_spring" and game.farm_music.active_player.playing, "farm starts its own spring theme")
	expect(game.farm_music.active_player.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "regional soundtrack repeats seamlessly as a loop")
	expect(game.farm_music.active_player.bus == "Music" and game.farm_audio.voices[0].bus == "SFX", "music and action sounds use separate mixer buses")
	var loop_data: PackedByteArray = game.farm_music.cached_tracks["farm_spring"].data
	var last_sample := absi(loop_data.decode_s16(loop_data.size() - 2))
	expect(last_sample < 100 and absi(loop_data.decode_s16(0)) < 100, "music loop endpoints fade to near-zero to avoid a click at wraparound")
	var sum_squares := 0.0
	var peak := 0
	for byte_index in range(0, loop_data.size(), 2):
		var sample := loop_data.decode_s16(byte_index)
		peak = maxi(peak, absi(sample))
		sum_squares += float(sample) * sample
	var rms := sqrt(sum_squares / (loop_data.size() / 2.0)) / 32767.0
	expect(rms > 0.025 and rms < 0.45 and peak < 30000, "layered regional score stays audible without excessive loudness or digital clipping")
	game.farm.day = 29
	await process_frame
	expect(game.farm_music.track_id == "farm_day_summer" and game.farm_music.cached_tracks.has("farm_summer"), "season change selects and caches a new farm variation")
	expect(game.farm_music.cached_tracks["farm_spring"].data != game.farm_music.cached_tracks["farm_summer"].data, "seasonal tracks have different pitches and are not duplicate loops")
	game.farm.day = 1
	await process_frame

	game._change_map("town_square", game.navigation.get_spawn("town_square"))
	await process_frame
	expect(game.farm_music.track_id == "town_day_spring" and game.farm_music.cached_tracks.has("town_spring"), "town uses a distinct cached spring theme")
	game.farm.day = 13
	await process_frame
	expect(game.farm_music.track_id == "festival_day_spring" and game.farm_music.cached_tracks.has("festival_spring"), "a town festival day selects the special celebration theme")
	game.farm.day = 1
	await process_frame
	expect(game.farm_music.track_id == "town_day_spring", "town music resumes after the festival date passes")
	game._change_map("countryside", game.navigation.get_spawn("countryside"))
	await process_frame
	expect(game.farm_music.track_id == "suburb_day_spring" and game.farm_music.cached_tracks.has("suburb_spring"), "suburb uses a distinct countryside theme")
	game._change_map("beach", game.navigation.get_spawn("beach"))
	await process_frame
	expect(game.farm_music.track_id == "beach_day_spring" and game.farm_music.cached_tracks.has("beach_spring"), "beach uses its own spring theme")
	game._change_map("cave", game.navigation.get_spawn("cave"))
	await process_frame
	expect(game.farm_music.track_id == "cave_day_spring" and game.farm_music.cached_tracks.has("cave_spring"), "cave switches to a sparse cave theme")
	game.clock_minutes = 1200
	await process_frame
	expect(game.farm_music.track_id == "cave_night_spring", "nightfall fades the active region into its quieter night mix")
	game._change_map("farmhouse_interior", game.navigation.get_spawn("farmhouse_interior"))
	await process_frame
	expect(game.farm_music.track_id == "interior_night_spring" and game.farm_music.cached_tracks.has("interior_spring"), "indoor rooms use their own theme")
	expect(game.farm_music.player_a != game.farm_music.player_b, "crossfade uses separate music voices")
	print("Farm music: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
