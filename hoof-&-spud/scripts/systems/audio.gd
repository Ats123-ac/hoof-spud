## Autoload owning every sound the game makes.
##
## Callers name what happened (`Audio.play(&"chop")`) and the bus is chosen here
## from the sound's name. Effects are PCM .wav files under `resources/audio/sfx`.

extends Node

const BUS_MASTER := &"Master"
const BUS_SFX := &"SFX"
const BUS_UI := &"UI"

const SFX_DIR := "res://resources/audio/sfx"
const SETTINGS_PATH := "user://settings.cfg"

const VOICES := 12

const RATE_FALLBACK := 22050

const UI_SOUNDS: Array[StringName] = [&"ui_click", &"ui_move", &"deny"]

var _streams: Dictionary[StringName, AudioStream] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0

var _last_played: Dictionary[StringName, int] = {}


func _ready() -> void:
	# Menus pause the tree; a click must still be audible.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_streams()
	_build_voices()
	_load_settings()


func play(sound: StringName, pitch_spread: float = 0.08, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return

	# At most one instance of a given sound per frame.
	var frame := Engine.get_process_frames()
	if _last_played.get(sound, -1) == frame:
		return
	_last_played[sound] = frame

	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()

	player.stream = stream
	player.bus = BUS_UI if sound in UI_SOUNDS else BUS_SFX
	player.pitch_scale = 1.0 if is_zero_approx(pitch_spread) else randf_range(
		1.0 - pitch_spread, 1.0 + pitch_spread
	)
	player.volume_db = volume_db
	player.play()


## [param linear] is 0.0-1.0 as a slider reports it; exactly zero mutes the bus.
func set_bus_volume(bus: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(String(bus))
	if index < 0:
		return
	AudioServer.set_bus_mute(index, is_zero_approx(linear))
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	_save_settings()


func bus_volume(bus: StringName) -> float:
	var index := AudioServer.get_bus_index(String(bus))
	if index < 0:
		return 1.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func has(sound: StringName) -> bool:
	return _streams.has(sound)


func _load_streams() -> void:
	var dir := DirAccess.open(SFX_DIR)
	if dir == null:
		push_warning("No sound effects at %s - run tools/make_sfx.py." % SFX_DIR)
		return

	var names: Array[StringName] = []
	for file in dir.get_files():
		# An exported project sees .remap entries where the editor sees the file.
		var clean := file.trim_suffix(".remap")
		if not clean.ends_with(".wav"):
			continue
		var sound := StringName(clean.get_basename())
		if sound not in names:
			names.append(sound)

	for sound in names:
		var stream := _parse_wav("%s/%s.wav" % [SFX_DIR, sound])
		if stream == null:
			continue
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		_streams[sound] = stream


## Reads a PCM .wav straight off disk. [method load] would depend on the importer,
## which an exported build without a .import cache may never have run.
func _parse_wav(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	file.seek(12)
	var channels := 1
	var rate := RATE_FALLBACK
	var bits := 16
	var payload := PackedByteArray()

	while file.get_position() < file.get_length():
		var chunk := file.get_buffer(8)
		if chunk.size() < 8:
			break
		var chunk_id := chunk.slice(0, 4).get_string_from_ascii()
		var chunk_size := chunk.decode_u32(4)
		match chunk_id:
			"fmt ":
				var body := file.get_buffer(chunk_size)
				if body.size() >= 16:
					channels = body.decode_u16(2)
					rate = body.decode_u32(4)
					bits = body.decode_u16(14)
			"data":
				payload = file.get_buffer(chunk_size)
			_:
				file.seek(file.get_position() + chunk_size)
		# RIFF chunks are word-aligned.
		if chunk_size % 2 != 0:
			file.seek(file.get_position() + 1)

	if payload.is_empty():
		push_warning("%s has no PCM data." % path)
		return null

	var stream := AudioStreamWAV.new()
	match bits:
		8:
			stream.format = AudioStreamWAV.FORMAT_8_BITS
		16:
			stream.format = AudioStreamWAV.FORMAT_16_BITS
		_:
			push_warning("%s is %d-bit, which is unsupported — skipped." % [path, bits])
			return null
	stream.mix_rate = rate
	stream.stereo = channels >= 2
	stream.data = payload
	return stream


func _build_voices() -> void:
	for index in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_voices.append(player)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus in [BUS_MASTER, BUS_SFX]:
		var stored: float = config.get_value("audio", String(bus), -1.0)
		if stored >= 0.0:
			var index := AudioServer.get_bus_index(String(bus))
			if index >= 0:
				AudioServer.set_bus_mute(index, is_zero_approx(stored))
				AudioServer.set_bus_volume_db(index, linear_to_db(maxf(stored, 0.0001)))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	for bus in [BUS_MASTER, BUS_SFX]:
		config.set_value("audio", String(bus), bus_volume(bus))
	config.save(SETTINGS_PATH)
