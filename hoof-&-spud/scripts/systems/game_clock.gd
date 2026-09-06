## Autoload driving the in-game clock and calendar.
##
## Time is held as minutes-since-midnight in a float so the tint can interpolate,
## and broadcast as whole minutes so listeners never see jitter.

extends Node

signal time_changed(minutes: int)

signal hour_changed(hour: int)

## Everything that happens overnight hangs off this: crops grow, animals lay,
## watered soil dries out.
signal day_started(day: int)

signal phase_changed(phase: Phase)

enum Phase { DAWN, DAY, DUSK, NIGHT }

const MINUTES_PER_DAY := 24 * 60

const WAKE_HOUR := 6

## Hour to tint index, interpolated between keys so dusk slides in.
const TINT_KEYS: Array[Vector2] = [
	Vector2(0.0, 0.0),
	Vector2(4.5, 0.0),
	Vector2(7.0, 1.0),
	Vector2(9.0, 2.0),
	Vector2(16.5, 2.0),
	Vector2(19.0, 3.0),
	Vector2(21.5, 0.0),
	Vector2(24.0, 0.0),
]

const TINT_COLOURS: Array[Color] = [
	Color(0.42, 0.47, 0.72),  ## night
	Color(0.85, 0.72, 0.70),  ## dawn
	Color(1.0, 1.0, 1.0),  ## day
	Color(0.95, 0.71, 0.55),  ## dusk
]

## Real seconds one in-game day takes.
var day_length: float = 720.0

var day: int = 1

## Minutes since midnight, 0.0 to 1439.0.
var minutes: float = float(WAKE_HOUR * 60)

## Cleared while a menu or a transition owns the clock.
var running: bool = true

var _last_minute: int = -1
var _last_hour: int = -1
var _last_phase: Phase = Phase.DAY


func _ready() -> void:
	_last_minute = int(minutes)
	_last_hour = hour()
	_last_phase = phase()


func _process(delta: float) -> void:
	if not running or day_length <= 0.0:
		return
	advance(delta / day_length * MINUTES_PER_DAY)


func advance(amount: float) -> void:
	if amount <= 0.0:
		return

	minutes += amount
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1
		day_started.emit(day)

	_emit_changes()


func sleep() -> void:
	day += 1
	minutes = float(WAKE_HOUR * 60)
	day_started.emit(day)
	_emit_changes()


## Puts the clock back to a saved date and time and re-broadcasts it.
func restore(saved_day: int, saved_minutes: float) -> void:
	day = maxi(saved_day, 1)
	minutes = clampf(saved_minutes, 0.0, float(MINUTES_PER_DAY - 1))
	# Force the re-broadcast: a save can hold the very minute already on screen.
	_last_minute = -1
	_emit_changes()


func reset() -> void:
	day = 1
	minutes = float(WAKE_HOUR * 60)
	running = true
	_last_minute = -1
	_emit_changes()


func hour() -> int:
	return int(minutes / 60.0) % 24


func minute_of_hour() -> int:
	return int(minutes) % 60


func clock_text() -> String:
	var raw := hour()
	var suffix := "am" if raw < 12 else "pm"
	var display := raw % 12
	if display == 0:
		display = 12
	return "%d:%02d %s" % [display, minute_of_hour(), suffix]


func phase() -> Phase:
	var raw := hour()
	if raw < 5 or raw >= 21:
		return Phase.NIGHT
	if raw < 8:
		return Phase.DAWN
	if raw < 18:
		return Phase.DAY
	return Phase.DUSK


## Colour for a [CanvasModulate] at the current hour.
func tint() -> Color:
	var position := minutes / 60.0

	for index in range(TINT_KEYS.size() - 1):
		var from := TINT_KEYS[index]
		var to := TINT_KEYS[index + 1]
		if position < from.x or position > to.x:
			continue
		var span := to.x - from.x
		var weight := 0.0 if is_zero_approx(span) else (position - from.x) / span
		return TINT_COLOURS[int(from.y)].lerp(TINT_COLOURS[int(to.y)], weight)

	return TINT_COLOURS[2]


func _emit_changes() -> void:
	var whole := int(minutes)
	if whole != _last_minute:
		_last_minute = whole
		time_changed.emit(whole)

	var current_hour := hour()
	if current_hour != _last_hour:
		_last_hour = current_hour
		hour_changed.emit(current_hour)

	var current_phase := phase()
	if current_phase != _last_phase:
		_last_phase = current_phase
		phase_changed.emit(current_phase)
