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
@export var blight_value: float = 0.0 

const MAX_BLIGHT_VALUE = 100.0

@onready var tile_button = $TileButton
@onready var tile_texture = $TileTexture
var local_node : GameNode

var _visual_tween : Tween

func _ready() -> void:
	# CRITICAL FIX: Create a unique material instance for this tile
	# This allows us to change shader parameters (like intensity) without affecting other tiles
	if tile_texture and tile_texture.material:
		tile_texture.material = tile_texture.material.duplicate()
		
		# Initialize shader to "invisible" state (intensity 0)
		(tile_texture.material as ShaderMaterial).set_shader_parameter("base_intensity", 0.0)
		
		# NOTE: We removed the color overrides here to use the default Red from the resource
	
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
	
	# Force immediate update on setup, no tween
	update_visuals(true)

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
	node_instance.grid_position = Vector2i(col, row)
	
	add_child(node_instance)
	local_node = node_instance
	has_node = true
	node_placed.emit(self, Vector2i(col, row), node_instance)

func remove_node() -> void:
	if local_node:
		local_node.queue_free()
		local_node = null
		has_node = false
		node_removed.emit(self, Vector2i(col, row))

func flash_red() -> void:
	tile_texture.modulate = Color(1.0, 0.2, 0.2, 1.0)
	await get_tree().create_timer(0.18).timeout
	update_visuals()

func update_visuals(immediate: bool = false) -> void:
	if tile_texture == null:
		tile_texture = $TileTexture
	
	if blocked:
		tile_texture.modulate = Color(0.2, 0.2, 0.2, 1.0)
		if tile_texture.material:
			(tile_texture.material as ShaderMaterial).set_shader_parameter("base_intensity", 0.0)
		return

	# --- SHADER LOGIC ---
	if tile_texture.material is ShaderMaterial:
		var mat = tile_texture.material as ShaderMaterial
		var ratio = blight_value / MAX_BLIGHT_VALUE
		
		# Piecewise Linear Interpolation based on requests
		var target_time_scale : float
		var target_layer_count : int
		var target_size : float
		
		if ratio <= 0.5:
			# Range 0% -> 50%
			var t = ratio / 0.5
			# Time Scale: 0.006 -> 0.2
			target_time_scale = lerpf(0.006, 0.2, t)
			# Layer Count: 2 -> 8
			target_layer_count = int(lerpf(2.0, 8.0, t))
			# Size: 1.0 -> 0.25
			target_size = lerpf(1.0, 0.25, t)
		else:
			# Range 50% -> 100%
			var t = (ratio - 0.5) / 0.5
			# Time Scale: 0.2 -> 0.45
			target_time_scale = lerpf(0.2, 0.45, t)
			# Layer Count: 8 -> 16
			target_layer_count = int(lerpf(8.0, 16.0, t))
			# Size: 0.25 -> 0.1
			target_size = lerpf(0.25, 0.1, t)
		
		var target_intensity = clamp(ratio * 5.0, 0.0, 1.0)
		
		if immediate:
			mat.set_shader_parameter("time_scale", target_time_scale)
			mat.set_shader_parameter("layer_count", target_layer_count)
			mat.set_shader_parameter("size", target_size)
			mat.set_shader_parameter("base_intensity", target_intensity)
		else:
			# Kill previous tween if active
			if _visual_tween and _visual_tween.is_valid():
				_visual_tween.kill()
			
			_visual_tween = create_tween()
			_visual_tween.set_parallel(true)
			_visual_tween.tween_method(func(v): mat.set_shader_parameter("time_scale", v), 
				mat.get_shader_parameter("time_scale"), target_time_scale, 0.5)
			
			_visual_tween.tween_method(func(v): mat.set_shader_parameter("size", v), 
				mat.get_shader_parameter("size"), target_size, 0.5)
			
			_visual_tween.tween_method(func(v): mat.set_shader_parameter("base_intensity", v), 
				mat.get_shader_parameter("base_intensity"), target_intensity, 0.5)
				
			# Integers like layer_count step abruptly, maybe better to set directly or floor the tween
			mat.set_shader_parameter("layer_count", target_layer_count)
	
	# --- MODULATE LOGIC ---
	if is_fully_blighted:
		tile_texture.modulate = Color(0.8, 0.8, 0.8, 1.0)
	else:
		tile_texture.modulate = Color(1, 1, 1, 0.7) 
