class_name GameTile extends Node

signal request_placement(tile, grid_position)
signal request_purge(tile, grid_position)
signal tile_blight_changed(tile, grid_position, blight_value)
signal node_placed(tile, grid_position, node_instance)
signal node_removed(tile, grid_position)

@export var node_scene : PackedScene

@export_category("Tile Status")
@export var row : int
@export var col : int
@export var blocked : bool
@export var blight_resistance: float = 0.0
@export var dps_effect: float = 0.0
@export var has_node : bool
@export var has_blight: bool
@export var blight_value: int = 0

#@onready var tile_button = $TileButton
var local_node : GameNode

func _ready() -> void:
	var tile_button = $TileButton
	tile_button.pressed.connect(_on_tile_button_pressed)
	pass # Replace with function body.

func setup(row_: int, col_: int, blocked_: bool, blight_resist_: float, dps_: float, special_: Variant) -> void:
	row = row_
	col = col_
	blocked = blocked_
	blight_resistance = blight_resist_
	dps_effect = dps_
	name = "Tile_%d_%d" % [row, col]

	if blocked:
		tile_blocked()
		# Optionally, disable visuals/interactivity here
	else:
		pass
		# Connect input signals as needed for active tiles
		#tile_button.pressed.connect(_on_tile_button_pressed)

func tile_blocked() -> void:
	var tile_button = $TileButton
	tile_button.disabled = true
	var tex = $TileTexture
	if tex:
		tex.modulate = Color(0.5,0.5,0.5,1.0)

func _on_tile_button_pressed() -> void:
	# Only process if not blocked
	if blocked:
		return
	# Emit signal for placement request, etc.
	request_placement.emit(self, Vector2i(row, col))

func on_tile_input( input : InputEvent ) -> void:
	pass
	
func update_blight( value : int ) -> void:
	pass 	
	
func set_node( node : NodeType ) -> void:
	pass 	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
