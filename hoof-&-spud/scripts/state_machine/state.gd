## Base class for a single state inside a [StateMachine].
##
## Subclasses override only the hooks they use and reach the node they drive through
## [member agent], so one state script can serve the player and the animals.

class_name State
extends Node

## Requests a switch to the state registered under [param next].
signal transitioned(next: StringName)

## Assigned by [StateMachine] before [method enter] is called.
var agent: Node


func enter(_previous: StringName) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
