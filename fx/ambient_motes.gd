class_name AmbientMotes
extends Node3D
## Night air around the camera's target: ash drifting down, a few embers rising, fireflies
## wandering. Follows `target` so the effect is always on screen and costs the same anywhere.

var target: Node3D


func _ready() -> void:
	_add(&"ash", 90, 9.0, Vector3(0, -0.6, 0), Color(0.6, 0.58, 0.55, 0.4), 0.025, false)
	_add(&"ember", 16, 5.0, Vector3(0, 1.2, 0), Color(1.0, 0.5, 0.15, 0.9), 0.03, true)
	_add(&"firefly", 18, 6.0, Vector3.ZERO, Color(0.75, 1.0, 0.4, 0.9), 0.04, true)


func _process(_delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = target.global_position


func _add(kind: StringName, amount: int, lifetime: float, gravity: Vector3, color: Color, size: float, glowing: bool) -> void:
	var particles := CPUParticles3D.new()
	particles.name = String(kind)
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(22.0, 4.0, 22.0)
	particles.position.y = 4.0
	particles.gravity = gravity
	particles.direction = Vector3(1, 0.2, 0.3)
	particles.spread = 180.0
	particles.initial_velocity_min = 0.1
	particles.initial_velocity_max = 0.6 if kind != &"firefly" else 0.3
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size * 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color, 0.0))
	ramp.add_point(0.2, color)
	ramp.add_point(0.8, color)
	ramp.set_color(1, Color(color, 0.0))
	particles.color_ramp = ramp
	particles.mesh = Burst._quad(glowing)
	particles.local_coords = false
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	if kind == &"firefly":
		# Fireflies blink: scale pulses along their life.
		var curve := Curve.new()
		for i in 9:
			curve.add_point(Vector2(i / 8.0, 0.2 if i % 2 == 0 else 1.0))
		particles.scale_amount_curve = curve
