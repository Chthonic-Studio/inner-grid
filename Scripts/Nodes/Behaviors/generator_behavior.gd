class_name GeneratorBehavior extends NodeBehavior

func perform_tick(economy: EconomyManager) -> void:
	# Only produce if connected to the Core network
	if parent_node.connected:
		# Calculate efficiency: Base * (Data Efficiency / 100) * (Synergy Multiplier)
		var efficiency_factor = (data.node_efficiency / 100.0) * parent_node.current_multiplier
		var amount = int(data.base_output * efficiency_factor)
		
		if amount > 0:
			economy.gain_resources(amount, "Building")
