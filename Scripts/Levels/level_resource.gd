class_name LevelResource extends Resource

@export_category("Level-wide Properties")
@export var blight_speed: float = 1.0
@export var resource_target: int = 100

@export_category("Tile-specific Arrays")
@export var blocked_tiles: Array[Vector2i] = []
@export var initial_blight_tiles: Array[Vector2i] = []
@export var tile_blight_resistance: Dictionary = {} # {(row, col): resistance}
@export var tile_dps_effect: Dictionary = {}        # {(row, col): dps}
@export var tile_special: Dictionary = {}           # {(row, col): special_effect}

# Add more fields as needed for future per-tile properties
