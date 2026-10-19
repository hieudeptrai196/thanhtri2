shader_type spatial;

// World-space ground: soft blotches of the route's two colours (value noise, two octaves) plus a
// fine speckle, so movement stays visible without the old checkerboard look.
uniform vec3 color_a : source_color = vec3(0.24, 0.3, 0.18);
uniform vec3 color_b : source_color = vec3(0.27, 0.22, 0.16);
uniform float cell_size = 5.0;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / (cell_size * 2.4);
	float blotch = noise(p) * 0.65 + noise(p * 2.7 + 17.0) * 0.35;
	vec3 base = mix(color_a, color_b, smoothstep(0.35, 0.65, blotch));
	float speckle = noise(world_pos.xz * 1.7) * 0.5 + noise(world_pos.xz * 5.3) * 0.5;
	ALBEDO = base * (0.9 + speckle * 0.2);
	ROUGHNESS = 0.95;
}
