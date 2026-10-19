class_name Pickup
extends Area3D
## Loose resources on the ground. A living player walking over it takes as much as fits.

## Bodies farther than this are ignored even if physics reports an overlap: with Jolt, a body
## that died on the pile and respawned elsewhere is briefly still reported as overlapping.
const MAX_REACH: float = 2.0

var contents: Dictionary = {}
## Identifies this pile between host and clients (given by the host's match).
var net_id: int = 0
var color: Color = Color.WHITE

@onready var _mesh: MeshInstance3D = $Mesh


## Model per resource (the pile's colour tells which, also on clients); mixed piles get a sack.
const LOOKS := {
	&"wood": ["res://assets/kaykit/medieval/resource_lumber.gltf", 1.3, Color.WHITE],
	&"coal": ["res://assets/kaykit/medieval/resource_stone.gltf", 1.6, Color(0.3, 0.28, 0.32)],
	&"bronze": ["res://assets/kaykit/medieval/crate_A_small.gltf", 4.0, Color(1.0, 0.75, 0.4)],
}
const MIXED_LOOK := ["res://assets/kaykit/medieval/sack.gltf", 5.0, Color.WHITE]


func set_color(new_color: Color) -> void:
	color = new_color
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	_mesh.material_override = material
	var look: Array = MIXED_LOOK
	for type in ResourceTypes.ALL:
		if type.color.is_equal_approx(color) and LOOKS.has(type.id):
			look = LOOKS[type.id]
	var model: Node3D = load(look[0]).instantiate()
	model.scale = Vector3.ONE * look[1]
	if look[2] != Color.WHITE:
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var tinted := mesh.get_active_material(0).duplicate() as StandardMaterial3D
			tinted.albedo_color = look[2]
			mesh.material_override = tinted
	add_child(model)
	_mesh.visible = false


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var inventory: Inventory = body.get("inventory")
		if inventory == null or body.global_position.distance_to(global_position) > MAX_REACH:
			continue
		contents = inventory.add_all(contents)
		if contents.is_empty():
			queue_free()
			return
