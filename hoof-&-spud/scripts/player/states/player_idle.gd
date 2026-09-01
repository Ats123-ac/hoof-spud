## Standing still. Leaves for "walk" on input, or for the active tool's state
## when the use_tool action fires.
extends State

var _player: Player


func enter(_previous: StringName) -> void:
	_player = agent as Player
	_player.play_directional(&"idle")


func physics_update(delta: float) -> void:
	_player.decelerate(delta)
	_player.move_and_slide()

	if not _player.get_input_direction().is_zero_approx():
		transitioned.emit(&"walk")


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"use_tool"):
		var tool_state := _player.current_tool()
		if _player.state_machine.has_state(tool_state):
			transitioned.emit(tool_state)
