## Autoload driving the in-game clock and calendar (Part 16).
##
## Everything that happens "overnight" hangs off [signal day_started]: crops grow,
## animals lay, watered soil dries out. Nothing else needs to know how long a day
## takes in real seconds, which is why that is the only tunable here.
##
## Time is held in minutes-since-midnight as a float so the tint can move
## smoothly, but it is reported as whole minutes so listeners never see jitter.
extends Node

## Emitted whenever the whole-minute reading changes.
signal time_changed(minutes: int)

## Emitted on the hour, with the new hour in 0-23.
signal hour_changed(hour: int)

## Emitted when a new day begins, either by the clock rolling over or by sleeping.
signal day_started(day: int)

## Emitted when the light changes band. Useful for lamps and NPC schedules.
signal phase_changed(phase: Phase)

enum Phase { DAWN, DAY, DUSK, NIGHT }

const MINUTES_PER_DAY := 24 * 60

## Hour the player wakes up on, and the hour a fresh save starts at.
const WAKE_HOUR := 6

## Ambient tint keyed by hour. Interpolated, so dusk slides in rather than
## snapping. Kept above 1.0 nowhere — this multiplies the whole canvas.
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

## Real seconds one whole in-game day takes. 12 minutes gives a day long enough
## to get chores done and short enough that watering pays off in one session.
var day_length: float = 720.0

var day: int = 1

## Minutes since midnight, 0 to 1440.
var minutes: float = float(WAKE_HOUR * 60)

## Cleared while a menu is open or the day-transition fade is playing.
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


## Push the clock forward by [param amount] in-game minutes, rolling the day over
## as many times as needed.
func advance(amount: float) -> void:
	if amount <= 0.0:
		return

	minutes += amount
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1
		day_started.emit(day)

	_emit_changes()


## Skip to [constant WAKE_HOUR] tomorrow. Used by the bed and by passing out.
func sleep() -> void:
	day += 1
	minutes = float(WAKE_HOUR * 60)
	day_started.emit(day)
	_emit_changes()


## Start a brand new save at day 1, morning.
func reset() -> void:
	day = 1
	minutes = float(WAKE_HOUR * 60)
	running = true
	_emit_changes()


func hour() -> int:
	return int(minutes / 60.0) % 24


func minute_of_hour() -> int:
	return int(minutes) % 60


## "6:05 am" — the HUD reads better with a 12-hour clock than with 06:05.
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


## How far through the day we are, 0 at midnight and 1 at the next midnight.
func day_progress() -> float:
	return minutes / float(MINUTES_PER_DAY)


## Colour to hand a [CanvasModulate] so the world dims at night.
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
