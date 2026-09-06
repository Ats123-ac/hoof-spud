## Root of the playable farm.
##
## Owns the four things nothing else can: the painted ground, the navigation map,
## the save file's round trip, and routing tool swings into the [FarmSystem].
##
## Ground is painted here rather than stored in the scene because a hand-painted
## 64x40 field is thousands of tile entries that drift; a deterministic paint
## function is one screen and never does.

extends Node2D

## Hour at which an unfinished day ends by itself.
const PASS_OUT_HOUR := 2

## Grass atlas index in tilesets/farm_tileset.tres.
const GRASS_SOURCE := 0
## Solid interior cell of the grass blob.
const GRASS_TILE := Vector2i(1, 1)
## Water source and its single animated tile.
const WATER_SOURCE := 3
const WATER_TILE := Vector2i(0, 0)

## The farm's extent in tiles, and the navigation map's outline.
const FIELD := Rect2i(-32, -22, 64, 40)
## The pond, as an ellipse in tile space.
const POND_CENTER := Vector2(16.0, 7.0)
const POND_RADIUS := Vector2(7.0, 4.0)
## Pre-hoed plot in tiles, so a new save can sow immediately.
const STARTER_PLOT := Rect2i(-6, 2, 5, 3)

@onready var water: TileMapLayer = $Water
@onready var ground: TileMapLayer = $Ground
@onready var farm: FarmSystem = $Farm
@onready var navigation: NavigationRegion2D = $Navigation
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var hud: Hud = $HUD

var _passing_out := false


func _ready() -> void:
	add_to_group(&"level")

	if ground.get_used_cells().is_empty():
		_paint_level()

	player.tool_swung.connect(_on_tool_swung)
	GameClock.day_started.connect(_on_day_started)
	SceneSwap.scene_changing.connect(_on_scene_changing)

	_load()
	_build_navigation()

	GameClock.running = true


func _process(_delta: float) -> void:
	if _passing_out or SceneSwap.is_swapping():
		return
	if GameClock.hour() == PASS_OUT_HOUR:
		_pass_out()


#region level


func _paint_level() -> void:
	for y in range(FIELD.position.y, FIELD.end.y):
		for x in range(FIELD.position.x, FIELD.end.x):
			var cell := Vector2i(x, y)
			if _in_pond(cell):
				water.set_cell(cell, WATER_SOURCE, WATER_TILE)
				continue
			ground.set_cell(cell, GRASS_SOURCE, GRASS_TILE)

	# A fresh farm comes with the plot already hoed.
	for y in range(STARTER_PLOT.position.y, STARTER_PLOT.end.y):
		for x in range(STARTER_PLOT.position.x, STARTER_PLOT.end.x):
			farm.till(Vector2i(x, y))


func _in_pond(cell: Vector2i) -> bool:
	var offset := (Vector2(cell) + Vector2(0.5, 0.5) - POND_CENTER) / POND_RADIUS
	return offset.length_squared() <= 1.0


## One navigation map for the whole farm: the field outline with a hole punched for
## every cell or footprint an animal should walk around. Holes are outlines
## contained by the outer one, which the bake resolves.
func _build_navigation() -> void:
	var poly := NavigationPolygon.new()
	poly.add_outline(_rect_points(_tile_rect_to_world(FIELD)))

	for cell in water.get_used_cells():
		poly.add_outline(_rect_points(_cell_rect(cell)))

	for child in entities.get_children():
		var footprint := _footprint(child)
		if footprint.size.x > 0.0:
			poly.add_outline(_rect_points(footprint))

	navigation.navigation_polygon = poly
	navigation.bake_navigation_polygon()


## Solid ground an animal must path around, in world space.
func _footprint(node: Node2D) -> Rect2:
	if node is Harvestable or node is Chest:
		return Rect2(node.global_position - Vector2(7, 6), Vector2(14, 12))
	if node is Farmhouse:
		return Rect2(node.global_position - Vector2(26, 10), Vector2(52, 14))
	return Rect2()


func _tile_rect_to_world(rect: Rect2i) -> Rect2:
	var top_left := ground.map_to_local(rect.position)
	return Rect2(top_left, Vector2(rect.size) * 16.0)


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(water.map_to_local(cell), Vector2(16, 16))


func _rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		]
	)


#endregion
#region tools into farming


