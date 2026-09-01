## Writes magnified, grid-annotated copies of the sheets the remaining parts need,
## so cell regions can be read off by eye instead of guessed.
##
##   godot --headless -s res://tools/view_sheets.gd
##
## Output lands in tools/_view/ and is safe to delete.
extends SceneTree

const ROOT := "res://Assets/farming sprites"
const OUT := "res://tools/_view"

## Sheet, cell size, and magnification. Kept small enough to stay legible.
const SHEETS := [
	["Characters/Free Chicken Sprites.png", 16, 12],
	["Characters/Free Cow Sprites.png", 32, 9],
	["Characters/Tools.png", 16, 8],
	["Characters/Egg_And_Nest.png", 16, 12],
	["Objects/Basic Plants.png", 16, 11],
	["Objects/Basic tools and meterials.png", 16, 14],
	["Objects/Chest.png", 16, 5],
	["Objects/Simple Milk and grass item.png", 16, 12],
	["Objects/Free_Chicken_House.png", 16, 11],
	["Objects/Basic Furniture.png", 16, 7],
	["Tilesets/Wooden House.png", 16, 8],
	["Tilesets/Wooden_House_Roof_Tilset.png", 16, 8],
	["Tilesets/Wooden_House_Walls_Tilset.png", 16, 11],
	["Tilesets/Doors.png", 16, 11],
	["Tilesets/Tilled_Dirt.png", 16, 6],
	["Tilesets/Fences.png", 16, 11],
	["Objects/Paths.png", 16, 11],
]

const LIGHT := Color(0.30, 0.30, 0.34)
const DARK := Color(0.20, 0.20, 0.24)
const GRID := Color(1.0, 0.25, 0.9, 0.85)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	for entry in SHEETS:
		var path: String = "%s/%s" % [ROOT, entry[0]]
		var cell: int = entry[1]
		var zoom: int = entry[2]

		var source := Image.load_from_file(path)
		if source == null:
			print("missing %s" % path)
			continue
		source.convert(Image.FORMAT_RGBA8)

		var size := source.get_size()
		var out := Image.create(size.x * zoom, size.y * zoom, false, Image.FORMAT_RGBA8)

		for y in out.get_height():
			for x in out.get_width():
				var source_pixel := Vector2i(x / zoom, y / zoom)
				var pixel := source.get_pixelv(source_pixel)
				var checker := LIGHT if (source_pixel.x + source_pixel.y) % 2 == 0 else DARK
				out.set_pixel(x, y, checker.lerp(pixel, pixel.a))

		# Cell boundaries, drawn last so they sit on top of the art.
		for gx in range(0, size.x + 1, cell):
			for y in out.get_height():
				out.set_pixel(mini(gx * zoom, out.get_width() - 1), y, GRID)
		for gy in range(0, size.y + 1, cell):
			for x in out.get_width():
				out.set_pixel(x, mini(gy * zoom, out.get_height() - 1), GRID)

		var label: String = String(entry[0]).get_file().get_basename().to_snake_case()
		var target := "%s/%s.png" % [OUT, label]
		out.save_png(target)
		print(
			"%-32s %dx%d px, %dx%d cells of %d, zoom %d"
			% [label, size.x, size.y, size.x / cell, size.y / cell, cell, zoom]
		)

	quit()
