class_name ResourceNode
extends StaticBody3D
## A tree, rock, ... Each weapon hit gives one unit to the attacker's inventory until depleted.

@export var resource_type: ResourceType
@export var amount: int = 5

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node3D = $Visual


func _ready() -> void:
	_hurtbox.hit_taken.connect(_on_hit_taken)


# Attackers are duck-typed: anything exposing an `inventory` can gather.
func _on_hit_taken(_amount: float, source: Node) -> void:
	var inventory: Inventory = source.get("inventory") if source else null
	if inventory == null or inventory.add(resource_type.id, 1) == 0:
		return
	amount -= 1
	_visual.scale = Vector3.ONE * 1.12
	create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.12)
	if amount <= 0:
		queue_free()
