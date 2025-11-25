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
	
	# We need to determine the "Flow Direction" towards the Core.
	# Flow is from High Distance -> Low Distance (closer to core).
	
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
				
				# Only apply visual if we are actually connected to this neighbor logically
				# Check visibility of connection line as a proxy for logical connection
				# (Since Level.gd handles the BFS and visibility toggling)
				var my_conn = parent_node.get_connection_rect(dir)
				if my_conn.visible:
					_apply_tube_shader(my_conn, my_dist, target_pos.distance_to(core_pos), dir)

func _apply_tube_shader(rect: NinePatchRect, my_dist: float, neighbor_dist: float, dir: Vector2i) -> void:
	# Setup Material
	if not rect.material or not (rect.material is ShaderMaterial) or (rect.material as ShaderMaterial).shader != _tube_shader:
		var mat = ShaderMaterial.new()
		mat.shader = _tube_shader
		mat.set_shader_parameter("ball_color", Color(0.0, 0.8, 1.0, 1.0))
		mat.set_shader_parameter("bg_color", Color(0.2, 0.2, 0.2, 0.5))
		rect.material = mat
	
	var mat = rect.material as ShaderMaterial
	
	# Logic: 
	# If Neighbor is Closer (neighbor_dist < my_dist): Flow is OUT (Me -> Neighbor).
	# If Neighbor is Further (neighbor_dist > my_dist): Flow is IN (Neighbor -> Me).
	
	var is_flowing_out = neighbor_dist < my_dist
	
	# Texture Coordinates on NinePatchRects:
	# Usually 0 is Left/Top, 1 is Right/Bottom.
	# However, the Rects in node.tscn are rotated.
	# UP (No Rot): Bottom->Top? 0->1 Y? 
	# Let's assume standard UV x:0->1 flows along the length.
	
	# Speed + = 0->1. Speed - = 1->0.
	var flow_speed = 2.0
	
	if is_flowing_out:
		# OUT means moving away from center of node.
		# UV 0 is usually start.
		mat.set_shader_parameter("speed", -flow_speed) # 1->0 (Towards edge?)
	else:
		# IN means moving towards center of node.
		mat.set_shader_parameter("speed", flow_speed) # 0->1 (Towards center?)
	
	# NOTE: Without seeing exact UV rotation in editor, signs might need swapping.
	# Assuming Left-to-Right texture mapping on the rect.
