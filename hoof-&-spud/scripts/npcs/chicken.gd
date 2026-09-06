## The hen: a small [Animal] that pecks about the yard and leaves an egg every
## morning.
##
## Its sheet is a 4x2 grid of 16px cells - two blink frames on the top row, a
## four-frame strut on the bottom - so the clips are sliced here the same way
## [Player] slices its sheets.

extends Animal

const SHEET := "res://Assets/farming sprites/Characters/Free Chicken Sprites.png"
const CELL := Vector2i(16, 16)


func _ready() -> void:
	_build_frames()
	super._ready()


func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var sheet := load(SHEET) as Texture2D
	# Head down, then back up: reads as a peck on loop.
	SpriteSheet.add_clip(frames, sheet, CELL, &"idle", SpriteSheet.row(0, 2), 3.0)
	SpriteSheet.add_clip(frames, sheet, CELL, &"walk", SpriteSheet.row(1, 4), 7.0)
	SpriteSheet.add_clip(
		frames, sheet, CELL, &"peck", [Vector2i(1, 1), Vector2i(0, 0)], 2.5
	)

	sprite.sprite_frames = frames
	sprite.play(&"idle")
