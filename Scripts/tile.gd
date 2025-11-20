class_name GameTile extends Node

signal request_placement(tile, grid_position)
signal request_purge(tile, grid_position)
signal tile_blight_changed(tile, grid_position, blight_value)
signal tile_fully_blighted(tile, grid_position)
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
@export var has_blight: bool # True if blight > 0
@export var is_fully_blighted: bool = false # True if reached max
@export var blight_value: float = 0.0 # Changed to float for granular resistance math

const MAX_BLIGHT_VALUE = 100.0

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
	
	update_visuals()

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

# Called by BlightManager
func increase_blight( amount : float ) -> void:
	if is_fully_blighted or blocked:
		return
		
	blight_value += amount
	has_blight = blight_value > 0
	
	if blight_value >= MAX_BLIGHT_VALUE:
		blight_value = MAX_BLIGHT_VALUE
		is_fully_blighted = true
		tile_fully_blighted.emit(self, Vector2i(col, row))
	
	tile_blight_changed.emit(self, Vector2i(col, row), blight_value)
	update_visuals()

# Called by Purifier / Sacrifice
func reduce_blight( amount : float ) -> void:
	if blight_value <= 0:
		return
		
	blight_value -= amount
	if blight_value < 0:
		blight_value = 0
		
	has_blight = blight_value > 0
	if is_fully_blighted and blight_value < MAX_BLIGHT_VALUE:
		is_fully_blighted = false
		
	tile_blight_changed.emit(self, Vector2i(col, row), blight_value)
	update_visuals()
	
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
	update_visuals()

func update_visuals() -> void:
	if tile_texture == null:
		tile_texture = $TileTexture
	if blocked:
		tile_texture.modulate = Color(0.2, 0.2, 0.2, 1.0)
	elif is_fully_blighted:
		tile_texture.modulate = Color(0.2, 0.0, 0.3, 1.0) # Deep purple for full blight
	elif has_blight:
		# Gradient from White to Purple based on blight value
		var ratio = blight_value / MAX_BLIGHT_VALUE
		tile_texture.modulate = Color.WHITE.lerp(Color(0.5, 0.0, 0.5, 1.0), ratio)
	else:
		tile_texture.modulate = Color(1, 1, 1, 0.7)
