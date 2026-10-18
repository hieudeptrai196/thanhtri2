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
	add_to_group(&"resource_nodes")
	_hurtbox.hit_taken.connect(_on_hit_taken)


# Attackers are duck-typed: anything exposing an `inventory` can gather.
func _on_hit_taken(_amount: float, source: Node) -> void:
	gather(source, 1)


## Gives up to `count` units to `source`'s inventory (a Tiều phu's Bổ mạnh takes several). Host only.
func gather(source: Node, count: int) -> void:
	if not multiplayer.is_server() or amount <= 0:
		return
	var inventory: Inventory = source.get("inventory") if source else null
	if inventory == null:
		return
	var taken := inventory.add(resource_type.id, mini(count, amount))
	if taken == 0:
		return
	amount -= taken
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
