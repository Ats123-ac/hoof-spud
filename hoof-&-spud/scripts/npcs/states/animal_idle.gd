## Standing about, until the animal gets bored of standing about.
##
## Shared by every [Animal]: the chicken and the cow differ only in the exported
## [member animation] and the numbers on their scenes.

extends State

@export var animation: StringName = &"idle"

var _animal: Animal
var _timer: float = 0.0


func enter(_previous: StringName) -> void:
	_animal = agent as Animal
	_timer = _animal.pause_seconds()
	_animal.sprite.play(animation)
	if randf() < 0.25:
		_animal.maybe_speak()


func physics_update(delta: float) -> void:
	# [Animal] owns move_and_slide; the states only set velocity.
	_animal.stop()

	_timer -= delta
	if _timer <= 0.0:
		transitioned.emit(&"wander")
