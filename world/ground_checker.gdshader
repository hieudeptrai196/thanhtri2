shader_type spatial;

// World-space checkerboard so movement is visible on a flat placeholder ground.
uniform vec3 color_a : source_color = vec3(0.32, 0.45, 0.25);
uniform vec3 color_b : source_color = vec3(0.28, 0.40, 0.22);
uniform float cell_size = 5.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 cell = floor(world_pos.xz / cell_size);
	ALBEDO = mix(color_a, color_b, mod(cell.x + cell.y, 2.0));
}
