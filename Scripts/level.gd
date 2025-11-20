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
@export var level_resource: Resource = null 

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

# --- GLOBAL TICK ---
var tick_timer : Timer

func _ready() -> void:
	LevelManager.node_selected.connect(_on_node_selected)
	LevelManager.affordability_changed.connect(update_affordability)
	
	# 1. Setup Global Tick Timer (1 second tick)
	tick_timer = Timer.new()
	tick_timer.wait_time = 1.0
	tick_timer.one_shot = false
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_global_tick)
	add_child(tick_timer)
	
	if level_resource == null:
		level_resource = LevelManager.get_current_level_resource()
		if level_resource == null:
			level_resource = preload("res://Scripts/Levels/level_resource.gd").new()

	# 2. Purge old tiles
	for child in GameGrid.get_children():
		GameGrid.remove_child(child)
		child.queue_free()
		
	# 3. Build Grid
	for row in GRID_ROWS:
		for col in GRID_COLS:
			# FIX: Use (col, row) for position key. X=Col, Y=Row.
			var pos = Vector2i(col, row)
			var tile = tile_scene.instantiate()
			tile.name = "Tile_%d_%d" % [row, col]
			var blocked = level_resource.blocked_tiles.has(pos)
			var blight_resist = level_resource.tile_blight_resistance.get(pos, 0.0)
			var dps = level_resource.tile_dps_effect.get(pos, 0.0)
			tile.setup(row, col, blocked, blight_resist, dps)
			GameGrid.add_child(tile)
	
	win_condition = level_resource.resource_target
	
	# 4. Connect Signals
	for child in GameGrid.get_children():
		child.request_placement.connect(self._on_tile_placement_requested)
		child.node_removed.connect(self._on_node_removed_from_tile)
	
	# 5. SPAWN CORE NODES
	var cores_to_spawn : Array = []
	var raw_data = level_resource.core_starting_tile
	
	if raw_data is Array:
		cores_to_spawn = raw_data
	elif raw_data is Vector2i:
		cores_to_spawn = [raw_data]
	
	for core_pos in cores_to_spawn:
		var tile = _get_tile_at_position(core_pos)
		if tile:
			tile.set_node(core_node)
	
	LevelManager.income_updated.emit(EconomyManager.main_resource, EconomyManager.building_resource)
	
	# 6. Initial Network Calc
	recalculate_network()

func _on_global_tick() -> void:
	for tile in GameGrid.get_children():
		if tile.has_node and tile.local_node:
			tile.local_node.on_global_tick(EconomyManager)

func _on_node_selected(node : String):
	if node == "Generator": _current_selected_node_res = generator_node
	elif node == "Harvester": _current_selected_node_res = harvester_node
	elif node == "Shield": _current_selected_node_res = shield_node
	elif node == "Sensor": _current_selected_node_res = sensor_node
	elif node == "Synergy": _current_selected_node_res = synergy_node
	elif node == "Conduit": _current_selected_node_res = conduit_node
	elif node == "Purifier": _current_selected_node_res = purifier_node
	print("Selected node: ", _current_selected_node_res)

func _on_tile_placement_requested(tile: GameTile, grid_position: Vector2i) -> void:
	if Input.is_action_just_released("right_click"):
		_on_tile_purge_requested(tile, grid_position)
		return

	if Input.is_action_just_released("left_click"):
		if _current_selected_node_res == null:
			tile.flash_red()
			return
		if tile.has_node:
			tile.flash_red()
			return
		if not EconomyManager.can_afford(_current_selected_node_res.placement_cost, _current_selected_node_res.main_resource_placement_cost):
			tile.flash_red()
			return
			
		EconomyManager.spend_resources(_current_selected_node_res.placement_cost, _current_selected_node_res.main_resource_placement_cost)
		tile.set_node(_current_selected_node_res)
		print("Node placed: ", _current_selected_node_res)
		
		recalculate_network()
		
		if not Input.is_key_pressed(KEY_SHIFT):
			_current_selected_node_res = null

