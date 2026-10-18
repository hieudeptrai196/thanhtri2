extends Node3D
## Placeholder explosion: a flash sphere that grows and fades, then frees itself.

@export var max_scale: float = 6.0
@export var duration: float = 0.5

@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	var material: StandardMaterial3D = _mesh.mesh.material
	var tween := create_tween().set_parallel()
	tween.tween_property(_mesh, "scale", Vector3.ONE * max_scale, duration).from(Vector3.ONE)
	tween.tween_property(material, "albedo_color:a", 0.0, duration).from(0.85)
	tween.chain().tween_callback(queue_free)
