## Prints the pixel size and opaque extent of every art sheet, so cell grids can
## be worked out before any region is hard-coded.
##
##   godot --headless -s res://tools/sheet_sizes.gd
extends SceneTree

const ROOT := "res://Assets/farming sprites"


func _init() -> void:
	for folder in ["Characters", "Objects", "Tilesets"]:
		print("\n== %s" % folder)
		var directory := DirAccess.open("%s/%s" % [ROOT, folder])
		if directory == null:
			continue
		for file in directory.get_files():
			if not file.ends_with(".png"):
				continue
			var path := "%s/%s/%s" % [ROOT, folder, file]
			var image := Image.load_from_file(path)
			if image == null:
				continue
			var size := image.get_size()
			print(
				"  %-40s %4dx%-4d  /16 = %sx%s%s"
				% [
					file,
					size.x,
					size.y,
					"%.2f" % (size.x / 16.0),
					"%.2f" % (size.y / 16.0),
					"" if size.x % 16 == 0 and size.y % 16 == 0 else "   (not a 16 grid)",
				]
			)
	quit()
