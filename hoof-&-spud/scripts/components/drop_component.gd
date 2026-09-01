## Spawns collectable pickups from a [DropTable] when its owner breaks.
##
## Pickups are parented outside the owner so they survive it being freed — a
## chopped tree disappears, its logs do not.
class_name DropComponent
extends Node

signal dropped(item: ItemData, amount: int)

@export var table: DropTable

## Scene instantiated per pickup. Must expose `item` and `amount`.
@export var collectable_scene: PackedScene

## Radius of the random scatter applied to each pickup, in pixels.
@export_range(0.0, 32.0) var spread: float = 5.0

## Node the pickups are parented to. Defaults to the owner's parent.
@export var container: Node

## Safety valve so a mis-configured table cannot spawn hundreds of nodes.
const MAX_NODES_PER_DROP := 12


## Roll [member table] and spawn the results around [param origin] (global).
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

		# One node per unit reads better than a single stack of five.
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
