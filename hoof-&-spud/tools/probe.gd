## Throwaway integration check for the Part 6-9 component layer.
##
## Runs as a real main-loop scene (not `-s`) so autoloads exist: the Inventory
## singleton is what receives the pickups at the end of the chain.
##
##   godot --headless res://tools/probe.tscn
extends Node

## Physics frames waited for an overlap or a swing to register.
const SETTLE := 4

## Sides a harvestable has to be reachable from, as unit offsets.
const APPROACHES: Dictionary[StringName, Vector2] = {
	&"north": Vector2.UP,
	&"south": Vector2.DOWN,
	&"east": Vector2.RIGHT,
	&"west": Vector2.LEFT,
}

var _world: Node2D
var _player: Player
var _entities: Node2D


func _ready() -> void:
	_world = load("res://scenes/world/world.tscn").instantiate()
	add_child(_world)
	await get_tree().physics_frame

	_player = _world.get_node("Entities/Player")
	_entities = _world.get_node("Entities")

	_report_tools()

	# Bigger bodies must not push the player out of the tool's range.
	await _report_reach(_world.get_node("Entities/Tree"), &"chop")
	await _report_reach(_world.get_node("Entities/Rock"), &"mine")

	await _report_fade(_world.get_node("Entities/Tree2"))

	# Each tool must fell its own target and bounce off the other one.
	await _harvest(_world.get_node("Entities/Tree"), &"chop", &"wood")
	await _harvest(_world.get_node("Entities/Rock"), &"mine", &"stone")

	await _reject(_world.get_node("Entities/Tree2"), &"mine")
	await _reject(_world.get_node("Entities/Tree3"), &"water")
	await _reject(_world.get_node("Entities/Rock2"), &"chop")
	await _reject(_world.get_node("Entities/Rock3"), &"till")

	print("\ninventory: %s" % Inventory.snapshot())
	print("probe finished")
	get_tree().quit()


func _report_tools() -> void:
	print("tools: %s" % [_player.tools])
	var frames: SpriteFrames = _player.sprite.sprite_frames
	for tool_name in _player.tools:
		var clip := "%s_down" % tool_name
		var row: int = Player.TOOL_ROW[tool_name]
		print(
			"  %-6s sheet row %d, clip %-11s frames=%d, state=%s"
			% [tool_name, row, clip, frames.get_frame_count(clip), _player.state_machine.has_state(tool_name)]
		)


## Report, per side, how far the body holds the player off and whether the tool
## still lands — plus how much of the 16px-tall character the art would cover.
func _report_reach(target: Harvestable, tool_name: StringName) -> void:
	print("\n--- %s reach (sprite offset %s) ---" % [target.name, target.sprite.offset])
	_player.select_tool(_player.tools.find(tool_name))

	for side: StringName in APPROACHES:
		var direction: Vector2 = APPROACHES[side]
		var distance := _rest_distance(target, direction)
		_player.global_position = target.global_position + direction * distance
		_player.facing = -direction
		await _wait(SETTLE)

		var reaches := _player.tool_hitbox.get_overlapping_areas().any(
			func(area: Area2D) -> bool: return area.owner == target
		)
		print(
			"  %-5s stops %5.1fpx out, tool reaches=%s%s"
			% [side, distance, reaches, _occlusion_note(target, side, distance)]
		)


## Standing behind a prop has to fade it, and standing in front of it must not.
func _report_fade(target: Harvestable) -> void:
	print("\n--- %s see-through ---" % target.name)
	var fade: SeeThroughComponent = target.get_node("SeeThrough")

	for side: StringName in [&"north", &"south"]:
		var direction: Vector2 = APPROACHES[side]
		# Stand hard against the trunk, where the canopy would cover the player.
		_player.global_position = (
			target.global_position + direction * _rest_distance(target, direction)
		)
		await _wait(40)
		print(
			"  from %-5s alpha %.2f, obscuring=%s"
			% [side, target.sprite.modulate.a, fade.is_obscuring()]
		)

	# And it has to come back once the player leaves.
	_player.global_position = target.global_position + Vector2(0, 80)
	await _wait(40)
	print("  walked away  alpha %.2f" % target.sprite.modulate.a)


## Slide the player outward from [param target] until the body no longer overlaps
## it — where move_and_slide would come to rest. Searched outwards so a
## neighbouring prop further along the axis cannot be mistaken for this one.
func _rest_distance(target: Harvestable, direction: Vector2) -> float:
	var transform := _player.global_transform
	var distance := 0.0
	while distance < 64.0:
		transform.origin = target.global_position + direction * distance
		if not _player.test_move(transform, Vector2.ZERO, null, 0.08, true):
			return distance
		distance += 1.0
	return distance


