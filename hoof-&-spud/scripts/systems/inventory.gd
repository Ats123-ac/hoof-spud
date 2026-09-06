## Autoload holding what the player carries, as counts keyed by [member ItemData.id].
##
## UI renders from [signal changed] rather than polling, and [method snapshot] is
## what the save file stores.

extends Node

signal changed(id: StringName, total: int)
signal item_added(id: StringName, amount: int, total: int)

var _counts: Dictionary[StringName, int] = {}


func add(id: StringName, amount: int = 1) -> void:
	if id == &"" or amount <= 0:
		return

	var total: int = _counts.get(id, 0) + amount
	_counts[id] = total
	item_added.emit(id, amount, total)
	changed.emit(id, total)


## Removes up to [param amount]; returns how many were actually removed.
func remove(id: StringName, amount: int = 1) -> int:
	if amount <= 0:
		return 0

	var held: int = _counts.get(id, 0)
	var taken := mini(held, amount)
	if taken == 0:
		return 0

	var total := held - taken
	if total == 0:
		_counts.erase(id)
	else:
		_counts[id] = total

	changed.emit(id, total)
	return taken


func count(id: StringName) -> int:
	return _counts.get(id, 0)


func has(id: StringName, amount: int = 1) -> bool:
	return count(id) >= amount


## A copy, so callers may mutate it freely.
func snapshot() -> Dictionary[StringName, int]:
	return _counts.duplicate()


func load_snapshot(data: Dictionary) -> void:
	_counts.clear()
	for key in data:
		var id := StringName(key)
		var total := int(data[key])
		if total > 0:
			_counts[id] = total
			changed.emit(id, total)


func clear() -> void:
	for id in _counts.keys():
		changed.emit(id, 0)
	_counts.clear()
