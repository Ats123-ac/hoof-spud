## Hit points for anything destructible. Deliberately knows nothing about how
## damage arrives, so trees, rocks, crops and NPCs can all use it.
class_name HealthComponent
extends Node

signal damaged(amount: int, remaining: int)
signal healed(amount: int, remaining: int)
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


func heal(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return

	health = mini(health + amount, max_health)
	healed.emit(amount, health)


func is_alive() -> bool:
	return health > 0


## Restore to full without emitting [signal died]/[signal damaged]. Used when a
## harvested node respawns.
func reset() -> void:
	health = max_health
