class_name MainUI extends Node

@export_category("Node Buttons")
@export var generator_button : Button
@export var harvester_button : Button
@export var shield_button : Button
@export var sensor_button : Button
@export var synergy_button : Button
@export var conduit_button : Button
@export var purifier_button : Button

@export_category("Resource Value Labels")
@export var blight_clock : Label
@export var main_resource_label : Label
@export var build_resource_label : Label

var node_button_clicked : String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LevelManager.income_updated.connect(update_labels)
	LevelManager.affordability_changed.connect(_on_affordability_changed)

func update_labels( main_resource: int, build_resource: int) -> void:
	main_resource_label.text = str(main_resource)
	build_resource_label.text = str(build_resource)

func _on_generator_button_pressed():
	node_button_clicked = "Generator"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""
	
func _on_harvester_button_pressed():
	node_button_clicked = "Harvester"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""

func _on_shield_button_pressed():
	node_button_clicked = "Shield"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""

func _on_sensor_button_pressed():
	node_button_clicked = "Sensor"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""

func _on_synergy_button_pressed():
	node_button_clicked = "Synergy"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""

func _on_conduit_button_pressed():
	node_button_clicked = "Conduit"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""

func _on_purifier_button_pressed():
	node_button_clicked = "Purifier"
	LevelManager.emit_signal("node_selected", node_button_clicked)
	print("Button pressed: ", node_button_clicked)
	node_button_clicked = ""
		
func _on_affordability_changed(affordable_nodes: Dictionary) -> void:
	generator_button.disabled = not affordable_nodes.get("Generator", false)
	harvester_button.disabled = not affordable_nodes.get("Harvester", false)
	shield_button.disabled = not affordable_nodes.get("Shield", false)
	sensor_button.disabled = not affordable_nodes.get("Sensor", false)
	synergy_button.disabled = not affordable_nodes.get("Synergy", false)
	conduit_button.disabled = not affordable_nodes.get("Conduit", false)
	purifier_button.disabled = not affordable_nodes.get("Purifier", false)
