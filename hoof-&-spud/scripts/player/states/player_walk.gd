## Moving under player input. Re-plays the directional walk clip whenever the
## facing changes so turning corners swaps animation immediately.
extends State

var _player: Player
var _last_facing: StringName = &""


func enter(_previous: StringName) -> void:
	_player = agent as Player
	_last_facing = &""


func physics_update(delta: float) -> void:
	var direction := _player.get_input_direction()
	if direction.is_zero_approx():
		transitioned.emit(&"idle")
		return

	_player.accelerate(direction, delta)
	_player.move_and_slide()

	var facing := _player.facing_name()
	if facing != _last_facing:
		_last_facing = facing
		_player.play_directional(&"walk")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"use_tool"):
		var tool_state := _player.current_tool()
		if _player.state_machine.has_state(tool_state):
			transitioned.emit(tool_state)
