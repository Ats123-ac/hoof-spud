## Spawns collectable pickups from a [DropTable] when its owner breaks.
##
## Pickups are parented outside the owner so they outlive it being freed.

class_name DropComponent
extends Node

signal dropped(item: ItemData, amount: int)

@export var table: DropTable

## Instantiated once per unit dropped; must expose `item` and `amount`.
@export var collectable_scene: PackedScene

## Random scatter radius per pickup, in pixels.
@export_range(0.0, 32.0) var spread: float = 5.0

## Parent for the pickups; defaults to the owner's parent.
@export var container: Node

## Ceiling so a mis-configured table cannot spawn hundreds of nodes.
const MAX_NODES_PER_DROP := 12


## Rolls [member table] and spawns the results around [param origin], in global space.
func drop(origin: Vector2) -> void:
	if table == null or collectable_scene == null:
		return

	var parent := _resolve_container()
	if parent == null:
		push_warning("%s has nowhere to parent its drops." % name)
		return

	var budget := MAX_NODES_PER_DROP
	for result in table.roll():
		var item: ItemData = result["item"]
		var amount: int = result["amount"]
		dropped.emit(item, amount)

		for _i in mini(amount, budget):
			_spawn(parent, item, origin)
		budget -= mini(amount, budget)
		if budget <= 0:
			break


func _spawn(parent: Node, item: ItemData, origin: Vector2) -> void:
	var pickup := collectable_scene.instantiate()
	pickup.item = item
	pickup.amount = 1
	parent.add_child(pickup)
	pickup.global_position = origin + Vector2(
		randf_range(-spread, spread), randf_range(-spread, spread)
	)


func _resolve_container() -> Node:
	if container != null:
		return container
	if owner != null and owner.get_parent() != null:
		return owner.get_parent()
	return get_tree().current_scene
