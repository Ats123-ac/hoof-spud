## Head down, busy: pecking at the ground or cropping grass for a few seconds.
##
## Cosmetic only - the produce timer runs off [GameClock], not off this - but an
## animal that never stops to eat reads as a sliding sprite.

extends State

@export var animation: StringName = &"peck"

@export var graze_min: float = 1.2
@export var graze_max: float = 3.0

var _animal: Animal
var _timer: float = 0.0


func enter(_previous: StringName) -> void:
	_animal = agent as Animal
	_timer = randf_range(graze_min, graze_max)
	_animal.sprite.play(animation)


func physics_update(delta: float) -> void:
	_animal.stop()

	_timer -= delta
	if _timer <= 0.0:
		transitioned.emit(&"idle")
