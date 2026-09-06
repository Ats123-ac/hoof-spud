## Area the player's tool hitbox can strike.
##
## [method Player.swing_tool] calls [method take_hit] on every overlapping area that
## defines it, so this is the one contract between the player and every destructible
## thing. [member accepted_tools] is what makes an axe useless on a rock.

class_name HurtboxComponent
extends Area2D

## A hit that passed the tool check and was forwarded to health.
signal hit_received(tool_name: StringName, damage: int)

## Wrong tool; drive a bounce or a deny sound from this.
signal hit_rejected(tool_name: StringName)

## Tools allowed to damage this; empty accepts every tool.
@export var accepted_tools: Array[StringName] = []

## Optional: leave null and listen to [signal hit_received] to handle hits yourself.
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
