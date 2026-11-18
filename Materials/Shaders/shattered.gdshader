shader_type canvas_item;
uniform bool enabled = true;
uniform sampler2D screen_texture: hint_screen_texture;
uniform float angle : hint_range(0, 360) = 0.0;

vec2 rotate(vec2 uv, vec2 pivot, float angle_rad) {
    uv -= pivot;
    uv = vec2(
        uv.x * cos(angle_rad) - uv.y * sin(angle_rad),
        uv.x * sin(angle_rad) + uv.y * cos(angle_rad)
    );
    uv += pivot;
    return uv;
}

void fragment() {
	if(enabled){
		vec2 rotated_uv = rotate(SCREEN_UV, vec2(0.5), radians(angle));
		COLOR = texture(screen_texture, rotated_uv);
	}
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
