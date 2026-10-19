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
	&"wood": ["res://assets/kaykit2/resources/Wood_Log_A.gltf", 0.8, Color.WHITE],
	&"coal": ["res://assets/kaykit2/resources/Stone_Chunks_Small.gltf", 0.7, Color(0.25, 0.24, 0.27)],
	&"bronze": ["res://assets/kaykit2/resources/Copper_Nuggets.gltf", 1.1, Color.WHITE],
}
const MIXED_LOOK := ["res://assets/kaykit2/resources/Parts_Pile_Small.gltf", 0.8, Color.WHITE]


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
