## The farmhouse, assembled from atlas sprites rather than painted tiles: the house
## sheet's shingle and plank blocks are self-contained rectangles, so three sprites
## and two collision boxes make a building that can be dropped anywhere.
##
## The door is locked and says so through a [DialogueComponent].

class_name Farmhouse
extends Node2D

const HOUSE_SHEET := "res://Assets/farming sprites/Tilesets/Wooden House.png"
const DOOR_SHEET := "res://Assets/farming sprites/Tilesets/Doors.png"

## One plank-and-window column of the front wall, three cells tall.
const WALL_REGION := Rect2(16, 16, 16, 48)
## A 2x2 block of roof shingles.
const ROOF_REGION := Rect2(80, 16, 32, 32)
## Closed door, one cell.
const DOOR_REGION := Rect2(0, 16, 16, 16)

## Front-wall columns in tiles; the middle one is left out for the door.
const WALL_COLUMNS := [-1, 1]

@onready var walls: Node2D = $Walls
@onready var roof: Sprite2D = $Roof
@onready var door: Sprite2D = $Door


func _ready() -> void:
	_build()


func _build() -> void:
	var house := load(HOUSE_SHEET) as Texture2D
	var door_sheet := load(DOOR_SHEET) as Texture2D

	for column in WALL_COLUMNS:
		var wall := Sprite2D.new()
		wall.texture = _atlas(house, WALL_REGION)
		# Origin sits at the base of the wall so Y-sorting meets the player feet-first;
		# the 48px column therefore hangs upward from here.
		wall.position = Vector2(column * 16, 0)
		wall.offset = Vector2(0, -24)
		walls.add_child(wall)

	roof.texture = _atlas(house, ROOF_REGION)
	roof.position = Vector2(0, -46)
	roof.z_index = 2

	door.texture = _atlas(door_sheet, DOOR_REGION)
	door.position = Vector2(0, -8)


func _atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = region
	texture.filter_clip = true
	return texture
