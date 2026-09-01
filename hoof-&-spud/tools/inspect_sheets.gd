## Inspection helper: magnifies sprite sheets with a cell-grid overlay so atlas
## coordinates can be read off directly instead of guessed. Output goes to
## tools/_slices/, which is scratch — safe to delete any time.
##
## Run with:
##   godot --headless --path <project> -s res://tools/inspect_sheets.gd
extends SceneTree

const OUT_DIR := "res://tools/_slices"
const BACKGROUND := Color(0.22, 0.22, 0.28)
const GRID_COLOR := Color(1.0, 0.25, 0.55, 0.55)

const ASSETS := "res://Assets/farming sprites"

## path, cell size, zoom factor
const SHEETS: Array[Dictionary] = [
	{"path": ASSETS + "/Objects/Basic Grass Biom things 1.png", "cell": 16, "zoom": 6},
	{"path": ASSETS + "/Objects/Basic tools and meterials.png", "cell": 16, "zoom": 12},
	{"path": ASSETS + "/Objects/Basic Plants.png", "cell": 16, "zoom": 10},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for sheet in SHEETS:
		_emit(sheet["path"], sheet["cell"], sheet["zoom"])
	quit()


func _emit(path: String, cell: int, zoom: int) -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	if source == null:
		push_error("could not load %s" % path)
		return

	source.convert(Image.FORMAT_RGBA8)
	var cells := source.get_size() / cell
	source.resize(source.get_width() * zoom, source.get_height() * zoom, Image.INTERPOLATE_NEAREST)

	# Flatten onto an opaque backdrop so transparent padding is distinguishable.
	var canvas := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	canvas.fill(BACKGROUND)
	canvas.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i.ZERO)
	_draw_grid(canvas, cell * zoom)

	var out_name := path.get_file().get_basename().replace(" ", "_")
	var out_path := "%s/%s_grid.png" % [OUT_DIR, out_name]
	canvas.save_png(ProjectSettings.globalize_path(out_path))
	print("wrote %s (%dx%d, %dx%d cells)" % [out_path, canvas.get_width(), canvas.get_height(), cells.x, cells.y])


func _draw_grid(canvas: Image, step: int) -> void:
	for x in range(0, canvas.get_width(), step):
		for y in canvas.get_height():
			canvas.set_pixel(x, y, GRID_COLOR)
	for y in range(0, canvas.get_height(), step):
		for x in canvas.get_width():
			canvas.set_pixel(x, y, GRID_COLOR)
