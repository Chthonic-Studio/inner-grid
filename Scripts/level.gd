class_name Level extends Node

signal affordability_changed(affordable_nodes: Dictionary) 

@export_category("Managers")
@warning_ignore("shadowed_global_identifier")
@export var EconomyManager: EconomyManager
@warning_ignore("shadowed_global_identifier")
@export var BlightManager: BlightManager
@warning_ignore("shadowed_global_identifier")
@export var NarrativeManager: NarrativeManager

@export_category("Grid & Viewport")
@export var GameViewport: Control
@export var GameGrid: GridContainer

@export_category("Tile Scene")
@export var tile_scene : PackedScene

@export_category("Level Resource")
@export var level_resource: Resource = null ## --- LEVEL DATA (for testing override)

@export_category("Node Resources")
@export var core_node : NodeType
@export var generator_node : NodeType
@export var harvester_node : NodeType
@export var shield_node : NodeType
@export var sensor_node : NodeType
@export var synergy_node : NodeType
@export var conduit_node : NodeType
@export var purifier_node : NodeType

var win_condition : int

const GRID_COLS := 16
const GRID_ROWS := 10

var _current_selected_node_res: NodeType = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to the Level Manager signal to know what the player wants to build
	LevelManager.node_selected.connect(_on_node_selected)
	LevelManager.affordability_changed.connect(update_affordability)
	
	# 1. Get level configuration from LevelManager or exported override
	if level_resource == null:
		level_resource = LevelManager.get_current_level_resource()
		if level_resource == null:
			level_resource = preload("res://Scripts/Levels/level_resource.gd").new() # Blank fallback

	# 2. Purge old tiles (for editor/test safety)
	for child in GameGrid.get_children():
		GameGrid.remove_child(child)
		child.queue_free()
	
	# 3. Build grid	
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var pos = Vector2i(row, col)
			var tile = tile_scene.instantiate()
			tile.name = "Tile_%d_%d" % [row, col]
			# Per-tile data
			var blocked = level_resource.blocked_tiles.has(pos)
			var blight_resist = level_resource.tile_blight_resistance.get(pos, 0.0)
			var dps = level_resource.tile_dps_effect.get(pos, 0.0)
			tile.setup(row, col, blocked, blight_resist, dps)
			GameGrid.add_child(tile)
	
	# 4. Set win condition
	win_condition = level_resource.resource_target
	
	for child in GameGrid.get_children():
		child.request_placement.connect(self._on_tile_placement_requested)

# Called by UI when player selects a node type
func _on_node_selected(node : String):
	if node == "Generator":
		_current_selected_node_res = generator_node
	if node == "Harvester":
		_current_selected_node_res = harvester_node
	if node == "Shield":
		_current_selected_node_res = generator_node
	if node == "Sensor":
		_current_selected_node_res = sensor_node
	if node == "Synergy":
		_current_selected_node_res = synergy_node
	if node == "Conduit":
		_current_selected_node_res = conduit_node
	if node == "Purifier":
		_current_selected_node_res = generator_node
	

# Called by Tile, passes self and grid_position
func _on_tile_placement_requested(tile: GameTile, grid_position: Vector2i) -> void:
	if Input.is_action_just_pressed("right_click"):
		_on_tile_purge_requested(tile, grid_position)
		return

	if Input.is_action_just_pressed("left_click"):
		# Check placement mode
		if _current_selected_node_res == null:
			tile.flash_red()
			AudioManager.play("fail") # UI sound
			return
		# Check empty
		if tile.has_node:
			tile.flash_red()
			AudioManager.play("fail")
			return
		# Check affordability
		if not EconomyManager.can_afford(_current_selected_node_res.placement_cost, _current_selected_node_res.main_resource_placement_cost):
			tile.flash_red()
			AudioManager.play("fail")
			return
		# All clear, place node
		EconomyManager.spend_resources(_current_selected_node_res.placement_cost, _current_selected_node_res.main_resource_placement_cost)
		tile.set_node(_current_selected_node_res)
		AudioManager.play("place_node")
		# Update UI (resource signals will fire)

# Called by Tile, passes self and grid_position
func _on_tile_purge_requested(tile: GameTile, grid_position: Vector2i) -> void:
	# Only allow if a node exists, and not the Main node
	if not tile.has_node or tile.local_node.node_type.name == "Main":
		return
	var node_type = tile.local_node.node_type
	var refund = EconomyManager.get_sacrifice_refund(node_type)
	if refund > 0:
		EconomyManager.gain_resources(refund, "Building")
	tile.remove_node()
	AudioManager.play("sacrifice")
	# AOE Purge: center + 8 neighbors (orthogonal + diagonals)
	var offsets = [
		Vector2i(0,0),
		Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
		Vector2i(1,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1)
	]
	for offset in offsets:
		var pos = grid_position + offset
		var neighbor = _get_tile_at_position(pos)
		if neighbor:
			BlightManager.purge_tile(pos)
			neighbor.flash_red() # Feedback for now; later: shader effect

# Helper: Get tile at grid position
func _get_tile_at_position(pos: Vector2i) -> GameTile:
	for child in GameGrid.get_children():
		if child.row == pos.x and child.col == pos.y:
			return child
	return null

# Call this after any resource or node selection change
func update_affordability():
	var result := {}
	var node_names = ["Generator", "Harvester", "Shield", "Sensor", "Synergy", "Conduit", "Purifier"]
	for s in node_names:
		var node_type = LevelManager.get_node_type(name) # Assumes you have a way to get this Resource
		result[name] = EconomyManager.can_afford(node_type.placement_cost, node_type.main_resource_placement_cost)
	emit_signal("affordability_changed", result)
