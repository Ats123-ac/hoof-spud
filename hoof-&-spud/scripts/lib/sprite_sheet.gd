## Slices uniform grid sprite sheets into [SpriteFrames] animations.
##
## The Sprout Lands sheets are plain grids, so an animation is just "row N,
## columns 0..K". Declaring clips this way keeps the whole mapping readable in
## one place instead of scattered across dozens of [AtlasTexture] sub-resources.
class_name SpriteSheet
extends RefCounted


## Cell coordinates for [param count] consecutive cells on row [param y],
## starting at column [param start].
static func row(y: int, count: int, start: int = 0) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in count:
		cells.append(Vector2i(start + i, y))
	return cells


## Register [param cells] of [param sheet] as an animation named [param clip].
static func add_clip(
	frames: SpriteFrames,
	sheet: Texture2D,
	cell_size: Vector2i,
	clip: StringName,
	cells: Array[Vector2i],
	fps: float = 8.0,
	loop: bool = true
) -> void:
	if not frames.has_animation(clip):
		frames.add_animation(clip)
	frames.set_animation_speed(clip, fps)
	frames.set_animation_loop(clip, loop)

	for coordinate in cells:
		var region := AtlasTexture.new()
		region.atlas = sheet
		region.region = Rect2i(coordinate * cell_size, cell_size)
		region.filter_clip = true
		frames.add_frame(clip, region)
