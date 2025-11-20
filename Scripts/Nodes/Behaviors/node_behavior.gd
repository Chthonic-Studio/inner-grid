class_name NodeBehavior extends Node

var parent_node : GameNode
var data : NodeType

func setup(parent: GameNode, resource_data: NodeType) -> void:
	parent_node = parent
	data = resource_data
	_on_setup()

func _on_setup() -> void:
	pass

func perform_tick(level: Level) -> void:
	pass

func on_network_update(is_connected: bool) -> void:
	pass

func apply_passives(level: Level, current_tile: GameTile) -> void:
	pass
