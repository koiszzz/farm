extends Node

const SAMPLE_RATE := 11025
const BEATS_PER_MINUTE := 96.0
const BEAT_SECONDS := 60.0 / BEATS_PER_MINUTE
const TRACK_SECONDS := BEAT_SECONDS * 8.0
const SEASON_TRANSPOSE := [0, 2, -2, -5]
const SEASON_IDS := ["spring", "summer", "autumn", "winter"]
const LifeCalendar = preload("res://scripts/life_calendar.gd")
const REGION_NOTES := {
	"farm": [67, 71, 74, 76, 74, 71, 69, 71, 67, 71, 74, 79, 76, 74, 71, 69],
	"town": [72, 76, 79, 76, 74, 77, 81, 77, 72, 76, 79, 84, 81, 79, 76, 74],
	"beach": [69, 72, 76, 79, 76, 72, 71, 74, 69, 72, 76, 81, 79, 76, 74, 72],
	"cave": [62, 65, 69, 72, 69, 65, 64, 67, 62, 65, 69, 74, 72, 69, 67, 65],
	"suburb": [64, 67, 71, 74, 71, 67, 66, 69, 64, 67, 71, 76, 74, 71, 69, 67],
	"festival": [72, 79, 76, 84, 81, 77, 79, 86, 84, 79, 76, 83, 79, 76, 74, 81],
	"interior": [72, 76, 79, 76, 74, 79, 83, 79, 72, 76, 79, 84, 79, 76, 74, 71],
}
const CHORDS := {
	"farm": [[55, 59, 62], [52, 55, 59], [57, 60, 64], [50, 54, 57]],
	"town": [[60, 64, 67], [57, 60, 64], [62, 65, 69], [55, 59, 62]],
	"beach": [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 55, 59]],
	"cave": [[50, 53, 57], [46, 50, 53], [48, 52, 55], [45, 48, 52]],
	"suburb": [[52, 55, 59], [48, 52, 55], [50, 54, 57], [47, 50, 54]],
	"festival": [[60, 67, 72], [57, 64, 69], [62, 69, 74], [55, 62, 67]],
	"interior": [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]],
}

var game
var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var active_player: AudioStreamPlayer
var cached_tracks: Dictionary = {}
var track_id := ""
var _active_tween: Tween
var _outgoing_tween: Tween


func _ready() -> void:
	player_a = AudioStreamPlayer.new()
	player_b = AudioStreamPlayer.new()
	player_a.name = "MusicVoiceA"
	player_b.name = "MusicVoiceB"
	player_a.volume_db = -60.0
	player_b.volume_db = -60.0
	player_a.bus = "Music"
	player_b.bus = "Music"
	add_child(player_a)
	add_child(player_b)
	active_player = player_a


func _process(_delta: float) -> void:
	if game == null or game.farm == null:
		return
	var region := _region_for_map(str(game.current_map_id))
	var is_night := int(game.clock_minutes) >= 19 * 60 or int(game.clock_minutes) < 5 * 60
	var season := int(LifeCalendar.date(int(game.farm.day)).season)
	if region == "town" and not LifeCalendar.festival(int(game.farm.day)).is_empty():
		region = "festival"
	var desired := "%s_%s_%s" % [region, "night" if is_night else "day", SEASON_IDS[season]]
	if desired != track_id:
		play_theme(desired, region, is_night, season)


func play_theme(id: String, region: String, is_night: bool, season: int) -> void:
	if id == track_id:
		return
	var theme := "interior" if region == "interior" else region
	if not REGION_NOTES.has(theme):
		theme = "farm"
	var cache_key := "%s_%s" % [theme, SEASON_IDS[posmod(season, 4)]]
	if not cached_tracks.has(cache_key):
		cached_tracks[cache_key] = _build_track(theme, posmod(season, 4))
	var incoming: AudioStreamPlayer = player_b if active_player == player_a else player_a
	if _active_tween != null and _active_tween.is_running():
		_active_tween.kill()
	if _outgoing_tween != null and _outgoing_tween.is_running():
		_outgoing_tween.kill()
	var outgoing := active_player
	incoming.stop()
	incoming.stream = cached_tracks[cache_key]
	incoming.volume_db = -36.0
	incoming.play()
	_active_tween = create_tween()
	_active_tween.tween_property(incoming, "volume_db", -19.0 if not is_night else -23.0, 0.9)
	if outgoing.playing:
		_outgoing_tween = create_tween()
		_outgoing_tween.tween_property(outgoing, "volume_db", -60.0, 0.9)
		_outgoing_tween.tween_callback(outgoing.stop)
	active_player = incoming
	track_id = id


