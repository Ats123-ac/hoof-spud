## Base class for a single state inside a [StateMachine].
##
## Subclasses override only the hooks they care about. Every state reaches its
## owner through [member agent], so the same state script can be reused by the
## player, the chicken and the cow.
class_name State
extends Node

## Request a switch to the state registered under [param next].
signal transitioned(next: StringName)

## The node this state drives. Assigned by [StateMachine] before [method enter].
var agent: Node


## Called once when the machine switches into this state.
func enter(_previous: StringName) -> void:
	pass


## Called once when the machine switches away from this state.
func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass
