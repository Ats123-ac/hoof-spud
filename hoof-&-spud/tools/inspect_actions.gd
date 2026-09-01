## Inspection helper: lays the three tool blocks of the character actions sheet
## side by side so the tool held in each can be identified by eye.
##
## Columns, left to right, are the three blocks at sheet rows 0, 4 and 8.
## Rows, top to bottom, are: facing-down frame 0, facing-down frame 1,
## facing-right frame 0, facing-right frame 1.
##
## Run with:
##   godot --headless --path <project> -s res://tools/inspect_actions.gd
extends SceneTree

const SHEET := "res://Assets/farming sprites/Characters/Basic Charakter Actions.png"
const OUT := "res://tools/_actions_blocks.png"

const CELL := 48
const ZOOM := 8
const BACKGROUND := Color(0.22, 0.22, 0.28)
const SEPARATOR := Color(1.0, 0.25, 0.55, 0.9)

## Sheet row of each tool block.
const BLOCKS: Array[int] = [0, 4, 8]

## Offset from a block's first row per output row, plus which frame column.
## The profile views are the ones that show a tool head's shape clearly.
const VIEWS: Array[Vector2i] = [
	Vector2i(0, 0),  # facing down, frame 0
	Vector2i(0, 1),  # facing down, frame 1
	Vector2i(3, 0),  # profile, frame 0
	Vector2i(3, 1),  # profile, frame 1
]


func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if source == null:
		push_error("could not load %s" % SHEET)
		quit(1)
		return

	source.convert(Image.FORMAT_RGBA8)
	print("sheet: %s px = %s cells of %d" % [source.get_size(), source.get_size() / CELL, CELL])

	var step := CELL * ZOOM
	var canvas := Image.create(BLOCKS.size() * step, VIEWS.size() * step, false, Image.FORMAT_RGBA8)
	canvas.fill(BACKGROUND)

	for column in BLOCKS.size():
		for row in VIEWS.size():
			var view: Vector2i = VIEWS[row]
			var cell := Vector2i(view.y, BLOCKS[column] + view.x)
			var tile := source.get_region(Rect2i(cell * CELL, Vector2i(CELL, CELL)))
			tile.resize(step, step, Image.INTERPOLATE_NEAREST)
			canvas.blend_rect(
				tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(column * step, row * step)
			)

	_draw_separators(canvas, step)
	canvas.save_png(ProjectSettings.globalize_path(OUT))
	print("wrote %s (%dx%d)" % [OUT, canvas.get_width(), canvas.get_height()])
	quit()


func _draw_separators(canvas: Image, step: int) -> void:
	for x in range(step, canvas.get_width(), step):
		for y in canvas.get_height():
			canvas.set_pixel(x, y, SEPARATOR)
	for y in range(step, canvas.get_height(), step):
		for x in canvas.get_width():
			canvas.set_pixel(x, y, SEPARATOR)
