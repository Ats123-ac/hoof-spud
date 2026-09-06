## A world object struck with a tool until it breaks, then drops pickups.
##
## Shared by the tree and the rock, which differ only in sprite, accepted tool,
## health and drop table. The sprite origin sits at the base of its opaque pixels so
## Y-sorting compares feet to feet, and collision is a small footprint straddling
## that origin rather than the height of the art: [SeeThroughComponent] fades the
## canopy instead of walling the player off with an invisible box.

class_name Harvestable
extends Node2D

signal harvested

## Sprite swapped in once broken, e.g. a stump; empty removes the node instead.
@export var depleted_texture: Texture2D

## Seconds until it comes back; 0 keeps it depleted forever.
@export_range(0.0, 600.0) var respawn_seconds: float = 0.0

## Sway applied per hit, in pixels.
@export_range(0.0, 8.0) var hit_shake: float = 2.0

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var health: HealthComponent = $Health
@onready var shake: ShakeComponent = $Shake
@onready var flash: HitFlashComponent = $Flash
@onready var drops: DropComponent = $Drop

var _full_texture: Texture2D
var _depleted: bool = false

## Tool behind the most recent accepted hit; tool ids double as sound names.
var _last_tool: StringName = &""


func _ready() -> void:
	_full_texture = sprite.texture
	_align_sprite()
	add_to_group(&"harvestable")

	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	hurtbox.hit_rejected.connect(_on_hit_rejected)


# Runs before [HealthComponent.damaged], so the impact sound already knows the tool.
func _on_hit_received(tool_name: StringName, _damage: int) -> void:
	_last_tool = tool_name


func _on_damaged(_amount: int, _remaining: int) -> void:
	shake.shake(hit_shake)
	flash.flash()
	if Audio.has(_last_tool):
		Audio.play(_last_tool)


func _on_hit_rejected(_tool_name: StringName) -> void:
	# Right idea, wrong tool: nudge it so the swing still reads as landing.
	shake.shake(hit_shake * 0.4)
	Audio.play(&"deny", 0.0)


func _on_died() -> void:
	drops.drop(global_position)
	harvested.emit()
	_set_depleted(true)

	if respawn_seconds > 0.0:
		get_tree().create_timer(respawn_seconds).timeout.connect(_respawn)


func _respawn() -> void:
	if not is_inside_tree():
		return
	health.reset()
	_set_depleted(false)


func _set_depleted(value: bool) -> void:
	_depleted = value

	if not value:
		sprite.texture = _full_texture
		_align_sprite()
		sprite.show()
		hurtbox.monitorable = true
		return

	if depleted_texture == null and respawn_seconds <= 0.0:
		queue_free()
		return

	if depleted_texture != null:
		sprite.texture = depleted_texture
		_align_sprite()
	else:
		sprite.hide()

	# The remnant keeps its footprint - a stump is still something to walk around -
	# it just cannot be struck again.
	hurtbox.monitorable = false


## Sits the sprite so the bottom of its *opaque* pixels rests on the node origin,
## the point Y-sorting compares. Measuring the texture would count the transparent
## padding inside a cell and float the prop above its own sort position.
func _align_sprite() -> void:
	var texture := sprite.texture
	if texture == null:
		return

	var height := texture.get_height()
	var base := height - 1

	var image := texture.get_image()
	if image != null:
		var opaque := image.get_used_rect()
		if opaque.size.y > 0:
			base = opaque.position.y + opaque.size.y - 1

	sprite.offset = Vector2(0.0, height * 0.5 - base - 1)


#region save / load


## Enough to bring a chopped tree back as a stump, or a half-whittled one back at
## two health.
func collect_save() -> Dictionary:
	return {
		"name": name,
		"health": health.health,
		"depleted": _depleted,
		"respawn": respawn_seconds,
	}


## Restores a prop from a [SaveData] entry. Anything not marked depleted comes back
## alive, whatever the health value in the file says.
func apply_save(entry: Dictionary) -> void:
	var was_depleted := bool(entry.get("depleted", false))
	respawn_seconds = float(entry.get("respawn", respawn_seconds))

	if was_depleted:
		health.health = 0
		_set_depleted(true)
	else:
		_set_depleted(false)
		health.health = clampi(int(entry.get("health", health.max_health)), 1, health.max_health)


#endregion