func _on_tool_swung(tool: StringName, target: Vector2) -> void:
	var data := player.current_tool_data()
	if data == null:
		return

	var cell := farm.cell_for(target)
	match data.kind:
		ToolData.Kind.TILL:
			farm.till(cell)
		ToolData.Kind.WATER:
			farm.water(cell)
		ToolData.Kind.SEED:
			_sow(cell, data)
		_:
			pass


func _sow(cell: Vector2i, data: ToolData) -> void:
	if data.crop == null:
		return
	if not farm.can_plant(cell):
		return

	var seed_item: ItemData = data.crop.seed_item
	if seed_item != null:
		if not Inventory.has(seed_item.id):
			Audio.play(&"deny", 0.0)
			return
		Inventory.remove(seed_item.id, 1)

	farm.plant(cell, data.crop)


#endregion
#region day cycle


func _on_day_started(_day: int) -> void:
	if SaveGame.restoring or _passing_out:
		return
	save_now()


func _pass_out() -> void:
	_passing_out = true
	hud.toast("You passed out in the field...")
	await SceneSwap.fade_out(0.8)
	Audio.play(&"sleep")
	GameClock.sleep()
	save_now()
	await get_tree().create_timer(0.3).timeout
	await SceneSwap.fade_in(0.8)
	_passing_out = false


#endregion
#region save / load


func _on_scene_changing(_path: String) -> void:
	save_now()


## Writes the whole farm; the pause menu prints the result.
func save_now() -> bool:
	return SaveGame.write(_gather())


func _gather() -> SaveData:
	var data := SaveData.new()
	data.day = GameClock.day
	data.minutes = GameClock.minutes
	data.player_position = player.global_position
	data.player_facing = player.facing_name()
	data.tool_index = player.tool_index
	data.inventory = Inventory.snapshot()

	var field := farm.collect_save()
	data.tilled = field["tilled"]
	data.watered = field["watered"]
	data.crops = field["crops"]

	for node in get_tree().get_nodes_in_group(&"harvestable"):
		data.harvestables.append((node as Harvestable).collect_save())
	for node in get_tree().get_nodes_in_group(&"chest"):
		var chest := node as Chest
		data.chests.append({"name": chest.name, "items": chest.items.duplicate()})
	for child in entities.get_children():
		var animal := child as Animal
		if animal != null:
			data.animals.append(animal.collect_save())

	data.met = SaveGame.met.duplicate()
	return data


func _load() -> void:
	var data := SaveGame.read()
	if data == null:
		_fresh_save()
		return

	SaveGame.restoring = true
	GameClock.restore(data.day, data.minutes)

	player.global_position = data.player_position
	player.facing = _facing_vector(data.player_facing)
	player.select_tool(data.tool_index)
	Inventory.load_snapshot(data.inventory)

	farm.apply_save(data.tilled, data.watered, data.crops)

	var harvestables := _by_name(data.harvestables)
	for node in get_tree().get_nodes_in_group(&"harvestable"):
		var entry: Dictionary = harvestables.get(node.name, {})
		if not entry.is_empty():
			(node as Harvestable).apply_save(entry)

	var chests := _by_name(data.chests)
	for node in get_tree().get_nodes_in_group(&"chest"):
		var entry: Dictionary = chests.get(node.name, {})
		if not entry.is_empty():
			(node as Chest).items = (entry.get("items", {}) as Dictionary).duplicate()

	var animals := _by_name(data.animals)
	for child in entities.get_children():
		var animal := child as Animal
		if animal == null:
			continue
		var entry: Dictionary = animals.get(child.name, {})
		if not entry.is_empty():
			animal.apply_save(entry)

	SaveGame.met.assign(data.met)
	SaveGame.restoring = false


# The autoloads outlive the scene, so a new farm starts from empty hands and day
# one even when the process has already run a session.
func _fresh_save() -> void:
	Inventory.clear()
	SaveGame.met.clear()
	GameClock.reset()
	Inventory.add(&"wheat_seeds", 8)
	Inventory.add(&"eggplant_seeds", 4)
	hud.toast("Welcome to the farm.")


func _by_name(entries: Array[Dictionary]) -> Dictionary:
	var by_name := {}
	for entry in entries:
		var key := String(entry.get("name", ""))
		if key != "":
			by_name[key] = entry
	return by_name


func _facing_vector(facing: StringName) -> Vector2:
	match facing:
		&"up":
			return Vector2.UP
		&"left":
			return Vector2.LEFT
		&"right":
			return Vector2.RIGHT
		_:
			return Vector2.DOWN


#endregion
