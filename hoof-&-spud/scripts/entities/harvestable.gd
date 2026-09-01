## A world object that can be struck with a tool until it breaks, dropping
## pickups. Shared by the tree (Part 6) and the rock (Part 8) — they differ only
## in sprite, accepted tool, health and drop table.
##
## The sprite's origin sits at the base of its opaque pixels so Y-sorting
## (Part 9) compares feet to feet with the player and NPCs.
##
## Collision is a small footprint straddling that origin — the ground the prop
## stands on, not the height of its art. The player's body box is 12x7 centred on
## its feet, so a footprint centred on the origin holds them a similar distance
## back on all four sides; a box stacked above the origin instead lets them walk
## in until they overlap from below while walling them off from above.
## [SeeThroughComponent] handles the canopy hiding the player, which is what
## oversized collision would otherwise be papering over.
class_name Harvestable
extends Node2D

signal harvested

## Sprite swapped in once broken, e.g. a stump. Leave empty to remove the node.
@export var depleted_texture: Texture2D

## Seconds until it comes back. 0 keeps it depleted forever.
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


func _ready() -> void:
	_full_texture = sprite.texture
	_align_sprite()

	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hurtbox.hit_rejected.connect(_on_hit_rejected)


func _on_damaged(_amount: int, _remaining: int) -> void:
	shake.shake(hit_shake)
	flash.flash()


func _on_hit_rejected(_tool_name: StringName) -> void:
	# Right idea, wrong tool — nudge it so the swing still reads as landing.
	shake.shake(hit_shake * 0.4)


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

	# The remnant keeps its footprint — a stump is still something to walk around.
	# It just cannot be struck again.
	hurtbox.monitorable = false


## Sit the sprite so the bottom of its *opaque* pixels rests on the node origin,
## which is the point Y-sorting compares. Measuring the texture instead would
## count the transparent padding at the bottom of a cell, floating the prop above
## its own sort position — the rock sits 2px off that way.
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


func is_depleted() -> bool:
	return _depleted
