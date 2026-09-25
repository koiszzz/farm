extends SceneTree

const SAMPLE_RATE := 11025
const FarmMusicScript = preload("res://scripts/farm_music.gd")
const REGIONS := ["farm", "town", "beach", "cave"]
const OUTPUT := "res://design/qa/2026-09-25/music/original-region-themes-preview.wav"


func _init() -> void:
	call_deferred("_export")


func _export() -> void:
	var composer = FarmMusicScript.new()
	var audio := PackedByteArray()
	for region in REGIONS:
		var track: AudioStreamWAV = composer._build_track(region, 0)
		audio.append_array(track.data)
		for _sample in SAMPLE_RATE / 2:
			audio.append_array(PackedByteArray([0, 0]))
	var absolute := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		push_error("Unable to export original music preview: " + absolute)
		quit(1)
		return
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + audio.size())
	file.store_buffer("WAVE".to_ascii_buffer())
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(SAMPLE_RATE)
	file.store_32(SAMPLE_RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(audio.size())
	file.store_buffer(audio)
	file.close()
	print("Original region preview exported: " + OUTPUT + " bytes=" + str(audio.size()))
	quit()
