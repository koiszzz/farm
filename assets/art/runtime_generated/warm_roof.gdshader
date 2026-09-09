shader_type canvas_item;
// Preserve the facade and glass; remap only the slate-blue roof pixels.
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	bool dormer_glass = UV.x > 0.24 && UV.x < 0.285 && UV.y > 0.18 && UV.y < 0.227;
	if (UV.x < 0.5 && UV.y < 0.33 && !dormer_glass && texel.b > texel.r * 1.12 && texel.g > texel.r * 1.04) {
		float value = dot(texel.rgb, vec3(0.22, 0.58, 0.20));
		texel.rgb = vec3(value * 1.65, value * 0.70, value * 0.32);
	}
	COLOR = texel;
}
