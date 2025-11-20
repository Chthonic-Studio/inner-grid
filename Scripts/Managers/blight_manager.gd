class_name BlightManager extends Node

signal blight_wave_pulsed()
signal base_damaged(current_health)

# Configuration
const BASE_SPREAD_AMOUNT = 15.0 # How much blight is added per tick to a tile
const SPREAD_TICK_RATE = 1.0 # Seconds between spread calculations
const NODE_DAMAGE_PER_TICK = 10 # Damage dealt to nodes instead of blighting

# State
var _level_ref: Level
var _grid_map: Dictionary = {} # { Vector2i: GameTile }
var _blighted_tiles: Array[Vector2i] = [] # List of tiles that are sources of spread
var _active_shields: Dictionary = {} # { Vector2i(tile_pos) : Array[GameNode(shield)] }
var _core_position: Vector2i

var _timer: float = 0.0
var _is_active: bool = false

func _ready() -> void:
	pass

func setup(level: Level, grid_container: GridContainer, resource: LevelResource) -> void:
	_level_ref = level
	_is_active = true
	
	# 1. Map Grid for fast access
	for child in grid_container.get_children():
		if child is GameTile:
			var pos = Vector2i(child.col, child.row)
			_grid_map[pos] = child
	
	# 2. Set Core Position
	# FIX: LevelResource defines this strictly as Vector2i, so we assign directly.
	_core_position = resource.core_starting_tile
	
	# 3. Initialize Blight
	for pos in resource.initial_blight_tiles:
		if _grid_map.has(pos):
			var tile = _grid_map[pos]
			# NOTE: Ensure GameTile has 'increase_blight' and 'MAX_BLIGHT_VALUE' from the proposed Tile.gd update
			tile.increase_blight(GameTile.MAX_BLIGHT_VALUE) 
			if not _blighted_tiles.has(pos):
				_blighted_tiles.append(pos)
	
	print("BlightManager Initialized. Core at: ", _core_position)

func _process(delta: float) -> void:
	if not _is_active: 
		return
		
	_timer += delta
	if _timer >= SPREAD_TICK_RATE:
		_timer = 0.0
		spread_corruption()

# --- SPREAD LOGIC ---

func spread_corruption() -> void:
	if _blighted_tiles.is_empty():
		return

	var active_sources = _blighted_tiles.duplicate()
	
	for source_pos in active_sources:
		_process_source_tile(source_pos)
		
	blight_wave_pulsed.emit()

func _process_source_tile(source_pos: Vector2i) -> void:
	var neighbors = _get_neighbors(source_pos)
	
	for target_pos in neighbors:
		var target_tile = _grid_map.get(target_pos)
		if not target_tile or target_tile.blocked:
			continue
			
		if target_tile.is_fully_blighted:
			continue
			
		# BIAS CALCULATION:
		# Prefer tiles closer to the core.
		var current_dist = source_pos.distance_to(_core_position)
		var target_dist = target_pos.distance_to(_core_position)
		
		var spread_chance = 0.3 
		
		# If moving closer to core, increase chance
		if target_dist < current_dist:
			spread_chance += 0.4
		
		if randf() < spread_chance:
			_attempt_corruption(target_tile, target_pos)

func _attempt_corruption(tile: GameTile, pos: Vector2i) -> void:
	# 1. CHECK SHIELDS
	if _active_shields.has(pos) and not _active_shields[pos].is_empty():
		var shields = _active_shields[pos]
		var defender = shields[0] 
		if is_instance_valid(defender) and defender.current_shield > 0:
			defender.apply_blight_damage(NODE_DAMAGE_PER_TICK)
			return 
		else:
			# Cleanup invalid/empty shields
			_active_shields[pos].erase(defender)
			if not _active_shields[pos].is_empty():
				_attempt_corruption(tile, pos)
				return

	# 2. CHECK NODES
	if tile.has_node and is_instance_valid(tile.local_node):
		tile.local_node.apply_blight_damage(NODE_DAMAGE_PER_TICK)
		return

	# 3. APPLY BLIGHT
	var resistance = tile.blight_resistance
	var amount = BASE_SPREAD_AMOUNT * (1.0 - resistance)
	amount = max(amount, 1.0)
	
	tile.increase_blight(amount)
	
	if tile.is_fully_blighted:
		if not _blighted_tiles.has(pos):
			_blighted_tiles.append(pos)
		
		# Check for Base Damage on adjacency
		if pos.distance_to(_core_position) <= 1.5: 
			_damage_core()

func _damage_core() -> void:
	if _grid_map.has(_core_position):
		var core_tile = _grid_map[_core_position]
		if core_tile.has_node and core_tile.local_node:
			core_tile.local_node.apply_blight_damage(NODE_DAMAGE_PER_TICK)
			base_damaged.emit(core_tile.local_node.current_health)

# --- SHIELD REGISTRY ---

func register_shield(shield_node: GameNode, center_pos: Vector2i) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			var offset = Vector2i(x, y)
			var target = center_pos + offset
			if not _active_shields.has(target):
				_active_shields[target] = []
			
			if not _active_shields[target].has(shield_node):
				_active_shields[target].append(shield_node)

func unregister_shield(shield_node: GameNode, center_pos: Vector2i) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			var offset = Vector2i(x, y)
			var target = center_pos + offset
			if _active_shields.has(target):
				_active_shields[target].erase(shield_node)
				if _active_shields[target].is_empty():
					_active_shields.erase(target)

# --- UTILS ---

func purge_tile( pos: Vector2i ) -> void:
	if _grid_map.has(pos):
		var tile = _grid_map[pos]
		tile.reduce_blight(GameTile.MAX_BLIGHT_VALUE)
		if _blighted_tiles.has(pos) and not tile.is_fully_blighted:
			_blighted_tiles.erase(pos)

func _get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	var offsets = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for off in offsets:
		arr.append(pos + off)
	return arr
