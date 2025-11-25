class_name SynergyBehavior extends NodeBehavior

# Cache to avoid re-loading the shader
var _energy_line_shader : Shader
var _last_neighbor_state: Dictionary = {}

func _on_setup() -> void:
	_energy_line_shader = load("res://Assets/Shaders/energy_line.gdshader")

func perform_tick(level: Level) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	var step_bonus = float(data.base_output) / 100.0
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var grid_pos = parent_node.grid_position
	
	var valid_neighbors = []
	var current_neighbor_state = {}
	
	# 1. Identify Neighbors
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile and tile.has_node and tile.local_node:
				var t_name = tile.local_node.node_type.node_name
				
				valid_neighbors.append({
					"node": tile.local_node, 
					"type": t_name,
					"dir": offset
				})
				current_neighbor_state[target_pos] = t_name

	# 2. Group and Calculate Bonuses
	var type_counts = {}
	for entry in valid_neighbors:
		var t_name = entry["type"]
		if not type_counts.has(t_name):
			type_counts[t_name] = 0
		type_counts[t_name] += 1
	
	# 3. Apply Boosts and Visuals
	for entry in valid_neighbors:
		var neighbor_node = entry["node"]
		var type_name = entry["type"]
		var count = type_counts[type_name]
		var dir = entry["dir"]
		
		# Apply Logic
		var total_bonus = step_bonus * count
		neighbor_node.current_multiplier += total_bonus
		
		# Apply Visuals (Energy Line)
		_apply_synergy_visuals(parent_node, dir, count)
		_apply_synergy_visuals(neighbor_node, -dir, count)
		
		# Turn on connection visibility
		parent_node.show_connection(dir, true)
		neighbor_node.show_connection(-dir, true)
		
	_last_neighbor_state = current_neighbor_state.duplicate()

func _apply_synergy_visuals(node: GameNode, direction: Vector2i, count: int) -> void:
	if not _energy_line_shader: return
	
	var rect = node.get_connection_rect(direction)
	if rect:
		# Create unique material if needed or check if already correct
		if not rect.material or not (rect.material is ShaderMaterial) or (rect.material as ShaderMaterial).shader != _energy_line_shader:
			var mat = ShaderMaterial.new()
			mat.shader = _energy_line_shader
			rect.material = mat
		
		# Update Thickness based on Synergy Count
		# 1 Node = 1.0 scale, 4 Nodes = 2.5 scale
		var thickness = 1.0 + (float(count - 1) * 0.5)
		(rect.material as ShaderMaterial).set_shader_parameter("thickness_scale", thickness)
