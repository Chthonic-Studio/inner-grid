class_name NodeType extends Resource

@export_category("Node Info")
@export var node_name : String
@export var function_timer: float

@export_category("Node Stats")
@export var node_health: int = 100
@export var node_shield: int = 100
@export_range(0, 100) var node_efficiency: float = 100

@export_category("Behavior")
@export var behavior_scene : PackedScene 
@export var base_output : int = 0
@export var requires_network_connection : bool = true

@export_category("Node Costs")
@export var placement_cost : int
@export var main_resource_placement_cost : int
