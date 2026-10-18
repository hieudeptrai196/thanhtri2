class_name DivineCrossbow
extends Area3D
## "Nỏ thần": the fortress's ultimate. The whole team charges it (kills, deposits, finished
## structures); when full, any player fires a volley that hits every enemy around the fortress.
## The area's shape sets the reach; its collision mask decides what it hits.

signal charge_changed(charge: float, maximum: float)
signal fired(hit_count: int)

const BLAST_SCENE := preload("res://world/blast_fx.tscn")

@export var max_charge: float = 100.0
@export var damage: float = 80.0
@export var noise: float = 10.0
@export var charge_per_kill: float = 3.0
@export var charge_per_deposited_unit: float = 1.0
@export var charge_per_structure_built: float = 5.0

var charge: float = 0.0


func add_charge(amount: float) -> void:
	if amount <= 0.0 or charge >= max_charge:
		return
	charge = minf(charge + amount, max_charge)
	charge_changed.emit(charge, max_charge)


func is_ready() -> bool:
	return charge >= max_charge


## Fires if fully charged; returns how many enemies were hit (-1 when not ready).
func fire() -> int:
	if not is_ready():
		return -1
	var hits := 0
	for area in get_overlapping_areas():
		if area is Hurtbox:
			area.take_hit(damage, owner)
			hits += 1
	charge = 0.0
	charge_changed.emit(charge, max_charge)
	get_tree().call_group(&"noise", &"add", noise)
	var blast: Node3D = BLAST_SCENE.instantiate()
	blast.max_scale = 25.0
	owner.get_parent().add_child(blast)  # in the world, not on the moving fortress
	blast.global_position = global_position
	fired.emit(hits)
	return hits
