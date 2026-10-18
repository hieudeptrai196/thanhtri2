class_name ResourceNode
extends StaticBody3D
## A tree, coal deposit, ... Each weapon hit gives one unit to the attacker's inventory until depleted.

## After each unit taken (the host tells clients).
signal gathered(amount_left: int)

@export var resource_type: ResourceType
@export var amount: int = 5
## Noise made by each successful hit (chopping, digging).
@export var noise_per_hit: float = 0.3

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node3D = $Visual


func _ready() -> void:
	_hurtbox.hit_taken.connect(_on_hit_taken)


# Attackers are duck-typed: anything exposing an `inventory` can gather.
func _on_hit_taken(_amount: float, source: Node) -> void:
	if not multiplayer.is_server():
		return
	var inventory: Inventory = source.get("inventory") if source else null
	if inventory == null or inventory.add(resource_type.id, 1) == 0:
		return
	amount -= 1
	get_tree().call_group(&"noise", &"add", noise_per_hit)
	gathered.emit(amount)
	_bump()
	if amount <= 0:
		queue_free()


## Client: the host says how much is left.
func set_net_amount(value: int) -> void:
	if value < amount:
		_bump()
	amount = value
	if amount <= 0:
		queue_free()


func _bump() -> void:
	_visual.scale = Vector3.ONE * 1.12
	create_tween().tween_property(_visual, "scale", Vector3.ONE, 0.12)
