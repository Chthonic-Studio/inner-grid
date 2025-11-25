class_name GeneratorBehavior extends NodeBehavior

var _visual : ColorRect

func _on_setup() -> void:
	# Create Visual Overlay
	_visual = ColorRect.new()
	# Size to fit inside the 80x80 node, with some padding
	_visual.size = Vector2(60, 60)
	_visual.position = Vector2(10, 10)
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat = load("res://Assets/electric_ball.tres")
	if mat:
		# Duplicate to allow unique parameter tweaking if needed later
		_visual.material = mat.duplicate()
	
	parent_node.add_child(_visual)

func perform_tick(level: Level) -> void:
	# Only produce if connected to the Core network
	if parent_node.connected:
		# Calculate efficiency: Base * (Data Efficiency / 100) * (Synergy Multiplier)
		var efficiency_factor = (data.node_efficiency / 100.0) * parent_node.current_multiplier
		var amount = int(data.base_output * efficiency_factor)
		
		if amount > 0:
			# Access EconomyManager VIA the level object
			level.EconomyManager.gain_resources(amount, "Building")
