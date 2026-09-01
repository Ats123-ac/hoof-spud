## Reviews a gameplay capture that VLC has already been sampled into JPEGs.
##
## First it scores every frame by how much *coloured* pixel content the game
## panel holds — an empty Godot embedded-game panel is flat grey, so this
## separates "the game was rendering" from "the window was blank". Then it tiles
## the frames that actually have content into sheets, cropped to the panel and
## halved back to roughly the game's native 640x360 render so no pixel detail is
## lost on the way in.
##
## Run with:
##   godot --headless --path <project> -s res://tools/frames.gd
extends SceneTree

const DIR := "C:/Users/pc/AppData/Local/Temp/hs_jpg"
const OUT := "C:/Users/pc/AppData/Local/Temp/hs_sheets"

## Editor chrome to skip when scoring: toolbar across the top, thin border round.
const PANEL := Rect2i(10, 45, 1276, 730)

## A pixel counts as content when its channels spread wider than this. Flat grey
## chrome scores zero; grass, dirt and sprites score high.
const CHROMA := 0.08

## Fraction of the panel that must be coloured before a frame is worth reading.
const CONTENT_FLOOR := 0.02

const COLUMNS := 2
const ROWS := 2
const SCALE := 2

const LABEL := Color(1.0, 0.3, 0.1)
const BORDER := Color(0.05, 0.05, 0.05)

## 3x5 dot matrix per digit, column-major bits, for stamping frame numbers.
const DIGITS := {
	"0": [0b11111, 0b10001, 0b11111],
	"1": [0b00000, 0b11111, 0b00000],
	"2": [0b10111, 0b10101, 0b11101],
	"3": [0b11111, 0b10101, 0b10101],
	"4": [0b11100, 0b00100, 0b11111],
	"5": [0b11101, 0b10101, 0b10111],
	"6": [0b11111, 0b10100, 0b11100],
	"7": [0b10000, 0b10000, 0b11111],
	"8": [0b11111, 0b10101, 0b11111],
	"9": [0b00111, 0b00101, 0b11111],
}

## Capture rate, for turning frame numbers into timestamps.
const FPS := 30.0


func _initialize() -> void:
	var names := _frame_names()
	if names.is_empty():
		push_error("no frames in %s" % DIR)
		quit(1)
		return

	var scored: Array[Dictionary] = []
	for name in names:
		var frame := Image.load_from_file("%s/%s" % [DIR, name])
		if frame == null:
			print("unreadable: %s" % name)
			continue
		frame.convert(Image.FORMAT_RGB8)
		scored.append({"name": name, "content": _content_ratio(frame), "image": frame})

	_report(scored)

	var interesting := scored.filter(func(entry: Dictionary) -> bool:
		return entry["content"] >= CONTENT_FLOOR)
	print("\n%d of %d frames have game content" % [interesting.size(), scored.size()])
	if interesting.is_empty():
		quit()
		return

	DirAccess.make_dir_recursive_absolute(OUT)
	_write_sheets(interesting)
	quit()


## Fraction of the panel whose pixels are coloured rather than flat chrome grey.
func _content_ratio(frame: Image) -> float:
	var data := frame.get_data()
	var width := frame.get_width()
	var coloured := 0
	var sampled := 0

	# Sampled on a lattice; a full sweep of 205 frames is needlessly slow and the
	# answer only needs to distinguish "blank" from "rendering".
	for y in range(PANEL.position.y, PANEL.end.y, 3):
		var row := y * width * 3
		for x in range(PANEL.position.x, PANEL.end.x, 3):
			var index := row + x * 3
			var r := data[index]
			var g := data[index + 1]
			var b := data[index + 2]
			var high: int = maxi(r, maxi(g, b))
			var low: int = mini(r, mini(g, b))
			if float(high - low) / 255.0 > CHROMA:
				coloured += 1
			sampled += 1

	return float(coloured) / float(sampled) if sampled > 0 else 0.0