func _build_track(theme: String, season: int) -> AudioStreamWAV:
	var total_samples := int(TRACK_SECONDS * SAMPLE_RATE)
	var data := PackedByteArray()
	data.resize(total_samples * 2)
	var melody: Array = REGION_NOTES[theme]
	var chords: Array = CHORDS[theme]
	var transpose: int = SEASON_TRANSPOSE[season]
	var loop_tail_fade_samples := int(SAMPLE_RATE * 0.02)
	for sample_index in total_samples:
		var time := float(sample_index) / SAMPLE_RATE
		var beat_position := time / BEAT_SECONDS
		var melody_step := int(floor(beat_position * 2.0)) % melody.size()
		var beat_in_step := fposmod(beat_position * 2.0, 1.0)
		var melody_note := int(melody[melody_step]) + transpose
		var melody_frequency := _frequency(melody_note)
		var pluck_envelope := exp(-5.0 * beat_in_step) * minf(beat_in_step * 24.0, 1.0)
		var melody_sample := sin(TAU * melody_frequency * time) * pluck_envelope * 0.22
		melody_sample += sin(TAU * melody_frequency * 2.0 * time) * pluck_envelope * 0.040
		melody_sample += sin(TAU * melody_frequency * 3.0 * time) * pluck_envelope * 0.010
		var chord_step := int(floor(beat_position / 2.0)) % chords.size()
		var chord_notes: Array = chords[chord_step]
		var chord_age := fposmod(beat_position, 2.0)
		var pad_envelope := minf(chord_age * 5.0, 1.0) * (0.95 + sin(TAU * chord_age / 2.0) * 0.05)
		var chord_sample := 0.0
		for note in chord_notes:
			var frequency := _frequency(int(note) + transpose)
			chord_sample += (sin(TAU * frequency * time) + sin(TAU * frequency * 2.0 * time) * 0.12) * 0.030 * pad_envelope
		var beat_index := int(floor(beat_position))
		var bass_note := int(chord_notes[0]) - 12 + transpose + (7 if beat_index % 2 == 1 else 0)
		var bass_frequency := _frequency(bass_note)
		var bass_phase := fposmod(beat_position, 1.0)
		var bass_envelope := exp(-3.4 * bass_phase) * minf(bass_phase * 22.0, 1.0)
		var bass_sample := (sin(TAU * bass_frequency * time) + sin(TAU * bass_frequency * 2.0 * time) * 0.08) * bass_envelope * 0.18
		var answer_sample := 0.0
		var answer_step := int(floor(beat_position * 2.0)) % melody.size()
		if answer_step % 4 == 3:
			var answer_note := int(chord_notes[2]) + 12 + transpose
			var answer_frequency := _frequency(answer_note)
			var answer_phase := fposmod(beat_position * 2.0, 1.0)
			var answer_envelope := exp(-7.0 * answer_phase) * minf(answer_phase * 30.0, 1.0)
			var answer_gain := 0.032 if theme in ["cave", "interior"] else 0.060 if theme == "festival" else 0.045
			answer_sample = (sin(TAU * answer_frequency * time) + sin(TAU * answer_frequency * 2.76 * time) * 0.14) * answer_envelope * answer_gain
		var loop_tail_fade := clampf(float(total_samples - sample_index) / loop_tail_fade_samples, 0.0, 1.0)
		var tone := clampf(melody_sample + chord_sample + bass_sample + answer_sample, -0.75, 0.75) * loop_tail_fade
		data.encode_s16(sample_index * 2, int(tone * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream


func _frequency(midi_note: int) -> float:
	return 440.0 * pow(2.0, float(midi_note - 69) / 12.0)


func _region_for_map(map_id: String) -> String:
	var location_id := map_id
	if game != null and map_id == "valley_world":
		location_id = str(game.navigation.zone_at(map_id, game.player_cell))
	if map_id in ["cave", "mine_2", "mine_3"]:
		return "cave"
	if map_id == "beach":
		return "beach"
	if location_id in ["town_square", "general_store_interior", "clinic_interior", "cafe_interior"]:
		return "town" if location_id == "town_square" else "interior"
	if location_id.ends_with("_interior"):
		return "interior"
	if location_id in ["farm_country", "countryside", "riverside", "western_forest", "forest_crossing", "eastern_lakes"]:
		return "suburb"
	if location_id == "farm_outdoor":
		return "farm"
	return "farm"
