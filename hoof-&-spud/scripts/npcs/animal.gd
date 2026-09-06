## Base class for the farm's animals, and - with a different sprite and a
## [DialogueComponent] - for villagers too.
##
## Movement is a three-state loop (idle -> wander -> graze) driven by a
## [NavigationAgent2D] with avoidance on, so two animals can want the same spot
## without shoving each other. Wander targets stay inside [member wander_radius] of
## [member home], the spot the scene placed the animal at, so nothing drifts across
## the map over a long session.
##
## Produce follows the day: an animal that needs feeding only yields on mornings
## after a fed day, one that does not yields every morning.

class_name Animal
extends CharacterBody2D

signal fed_changed(fed: bool)
signal product_ready_changed(ready: bool)

@export_group("Movement")
@export var wander_speed: float = 18.0
@export var wander_radius: float = 70.0
@export var pause_min: float = 1.5
@export var pause_max: float = 4.0

@export_group("Voice")
@export var idle_sound: StringName = &""
@export var sound_chance: float = 0.3

@export_group("Product")
## What interacting yields when ready.
@export var product: ItemData
@export var product_prompt: String = "Collect"
## Setting this makes the animal need feeding before it produces.
@export var feed_item: ItemData
@export var feed_prompt: String = "Feed"
## Hen-style: produces every morning without being fed.
@export var produces_unfed: bool = true

var home: Vector2
var fed: bool = false
var product_ready: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var state_machine: StateMachine = $StateMachine
@onready var interact: InteractableComponent = $Interact


func _ready() -> void:
	home = global_position

	agent.path_desired_distance = 3.0
	agent.target_desired_distance = 3.0
	agent.avoidance_enabled = true
	agent.radius = 5.0
	agent.neighbor_distance = 40.0

	interact.interacted.connect(_on_interacted)
	GameClock.day_started.connect(_on_day_started)
	_refresh_prompt()


func _physics_process(_delta: float) -> void:
	move_and_slide()


#region navigation helpers used by the states


## A random spot near home for the next wander.
func wander_target() -> Vector2:
	var angle := randf() * TAU
	var reach := randf_range(8.0, wander_radius)
	return home + Vector2(cos(angle), sin(angle)) * reach


func set_destination(point: Vector2) -> void:
	agent.target_position = point


func is_travel_done() -> bool:
	return agent.is_navigation_finished()


## Follows the current path, easing in and out so arrivals do not snap.
func steer(delta: float) -> void:
	if agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, 120.0 * delta)
		return

	var next := agent.get_next_path_position()
	var direction := (next - global_position).normalized()
	velocity = velocity.move_toward(direction * wander_speed, 240.0 * delta)
	face(direction)


func stop() -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 120.0 * get_physics_process_delta_time())


## Side-view sheets face right, so leftward travel is a flip.
func face(direction: Vector2) -> void:
	if absf(direction.x) > 0.15:
		sprite.flip_h = direction.x < 0.0


func pause_seconds() -> float:
	return randf_range(pause_min, pause_max)


func maybe_speak() -> void:
	if idle_sound != &"" and randf() < sound_chance:
		Audio.play(idle_sound)


#endregion
#region day cycle and interaction


func _on_day_started(_day: int) -> void:
	if produces_unfed or fed:
		product_ready = true
		product_ready_changed.emit(true)
	fed = false
	fed_changed.emit(false)
	_refresh_prompt()


func _on_interacted(_component: InteractableComponent) -> void:
	if product_ready and product != null:
		product_ready = false
		product_ready_changed.emit(false)
		Inventory.add(product.id, 1)
		Audio.play(&"pickup")
		maybe_speak()
		_refresh_prompt()
		return

	if feed_item != null and not fed:
		if not Inventory.has(feed_item.id):
			Audio.play(&"deny", 0.0)
			return
		Inventory.remove(feed_item.id, 1)
		fed = true
		fed_changed.emit(true)
		Audio.play(&"plant")
		maybe_speak()
		_refresh_prompt()
		return

	# Nothing to give and nothing to take: a greeting.
	if idle_sound != &"":
		Audio.play(idle_sound, 0.0)


func _refresh_prompt() -> void:
	if product_ready and product != null:
		interact.prompt_text = product_prompt
	elif feed_item != null and not fed:
		interact.prompt_text = feed_prompt
	else:
		interact.prompt_text = "Pet"
	interact.enabled = true


#endregion
#region save / load


func collect_save() -> Dictionary:
	return {
		"name": name,
		"position": global_position,
		"fed": fed,
		"ready": product_ready,
	}


func apply_save(entry: Dictionary) -> void:
	global_position = entry.get("position", global_position) as Vector2
	fed = bool(entry.get("fed", false))
	product_ready = bool(entry.get("ready", false))
	home = global_position
	_refresh_prompt()


#endregion
