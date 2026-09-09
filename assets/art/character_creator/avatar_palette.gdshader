shader_type canvas_item;

uniform vec4 hair_color : source_color = vec4(0.47, 0.26, 0.18, 1.0);
uniform vec4 cloth_color : source_color = vec4(0.15, 0.38, 0.45, 1.0);
uniform vec4 skin_color : source_color = vec4(0.93, 0.74, 0.57, 1.0);
uniform float columns = 8.0;
varying vec4 actor_tint;

void vertex() {
	actor_tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 cell_uv = fract(UV * vec2(columns, 4.0));
	float light = max(max(tex.r, tex.g), tex.b);
	if (tex.b > tex.r * 1.15 && tex.g > tex.r * 1.2) {
		tex.rgb = cloth_color.rgb * (0.38 + light * 1.5);
	} else if (cell_uv.y < 0.38 && tex.r > tex.g * 1.15 && tex.r > tex.b * 1.3) {
		tex.rgb = hair_color.rgb * (0.3 + light * 1.45);
	} else if (cell_uv.y > 0.32 && cell_uv.y < 0.72 && tex.r > 0.5 && tex.r > tex.g * 1.12 && tex.g > tex.b * 1.1) {
		tex.rgb = skin_color.rgb * (0.45 + light * 0.65);
	}
	COLOR = tex * actor_tint;
}
