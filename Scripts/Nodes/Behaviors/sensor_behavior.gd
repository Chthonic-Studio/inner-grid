class_name SensorBehavior extends NodeBehavior

var _sensor_visual : ColorRect

func _on_setup() -> void:
	# Instantiate Visual (3x3 area)
	_sensor_visual = ColorRect.new()
	_sensor_visual.size = Vector2(240, 240)
	_sensor_visual.position = Vector2(-80, -80)
	_sensor_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Allow drawing outside parent bounds
	parent_node.clip_contents = false
	
	var shader = load("res://Assets/Shaders/ripple.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		
		# Parameters for the new additive look
		mat.set_shader_parameter("frequency", 6.0)       # Fewer, wider rings
		mat.set_shader_parameter("ripple_rate", 2.5)     # Moderate speed
		# Yellow tint with low alpha (because additive blending adds up quickly)
		mat.set_shader_parameter("tint_color", Color(1.0, 0.8, 0.1, 0.4)) 
		
		_sensor_visual.material = mat
		
	parent_node.add_child(_sensor_visual)

func perform_tick(level: Level) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	var resistance_bonus = float(data.base_output) / 100.0
	
	var offsets = [
		Vector2i(0,0),
		Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
		Vector2i(1,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1)
	]
	var grid_pos = parent_node.grid_position
	
	for offset in offsets:
		var target_pos = grid_pos + offset
		if level._is_valid_pos(target_pos):
			var tile = level._get_tile_at_position(target_pos)
			if tile:
				tile.blight_resistance += resistance_bonus
