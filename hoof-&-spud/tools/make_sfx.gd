## Generates the sound effect bank (Part 25).
##
## The Sprout Lands pack ships no audio, so the effects are synthesised here once
## and committed as AudioStreamWAV resources. Keeping the recipe in the repo means
## a sound can be re-tuned by editing a number instead of hunting for a new file.
##
##   godot --headless -s res://tools/make_sfx.gd
extends SceneTree

const RATE := 22050
const OUT := "res://resources/audio/sfx"

var _noise_state: float = 0.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_write("chop", _chop())
	_write("mine", _mine())
	_write("till", _till())
	_write("water", _water())
	_write("plant", _plant())
	_write("pickup", _pickup())
	_write("harvest", _harvest())
	_write("ui_click", _ui_click())
	_write("ui_move", _ui_move())
	_write("deny", _deny())
	_write("chest_open", _chest_open())
	_write("cluck", _cluck())
	_write("moo", _moo())
	_write("sleep", _sleep())
	_write("step", _step())

	quit()


# --- sounds ------------------------------------------------------------------


## Axe into wood: a broadband thud with a short pitched knock under it.
func _chop() -> PackedFloat32Array:
	var length := 0.22
	var samples := _blank(length)
	var phase := 0.0
	for index in samples.size():
		var t := index / float(RATE)
		var envelope := _env(t, length, 0.004, 3.0)
		phase += TAU * lerpf(210.0, 80.0, t / length) / RATE
		var body := sin(phase) * 0.5
		var grain := _lowpass(_noise(), 0.35) * 0.9
		samples[index] = (body + grain) * envelope * 0.7
	return samples


## Mallet on stone: brighter, shorter, with a metallic ring.
func _mine() -> PackedFloat32Array:
	var length := 0.2
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		var click := _highpass(_noise(), 0.6) * _env(t, 0.05, 0.001, 4.0)
		var ring := (
			sin(TAU * 1280.0 * t) * 0.35 + sin(TAU * 1830.0 * t) * 0.2
		) * _env(t, length, 0.001, 5.0)
		samples[index] = (click * 0.8 + ring) * 0.65
	return samples


## Hoe through soil: a scrape, so noise with a soft attack and no pitch at all.
func _till() -> PackedFloat32Array:
	var length := 0.28
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		var shape := sin(PI * clampf(t / length, 0.0, 1.0))
		samples[index] = _bandpass(_noise(), 0.5, 0.12) * shape * 0.75
	return samples


## Watering can: a longer wash of low noise that swells and fades.
func _water() -> PackedFloat32Array:
	var length := 0.6
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		var shape := sin(PI * clampf(t / length, 0.0, 1.0))
		var wobble := 0.82 + 0.18 * sin(TAU * 7.0 * t)
		samples[index] = _lowpass(_noise(), 0.22) * shape * wobble * 0.85
	return samples


## Seed into the ground: one soft, dull tap.
func _plant() -> PackedFloat32Array:
	var length := 0.13
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		var envelope := _env(t, length, 0.008, 3.5)
		samples[index] = (_triangle(430.0, t) * 0.6 + _lowpass(_noise(), 0.2) * 0.4) * envelope * 0.5
	return samples


## Item absorbed: two rising steps, the classic pickup blip.
func _pickup() -> PackedFloat32Array:
	var length := 0.15
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		var frequency := 720.0 if t < length * 0.45 else 1080.0
		samples[index] = _square(frequency, t) * _env(t, length, 0.003, 1.6) * 0.28
	return samples


## Crop pulled up: a small three-note flourish.
func _harvest() -> PackedFloat32Array:
	var length := 0.34
	var notes := [523.25, 659.25, 830.61]
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		var step: int = mini(int(t / (length / notes.size())), notes.size() - 1)
		samples[index] = (
			_triangle(notes[step], t) * _env(t, length, 0.004, 1.2) * 0.34
		)
	return samples


func _ui_click() -> PackedFloat32Array:
	var length := 0.055
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		samples[index] = _square(940.0, t) * _env(t, length, 0.002, 2.0) * 0.2
	return samples


func _ui_move() -> PackedFloat32Array:
	var length := 0.04
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		samples[index] = _square(520.0, t) * _env(t, length, 0.002, 2.0) * 0.15
	return samples


## "You cannot do that here" — a low, flat buzz.
func _deny() -> PackedFloat32Array:
	var length := 0.16
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		samples[index] = _square(150.0, t) * _env(t, length, 0.004, 1.4) * 0.22
	return samples


