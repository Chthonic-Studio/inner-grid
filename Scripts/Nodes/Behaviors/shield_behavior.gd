class_name ShieldBehavior extends NodeBehavior

func perform_tick(level: Level) -> void:
	# Logic: Regenerate shield if not full
	if parent_node.current_shield < data.node_shield:
		# Use base_output as the regeneration rate per tick
		var regen = data.base_output
		parent_node.current_shield = min(parent_node.current_shield + regen, data.node_shield)
