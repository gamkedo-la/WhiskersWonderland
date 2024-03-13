shader_type canvas_item;
render_mode unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_size : hint_range(0, 50) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const vec2 OFFSETS[8] = { vec2(-0.71, -0.71), vec2(-1, 0), vec2(-0.71, 0.71), vec2(0, -1), vec2(0, 1), vec2(0.71, -0.71), vec2(1, 0), vec2(0.71, 0.71) };

void fragment() {
	vec2 size = SCREEN_PIXEL_SIZE * outline_size;
	float outline = 0.0;
	
	for (int i = 0; i < OFFSETS.length(); i++) {
		outline += texture(screen_texture, SCREEN_UV + size * OFFSETS[i]).a;
	}
	outline = min(outline, 1.0);
	
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}

	COLOR = mix(c, outline_color, outline - c.a);
}