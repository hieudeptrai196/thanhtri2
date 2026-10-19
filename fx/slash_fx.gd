class_name SlashFx
extends MeshInstance3D
## The swing of a melee weapon: a glowing arc sweeping across the weapon's real arc and reach,
## alternating direction each swing. Purely visual; also shown for other players on clients.

const SWEEP_SECONDS := 0.2
const SEGMENTS := 18

var _material: ShaderMaterial
var _arc: float = -1.0
var _reach: float = -1.0
var _flip: bool = false
var _tween: Tween


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = preload("res://fx/slash.gdshader")
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## Swings toward world yaw `yaw` (radians, Godot forward = -Z) over `arc_degrees` out to `reach` m.
func play(yaw: float, arc_degrees: float, reach: float, color: Color = Color(1.0, 0.88, 0.65)) -> void:
	if not is_equal_approx(arc_degrees, _arc) or not is_equal_approx(reach, _reach):
		_build(arc_degrees, reach)
	global_rotation = Vector3(0.0, yaw, 0.0)
	_flip = not _flip
	_material.set_shader_parameter(&"flip", 1.0 if _flip else 0.0)
	_material.set_shader_parameter(&"tint", color)
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(func(p: float) -> void: _material.set_shader_parameter(&"progress", p), 0.0, 1.0, SWEEP_SECONDS)
	_tween.tween_callback(hide)


# A flat ring sector in front of the body (-Z), slightly tilted so it reads from the iso camera.
func _build(arc_degrees: float, reach: float) -> void:
	_arc = arc_degrees
	_reach = reach
	var inner := reach * 0.35
	var half := deg_to_rad(minf(arc_degrees, 340.0)) * 0.5
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in SEGMENTS:
		var a0 := lerpf(-half, half, float(i) / SEGMENTS)
		var a1 := lerpf(-half, half, float(i + 1) / SEGMENTS)
		var u0 := float(i) / SEGMENTS
		var u1 := float(i + 1) / SEGMENTS
		var corners := [
			[_point(a0, inner), Vector2(u0, 0.0)], [_point(a0, reach), Vector2(u0, 1.0)],
			[_point(a1, reach), Vector2(u1, 1.0)], [_point(a1, inner), Vector2(u1, 0.0)]]
		for index in [0, 1, 2, 0, 2, 3]:
			tool.set_uv(corners[index][1])
			tool.add_vertex(corners[index][0])
	mesh = tool.commit()


static func _point(angle: float, radius: float) -> Vector3:
	return Vector3(sin(angle) * radius, (radius - 1.0) * 0.12, -cos(angle) * radius)
