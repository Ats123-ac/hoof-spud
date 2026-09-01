## Root of the playable farm.
##
## Ground is normally painted in the editor (Part 2). Until it has been, this
## fills a starter grass patch so the project is runnable — once Ground contains
## any tiles the seeding is skipped, so you can delete [method _seed_ground]
## after you paint the real map.
extends Node2D

## Index of the Grass atlas in tilesets/farm_tileset.tres.
const GRASS_SOURCE := 0
## Solid interior cell of the grass blob.
const GRASS_TILE := Vector2i(1, 1)
## Half-size of the seeded patch, in tiles.
const SEED_EXTENT := Vector2i(24, 14)

@onready var ground: TileMapLayer = $Ground


func _ready() -> void:
	if ground.get_used_cells().is_empty():
		_seed_ground()


func _seed_ground() -> void:
	for y in range(-SEED_EXTENT.y, SEED_EXTENT.y):
		for x in range(-SEED_EXTENT.x, SEED_EXTENT.x):
			ground.set_cell(Vector2i(x, y), GRASS_SOURCE, GRASS_TILE)
