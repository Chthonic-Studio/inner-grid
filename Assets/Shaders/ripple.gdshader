shader_type canvas_item;
render_mode blend_add; // Additive blending ensures ripples stack like light, not paint

uniform float frequency: hint_range(0, 20, 0.01) = 8.0;
uniform float ripple_rate : hint_range(0, 20.0, 1) = 3.0;
uniform vec4 tint_color : source_color = vec4(1.0, 0.9, 0.0, 0.5);

void fragment() {
	// Center coordinates (-1 to 1)
	vec2 center_position = UV * 2.0 - 1.0;
	float dist = length(center_position);

	// 1. Calculate Ripple Wave
	// Using sin() to create concentric bands
	float ripple_raw = sin(dist * -frequency * 3.14159 + TIME * ripple_rate);

	// 2. Sharpen the Wave
	// Power function makes the peaks thin and the valleys wide/transparent
	// max(0.0, ...) ensures we only draw the "positive" rings
	float ripple_sharp = pow(max(0.0, ripple_raw), 6.0);

	// 3. Attenuation (Fade out)
	// Box fade: Soften edges near the limit of the 3x3 square
	float box_edge = max(abs(center_position.x), abs(center_position.y));
	float edge_fade = 1.0 - smoothstep(0.7, 1.0, box_edge);

	// Center fade: Make the ripple slightly stronger near the source
	float center_strength = 1.0 / (0.5 + dist * 1.5);

	// 4. Final Color
	// RGB is just the tint
	vec3 final_color = tint_color.rgb;

	// Alpha controls visibility.
	// Where ripple_sharp is 0 (between rings), alpha is 0, showing the game below perfectly.
	float final_alpha = ripple_sharp * center_strength * edge_fade * tint_color.a;

	COLOR = vec4(final_color, final_alpha);
}