## Only a northern approach can hide the player behind the art, since Y-sort
## draws whatever stands further down on top.
func _occlusion_note(target: Harvestable, side: StringName, distance: float) -> String:
	if side != &"north":
		return ""
	var image := target.sprite.texture.get_image()
	if image == null:
		return ""

	# Opaque extent of the art in the target's local space.
	var opaque := image.get_used_rect()
	var centre := target.sprite.offset.y - image.get_height() * 0.5
	var art_top := centre + opaque.position.y
	var art_bottom := centre + opaque.position.y + opaque.size.y

	# The player is 16px tall with its feet on its own origin.
	var feet := -distance
	var covered: float = maxf(0.0, minf(feet, art_bottom) - maxf(feet - 16.0, art_top))
	if covered <= 0.0:
		return ", art never covers the player"

	var fade := target.get_node_or_null("SeeThrough") as SeeThroughComponent
	if fade == null:
		return ", art covers %.0f of the player's 16px with nothing to fade it" % covered
	return ", art covers %.0f of 16px but fades to %.2f alpha" % [covered, fade.faded_alpha]


## Strike something down from full health with [param tool_name] and follow the
## drops into the inventory.
func _harvest(target: Harvestable, tool_name: StringName, expected_item: StringName) -> void:
	print("\n--- %s with %s ---" % [target.name, tool_name])
	var origin := target.global_position
	await _equip_facing(tool_name, target)

	var max_health := target.health.max_health
	var swings := 0
	while swings < 8:
		if not is_instance_valid(target) or not target.health.is_alive():
			break
		_player.swing_tool()
		swings += 1
		await _wait(SETTLE)
		# The killing blow can free the node outright, so re-check before reading.
		if not is_instance_valid(target):
			print("  swing %d -> destroyed" % swings)
			break
		print("  swing %d -> health %d, shake %.2f" % [swings, target.health.health, _shake_of(target)])

	print("felled in %d swings (expected %d)" % [swings, max_health])
	if is_instance_valid(target):
		print(
			"remnant: depleted=%s, layer=%d, blocks all sides=%s"
			% [
				target.is_depleted(),
				target.get_node("Body").collision_layer,
				_blocked_from_every_side(target),
			]
		)
	else:
		print("remnant: none, node freed")

	print("pickups spawned: %d" % _pickups().size())

	# Drops scatter, so some land outside the pickup radius. Walk over the pile
	# the way a player would, rather than standing back and waiting.
	await _wait(30)
	_player.global_position = origin
	await _wait(60)

	print(
		"pickups left: %d, %s held: %d"
		% [_pickups().size(), expected_item, Inventory.count(expected_item)]
	)


## True only if the player is stopped walking in from all four sides.
func _blocked_from_every_side(target: Harvestable) -> bool:
	var transform := _player.global_transform
	for side: StringName in APPROACHES:
		var direction: Vector2 = APPROACHES[side]
		transform.origin = target.global_position + direction * 20.0
		if not _player.test_move(transform, -direction * 20.0):
			return false
	return true


## [param tool_name] must not damage [param target].
func _reject(target: Harvestable, tool_name: StringName) -> void:
	await _equip_facing(tool_name, target)

	var before := target.health.health
	_player.swing_tool()
	await _wait(SETTLE)
	var after := target.health.health
	print(
		"%-6s vs %-6s: health %d -> %d  %s"
		% [tool_name, target.name, before, after, "OK" if before == after else "DAMAGED"]
	)


## Select [param tool_name] and stand below [param target] looking up, so the
## tool hitbox lands on it.
func _equip_facing(tool_name: StringName, target: Node2D) -> void:
	_player.select_tool(_player.tools.find(tool_name))
	_player.global_position = target.global_position + Vector2(0, 16)
	_player.facing = Vector2.UP
	await _wait(SETTLE)


func _pickups() -> Array:
	return _entities.get_children().filter(func(node: Node) -> bool: return node is Collectable)


func _shake_of(target: Harvestable) -> float:
	if not is_instance_valid(target):
		return -1.0
	var material := target.sprite.material as ShaderMaterial
	return material.get_shader_parameter(&"shake_strength") if material != null else -1.0


func _wait(frames: int) -> void:
	for _i in frames:
		await get_tree().physics_frame
