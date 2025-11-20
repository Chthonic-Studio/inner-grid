class_name SynergyBehavior extends NodeBehavior

# State Cache: Stores { Vector2i(grid_pos) : String(node_type_name) }
var _last_neighbor_state: Dictionary = {}

func perform_tick(level: Level) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	# step_bonus is e.g., 0.25 (25%)
	var step_bonus = float(data.base_output) / 100.0
	
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var grid_pos = parent_node.grid_position
	
	# 1. Collect valid neighbors AND build current state snapshot
	var valid_neighbors = []
	var current_neighbor_state = {}
	
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			# Synergy only boosts nodes that have a node instance
			if tile and tile.has_node and tile.local_node:
				var t_name = tile.local_node.node_type.node_name
				
				valid_neighbors.append({
					"node": tile.local_node, 
					"type": t_name,
					"dir": offset
				})
				
				# Record state for change detection
				current_neighbor_state[target_pos] = t_name

	# 2. Check for changes (Compare hashes)
	# Level.gd calls this function frequently. We only want to log if the neighborhood changed.
	var should_log = current_neighbor_state.hash() != _last_neighbor_state.hash()
	
	# Update cache
	_last_neighbor_state = current_neighbor_state.duplicate()

	# 3. Group by type
	var type_counts = {}
	for entry in valid_neighbors:
		var t_name = entry["type"]
		if not type_counts.has(t_name):
			type_counts[t_name] = 0
		type_counts[t_name] += 1
	
	# 4. Apply Boosts (Always) & Log (Conditional)
	if should_log and valid_neighbors.size() > 0:
		print("\n=== SYNERGY CALCULATION AT %s ===" % [grid_pos])
		
	for entry in valid_neighbors:
		var neighbor_node = entry["node"]
		var type_name = entry["type"]
		var count = type_counts[type_name]
		
		# Logic: +X% per node in the group
		var total_bonus = step_bonus * count
		
		# ALWAYS Apply (Level resets multipliers to 1.0 every update, so we must re-apply)
		neighbor_node.current_multiplier += total_bonus
		parent_node.show_connection(entry["dir"], true)
		
		# CONDITIONALLY Log
		if should_log:
			print(" > Neighbor: %s | Count: %d | Bonus: +%.2f" % [type_name, count, total_bonus])
			print(" > New Multiplier for neighbor: %.2f" % neighbor_node.current_multiplier)

	if should_log and valid_neighbors.size() > 0:
		print("================================\n")
