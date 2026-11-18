shader_type canvas_item;
uniform sampler2D other_world_viewport;
uniform float alpha: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	COLOR = texture(other_world_viewport, UV);
	COLOR.a = alpha;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
