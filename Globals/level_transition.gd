extends ColorRect

const PROGRESS_UNIFORM_NAME: StringName = &"progress"

@export_category("Transition Timings")
@export var FADE_TIME: float = 1.0
@export var HOLD_TIME: float = 0.5

func _ready() -> void:
	set_shader_progress(0.0)
	
func fade_in() -> bool:
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(set_shader_progress, 20.0, 0.0, FADE_TIME)
	
	await tween.finished
		
	return true
	
func fade_out() -> bool:
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(set_shader_progress, 0.0, 20.0, FADE_TIME)
	
	await tween.finished
	
	return true

func set_shader_progress(value: float):
	material.set_shader_parameter(PROGRESS_UNIFORM_NAME, value)
