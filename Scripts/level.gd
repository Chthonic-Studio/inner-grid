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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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

func request_placement() -> void:
	pass
	
func request_purge() -> void:
	pass

func check_win_condition() -> void:
	pass

func check_lose_condition() -> void:
	pass
