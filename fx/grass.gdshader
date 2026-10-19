shader_type spatial;
render_mode cull_disabled;

// Wild grass clumps: crossed quads shaped into blades by the UV, swaying in the wind (world
// position + time), dark at the root and dry at the tips.
uniform vec3 root_color : source_color = vec3(0.08, 0.12, 0.06);
uniform vec3 tip_color : source_color = vec3(0.5, 0.5, 0.26);
uniform float sway = 0.18;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float bend = UV.y < 0.5 ? 0.0 : 1.0;
	float wave = sin(TIME * 1.6 + world.x * 0.35 + world.z * 0.27) + 0.5 * sin(TIME * 3.1 + world.z * 0.8);
	VERTEX.x += wave * sway * bend * (1.0 - UV.y * 0.0);
	VERTEX.z += wave * sway * 0.5 * bend;
}

void fragment() {
	// Three blades per quad: keep pixels under three narrow triangles.
	float x = fract(UV.x * 3.0) - 0.5;
	float height = 1.0 - UV.y;
	if (abs(x) > (1.0 - height) * 0.42 + 0.02) {
		discard;
	}
	float tip = clamp(height * 1.3, 0.0, 1.0);
	ALBEDO = mix(root_color, tip_color, tip) * (0.85 + COLOR.r * 0.3);
	ROUGHNESS = 0.9;
}
