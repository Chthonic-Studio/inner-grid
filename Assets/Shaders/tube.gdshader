shader_type canvas_item;

uniform float whiteness = 0.0;

uniform float l = 100.0;
uniform	float balls[16];
uniform float basic_wid_s = .1;

float my_smooth(float a, float b, float v) {
	return smoothstep(a, b, v) * .2 + smoothstep(a * 2., b, v)*.2 + smoothstep(a * 5., b, v)*.3;
}

void fragment() {
	COLOR = vec4(vec3(1.), smoothstep(basic_wid_s, basic_wid_s-.01, 2. * abs(UV.y - .5)));
	float closeness = 0.0;
	for(int i = 0; i < balls.length(); i++) {
		float offset = balls[i];
		float edge_shrink = smoothstep(0.0, .01, offset) * smoothstep(1.0, 0.99, offset);
		closeness += my_smooth(.1 / l * 255.0 * edge_shrink, .0, abs(UV.x - offset))
			/ (float(balls.length()) + float(i)) * edge_shrink;
		//COLOR += vec4(vec3(1.), closeness * smoothstep(.4, .0, 2. * abs(UV.y - .5)));
	}
	closeness = smoothstep(0.0, 1.0, .7 + closeness * .4) - smoothstep(0.0, 1.0, .7);
	closeness *= 2.2;
	float edge_shrink_t = smoothstep(- 0.02, .035, UV.x) * smoothstep(1.02, 0.965, UV.x);
	closeness *= edge_shrink_t;
	float a = smoothstep(closeness, -0.0001, 2. * abs(UV.y - .5));
	a = smoothstep(.0, .2, a);
	COLOR += vec4(vec3(1.), a);
}
