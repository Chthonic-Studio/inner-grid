class_name GeneratorBehavior extends NodeBehavior

var _visual : ColorRect

func _on_setup() -> void:
	# Create Visual Overlay
	_visual = ColorRect.new()
	_visual.size = Vector2(60, 60)
	_visual.position = Vector2(10, 10)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# FIX: Set to White. The shader uses this color as the tint/intensity base.
	# If this is transparent, the electricity calculation results in 0 visibility.
	# The shader overwrites the geometry, so we won't see a white box, just the shader output.
	_visual.color = Color(1, 1, 1, 1)
	
	var mat = load("res://Assets/electric_ball.tres")
	if mat:
		_visual.material = mat.duplicate()
	
	parent_node.add_child(_visual)

func perform_tick(level: Level) -> void:
	if parent_node.connected:
		var efficiency_factor = (data.node_efficiency / 100.0) * parent_node.current_multiplier
		var amount = int(data.base_output * efficiency_factor)
		
		if amount > 0:
			level.EconomyManager.gain_resources(amount, "Building")
