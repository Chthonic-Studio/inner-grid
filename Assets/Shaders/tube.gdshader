shader_type canvas_item;

uniform float speed = 1.0;
uniform vec4 bg_color : source_color = vec4(0.2, 0.2, 0.2, 0.5);
uniform vec4 ball_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);

void fragment() {
    // Tube Edges (Simple border)
    float tube_mask = 1.0 - step(0.4, abs(UV.y - 0.5)); // 80% height tube
    
    // Moving Ball
    // UV.x goes 0 -> 1.
    // speed controls direction: + = Left to Right (0->1), - = Right to Left (1->0)
    float t = TIME * speed;
    
    // Create a repeating "ball" shape (sine wave clamped)
    float wave = sin((UV.x * 4.0) - t);
    float ball_mask = smoothstep(0.9, 1.0, wave);
    
    vec3 final_rgb = mix(bg_color.rgb, ball_color.rgb, ball_mask);
    float final_a = max(bg_color.a, ball_mask * ball_color.a);
    
    COLOR = vec4(final_rgb, final_a * tube_mask);
}
