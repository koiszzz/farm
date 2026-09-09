shader_type canvas_item;

uniform float blackness : hint_range(0.0, 1.0) = 0.0;
uniform float reveal_radius : hint_range(-0.1, 1.5) = -0.1;
uniform float feather : hint_range(0.001, 0.2) = 0.045;
uniform vec2 reveal_center = vec2(0.5, 0.5);

void fragment() {
	vec2 delta = UV - reveal_center;
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	delta.x *= aspect;
	float distance_from_light = length(delta);
	float outside_light = smoothstep(reveal_radius - feather, reveal_radius + feather, distance_from_light);
	COLOR = vec4(0.0, 0.0, 0.0, blackness * outside_light);
}
