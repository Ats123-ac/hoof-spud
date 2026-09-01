## What an object yields when it breaks. Rolled by [DropComponent].
##
## Every entry is rolled independently, so a table can both guarantee wood and
## occasionally add a sapling.
class_name DropTable
extends Resource

@export var entries: Array[DropEntry] = []


## Roll every entry. Returns one `{item, amount}` dictionary per entry that hit.
func roll() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for entry in entries:
		if entry == null or entry.item == null:
			continue
		if entry.chance < 1.0 and randf() > entry.chance:
			continue

		var low := mini(entry.min_amount, entry.max_amount)
		var high := maxi(entry.min_amount, entry.max_amount)
		var amount := randi_range(low, high)
		if amount > 0:
			results.append({"item": entry.item, "amount": amount})

	return results
