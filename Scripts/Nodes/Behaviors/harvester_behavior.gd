class_name HarvesterBehavior extends NodeBehavior

func _on_setup() -> void:
	# Apply pulsing effect directly to the Node's main sprite
	var node_visuals = parent_node.get_node_or_null("TileContent/NodeVisuals")
	if node_visuals:
		var shader = load("res://Assets/Shaders/pulsing.gdshader")
		if shader:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			
			# Heartbeat Setup
			# Greenish flash
			mat.set_shader_parameter("shine_color", Color(0.2, 1.0, 0.2, 0.6)) 
			mat.set_shader_parameter("cycle_speed", 4.0) # Faster for heartbeat rhythm
			mat.set_shader_parameter("heartbeat_mode", true)
			
			node_visuals.material = mat

func perform_tick(level: Level) -> void:
	if parent_node.connected:
		var efficiency_factor = (data.node_efficiency / 100.0) * parent_node.current_multiplier
		var amount = int(data.base_output * efficiency_factor)
		
		if amount > 0:
			level.EconomyManager.gain_resources(amount, "Main")
