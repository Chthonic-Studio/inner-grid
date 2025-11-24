class_name ShieldBehavior extends NodeBehavior

@export var recharge_delay_seconds: int = 10

var _shield_visual : ColorRect
var _shader_material : ShaderMaterial
var _is_shield_active : bool = true
var _main_tween : Tween
var _damage_tween : Tween

# Timer to track how long the shield has been down
var _current_recharge_timer : int = 0

func _on_setup() -> void:
	# --- VISUAL SETUP ---
	_shield_visual = ColorRect.new()
	_shield_visual.size = Vector2(240, 240)
	_shield_visual.position = Vector2(-80, -80)
	_shield_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_visual.z_index = 5 
	
	var shader = load("res://Assets/Shaders/shield.gdshader")
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_shield_visual.material = _shader_material
		
		# Default Visual Parameters
		_shader_material.set_shader_parameter("shield_color", Color(0.0, 0.8, 1.0, 1.0))
		_shader_material.set_shader_parameter("damage_color", Color(1.0, 0.2, 0.2, 1.0))
		_shader_material.set_shader_parameter("inner_tint", Color(0.0, 0.2, 0.5, 0.3))
		_shader_material.set_shader_parameter("intensity", 1.5)
		_shader_material.set_shader_parameter("damage_flash", 0.0)
		_shader_material.set_shader_parameter("glitch_amount", 0.0)
		
	parent_node.add_child(_shield_visual)
	_update_visual_state(true)

func perform_tick(level: Level) -> void:
	# 1. CASE: Shield is BROKEN (0)
	if parent_node.current_shield <= 0:
		_current_recharge_timer += 1
		
		# If we reached the target delay, restore to FULL
		if _current_recharge_timer >= recharge_delay_seconds:
			parent_node.current_shield = data.node_shield
			_current_recharge_timer = 0
			
			# Restore Visuals
			if not _is_shield_active:
				_is_shield_active = true
				_play_glitch_effect(0.0) # Glitch In
				_update_visual_state(false)
				
	# 2. CASE: Shield is DAMAGED but ACTIVE (> 0)
	elif parent_node.current_shield < data.node_shield:
		_current_recharge_timer = 0 # Reset timer if we are active
		
		# Standard linear regeneration for partial damage
		var regen = data.base_output
		parent_node.current_shield = min(parent_node.current_shield + regen, data.node_shield)

func on_damage_received(current_health: int, current_shield: int) -> void:
	# 1. Trigger Damage Flash (Blue -> Red -> Blue)
	if _is_shield_active and _shader_material:
		if _damage_tween and _damage_tween.is_valid():
			_damage_tween.kill()
			
		_damage_tween = create_tween()
		_damage_tween.tween_method(func(v): _shader_material.set_shader_parameter("damage_flash", v), 0.0, 1.0, 0.1)
		_damage_tween.tween_method(func(v): _shader_material.set_shader_parameter("damage_flash", v), 1.0, 0.0, 0.3)

	# 2. Handle Breaking
	if current_shield <= 0 and _is_shield_active:
		_is_shield_active = false
		_play_glitch_effect(1.0) # Heavy glitch on break
		_update_visual_state(false)

# --- VISUAL HELPERS ---

func _play_glitch_effect(target_val: float) -> void:
	if not _shader_material: return
	var gt = create_tween()
	gt.tween_method(func(v): _shader_material.set_shader_parameter("glitch_amount", v), 0.8, 0.0, 0.4)

func _update_visual_state(immediate: bool) -> void:
	if not _shader_material: return
	
	var target_alpha = 1.0 if _is_shield_active else 0.0
	var target_intensity = 1.5 if _is_shield_active else 0.0
	
	if immediate:
		_shield_visual.modulate.a = target_alpha
		_shader_material.set_shader_parameter("intensity", target_intensity)
	else:
		if _main_tween: _main_tween.kill()
		_main_tween = create_tween()
		_main_tween.set_parallel(true)
		_main_tween.tween_property(_shield_visual, "modulate:a", target_alpha, 0.5)
		_main_tween.tween_method(func(v): _shader_material.set_shader_parameter("intensity", v),
			_shader_material.get_shader_parameter("intensity"), target_intensity, 0.5)
