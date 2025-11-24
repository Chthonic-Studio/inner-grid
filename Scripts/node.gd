class_name GameNode extends Button

signal node_destroyed

@export_category("Node Setup")
@export var node_type: NodeType
@export var up_connection: NinePatchRect
@export var right_connection: NinePatchRect
@export var left_connection: NinePatchRect
@export var down_connection: NinePatchRect

@export_category("Node Stats")
@export var current_health: int = 100
@export var current_shield: int = 0
@export var connected: bool = false
@export var current_multiplier: float = 1.0 
var grid_position: Vector2i

var active_behavior : NodeBehavior

func _ready() -> void:
	if node_type:
		current_health = node_type.node_health
		current_shield = node_type.node_shield
		
		if node_type.behavior_scene:
			var behavior_instance = node_type.behavior_scene.instantiate()
			add_child(behavior_instance)
			active_behavior = behavior_instance as NodeBehavior
			
			if active_behavior:
				active_behavior.setup(self, node_type)
			else:
				printerr("ERROR: Behavior Scene for ", node_type.node_name, " does not have a NodeBehavior script attached!")
	
	update_visuals()

func on_global_tick(level: Level) -> void:
	if active_behavior:
		active_behavior.perform_tick(level)

func apply_passives(level: Level, tile: GameTile) -> void:
	if active_behavior:
		active_behavior.apply_passives(level, tile)

func set_connected_status(status: bool) -> void:
	if connected != status:
		connected = status
		if active_behavior:
			active_behavior.on_network_update(connected)
		update_visuals()

# Called by BlightManager
func apply_blight_damage( dmg: int ) -> void:
	# 1. Absorb with Shield
	if current_shield > 0:
		if current_shield >= dmg:
			current_shield -= dmg
			dmg = 0
		else:
			dmg -= current_shield
			current_shield = 0
			
	# 2. Apply to Health
	if dmg > 0:
		current_health -= dmg
		if current_health <= 0:
			destroy_node()
			return # Stop processing if destroyed
	
	# Notify Behavior (For Visuals/Logic)
	if active_behavior:
		active_behavior.on_damage_received(current_health, current_shield)
	
	# Visual feedback could be triggered here (flash, shake, etc)

func destroy_node() -> void:
	# We call specific logic on the Tile via the Level/Manager flow usually,
	# but here we are the child. We emit signal so Tile can handle cleanup.
	node_destroyed.emit()
	
	# IMPORTANT: We need to tell the tile to unreference us.
	# Usually Tile.remove_node() handles this, but if we die from damage,
	# we are initiating the death.
	var parent = get_parent()
	if parent and parent.has_method("remove_node"):
		parent.remove_node()
	else:
		queue_free()

func update_visuals() -> void:
	# Default state: Lines hidden
	up_connection.visible = false
	down_connection.visible = false
	left_connection.visible = false
	right_connection.visible = false
	
	# LOGIC UPDATE: Only dim if the node actually REQUIRES a network connection
	if node_type.requires_network_connection and not connected:
		modulate = Color(0.5, 0.5, 0.5) # Dim effect
	else:
		modulate = Color.WHITE

func show_connection(direction: Vector2i, active: bool) -> void:
	if direction == Vector2i.UP: up_connection.visible = active
	elif direction == Vector2i.DOWN: down_connection.visible = active
	elif direction == Vector2i.LEFT: left_connection.visible = active
	elif direction == Vector2i.RIGHT: right_connection.visible = active
