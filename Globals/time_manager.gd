extends Node

var level_clock : float
var clock_running : bool
var blight_clock : float

func _ready() -> void:
	pass 

func menu_pause() -> void:
	Engine.time_scale = 0

func menu_unpause() -> void:
	Engine.time_scale = 1

func start_level_clock() -> void:
	level_clock = 0.0
	clock_running = true
	print("Level clock started")

func end_level_clock() -> void:
	clock_running = false
	print("Level clock stopped")
	
func _process(delta: float) -> void:
	if clock_running:
		level_clock += delta

func blight_wave_clock() -> void:
	pass
