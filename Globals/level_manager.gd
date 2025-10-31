extends Node

# --- HUD & Economy Signals ---
signal income_updated( main_resource, building_resource )

# --- Player Interaction Signals ---
signal node_selected(node_button_clicked : String)
signal tile_hovered(tile_data) 
signal tile_exited()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
