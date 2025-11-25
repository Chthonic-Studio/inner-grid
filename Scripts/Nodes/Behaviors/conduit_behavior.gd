class_name ConduitBehavior extends NodeBehavior

var _tube_shader : Shader

func _on_setup() -> void:
	_tube_shader = load("res://Assets/Shaders/tube.gdshader")

func perform_tick(level: Level) -> void:
	pass

func on_network_update(is_connected: bool) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	if not _tube_shader: return
	
	var core_pos = level.level_resource.core_starting_tile
	var my_pos = parent_node.grid_position
	var my_dist = my_pos.distance_to(core_pos)
	
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for dir in offsets:
		var target_pos = my_pos + dir
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile and tile.has_node and tile.local_node:
				var neighbor = tile.local_node
				var n_name = neighbor.node_type.node_name
				
				# RULE: Conduits only act as pipes for Core, Harvester, Generator, and other Conduits.
				var valid_pipe_target = (
					n_name == "Core" or 
					n_name == "Conduit" or 
					n_name == "Generator" or 
					n_name == "Harvester"
				)
				
				# Only apply visual if we are connected and it's a valid pipe target
				var my_conn = parent_node.get_connection_rect(dir)
				if my_conn.visible and valid_pipe_target:
					_apply_tube_shader(my_conn, my_dist, target_pos.distance_to(core_pos), dir)

func _apply_tube_shader(rect: NinePatchRect, my_dist: float, neighbor_dist: float, dir: Vector2i) -> void:
	if not rect.material or not (rect.material is ShaderMaterial) or (rect.material as ShaderMaterial).shader != _tube_shader:
		var mat = ShaderMaterial.new()
		mat.shader = _tube_shader
		mat.set_shader_parameter("ball_color", Color(0.0, 0.8, 1.0, 1.0))
		mat.set_shader_parameter("bg_color", Color(0.2, 0.2, 0.2, 0.5))
		rect.material = mat
	
	var mat = rect.material as ShaderMaterial
	var is_flowing_out = neighbor_dist < my_dist
	var flow_speed = 2.0
	
	if is_flowing_out:
		mat.set_shader_parameter("speed", -flow_speed) 
	else:
		mat.set_shader_parameter("speed", flow_speed) 
