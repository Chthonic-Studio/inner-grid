class_name PurifierBehavior extends NodeBehavior

@export var ticks_per_purge : int = 3
var _tick_counter : int = 0

func perform_tick(level: Level) -> void:
	_tick_counter += 1
	
	if _tick_counter < ticks_per_purge:
		return
		
	_tick_counter = 0
	_attempt_purge(level)

func _attempt_purge(level: Level) -> void:
	# FIXED: Removed Vector2i(0,0) so it doesn't purge itself
	var offsets = [
		Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), # Cardinal
		Vector2i(1,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1) # Diagonal
	]
	
	var grid_pos = parent_node.grid_position
	var candidates = []
	var core_pos = level.level_resource.core_starting_tile
	
	# 1. Find valid candidates (Tiles with Blight)
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile and tile.has_blight:
				candidates.append({
					"pos": target_pos,
					"tile": tile,
					"blight": tile.blight_value,
					"dist": target_pos.distance_to(core_pos)
				})
	
	if candidates.is_empty():
		return

	# 2. Sort Candidates
	# Priority 1: Highest Blight Value (Descending)
	# Priority 2: Closest to Core (Ascending)
	# Priority 3: Random
	
	# FIXED: Shuffle FIRST to handle random tie-breaking safely.
	# Using randf() inside sort_custom causes unstable sorting crashes.
	candidates.shuffle()
	
	candidates.sort_custom(func(a, b):
		# Higher blight comes first
		if not is_equal_approx(a.blight, b.blight):
			return a.blight > b.blight
		
		# Lower distance comes first
		if not is_equal_approx(a.dist, b.dist):
			return a.dist < b.dist
			
		# If both are equal, the shuffle order (stable sort) determines the winner
		return false
	)
	
	# 3. Purge the winner
	var winner = candidates[0]
	level.BlightManager.purge_tile(winner.pos)
