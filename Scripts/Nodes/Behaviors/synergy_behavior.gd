class_name SynergyBehavior extends NodeBehavior

func perform_tick(level: Level) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	# step_bonus is e.g., 0.25 (25%)
	var step_bonus = float(data.base_output) / 100.0
	
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var grid_pos = parent_node.grid_position
	
	# 1. Collect valid neighbors
	var valid_neighbors = []
	
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile and tile.has_node and tile.local_node:
				# Store struct for processing
				valid_neighbors.append({
					"node": tile.local_node, 
					"type": tile.local_node.node_type.node_name,
					"dir": offset
				})

	# 2. Count types (Synergy groups nodes of the same type)
	var type_counts = {}
	for entry in valid_neighbors:
		var t_name = entry["type"]
		if not type_counts.has(t_name):
			type_counts[t_name] = 0
		type_counts[t_name] += 1
	
	# 3. Apply Boosts based on counts
	if valid_neighbors.size() > 0:
		print("--- Synergy Node at %s Calculation ---" % [grid_pos])
		
	for entry in valid_neighbors:
		var neighbor_node = entry["node"]
		var type_name = entry["type"]
		var count = type_counts[type_name]
		
		# Logic: 25% per node in the group.
		var total_bonus = step_bonus * count
		
		neighbor_node.current_multiplier += total_bonus
		
		# Visuals
		parent_node.show_connection(entry["dir"], true)
		
		# LOGGING
		print(" > Neighbor found: %s at %s" % [type_name, neighbor_node.grid_position])
		print(" > Group Count: %d | Bonus Applied: +%.2f" % [count, total_bonus])
		print(" > %s new Multiplier: %.2f" % [type_name, neighbor_node.current_multiplier])

	if valid_neighbors.size() > 0:
		print("--------------------------------------")
