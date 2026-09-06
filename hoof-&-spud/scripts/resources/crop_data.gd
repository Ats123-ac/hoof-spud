## Static description of one crop: what it looks like at each growth stage and what
## it yields.
##
## Growth is counted in watered days rather than real time - a crop only advances if
## it was watered before the day rolled over, which is what ties farming to
## [GameClock].

class_name CropData
extends Resource

## Stable key used by save data.
@export var id: StringName = &""

@export var display_name: String = ""

## One 16x16 texture per stage, seedling first and ripe last.
@export var stages: Array[Texture2D] = []

## Watered days needed to climb one stage.
@export_range(1, 10) var days_per_stage: int = 1

## What harvesting gives.
@export var produce: ItemData
@export_range(1, 20) var produce_min: int = 1
@export_range(1, 20) var produce_max: int = 2

## Seeds sometimes recovered on harvest, so the farm can sustain itself.
@export var seed_item: ItemData
@export_range(0.0, 1.0) var seed_return_chance: float = 0.35

## Stage the plant drops back to after harvest; -1 clears the tile instead.
@export_range(-1, 8) var regrow_stage: int = -1


func ripe_stage() -> int:
	return maxi(stages.size() - 1, 0)


## Clamped, so a mis-typed save can never crash the draw call.
func texture_for(stage: int) -> Texture2D:
	if stages.is_empty():
		return null
	return stages[clampi(stage, 0, stages.size() - 1)]
