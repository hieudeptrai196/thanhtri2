class_name Projectile
extends Node3D
## A thrown axe, a magic orb or a crossbow bolt. It homes in on its target (so a shot that was
## aimed always lands) or, without one, flies straight to its range — that is how clients show the
## shots the host fires. Damage is dealt on arrival, on the host only; an orb also splashes.

const LOOKS := {
	&"axe": ["res://assets/kaykit2/tools/axe.gltf", 1.4],
	&"bolt": ["res://assets/kaykit2/weapons/arrow_A.gltf", 1.5],
}
## Enemy hurtboxes (layer 3) take splash damage.
const SPLASH_MASK := 4

var kind: StringName = &"bolt"
var speed: float = 22.0
var damage: float = 0.0
var splash_radius: float = 0.0
var source: Node = null
var target: Hurtbox = null
var max_distance: float = 14.0
var direction: Vector3 = Vector3.FORWARD

var _travelled: float = 0.0
var _visual: Node3D


func _ready() -> void:
	if LOOKS.has(kind):
		_visual = load(LOOKS[kind][0]).instantiate()
		_visual.scale = Vector3.ONE * LOOKS[kind][1]
		add_child(_visual)
	else:  # magic orb: a glowing ball with its own light
		var orb := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.85, 0.65, 1.0)
		material.emission_enabled = true
		material.emission = Color(0.7, 0.4, 1.0)
		material.emission_energy_multiplier = 4.0
		sphere.material = material
		orb.mesh = sphere
		add_child(orb)
		_visual = orb
		var light := OmniLight3D.new()
		light.light_color = Color(0.7, 0.45, 1.0)
		light.light_energy = 2.0
		light.omni_range = 5.0
		add_child(light)
	_visual.rotation.y = PI  # kit weapons face +Z
	look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	var goal := _goal()
	var to_goal := goal - global_position
	var step := speed * delta
	if kind == &"axe":
		_visual.rotate_object_local(Vector3.RIGHT, -18.0 * delta)
	if to_goal.length() <= step or _travelled >= max_distance:
		_arrive(goal)
		return
	direction = to_goal.normalized()
	global_position += direction * step
	_travelled += step
	look_at(global_position + direction, Vector3.UP)


func _goal() -> Vector3:
	if target != null and is_instance_valid(target) and target.is_inside_tree():
		return target.global_position + Vector3(0.0, 0.6, 0.0)
	return global_position + direction * maxf(max_distance - _travelled, 0.01)


func _arrive(at: Vector3) -> void:
	Burst.spawn(self, &"magic" if kind == &"orb" else &"spark", at)
	if damage > 0.0 and multiplayer.is_server():
		var hit_target := target != null and is_instance_valid(target) and target.is_inside_tree()
		if hit_target:
			target.take_hit(damage, source)
		if splash_radius > 0.0:
			_splash(at, target if hit_target else null)
	queue_free()


# Half damage to the other enemies around the impact.
func _splash(at: Vector3, already_hit: Hurtbox) -> void:
	var shape := SphereShape3D.new()
	shape.radius = splash_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, at)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = SPLASH_MASK
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var area: Object = hit.collider
		if area is Hurtbox and area != already_hit:
			area.take_hit(damage * 0.5, source)
