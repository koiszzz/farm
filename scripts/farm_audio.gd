extends Node

var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var _step_variation := 0
var played_footsteps := 0
var last_footstep_surface := ""
var last_footstep_stream: AudioStream

func _ready() -> void:
	for index in 4:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -20
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)
	for key in {"hoe": 130, "water": 640, "seed": 440, "harvest": 880, "scythe": 200, "gift": 660, "pet": 520, "select": 360}:
		var frequency: float = {"hoe": 130, "water": 640, "seed": 440, "harvest": 880, "scythe": 200, "gift": 660, "pet": 520, "select": 360}[key]
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var count := 3307
		var data := PackedByteArray()
		data.resize(count * 2)
		for sample in count:
			var time := float(sample) / 22050.0
			var fade := pow(1.0 - float(sample) / count, 2) * minf(time * 300, 1)
			var wave := sin(TAU * frequency * time) * 0.7 + sin(TAU * frequency * 2 * time) * 0.3
			data.encode_s16(sample * 2, int(wave * fade * 16000))
		stream.data = data
		sounds[key] = stream
	for surface in ["grass", "path", "soil", "sand", "wood", "stone"]:
		for variation in 2:
			sounds["step_%s_%d" % [surface, variation]] = _build_footstep(surface, variation)

func play(kind: String) -> void:
	if not sounds.has(kind) or voices.is_empty(): return
	_play_stream(sounds[kind], -20.0, 1.0)


func play_footstep(surface: String, running: bool = false) -> void:
	if voices.is_empty(): return
	var material := surface if surface in ["grass", "path", "soil", "sand", "wood", "stone"] else "grass"
	var variation := _step_variation % 2
	_step_variation += 1
	played_footsteps += 1
	last_footstep_surface = material
	last_footstep_stream = sounds["step_%s_%d" % [material, variation]]
	_play_stream(last_footstep_stream, -22.0 if running else -25.0, 1.07 if running else 0.94 + float(variation) * 0.09)


func _play_stream(stream: AudioStream, level_db: float, pitch: float) -> void:
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = stream
	voice.volume_db = level_db
	voice.pitch_scale = pitch
	voice.play()


func _build_footstep(surface: String, variation: int) -> AudioStreamWAV:
	const sample_rate := 22050
	const sample_count := 2205
	var profiles := {
		"grass": [118.0, 0.18, 0.20, 0.08],
		"path": [168.0, 0.11, 0.30, 0.24],
		"soil": [105.0, 0.14, 0.24, 0.12],
		"sand": [82.0, 0.28, 0.12, 0.045],
		"wood": [214.0, 0.10, 0.42, 0.36],
		"stone": [276.0, 0.06, 0.40, 0.44],
	}
	var profile: Array = profiles.get(surface, profiles["grass"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s_%d" % [surface, variation])
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var filtered_noise := 0.0
	for sample in sample_count:
		var t := float(sample) / sample_rate
		var envelope := (1.0 - exp(-t * 600.0)) * exp(-t * 42.0)
		var noise: float = rng.randf_range(-1.0, 1.0)
		filtered_noise = lerpf(filtered_noise, noise, float(profile[3]))
		var frequency: float = float(profile[0]) * (1.0 + float(variation) * 0.035)
		var body := sin(TAU * frequency * t) * float(profile[2])
		var texture := (filtered_noise * float(profile[1]) + noise * float(profile[3]) * 0.10) * exp(-t * 24.0)
		var transient := sin(TAU * (frequency * 2.15) * t) * exp(-t * 120.0) * (0.10 + float(profile[3]) * 0.12)
		var value := clampf((body + texture + transient) * envelope, -0.8, 0.8)
		data.encode_s16(sample * 2, int(value * 19000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
