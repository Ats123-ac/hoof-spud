## Walking to a fresh spot near home along the navigation path.
##
## Re-targets once on entry; when the agent reports the path finished the animal
## settles into whatever the scene wired as its busy state - pecking for the hen,
## grazing for the cow.

extends State

@export var animation: StringName = &"walk"

## State to enter on arrival.
@export var arrive_state: StringName = &"graze"

var _animal: Animal


func enter(_previous: StringName) -> void:
	_animal = agent as Animal
	_animal.set_destination(_animal.wander_target())
	_animal.sprite.play(animation)


func physics_update(delta: float) -> void:
	_animal.steer(delta)

	if _animal.is_travel_done():
		transitioned.emit(arrive_state)
