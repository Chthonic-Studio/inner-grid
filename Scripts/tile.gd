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

@onready var tile_button = $TileButton
@onready var tile_texture = $TileTexture
var local_node : GameNode

func _ready() -> void:
	pass
	
func setup(row_: int, col_: int, blocked_: bool, blight_resist_: float, dps_: float) -> void:
	row = row_
	col = col_
	blocked = blocked_
	blight_resistance = blight_resist_
	dps_effect = dps_
	name = "Tile_%d_%d" % [row, col]

	if blocked:
		tile_blocked()
	else:
		if tile_button == null:
			tile_button = $TileButton
		tile_button.pressed.connect(_on_tile_button_pressed)

func tile_blocked() -> void:
	if tile_button == null:
		tile_button = $TileButton
	if tile_texture == null:
		tile_texture = $TileTexture
	tile_button.disabled = true
	tile_texture.modulate = Color(0.5,0.5,0.5,1.0)

func _on_tile_button_pressed() -> void:
	if blocked:
		return
	# FIX: Send (col, row) instead of (row, col) to match standard X/Y axes
	request_placement.emit(self, Vector2i(col, row))

func on_tile_input( input : InputEvent ) -> void:
	pass
	
func placement_request() -> void:
	request_placement.emit(self)

func update_blight( value : int ) -> void:
	pass 	
	
func set_node(node_type: NodeType) -> void:
	if local_node:
		print("Tile already occupied!")
		return
	var node_instance = node_scene.instantiate()
	node_instance.node_type = node_type
	
	# FIX: Assign grid_position as (col, row)
	node_instance.grid_position = Vector2i(col, row)
	
	add_child(node_instance)
	local_node = node_instance
	has_node = true
	# FIX: Emit (col, row)
	node_placed.emit(self, Vector2i(col, row), node_instance)

func remove_node() -> void:
	if local_node:
		local_node.queue_free()
		local_node = null
		has_node = false
		# FIX: Emit (col, row)
		node_removed.emit(self, Vector2i(col, row))

func flash_red() -> void:
	tile_texture.modulate = Color(1.0, 0.2, 0.2, 1.0)
	await get_tree().create_timer(0.18).timeout
	tile_texture.modulate = Color(0.5,0.5,0.5,1.0)
