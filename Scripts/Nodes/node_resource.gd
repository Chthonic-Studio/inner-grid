class_name NodeType extends Resource

@export_category("Node Info")
@export var node_name : String
@export var function_timer: float

@export_category("Node Costs")
@export var placement_cost : int
@export var main_resource_placement_cost : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func calculate_output() -> void:
	pass
