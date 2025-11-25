class_name HarvesterBehavior extends NodeBehavior

var _visual : ColorRect

func _on_setup() -> void:
	# Create Visual Overlay
	_visual = ColorRect.new()
	_visual.size = Vector2(60, 60)
	_visual.position = Vector2(10, 10)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader = load("res://Assets/Shaders/pulsing.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("shine_color", Color(0.0, 1.0, 0.5, 0.5)) # Greenish pulse
		mat.set_shader_parameter("alpha_limit", 0.0)
		mat.set_shader_parameter("cycle_speed", 3.0)
		mat.set_shader_parameter("full_pulse_cycle", true)
		mat.set_shader_parameter("mode", 1) # Pulse Mode
		
		_visual.material = mat
	
	parent_node.add_child(_visual)

func perform_tick(level: Level) -> void:
	if parent_node.connected:
		var efficiency_factor = (data.node_efficiency / 100.0) * parent_node.current_multiplier
		var amount = int(data.base_output * efficiency_factor)
		
		if amount > 0:
			level.EconomyManager.gain_resources(amount, "Main")
