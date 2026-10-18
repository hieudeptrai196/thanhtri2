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


func set_color(new_color: Color) -> void:
	color = new_color
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	_mesh.material_override = material


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var inventory: Inventory = body.get("inventory")
		if inventory == null or body.global_position.distance_to(global_position) > MAX_REACH:
			continue
		contents = inventory.add_all(contents)
		if contents.is_empty():
			queue_free()
			return
