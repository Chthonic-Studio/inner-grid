class_name EconomyManager extends Node

signal resource_changed(main_resource, building_resource)

@export_category("Resources")
@export var main_resource : int = 0
@export var building_resource : int = 100

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func spend_resources(node_cost: int, main_cost: int) -> void:
	building_resource -= node_cost
	main_resource -= main_cost
	emit_signal("resource_changed", main_resource, building_resource)
	LevelManager.emit_signal("income_updated", main_resource, building_resource)

func gain_resources(amount: int, type: String) -> void:
	if type == "Building":
		building_resource += amount
	elif type == "Main":
		main_resource += amount
	else:
		print("Gaining spend of unrecognized type: ", type)
	emit_signal("resource_changed", main_resource, building_resource)
	LevelManager.emit_signal("income_updated", main_resource, building_resource)

func can_afford(node_cost: int, main_cost:int) -> bool:
	if building_resource < node_cost:
		return false
	if main_resource < node_cost:
		return false
	return true

# Runtime building cost (in case of adaptation effects)
func get_node_building_cost(node_type: NodeType) -> int:
	# Add adaptation/modifier logic if required
	return node_type.base_cost.get("building", 0)

func get_sacrifice_refund(node_type: NodeType) -> int:
	var cost = get_node_building_cost(node_type)
	var percent = 0.5 # Fetch from adaptation if needed
	if node_type.has("refund_percent"):
		percent = node_type.refund_percent
	return int(round(cost * percent))
