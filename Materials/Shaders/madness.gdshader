shader_type canvas_item;
uniform float alpha: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	float pixel_distance = distance(UV, vec2(0.5));
	float darkness = (pixel_distance + 0.2);
	COLOR = vec4(vec3(0.0), darkness * alpha);
}
