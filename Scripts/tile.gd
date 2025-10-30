class_name GameTile extends Node

signal request_placement(tile, grid_position)
signal request_purge(tile, grid_position)
signal tile_blight_changed(tile, grid_position, blight_value)
signal node_placed(tile, grid_position, node_instance)
signal node_removed(tile, grid_position)

@export var node_scene : PackedScene

@export_category("Tile Status")
@export var grid_position : int
@export var blocked : bool
@export var has_node : bool
@export var has_blight: bool
@export var blight_value: int = 0

@onready var tile_button = $TileButton
var local_node : GameNode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func on_tile_input( input : InputEvent ) -> void:
	pass
	
func update_blight( value : int ) -> void:
	pass 	
	
func set_node( node : NodeType ) -> void:
	pass 	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
