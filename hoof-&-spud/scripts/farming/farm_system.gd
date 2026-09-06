## Owns everything that happens to soil: tilling, watering, planting and the
## overnight growth tick.
##
## Tilled and watered ground is tiles, crops are nodes. Tiles are cheap and save as a
## cell list; crops carry stage and growth, so they live as [Crop] children of
## [member crop_container] and Y-sort with the rest of the farm. Watering only marks
## a cell damp - [signal GameClock.day_started] advances every crop on a damp cell
## and then dries the field.

class_name FarmSystem
extends Node

signal tilled(cell: Vector2i)
signal watered(cell: Vector2i)
signal planted(cell: Vector2i, crop: Crop)
signal cleared(cell: Vector2i)

const CROPS_DIR := "res://resources/crops"

## "Tilled Dirt" atlas in tilesets/farm_tileset.tres.
const TILLED_SOURCE := 2

## The flat, featureless dirt cell.
const TILLED_TILE := Vector2i(0, 5)

@export var ground_layer: TileMapLayer
@export var water_layer: TileMapLayer
@export var tilled_layer: TileMapLayer

## Painted with the same dirt tile under a darkened modulate, so damp soil reads as
## damp without a second art variant.
@export var moist_layer: TileMapLayer

@export var crop_container: Node2D
@export var crop_scene: PackedScene
@export var collectable_scene: PackedScene

## Cell to damp state. Only damp cells are painted on [member moist_layer], so the
## two cannot disagree.
var _watered: Dictionary = {}

## Cell to living crop node.
var _crops: Dictionary = {}

## Crop catalogue, scanned once so a saved crop id resolves.
var _crop_by_id: Dictionary[StringName, CropData] = {}


func _ready() -> void:
	GameClock.day_started.connect(_on_day_started)
	_scan_crops()


func _scan_crops() -> void:
	var dir := DirAccess.open(CROPS_DIR)
	if dir == null:
		push_warning("No crop resources found at %s." % CROPS_DIR)
		return

	for file in dir.get_files():
		var clean := file.trim_suffix(".remap")
		if not (clean.ends_with(".tres") or clean.ends_with(".res")):
			continue
		var data := ResourceLoader.load("%s/%s" % [CROPS_DIR, clean]) as CropData
		if data != null and data.id != &"":
			_crop_by_id[data.id] = data


func crop_data(id: StringName) -> CropData:
	return _crop_by_id.get(id)


#region queries


## The tile a world-space point falls in, on the tilled layer's grid.
func cell_for(point: Vector2) -> Vector2i:
	return tilled_layer.local_to_map(tilled_layer.to_local(point))


## World-space centre of [param cell].
func center_of(cell: Vector2i) -> Vector2:
	return tilled_layer.to_global(tilled_layer.map_to_local(cell))


func is_tilled(cell: Vector2i) -> bool:
	return tilled_layer.get_cell_source_id(cell) != -1


func is_watered(cell: Vector2i) -> bool:
	return _watered.has(cell)


## Ground the hoe can bite: painted, not water, not already tilled, nothing growing.
func can_till(cell: Vector2i) -> bool:
	if is_tilled(cell) or _crops.has(cell):
		return false
	if water_layer != null and water_layer.get_cell_source_id(cell) != -1:
		return false
	return ground_layer != null and ground_layer.get_cell_source_id(cell) != -1


func can_water(cell: Vector2i) -> bool:
	return is_tilled(cell) and not is_watered(cell)


func can_plant(cell: Vector2i) -> bool:
	return is_tilled(cell) and not _crops.has(cell)


#endregion
#region actions


## True when the soil actually turned over.
func till(cell: Vector2i) -> bool:
	if not can_till(cell):
		return false
	tilled_layer.set_cell(cell, TILLED_SOURCE, TILLED_TILE)
	tilled.emit(cell)
	return true


## True when the soil actually took water.
func water(cell: Vector2i) -> bool:
	if not can_water(cell):
		return false
	_watered[cell] = true
	moist_layer.set_cell(cell, TILLED_SOURCE, TILLED_TILE)
	watered.emit(cell)
	return true


## The caller owns seed consumption, so a failed plant can never eat a seed.
func plant(cell: Vector2i, data: CropData) -> Crop:
	if data == null or not can_plant(cell) or crop_scene == null:
		return null

	var crop: Crop = crop_scene.instantiate()
	crop_container.add_child(crop)
	crop.global_position = center_of(cell)
	crop.cell = cell
	crop.setup(data)

	_crops[cell] = crop
	planted.emit(cell, crop)
	return crop


## [param clear_soil] also hoes the tile back to plain ground, for saves and for
## crops pulled up whole.
func remove_crop(cell: Vector2i, clear_soil: bool) -> void:
	var crop: Crop = _crops.get(cell)
	if crop != null and is_instance_valid(crop):
		crop.queue_free()
	_crops.erase(cell)

	if clear_soil:
		tilled_layer.erase_cell(cell)
		_watered.erase(cell)
		moist_layer.erase_cell(cell)
	cleared.emit(cell)


## Scatters a pickup the same way [DropComponent] does.
func spawn_collectable(item: ItemData, at: Vector2, amount: int = 1) -> void:
	if item == null or collectable_scene == null:
		return
	var parent := crop_container.get_parent()
	if parent == null:
		parent = get_tree().current_scene
	for _i in amount:
		var pickup := collectable_scene.instantiate()
		pickup.item = item
		pickup.amount = 1
		parent.add_child(pickup)
		pickup.global_position = at + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))


#endregion
#region day cycle


func _on_day_started(_day: int) -> void:
	# Grow first, dry second: the damp flag describes the day that just ended.
	for cell in _crops.keys():
		var crop: Crop = _crops.get(cell)
		if crop != null and is_instance_valid(crop) and _watered.has(cell):
			crop.grow()

	_watered.clear()
	if moist_layer != null:
		moist_layer.clear()


#endregion
#region save / load


## Everything [SaveData] needs about the field.
func collect_save() -> Dictionary:
	var crops: Array[Dictionary] = []
	for cell in _crops.keys():
		var crop: Crop = _crops.get(cell)
		if crop == null or not is_instance_valid(crop) or crop.data == null:
			continue
		crops.append(
			{
				"cell": cell,
				"crop": crop.data.id,
				"stage": crop.stage,
				"growth": crop.growth,
			}
		)

	return {
		"tilled": tilled_layer.get_used_cells(),
		"watered": _watered.keys(),
		"crops": crops,
	}


func apply_save(tilled: Array[Vector2i], watered: Array[Vector2i], crops: Array[Dictionary]) -> void:
	tilled_layer.clear()
	moist_layer.clear()
	for cell in _crops.keys():
		var crop: Crop = _crops.get(cell)
		if crop != null and is_instance_valid(crop):
			crop.queue_free()
	_crops.clear()
	_watered.clear()

	for cell in tilled:
		tilled_layer.set_cell(cell, TILLED_SOURCE, TILLED_TILE)

	for entry in watered:
		var cell := entry as Vector2i
		if tilled_layer.get_cell_source_id(cell) == -1:
			continue
		_watered[cell] = true
		moist_layer.set_cell(cell, TILLED_SOURCE, TILLED_TILE)

	for entry in crops:
		var cell := entry.get("cell", Vector2i.ZERO) as Vector2i
		var data := crop_data(StringName(String(entry.get("crop", &""))))
		if data == null or tilled_layer.get_cell_source_id(cell) == -1:
			continue
		var crop := plant(cell, data)
		if crop != null:
			crop.restore(int(entry.get("stage", 0)), int(entry.get("growth", 0)))


#endregion
