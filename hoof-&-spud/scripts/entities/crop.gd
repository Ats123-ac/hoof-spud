## A planted crop.
##
## Growth is counted in watered days: [FarmSystem] calls [method grow] once per dawn,
## and only for cells that were damp, so a neglected plot simply waits.
## [member CropData.regrow_stage] lets a crop survive its own harvest: eggplant falls
## back to a half-grown plant, wheat is pulled up whole.

class_name Crop
extends Node2D

signal ripened

## Emitted after a successful harvest, before any regrow.
signal harvested(produce: ItemData, amount: int)

## Cell this crop occupies; assigned by [FarmSystem].
var cell: Vector2i = Vector2i.ZERO

var data: CropData

## Index into [member CropData.stages].
var stage: int = 0

## Watered days accumulated toward the next stage.
var growth: int = 0

@onready var sprite: Sprite2D = $Sprite
@onready var interact: InteractableComponent = $Interact


func _ready() -> void:
	interact.interacted.connect(_on_interacted)
	_refresh()


## Called by [FarmSystem] right after instantiation.
func setup(crop_data: CropData) -> void:
	data = crop_data
	stage = 0
	growth = 0
	if is_inside_tree():
		_refresh()


## Restores a half-grown field from a save.
func restore(saved_stage: int, saved_growth: int) -> void:
	if data == null:
		return
	stage = clampi(saved_stage, 0, data.ripe_stage())
	growth = maxi(saved_growth, 0)
	_refresh()


func is_ripe() -> bool:
	return data != null and stage >= data.ripe_stage()


## One watered day's worth of growth.
func grow() -> void:
	if data == null or is_ripe():
		return

	growth += 1
	if growth < data.days_per_stage:
		return

	growth = 0
	stage = mini(stage + 1, data.ripe_stage())
	_refresh()
	if is_ripe():
		ripened.emit()


## False when there was nothing to take.
func harvest() -> bool:
	if data == null or not is_ripe():
		return false

	var farm := _farm()
	var amount := randi_range(data.produce_min, data.produce_max)
	if farm != null and data.produce != null:
		farm.spawn_collectable(data.produce, global_position, amount)
	harvested.emit(data.produce, amount)
	Audio.play(&"harvest")

	if data.regrow_stage >= 0:
		stage = mini(data.regrow_stage, data.ripe_stage())
		growth = 0
		_refresh()
	else:
		if farm != null:
			farm.remove_crop(cell, false)
		else:
			queue_free()
	return true


func _on_interacted(_component: InteractableComponent) -> void:
	if not harvest():
		Audio.play(&"deny", 0.0)


func _refresh() -> void:
	if data == null:
		return

	if sprite != null:
		sprite.texture = data.texture_for(stage)

	if interact != null:
		interact.enabled = is_ripe()
		interact.prompt_text = "Harvest %s" % data.display_name


func _farm() -> FarmSystem:
	var node := get_parent()
	while node != null:
		var farm := node.get_node_or_null(^"Farm") as FarmSystem
		if farm != null:
			return farm
		node = node.get_parent()
	return null
