class_name HiddenBomb
extends Area3D
## Invisible bomb on the route. Explodes once when the fortress's Hurtbox rolls over it;
## the collision mask limits triggering to the fortress.

signal exploded(at: Vector3)

@export var damage: float = 80.0

@onready var _blast: MeshInstance3D = $Blast

var _spent: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	if _spent or not area is Hurtbox:
		return
	_spent = true
	area.take_hit(damage, self)
	exploded.emit(global_position)
	_play_blast()


# Placeholder blast: a flash sphere that grows and fades, then the bomb is gone.
func _play_blast() -> void:
	_blast.visible = true
	var material: StandardMaterial3D = _blast.mesh.material
	var tween := create_tween().set_parallel()
	# Grows past the fortress footprint so the blast is visible around the body that hides it.
	tween.tween_property(_blast, "scale", Vector3.ONE * 10.0, 0.6).from(Vector3.ONE * 2.0)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.6).from(0.85)
	tween.chain().tween_callback(queue_free)
