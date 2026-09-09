shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	vec2 step_uv = TEXTURE_PIXEL_SIZE * 4.0;
	float inner = min(min(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
		min(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a,
		texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a));
	COLOR = vec4(mix(vec3(0.30, 0.71, 0.74), vec3(1.0, 0.94, 0.65), 1.0 - inner),
		alpha * mix(0.48, 0.95, 1.0 - inner));
}
