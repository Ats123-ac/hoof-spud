## Hit points for anything destructible.
##
## Deliberately knows nothing about how damage arrives, so props, crops and NPCs
## can share it.

class_name HealthComponent
extends Node

signal damaged(amount: int, remaining: int)
signal died

@export_range(1, 999) var max_health: int = 3

var health: int


func _ready() -> void:
	health = max_health


func apply_damage(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return

	health = maxi(health - amount, 0)
	damaged.emit(amount, health)
	if health == 0:
		died.emit()


func is_alive() -> bool:
	return health > 0


## Back to full without emitting, for a respawning node.
func reset() -> void:
	health = max_health
