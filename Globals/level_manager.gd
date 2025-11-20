extends Node

# --- HUD & Economy Signals ---
signal income_updated( main_resource, building_resource )
signal affordability_changed(affordable_nodes: Dictionary)

# --- Player Interaction Signals ---
signal node_selected(node_button_clicked : String)
signal tile_hovered(tile_data) 
signal tile_exited()

var current_win_condition : int = 0
var level_active : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func affordability_signal( affordable_nodes: Dictionary ) -> void:
	affordability_changed.emit()
	
func level_start() -> void:
	level_active = true
	TimeManager.start_level_clock()

func end_level() -> void:
	level_active = false
	TimeManager.end_level_clock()

func win() -> void:
	pass

func lose() -> void:
	pass

func _process(delta: float) -> void:
	pass
