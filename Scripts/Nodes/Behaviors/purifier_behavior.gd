class_name PurifierBehavior extends NodeBehavior

func perform_tick(level: Level) -> void:
	
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var grid_pos = parent_node.grid_position
	
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile and tile.has_blight:
				level.BlightManager.purge_tile(target_pos)
