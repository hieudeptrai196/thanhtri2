shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

// A slash arc: UV.x runs along the arc (0 = where the swing starts), UV.y from the inner to the
// outer edge. `progress` 0 → 1 sweeps a bright head across the arc, leaving a fading trail.
uniform float progress = 0.0;
uniform float flip = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.9, 0.7, 1.0);

void fragment() {
	float u = mix(UV.x, 1.0 - UV.x, flip);
	float head = progress * 1.35;
	float behind = head - u;
	float trail = smoothstep(-0.02, 0.04, behind) * (1.0 - smoothstep(0.0, 0.6, behind));
	float edge = smoothstep(0.05, 0.55, UV.y) * (1.0 - smoothstep(0.9, 1.0, UV.y));
	float fade = 1.0 - smoothstep(0.7, 1.0, progress);
	float core = smoothstep(0.75, 0.95, UV.y) * (1.0 - smoothstep(0.0, 0.25, behind));
	ALBEDO = tint.rgb * (0.6 + 1.8 * UV.y) + vec3(core * 1.5);
	ALPHA = clamp(trail * edge * fade * tint.a, 0.0, 1.0);
}
