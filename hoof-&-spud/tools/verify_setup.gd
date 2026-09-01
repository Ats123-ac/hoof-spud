## Throwaway check: loads the world headlessly and reports that the sprite sheet
## slicing, tile atlases and animated water tile all resolved.
extends SceneTree

var _world: Node


func _initialize() -> void:
	_world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(_world)


func _process(_delta: float) -> bool:
	_report_player(_world.get_node("Entities/Player"))
	_report_tileset(_world.ground)
	return true


func _report_player(player: Node) -> void:
	var frames: SpriteFrames = player.sprite.sprite_frames
	var names := Array(frames.get_animation_names())
	names.sort()
	print("clips (%d): %s" % [names.size(), ", ".join(names)])
	for clip in ["idle_down", "walk_left", "chop_down", "till_up", "water_right"]:
		print(
			"  %-12s frames=%d loop=%s"
			% [clip, frames.get_frame_count(clip), frames.get_animation_loop(clip)]
		)
	print("state: %s, playing: %s" % [player.state_machine.current_name, player.sprite.animation])


func _report_tileset(ground: TileMapLayer) -> void:
	var tile_set := ground.tile_set
	print("\nground cells seeded: %d" % ground.get_used_cells().size())
	print("tile size: %s, sources: %d" % [tile_set.tile_size, tile_set.get_source_count()])
	for i in tile_set.get_source_count():
		var id := tile_set.get_source_id(i)
		var atlas := tile_set.get_source(id) as TileSetAtlasSource
		print("  %d %-14s tiles=%d" % [id, atlas.resource_name, atlas.get_tiles_count()])

	var water := tile_set.get_source(3) as TileSetAtlasSource
	print(
		"water animation: frames=%d speed=%s"
		% [water.get_tile_animation_frames_count(Vector2i.ZERO), water.get_tile_animation_speed(Vector2i.ZERO)]
	)
	print("terrains in set 0: %d" % tile_set.get_terrains_count(0))
