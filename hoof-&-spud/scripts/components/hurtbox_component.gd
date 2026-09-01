## Area the player's tool hitbox can strike.
##
## [method Player.swing_tool] calls [method take_hit] on every overlapping area
## that defines it, so this is the single contract between the player and every
## destructible thing in the world. Gating on [member accepted_tools] is what
## makes an axe useless on a rock.
class_name HurtboxComponent
extends Area2D

## A hit that passed the tool check and was forwarded to health.
signal hit_received(tool_name: StringName, damage: int)

## A hit with the wrong tool. Useful for a "wrong tool" bounce or sound.
signal hit_rejected(tool_name: StringName)

## Tools allowed to damage this. Leave empty to accept every tool.
@export var accepted_tools: Array[StringName] = []

## Health to damage. Optional — listen to [signal hit_received] instead if the
## owner wants to handle hits itself.
@export var health: HealthComponent


func take_hit(tool_name: StringName, damage: int) -> void:
	if health != null and not health.is_alive():
		return

	if not accepted_tools.is_empty() and not accepted_tools.has(tool_name):
		hit_rejected.emit(tool_name)
		return

	hit_received.emit(tool_name, damage)
	if health != null:
		health.apply_damage(damage)