func _on_tile_purge_requested(tile: GameTile, grid_position: Vector2i) -> void:
	if not tile.has_node or tile.local_node.node_type.name == "Core":
		return
	var node_type = tile.local_node.node_type
	var refund = EconomyManager.get_sacrifice_refund(node_type)
	if refund > 0:
		EconomyManager.gain_resources(refund, "Building")
	
	tile.remove_node()
	
	# AOE Purge logic - offsets are still valid for (col, row)
	var offsets = [
		Vector2i(0,0), Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
		Vector2i(1,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1)
	]
	for offset in offsets:
		var pos = grid_position + offset
		if _is_valid_pos(pos):
			var neighbor = _get_tile_at_position(pos)
			if neighbor:
				BlightManager.purge_tile(pos)
				neighbor.flash_red()

func _on_node_removed_from_tile(tile, grid_pos):
	recalculate_network()

# --- NETWORK LOGIC ---
func recalculate_network() -> void:
	var all_tiles = GameGrid.get_children()
	
	# 1. Reset State
	for tile in all_tiles:
		if tile.has_node and tile.local_node:
			tile.local_node.set_connected_status(false)
			tile.local_node.update_visuals()

	# 2. Initialize BFS
	var open_list = [] 
	var visited = {}   
	
	# Find Core(s)
	for tile in all_tiles:
		if tile.has_node and tile.local_node.node_type.node_name == "Core":
			tile.local_node.set_connected_status(true)
			# FIX: Use (col, row)
			var pos = Vector2i(tile.col, tile.row)
			open_list.append(pos)
			visited[pos] = true

	# 3. Process BFS
	while open_list.size() > 0:
		var current_pos = open_list.pop_front()
		var current_tile = _get_tile_at_position(current_pos)
		
		# These constants now correctly correspond to (x=col, y=row)
		# UP=(0,-1) -> Row-1 (Up). RIGHT=(1,0) -> Col+1 (Right).
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		
		for dir in directions:
			var neighbor_pos = current_pos + dir
			if not _is_valid_pos(neighbor_pos):
				continue
				
			var neighbor_tile = _get_tile_at_position(neighbor_pos)
			if not neighbor_tile or not neighbor_tile.has_node:
				continue
				
			var neighbor_node = neighbor_tile.local_node
			var neighbor_name = neighbor_node.node_type.node_name
			
			var current_is_conductor = (current_tile.local_node.node_type.node_name == "Conduit" or current_tile.local_node.node_type.node_name == "Core")
			
			if current_is_conductor:
				neighbor_node.set_connected_status(true)
				
				# Visuals: Now align with Vector constants
				current_tile.local_node.show_connection(dir, true)
				neighbor_node.show_connection(-dir, true)
				
				if (neighbor_name == "Conduit" or neighbor_name == "Core") and not visited.has(neighbor_pos):
					visited[neighbor_pos] = true
					open_list.append(neighbor_pos)

func _get_tile_at_position(pos: Vector2i) -> GameTile:
	# FIX: Calc index based on Row-Major order 1D array (GridContainer structure)
	# Index = Row * Width + Col.
	# Since pos is (x=Col, y=Row):
	var index = pos.y * GRID_COLS + pos.x
	if index >= 0 and index < GameGrid.get_child_count():
		return GameGrid.get_child(index)
	return null

func _is_valid_pos(pos: Vector2i) -> bool:
	# FIX: Check x against COLS, y against ROWS
	return pos.x >= 0 and pos.x < GRID_COLS and pos.y >= 0 and pos.y < GRID_ROWS

func update_affordability():
	var result := {}
	if generator_node: result["Generator"] = EconomyManager.can_afford(generator_node.placement_cost, generator_node.main_resource_placement_cost)
	if harvester_node: result["Harvester"] = EconomyManager.can_afford(harvester_node.placement_cost, harvester_node.main_resource_placement_cost)
	if conduit_node: result["Conduit"] = EconomyManager.can_afford(conduit_node.placement_cost, conduit_node.main_resource_placement_cost)
	if shield_node: result["Shield"] = EconomyManager.can_afford(shield_node.placement_cost, shield_node.main_resource_placement_cost)
	if sensor_node: result["Sensor"] = EconomyManager.can_afford(sensor_node.placement_cost, sensor_node.main_resource_placement_cost)
	if synergy_node: result["Synergy"] = EconomyManager.can_afford(synergy_node.placement_cost, synergy_node.main_resource_placement_cost)
	if purifier_node: result["Purifier"] = EconomyManager.can_afford(purifier_node.placement_cost, purifier_node.main_resource_placement_cost)
	emit_signal("affordability_changed", result)
