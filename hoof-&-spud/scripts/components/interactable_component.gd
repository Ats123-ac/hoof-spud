## Area marking its owner as something the player can talk to, open, harvest or sleep in.
##
## The owner listens to [signal interacted], the HUD reads [member prompt_text] of the
## component the player stands in, and the player calls [method try_interact] on the
## nearest one. Sits on collision layer 7 and watches layer 2 (the player) only.

class_name InteractableComponent
extends Area2D

signal interacted(component: InteractableComponent)

signal player_hover_changed(inside: bool)

## What the HUD prints, e.g. "Open Chest".
@export var prompt_text: String = "Interact"

## Lets an owner stop being interactable without leaving the tree.
@export var enabled: bool = true

var player_inside: bool = false


func _ready() -> void:
	collision_layer = 64
	collision_mask = 2
	monitorable = false
	monitoring = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	add_to_group(&"interactable")


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	player_inside = true
	player_hover_changed.emit(true)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	player_inside = false
	player_hover_changed.emit(false)


## False when the attempt was ignored, so callers can play a deny.
func try_interact() -> bool:
	if not enabled or not player_inside or not is_inside_tree():
		return false
	interacted.emit(self)
	return true


## Closest component [param node] is standing in; compares squared distances.
static func nearest_to(node: Node2D, require_inside: bool = true) -> InteractableComponent:
	var best: InteractableComponent = null
	var best_distance := INF

	for candidate in node.get_tree().get_nodes_in_group(&"interactable"):
		var component := candidate as InteractableComponent
		if component == null or not is_instance_valid(component):
			continue
		if require_inside and not component.player_inside:
			continue
		var distance := component.global_position.distance_squared_to(node.global_position)
		if distance < best_distance:
			best_distance = distance
			best = component

	return best
