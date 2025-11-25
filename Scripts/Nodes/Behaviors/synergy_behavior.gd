class_name SynergyBehavior extends NodeBehavior

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
	
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile and tile.has_node and tile.local_node:
				var t_name = tile.local_node.node_type.node_name
				
				# RULE: Synergy should NOT connect to Conduits or other Synergy nodes
				if t_name == "Conduit" or t_name == "Synergy":
					continue
				
				valid_neighbors.append({
					"node": tile.local_node, 
					"type": t_name,
					"dir": offset
				})
				current_neighbor_state[target_pos] = t_name

	var type_counts = {}
	for entry in valid_neighbors:
		var t_name = entry["type"]
		if not type_counts.has(t_name):
			type_counts[t_name] = 0
		type_counts[t_name] += 1
	
	for entry in valid_neighbors:
		var neighbor_node = entry["node"]
		var type_name = entry["type"]
		var count = type_counts[type_name]
		var dir = entry["dir"]
		
		var total_bonus = step_bonus * count
		neighbor_node.current_multiplier += total_bonus
		
		_apply_synergy_visuals(parent_node, dir, count)
		_apply_synergy_visuals(neighbor_node, -dir, count)
		
		parent_node.show_connection(dir, true)
		neighbor_node.show_connection(-dir, true)
		
	_last_neighbor_state = current_neighbor_state.duplicate()

func _apply_synergy_visuals(node: GameNode, direction: Vector2i, count: int) -> void:
	if not _energy_line_shader: return
	
	var rect = node.get_connection_rect(direction)
	if rect:
		if not rect.material or not (rect.material is ShaderMaterial) or (rect.material as ShaderMaterial).shader != _energy_line_shader:
			var mat = ShaderMaterial.new()
			mat.shader = _energy_line_shader
			rect.material = mat
			
			# Tweak for "Electricity" look (Jagged)
			mat.set_shader_parameter("roughness", 5) # Higher = more jagged noise
			mat.set_shader_parameter("frequency", 12) # More ripples
			mat.set_shader_parameter("energy", 5.0) # Higher amplitude
			mat.set_shader_parameter("speed", 2.0) # Faster jitter
			mat.set_shader_parameter("color", Color(0.2, 1.0, 1.0, 1.0)) # Cyan Electric
		
		var thickness = 1.0 + (float(count - 1) * 0.5)
		(rect.material as ShaderMaterial).set_shader_parameter("thickness_scale", thickness)
