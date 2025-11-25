shader_type canvas_item;

uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform float cycle_speed : hint_range(0.0, 10.0, 0.1) = 1.0; 
uniform bool heartbeat_mode = true; 

void fragment()
{
	vec4 tex_color = texture(TEXTURE, UV);
	
	float pulse = 0.0;
	
	if (heartbeat_mode) {
		// Heartbeat math: sharp peaks, long rest
		// sin(x) mapped to 0-1, raised to high power for sharpness
		float t = TIME * cycle_speed;
		float wave = sin(t);
		
		// Creating a "Lub-Dub" double beat rhythm
		// Beat 1 (Major)
		float b1 = pow(max(0.0, sin(t)), 8.0);
		// Beat 2 (Minor, offset slightly)
		float b2 = pow(max(0.0, sin(t - 0.4)), 16.0) * 0.5;
		
		pulse = max(b1, b2);
	} else {
		// Standard smooth sine
		pulse = (sin(TIME * cycle_speed) + 1.0) * 0.5;
	}
	
	// Apply pulse as an ADDITIVE flash on top of original color
	// This preserves the underlying sprite art while making it glow
	vec3 flash = shine_color.rgb * pulse * shine_color.a;
	
	COLOR.rgb = tex_color.rgb + flash;
	COLOR.a = tex_color.a;
}