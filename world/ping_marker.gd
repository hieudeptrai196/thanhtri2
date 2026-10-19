class_name PingMarker
extends Node3D
## A mark a player puts on the ground for the team: a ring, a light pillar and a short line saying
## what it means, in the pinging player's colour. Fades out after a few seconds. The HUD points at
## the ones that are off screen (group "pings").

const LIFETIME := 4.0
const FADE_TIME := 0.6

var peer_id: int = 1
## What the ping means, picked by what is at the pinged point (see Match.ping_kind):
## enemy, blueprint, structure, pickup, resource, fortress or ground.
var kind: StringName = &"ground"
## Untranslated name put into the text (a resource or structure name), or "".
var subject: String = ""
var color: Color = Color.WHITE

var _left: float = LIFETIME
var _material: StandardMaterial3D
var _label: Label3D
var _ring: MeshInstance3D


func _ready() -> void:
	add_to_group(&"pings")
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(color, 0.55)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.2
	ring.material = _material
	_ring = _add_mesh(ring, 0.08)
	var pillar := CylinderMesh.new()
	pillar.top_radius = 0.08
	pillar.bottom_radius = 0.08
	pillar.height = 3.0
	pillar.material = _material
	_add_mesh(pillar, 1.5)
	_label = Label3D.new()
	_label.text = text()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.font_size = 56
	_label.pixel_size = 0.012
	_label.outline_size = 14
	_label.modulate = color.lightened(0.3)
	_label.position.y = 3.4
	add_child(_label)


## The line shown on the mark, in this machine's language.
func text() -> String:
	match kind:
		&"enemy":
			return tr("Quái ở đây!")
		&"blueprint":
			return tr("Xây giúp ở đây")
		&"structure":
			return tr("Thu %s này") % tr(subject)
		&"pickup":
			return tr("Đồ rơi ở đây")
		&"resource":
			return tr("Lấy %s ở đây") % tr(subject)
		&"fortress":
			return tr("Về giữ thành!")
	return tr("Đến đây")


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	var alpha := clampf(_left / FADE_TIME, 0.0, 1.0)
	_material.albedo_color.a = 0.55 * alpha
	_label.modulate.a = alpha
	# A slow pulse so the ring catches the eye.
	var pulse := 1.0 + 0.15 * sin((LIFETIME - _left) * 8.0)
	_ring.scale = Vector3(pulse, 1.0, pulse)


func _add_mesh(mesh: Mesh, height: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position.y = height
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance
