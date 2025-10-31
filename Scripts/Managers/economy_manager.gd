class_name EconomyManager extends Node

@export_category("Resources")
@export var main_resource : int = 0
@export var building_resource : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func spend_resources( amount: int, type: String ):
	if type == "Building":
		building_resource -= amount
	if type == "Main":
		main_resource -= amount
	else:
		print("Requesting spend of unrecognized type: ", type)
	# Emit a signal with the new values
	LevelManager.emit_signal("income_updated", main_resource, building_resource)
	MainUI.update_labels(main_resource, building_resource)

func gain_resources( amount: int, type: String ):
	if type == "Building":
		building_resource += amount
	if type == "Main":
		main_resource += amount
	else:
		print("Gaining spend of unrecognized type: ", type)
	# Emit a signal with the new values
	LevelManager.emit_signal("income_updated", main_resource, building_resource)
