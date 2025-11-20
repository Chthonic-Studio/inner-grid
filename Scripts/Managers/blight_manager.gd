class_name BlightManager extends Node

signal blight_wave_pulsed()

const WAVE_CORRUPTION_AMOUNT = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func trigger_blight_wave() -> void:
	print("Blight Wave!")
	blight_wave_pulsed.emit()
	
func spread_corruption() -> void:
	pass

func purge_tile( pos: Vector2i ) -> void:
	print("Removing blight in tile ", pos)
