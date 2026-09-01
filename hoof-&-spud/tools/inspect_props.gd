## Inspection helper: magnifies the harvestable prop sprites with a measuring
## grid so collision boxes can be sized against the real silhouette.
##
## Each panel is a 32x32 window with the sprite bottom-centred, matching how
## Harvestable aligns them (origin at the base, centred horizontally). Grid
## lines are every 4 source pixels; the brighter lines mark the origin column
## and the base row.
##
## Run with:
##   godot --headless --path <project> -s res://tools/inspect_props.gd
extends SceneTree

const SHEET := "res://Assets/farming sprites/Objects/Basic Grass Biom things 1.png"
const OUT := "res://tools/_props.png"

## Window each sprite is placed into, in source pixels.
const WINDOW := 32
const ZOOM := 14
const GRID_STEP := 4

const BACKGROUND := Color(0.22, 0.22, 0.28)
const GRID := Color(1.0, 0.25, 0.55, 0.35)
const AXIS := Color(0.35, 1.0, 0.6, 0.85)
const EDGE := Color(1.0, 0.85, 0.2, 0.9)

## Regions to inspect, in the order they appear left to right.
const REGIONS: Array[Dictionary] = [
	{"name": "tree", "rect": Rect2i(16, 0, 32, 32)},
	{"name": "stump", "rect": Rect2i(48, 32, 16, 16)},
	{"name": "rock", "rect": Rect2i(128, 16, 16, 16)},
]


func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if source == null:
		push_error("could not load %s" % SHEET)
		quit(1)
		return

	source.convert(Image.FORMAT_RGBA8)

	var panel := WINDOW * ZOOM
	var canvas := Image.create(REGIONS.size() * panel, panel, false, Image.FORMAT_RGBA8)
	canvas.fill(BACKGROUND)

	for i in REGIONS.size():
		var region: Dictionary = REGIONS[i]
		var rect: Rect2i = region["rect"]
		var tile := source.get_region(rect)
		print("%s: %s at %s, opaque bounds %s" % [region["name"], rect.size, rect.position, tile.get_used_rect()])

		# Bottom-centre inside the window, the way Harvestable aligns it.
		var window_image := Image.create(WINDOW, WINDOW, false, Image.FORMAT_RGBA8)
		var offset := Vector2i((WINDOW - rect.size.x) / 2, WINDOW - rect.size.y)
		window_image.blend_rect(tile, Rect2i(Vector2i.ZERO, rect.size), offset)
		window_image.resize(panel, panel, Image.INTERPOLATE_NEAREST)

		canvas.blend_rect(window_image, Rect2i(Vector2i.ZERO, Vector2i(panel, panel)), Vector2i(i * panel, 0))
		_draw_measures(canvas, i * panel, panel)

	canvas.save_png(ProjectSettings.globalize_path(OUT))
	print("wrote %s (%dx%d), %d px per source pixel" % [OUT, canvas.get_width(), canvas.get_height(), ZOOM])
	quit()


func _draw_measures(canvas: Image, x_origin: int, panel: int) -> void:
	for step in range(0, WINDOW + 1, GRID_STEP):
		var offset: int = step * ZOOM
		for y in panel:
			_plot(canvas, x_origin + offset, y, GRID)
		for x in panel:
			_plot(canvas, x_origin + x, offset, GRID)

	# Origin column (sprite centre) and base row (sprite bottom).
	for y in panel:
		_plot(canvas, x_origin + (WINDOW / 2) * ZOOM, y, AXIS)
	for x in panel:
		_plot(canvas, x_origin + x, panel - 1, AXIS)

	# Panel divider.
	for y in panel:
		_plot(canvas, x_origin, y, EDGE)


func _plot(canvas: Image, x: int, y: int, colour: Color) -> void:
	if x >= 0 and y >= 0 and x < canvas.get_width() and y < canvas.get_height():
		canvas.set_pixel(x, y, colour)
