class_name Burst
extends RefCounted
## One-shot particle bursts and rings (sparks on hits, bone dust when an enemy falls, wood chips,
## shock rings). CPU particles so they also run on the Mobile renderer; each kind is capped so a big
## fight stays cheap. `spawn` puts the effect in `context`'s 3D world.

## kind -> [amount, lifetime s, speed range, gravity, size, colour start, colour end, cap]
const KINDS := {
	&"spark": [12, 0.35, Vector2(3.0, 7.0), 9.0, 0.09, Color(1.0, 0.92, 0.6), Color(1.0, 0.4, 0.1, 0.0), 16],
	&"bone": [14, 0.6, Vector2(2.0, 5.0), 12.0, 0.1, Color(0.85, 0.82, 0.74), Color(0.5, 0.48, 0.44, 0.0), 10],
	&"chips": [8, 0.5, Vector2(2.5, 5.0), 14.0, 0.09, Color(0.62, 0.42, 0.22), Color(0.4, 0.26, 0.12, 0.0), 8],
	&"dust": [16, 0.7, Vector2(1.0, 3.0), -0.5, 0.35, Color(0.55, 0.48, 0.38, 0.45), Color(0.4, 0.36, 0.3, 0.0), 8],
	&"magic": [18, 0.5, Vector2(2.0, 6.0), 0.0, 0.12, Color(0.85, 0.6, 1.0), Color(0.4, 0.2, 1.0, 0.0), 10],
}

## Kinds that glow (added light) rather than block light (dust, bone, chips).
const GLOWING: Array[StringName] = [&"spark", &"magic"]

static var _alive: Dictionary = {}
static var _meshes: Dictionary = {}


static func spawn(context: Node, kind: StringName, at: Vector3) -> void:
	if context == null or not context.is_inside_tree() or not KINDS.has(kind):
		return
	var spec: Array = KINDS[kind]
	if _alive.get(kind, 0) >= spec[7]:
		return
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = spec[0]
	particles.lifetime = spec[1]
	particles.direction = Vector3.UP
	particles.spread = 80.0
	particles.initial_velocity_min = spec[2].x
	particles.initial_velocity_max = spec[2].y
	particles.gravity = Vector3(0.0, -spec[3], 0.0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, spec[5])
	ramp.set_color(1, spec[6])
	particles.color_ramp = ramp
	particles.mesh = quad(GLOWING.has(kind), spec[4])
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_track(particles, kind)
	context.get_viewport().add_child(particles)
	particles.global_position = at
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


## An expanding flat ring on the ground (a hammer smash, a war cry).
static func ring(context: Node, at: Vector3, radius: float, color: Color = Color(1.0, 0.85, 0.55)) -> void:
	if context == null or not context.is_inside_tree() or _alive.get(&"ring", 0) >= 6:
		return
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 32
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = color
	torus.material = material
	mesh.mesh = torus
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_track(mesh, &"ring")
	context.get_viewport().add_child(mesh)
	mesh.global_position = at + Vector3(0.0, 0.1, 0.0)
	mesh.scale = Vector3(0.3, 0.2, 0.3)
	var tween := mesh.create_tween().set_parallel()
	tween.tween_property(mesh, "scale", Vector3(radius, 0.2, radius), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(mesh.queue_free)


static func _track(node: Node, kind: StringName) -> void:
	_alive[kind] = _alive.get(kind, 0) + 1
	node.tree_exiting.connect(func() -> void: _alive[kind] = maxi(_alive.get(kind, 1) - 1, 0))


## A soft round billboard `size` metres wide (radial gradient), shared per glow/size; colour comes
## from the particle ramp. Glowing kinds add light, the others blend normally. The size lives in the
## mesh because billboarded particles do not shrink a unit quad reliably.
static func quad(glowing: bool, size: float) -> QuadMesh:
	var key := [glowing, snappedf(size, 0.005)]
	if not _meshes.has(key):
		var dot := GradientTexture2D.new()
		dot.fill = GradientTexture2D.FILL_RADIAL
		dot.fill_from = Vector2(0.5, 0.5)
		dot.fill_to = Vector2(1.0, 0.5)
		var falloff := Gradient.new()
		falloff.set_color(0, Color(1, 1, 1, 1))
		falloff.set_color(1, Color(1, 1, 1, 0))
		falloff.add_point(0.45, Color(1, 1, 1, 0.7))
		dot.gradient = falloff
		dot.width = 64
		dot.height = 64
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if glowing else BaseMaterial3D.BLEND_MODE_MIX
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.vertex_color_use_as_albedo = true
		material.albedo_texture = dot
		var mesh := QuadMesh.new()
		mesh.size = Vector2(size, size)
		mesh.material = material
		_meshes[key] = mesh
	return _meshes[key]