## Chest lid: a wooden knock followed by a rising creak.
func _chest_open() -> PackedFloat32Array:
	var length := 0.4
	var samples := _blank(length)
	var phase := 0.0
	for index in samples.size():
		var t := index / float(RATE)
		var knock := _lowpass(_noise(), 0.3) * _env(t, 0.06, 0.002, 3.0) * 0.8
		phase += TAU * lerpf(320.0, 610.0, clampf(t / length, 0.0, 1.0)) / RATE
		var creak := sin(phase) * 0.22 * sin(PI * clampf(t / length, 0.0, 1.0))
		samples[index] = (knock + creak) * 0.6
	return samples


## Chicken: two clipped chirps with a fast warble.
func _cluck() -> PackedFloat32Array:
	var length := 0.26
	var samples := _blank(length)
	var phase := 0.0
	for index in samples.size():
		var t := index / float(RATE)
		var gate := 1.0 if t < 0.07 or (t > 0.12 and t < 0.2) else 0.0
		var warble := 1.0 + 0.28 * sin(TAU * 34.0 * t)
		phase += TAU * 870.0 * warble / RATE
		samples[index] = _shape(sin(phase)) * gate * _env(t, length, 0.004, 0.6) * 0.24
	return samples


## Cow: a long descending low tone with a slow vibrato.
func _moo() -> PackedFloat32Array:
	var length := 0.85
	var samples := _blank(length)
	var phase := 0.0
	for index in samples.size():
		var t := index / float(RATE)
		var progress := clampf(t / length, 0.0, 1.0)
		var vibrato := 1.0 + 0.05 * sin(TAU * 5.5 * t)
		phase += TAU * lerpf(196.0, 128.0, progress) * vibrato / RATE
		var body := sin(phase) * 0.6 + sin(phase * 2.0) * 0.22 + sin(phase * 3.0) * 0.1
		samples[index] = body * sin(PI * pow(progress, 0.7)) * 0.36
	return samples


## Fade to the next morning: a soft, slow settle.
func _sleep() -> PackedFloat32Array:
	var length := 1.1
	var samples := _blank(length)
	var phase := 0.0
	for index in samples.size():
		var t := index / float(RATE)
		var progress := clampf(t / length, 0.0, 1.0)
		phase += TAU * lerpf(392.0, 196.0, progress) / RATE
		samples[index] = (
			(sin(phase) * 0.6 + sin(phase * 0.5) * 0.3) * _env(t, length, 0.08, 1.4) * 0.3
		)
	return samples


## Footstep: barely there, so it can play every other stride without grating.
func _step() -> PackedFloat32Array:
	var length := 0.06
	var samples := _blank(length)
	for index in samples.size():
		var t := index / float(RATE)
		samples[index] = _lowpass(_noise(), 0.25) * _env(t, length, 0.002, 3.0) * 0.22
	return samples


# --- synthesis helpers -------------------------------------------------------


func _blank(seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	return samples


## Attack then a curved decay. Higher [param curve] falls away faster.
func _env(t: float, length: float, attack: float, curve: float) -> float:
	if t <= 0.0:
		return 0.0
	if t < attack:
		return t / maxf(attack, 0.00001)
	var progress := (t - attack) / maxf(length - attack, 0.00001)
	return pow(maxf(1.0 - progress, 0.0), curve)


func _square(frequency: float, t: float) -> float:
	return 1.0 if fmod(t * frequency, 1.0) < 0.5 else -1.0


func _triangle(frequency: float, t: float) -> float:
	var phase := fmod(t * frequency, 1.0)
	return 4.0 * absf(phase - 0.5) - 1.0


func _noise() -> float:
	return randf_range(-1.0, 1.0)


## One-pole low pass. [param amount] near 0 is dark, near 1 is untouched.
func _lowpass(sample: float, amount: float) -> float:
	_noise_state += (sample - _noise_state) * amount
	return _noise_state


func _highpass(sample: float, amount: float) -> float:
	return sample - _lowpass(sample, 1.0 - amount)


## Low pass then subtract a darker copy, leaving a band around the middle.
func _bandpass(sample: float, high: float, low: float) -> float:
	var bright := _lowpass(sample, high)
	return bright - bright * low


## Soft clip, which fattens a thin sine without the crackle of hard clipping.
func _shape(sample: float) -> float:
	return tanh(sample * 2.2) * 0.8


func _write(sound_name: String, samples: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes

	var path := "%s/%s.res" % [OUT, sound_name]
	var error := ResourceSaver.save(stream, path)
	print(
		"%-12s %5.2fs  %s"
		% [sound_name, samples.size() / float(RATE), "ok" if error == OK else error_string(error)]
	)
