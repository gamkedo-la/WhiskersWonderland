shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_size : hint_range(0, 50) = 1.0;

const vec2 OFFSETS[8] = { vec2(-0.71, -0.71), vec2(-1, 0), vec2(-0.71, 0.71), vec2(0, -1), vec2(0, 1), vec2(0.71, -0.71), vec2(1, 0), vec2(0.71, 0.71) };

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_size;
	float outline = 0.0;
	
	for (int i = 0; i < OFFSETS.length(); i++) {
		outline += texture(TEXTURE, UV + size * OFFSETS[i]).a;
	}
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, UV);
	COLOR = mix(color, outline_color, outline - color.a);
}