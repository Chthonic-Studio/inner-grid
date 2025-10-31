class_name GameNode extends Node

signal node_destroyed

@export_category("Node Setup")
@export var node_type: NodeType
@export var up_connection: NinePatchRect
@export var right_connection: NinePatchRect
@export var left_connection: NinePatchRect
@export var down_connection: NinePatchRect
@export var logic_timer: Timer

@export_category("Node Stats")
@export var current_health: int = 100
@export var connected: bool
@export var synergy_buff: float = 0.0

@export_category("Synergies")
@export var synergy_up: bool
@export var synergy_right: bool
@export var synergy_left: bool
@export var synergy_down: bool

func _ready() -> void:
	logic_timer.start(node_type.function_timer)


func _on_logic_timer_timeout() -> void:
	node_type.calculate_output()

func apply_blight_damage( dmg: int ) -> void:
	current_health -= dmg
	if current_health <= 0:
		destroy_node()

func update_connection( _location ) -> void:
	pass

func destroy_node() -> void:
	node_destroyed.emit()
	queue_free()
