## A pickup lying in the world: pops out on spawn, then homes in on the player.
##
## Proximity is a distance check against the "player" group rather than an Area2D.
## Drops spawn on top of whatever was just struck, often already overlapping the
## player, and a distance check behind an arming delay sidesteps the enter/exit
## ordering problems that come with monitoring areas.

class_name Collectable
extends Node2D

signal collected(item: ItemData, amount: int)

@export var item: ItemData:
	set(value):
		item = value
		if is_inside_tree():
			_refresh_icon()

@export_range(1, 999) var amount: int = 1

## Seconds before the pickup will home, so it visibly pops out first.
@export_range(0.0, 2.0) var arm_delay: float = 0.35

## Distance at which an armed pickup starts homing, in pixels.
@export_range(4.0, 64.0) var pickup_radius: float = 22.0

## Distance at which it is absorbed, in pixels.
@export_range(1.0, 16.0) var absorb_radius: float = 4.0

@export_range(10.0, 600.0) var home_speed: float = 230.0

## Height of the arc played on spawn, in pixels.
@export_range(0.0, 24.0) var pop_height: float = 7.0

var _age: float = 0.0
var _target: Node2D = null
var _absorbed: bool = false

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	_refresh_icon()
	_play_pop()


func _physics_process(delta: float) -> void:
	if _absorbed:
		return

	_age += delta

	if _target == null:
		if _age >= arm_delay:
			_acquire_target()
		return

	if not is_instance_valid(_target):
		_target = null
		return

	global_position = global_position.move_toward(_target.global_position, home_speed * delta)
	if global_position.distance_to(_target.global_position) <= absorb_radius:
		_absorb()


func _acquire_target() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= pickup_radius:
		_target = player


func _absorb() -> void:
	_absorbed = true
	if item != null:
		Inventory.add(item.id, amount)
	Audio.play(&"pickup")
	collected.emit(item, amount)
	queue_free()


func _refresh_icon() -> void:
	if sprite != null and item != null:
		sprite.texture = item.icon


## A small hop so a fresh drop reads as knocked loose.
func _play_pop() -> void:
	if is_zero_approx(pop_height):
		return

	sprite.position = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", -pop_height, 0.14).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 0.16).set_ease(Tween.EASE_IN)
