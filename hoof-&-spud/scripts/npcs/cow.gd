## The cow: the same [Animal] as the hen with a bigger sheet, a bigger footprint and
## an appetite - she only gives milk on mornings after a fed day.
##
## The sheet is 3x2 cells of 32px: three idle frames over two walk frames.

extends Animal

const SHEET := "res://Assets/farming sprites/Characters/Free Cow Sprites.png"
const CELL := Vector2i(32, 32)


func _ready() -> void:
	_build_frames()
	super._ready()


func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var sheet := load(SHEET) as Texture2D
	SpriteSheet.add_clip(frames, sheet, CELL, &"idle", SpriteSheet.row(0, 3), 3.0)
	SpriteSheet.add_clip(frames, sheet, CELL, &"walk", SpriteSheet.row(1, 2), 4.0)

	sprite.sprite_frames = frames
	sprite.play(&"idle")
