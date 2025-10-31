extends Node

# --- HUD & Economy Signals ---
signal income_updated( main_resource, building_resource )
signal affordability_changed(affordable_nodes: Dictionary)

# --- Player Interaction Signals ---
signal node_selected(node_button_clicked : String)
signal tile_hovered(tile_data) 
signal tile_exited()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func affordability_signal( affordable_nodes: Dictionary ) -> void:
	affordability_changed.emit()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
