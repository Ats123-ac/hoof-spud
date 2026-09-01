## Magnifies the individual cells that are candidates for tool-bar icons, so the
## right one gets hard-coded instead of a guess.
##
##   godot --headless -s res://tools/view_icons.gd
extends SceneTree

const ROOT := "res://Assets/farming sprites"
const ZOOM := 18

## sheet, cell coordinate — laid out left to right in the output strip.
const CELLS := [
	["Objects/Basic tools and meterials.png", Vector2i(0, 0)],
	["Objects/Basic tools and meterials.png", Vector2i(1, 0)],
	["Objects/Basic tools and meterials.png", Vector2i(2, 0)],
	["Characters/Tools.png", Vector2i(0, 2)],
	["Characters/Tools.png", Vector2i(1, 2)],
	["Characters/Tools.png", Vector2i(2, 2)],
	["Characters/Tools.png", Vector2i(3, 2)],
	["Characters/Tools.png", Vector2i(4, 2)],
	["Characters/Tools.png", Vector2i(5, 2)],
]

const LIGHT := Color(0.30, 0.30, 0.34)
const DARK := Color(0.20, 0.20, 0.24)
const EDGE := Color(1.0, 0.25, 0.9)


func _init() -> void:
	var out := Image.create(16 * ZOOM * CELLS.size(), 16 * ZOOM, false, Image.FORMAT_RGBA8)

	for index in CELLS.size():
		var entry: Array = CELLS[index]
		var sheet := Image.load_from_file("%s/%s" % [ROOT, entry[0]])
		if sheet == null:
			continue
		sheet.convert(Image.FORMAT_RGBA8)
		var origin: Vector2i = entry[1] * 16

		for y in 16 * ZOOM:
			for x in 16 * ZOOM:
				var pixel := sheet.get_pixelv(origin + Vector2i(x / ZOOM, y / ZOOM))
				var checker := LIGHT if (x / ZOOM + y / ZOOM) % 2 == 0 else DARK
				out.set_pixel(index * 16 * ZOOM + x, y, checker.lerp(pixel, pixel.a))

		for y in 16 * ZOOM:
			out.set_pixel(index * 16 * ZOOM, y, EDGE)
		print("%d: %s %s" % [index, entry[0].get_file(), entry[1]])

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/_view"))
	out.save_png("res://tools/_view/icon_candidates.png")
	quit()
