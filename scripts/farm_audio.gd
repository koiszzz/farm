extends Node

var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0

func _ready() -> void:
	for index in 4:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -20
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

func play(kind: String) -> void:
	if not sounds.has(kind) or voices.is_empty(): return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = sounds[kind]
	voice.play()
