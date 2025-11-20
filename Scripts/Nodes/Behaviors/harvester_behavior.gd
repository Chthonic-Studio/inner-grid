class_name HarvesterBehavior extends NodeBehavior

func perform_tick(level: Level) -> void:
	if parent_node.connected:
		var efficiency_factor = (data.node_efficiency / 100.0) * parent_node.current_multiplier
		var amount = int(data.base_output * efficiency_factor)
		
		if amount > 0:
			level.EconomyManager.gain_resources(amount, "Main")
