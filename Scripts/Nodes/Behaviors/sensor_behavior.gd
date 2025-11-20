class_name SensorBehavior extends NodeBehavior

func perform_tick(level: Level) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	var resistance_bonus = float(data.base_output) / 100.0
	
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var grid_pos = parent_node.grid_position
	
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile:
				tile.blight_resistance += resistance_bonus