## Print a compact timeline so a blank stretch is obvious at a glance.
func _report(scored: Array[Dictionary]) -> void:
	print("frame  time   content")
	for i in scored.size():
		var entry: Dictionary = scored[i]
		var number := int(String(entry["name"]).lstrip("j").trim_suffix(".jpg"))
		var ratio: float = entry["content"]
		var bar := "#".repeat(int(ratio * 60.0))
		print("%5d  %5.1fs  %5.1f%% %s" % [number, number / FPS, ratio * 100.0, bar])


func _write_sheets(frames: Array[Dictionary]) -> void:
	var crop := _panel_crop(frames[0]["image"])
	var cell := crop.size / SCALE
	var per_sheet := COLUMNS * ROWS
	var sheets := int(ceil(float(frames.size()) / per_sheet))
	print("crop %s -> cell %s, %d sheets" % [crop, cell, sheets])

	for sheet in sheets:
		var canvas := Image.create(cell.x * COLUMNS, cell.y * ROWS, false, Image.FORMAT_RGB8)
		canvas.fill(BORDER)
		var members := PackedStringArray()

		for slot in per_sheet:
			var index := sheet * per_sheet + slot
			if index >= frames.size():
				break
			var frame: Image = frames[index]["image"]
			var view := frame.get_region(crop)
			view.resize(cell.x, cell.y, Image.INTERPOLATE_NEAREST)

			var at := Vector2i(slot % COLUMNS, slot / COLUMNS) * cell
			canvas.blit_rect(view, Rect2i(Vector2i.ZERO, cell), at)

			var number := int(String(frames[index]["name"]).lstrip("j").trim_suffix(".jpg"))
			_stamp(canvas, at + Vector2i(4, 4), str(number))
			members.append("%d" % number)

		canvas.save_png("%s/sheet%02d.png" % [OUT, sheet])
		print("sheet%02d: %s" % [sheet, ", ".join(members)])


## Trim to the coloured game view inside the panel, keeping the size even so
## halving it is exact.
func _panel_crop(frame: Image) -> Rect2i:
	var data := frame.get_data()
	var width := frame.get_width()
	var bounds := Rect2i()
	var found := false

	for y in range(PANEL.position.y, PANEL.end.y):
		var row := y * width * 3
		for x in range(PANEL.position.x, PANEL.end.x):
			var index := row + x * 3
			var high: int = maxi(data[index], maxi(data[index + 1], data[index + 2]))
			var low: int = mini(data[index], mini(data[index + 1], data[index + 2]))
			if float(high - low) / 255.0 <= CHROMA:
				continue
			if found:
				bounds = bounds.expand(Vector2i(x, y))
			else:
				bounds = Rect2i(x, y, 1, 1)
				found = true

	if not found:
		return PANEL
	bounds.size.x = bounds.size.x & ~1
	bounds.size.y = bounds.size.y & ~1
	return bounds


## Write [param text] as 3x5 dots scaled 2x, so a sheet says which frame is which.
func _stamp(canvas: Image, at: Vector2i, text: String) -> void:
	var cursor := at
	for character in text:
		var glyph: Array = DIGITS.get(character, [])
		for column in glyph.size():
			for row in 5:
				if glyph[column] & (1 << (4 - row)):
					_dot(canvas, cursor + Vector2i(column, row) * 2)
		cursor.x += 8


func _dot(canvas: Image, at: Vector2i) -> void:
	for x in 2:
		for y in 2:
			var point := at + Vector2i(x, y)
			if point.x < canvas.get_width() and point.y < canvas.get_height():
				canvas.set_pixelv(point, LABEL)


func _frame_names() -> PackedStringArray:
	var names := PackedStringArray()
	var dir := DirAccess.open(DIR)
	if dir == null:
		return names
	for file in dir.get_files():
		if file.ends_with(".jpg"):
			names.append(file)
	names.sort()
	return names
