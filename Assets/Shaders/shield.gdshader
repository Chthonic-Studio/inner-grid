shader_type canvas_item;

// Colors
uniform vec4 shield_color : source_color = vec4(0.0, 0.8, 1.0, 1.0); // Main Neon Blue
uniform vec4 damage_color : source_color = vec4(1.0, 0.2, 0.2, 1.0); // Red for damage
uniform vec4 inner_tint : source_color = vec4(0.0, 0.2, 0.5, 0.15); // Subtle blue tint background

// State
uniform float intensity : hint_range(0.0, 5.0) = 1.5; 
uniform float damage_flash : hint_range(0.0, 1.0) = 0.0; // 0 = Blue, 1 = Red
uniform float glitch_amount : hint_range(0.0, 1.0) = 0.0;

// Shape
uniform float radius : hint_range(0.0, 1.0) = 0.45;
uniform float thickness : hint_range(0.0, 0.2) = 0.02;

// Noise
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5);
    
    // --- GLITCH DISPLACEMENT ---
    if (glitch_amount > 0.0) {
        float t = TIME * 30.0;
        // Random horizontal slices
        float slice_noise = noise(vec2(uv.y * 10.0, t));
        if (slice_noise > 0.5) {
            uv.x += (slice_noise - 0.5) * glitch_amount * 0.2;
        }
        // Color channel split (Chromatic Aberration) simulation
        // handled by coloring later
    }

    float dist = distance(uv, center);
    
    // --- MASKS ---
    // 1. Ring Mask
    float ring_mask = smoothstep(radius, radius - thickness, dist) - smoothstep(radius - thickness, radius - thickness - 0.01, dist);
    
    // 2. Inner Field Mask
    float inner_mask = smoothstep(radius - thickness, 0.0, dist);
    
    // --- COLOR LOGIC ---
    // Interpolate between Shield Color and Damage Color based on flash
    vec3 current_main_col = mix(shield_color.rgb, damage_color.rgb, damage_flash);
    
    // --- INNER GLIMMER ---
    // Moving noise pattern for the "neon" feel inside
    float glimmer_noise = noise(uv * 8.0 + vec2(TIME * 0.5, -TIME * 0.8));
    // Make it pulse slightly
    float pulse = 0.8 + 0.2 * sin(TIME * 2.0);
    
    vec3 inner_visual = mix(inner_tint.rgb, current_main_col, 0.2); // Base tint mixed with main color
    inner_visual += current_main_col * glimmer_noise * 0.3 * pulse; // Add glimmer highlights
    
    // --- COMPOSITION ---
    vec3 final_rgb = (current_main_col * ring_mask * 2.0) + (inner_visual * inner_mask);
    
    // Glitch Color Artifacts (add random noise to color when glitching)
    if (glitch_amount > 0.0) {
        float gn = random(uv + TIME);
        final_rgb += vec3(gn) * glitch_amount * inner_mask;
    }
    
    float final_alpha = (ring_mask * shield_color.a) + (inner_mask * inner_tint.a * 2.0);
    
    // Intensity Multiplier
    final_rgb *= intensity;
    
    // Hard Cutoff
    if (dist > radius) final_alpha = 0.0;
    
    COLOR = vec4(final_rgb, final_alpha);
}