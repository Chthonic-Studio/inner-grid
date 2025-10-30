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

var win_condition : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func request_placement() -> void:
	pass
	
func request_purge() -> void:
	pass

func check_win_condition() -> void:
	pass

func check_lose_condition() -> void:
	pass
