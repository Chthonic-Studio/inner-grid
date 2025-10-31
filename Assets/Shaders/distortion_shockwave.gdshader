shader_type canvas_item;

// Godot's built-in TIME variable handles the automatic animation.
uniform float strength: hint_range(0.0, 0.1, 0.001) = 0.08;
uniform float radius: hint_range(0.0, 1.0, 0.001) = 0.35;
uniform float aberration: hint_range(0.0, 1.0, 0.001) = 0.425;
uniform float width: hint_range(0.0, 0.1, 0.0001) = 0.04;
uniform float feather: hint_range(0.0, 1.0, 0.001) = 0.135;

void fragment() {
	// Use the built-in TIME variable
	float pulse = sin(TIME * 3.0) * 0.02 + 0.02;
	float dynamic_strength = strength + pulse;
	
	vec2 center = UV - vec2(0.5); 
	vec2 st = UV; 

	vec2 dist_center = center;
	
	// Create the mask ring shape
	float mask = (1.0 - smoothstep(radius - feather, radius, length(dist_center))) * smoothstep(radius - width - feather, radius - width, length(dist_center));
	
	vec2 offset = normalize(dist_center) * dynamic_strength * mask; 
	vec2 final_st = st - offset;
	
	vec2 abber_vec = offset * aberration * mask;

	// Use the built-in TEXTURE variable to sample the ColorRect's color/texture
	vec4 red = texture(TEXTURE, final_st + abber_vec);
	vec4 blue = texture(TEXTURE, final_st - abber_vec);
	vec4 ori = texture(TEXTURE, final_st);
	
	// Combine channels for the visual effect
	vec4 effect_color = vec4(red.r, ori.g, blue.b, 1.0);
	
	// **CRITICAL FIX:** Use the mask to blend the effect.
    // The distortion effect should only be visible where the 'mask' is strong (near the center).
    // Everywhere else, we should allow the background to show through.
    // However, since we are only sampling the ColorRect's internal texture, this will only distort the ColorRect's color.

    // If you are trying to sample what is visually behind the ColorRect, you MUST use the 
    // CANVAS_TEXTURE function *within* the shader, which is a different rendering technique.

    // Let's assume you want the *ColorRect itself* to look like a distorted glow:
	COLOR = effect_color;
	
	// Now, let's control the opacity of the final effect.
    // We make the whole effect semi-transparent, and totally transparent outside the masked area.
    // This allows the node's geometry/texture behind the ColorRect to remain visible.
	COLOR.a = mask * 0.8; // Set alpha based on the mask strength, max 80% opacity
}