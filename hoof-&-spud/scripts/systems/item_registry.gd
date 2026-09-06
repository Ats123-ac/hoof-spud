## Autoload mapping [member ItemData.id] to its [ItemData] resource.
##
## Scans `resources/items` once at boot, so a new item is a new .tres file and
## nothing else.

extends Node

const ITEMS_DIR := "res://resources/items"

var _by_id: Dictionary[StringName, ItemData] = {}


func _ready() -> void:
	_scan()


func _scan() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("No item resources found at %s." % ITEMS_DIR)
		return

	for file in dir.get_files():
		var clean := file.trim_suffix(".remap")
		if not (clean.ends_with(".tres") or clean.ends_with(".res")):
			continue
		var resource := ResourceLoader.load("%s/%s" % [ITEMS_DIR, clean]) as ItemData
		if resource == null:
			continue
		if resource.id == &"":
			push_warning("%s has no id and was skipped." % clean)
			continue
		_by_id[resource.id] = resource


## Null for an unknown id, so a data typo draws a placeholder instead of crashing.
func data(id: StringName) -> ItemData:
	return _by_id.get(id)


func has(id: StringName) -> bool:
	return _by_id.has(id)


func all() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for id in _by_id.keys():
		items.append(_by_id[id])
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.id < b.id)
	return items
