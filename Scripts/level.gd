class_name Level extends Node

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

var win_condition : int

const GRID_COLS := 16
const GRID_ROWS := 10

var _current_selected_node_res: NodeType = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect to the Level Manager signal to know what the player wants to build
	LevelManager.node_selected.connect(_on_node_selected)
	
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
			var special = level_resource.tile_special.get(pos, null)
			tile.setup(row, col, blocked, blight_resist, dps, special)
			GameGrid.add_child(tile)
	
	# 4. Set win condition
	win_condition = level_resource.resource_target
	
	for child in GameGrid.get_children():
		child.request_placement.connect()

func _on_node_selected(node_resource: NodeType):
	# Store what the player wants to place
	_current_selected_node_res = node_resource
	# Placement mode (update cursor?)
	
func _on_tile_placement_requested(tile: GameTile):
	if Input.is_action_just_pressed("right_click"):
		if tile.placed_node != null:
			request_purge(tile)
		return # Stop processing
	
	# Check for Left-Click (Placement)
	if Input.is_action_just_pressed("left_click"):
		# Check 1: Is the player holding a node to place?
		if _current_selected_node_res == null:
			return # Not in placement mode

		# Check 2: Is the tile empty?
		if tile.placed_node != null:
			return # Tile is occupied

		# Check 3: Can we afford it?
		if EconomyManager.can_afford(_current_selected_node_res.base_cost):
			# All checks passed!
			EconomyManager.spend_resources(_current_selected_node_res.base_cost)
			
func request_placement() -> void:
	pass
	
func request_purge( tile ) -> void:
	pass

func check_win_condition() -> void:
	pass

func check_lose_condition() -> void:
	pass
