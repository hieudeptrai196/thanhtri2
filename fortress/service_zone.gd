class_name ServiceZone
extends Area3D
## Area around the fortress. Players inside drop off everything they carry,
## and repair the fortress while holding interact.

signal deposited(contents: Dictionary)

@onready var _fortress: Fortress = owner


# Players are duck-typed: they may expose `inventory` and `input`.
func _physics_process(delta: float) -> void:
	# The best repairer present sets the pace (a Công binh repairs faster).
	var repair_rate := 0.0
	for body in get_overlapping_bodies():
		var inventory: Inventory = body.get("inventory")
		if inventory and inventory.total() > 0:
			var contents := inventory.take_all()
			_fortress.storage.add_all(contents)
			deposited.emit(contents)
		var input: PlayerInput = body.get("input")
		if input and input.interact_held:
			var multiplier: Variant = body.get("repair_multiplier")
			repair_rate = maxf(repair_rate, multiplier if multiplier != null else 1.0)
	if repair_rate > 0.0:
		_fortress.tick_repair(delta, repair_rate)
