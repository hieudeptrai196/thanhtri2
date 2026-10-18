class_name ClassSkills
extends Node
## The warrior's active class skill (R / LT), run on the host. Which effect fires is chosen by the
## class id; its numbers (cooldown, duration, radius, power) come from the PlayerClass. A skill that
## would do nothing (no blueprint, tree or deposit in reach…) is not spent.
## Effects that need the rest of the world (the Bùa trận area, visuals for clients) are left to the
## match through `used`.

signal used(skill_id: StringName, at: Vector3)

## Set by the match (Thợ máy's Đốt lò).
var fortress: Fortress
var cooldown_left: float = 0.0
# Seconds left of the Võ tướng's reduced damage.
var _guard_left: float = 0.0

@onready var _warrior: Warrior = get_parent()


func _physics_process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if _guard_left > 0.0:
		_guard_left -= delta
		if _guard_left <= 0.0:
			_warrior.health.damage_taken_multiplier = 1.0


## 0 = just used, 1 = ready.
func ready_fraction() -> float:
	var c := _warrior.player_class
	return 1.0 if c == null or c.skill_cooldown <= 0.0 else 1.0 - cooldown_left / c.skill_cooldown


func try_use() -> bool:
	var c := _warrior.player_class
	if c == null or cooldown_left > 0.0 or not _warrior.is_alive or not multiplayer.is_server():
		return false
	var at := _warrior.global_position
	var done := false
	match c.id:
		&"engineer":
			done = _rapid_build(c)
		&"woodcutter":
			done = _heavy_chop(c)
		&"general":
			done = _war_cry(c)
		&"shaman":
			at = _charm_point(c)
			done = true
		&"mechanic":
			done = _stoke_boiler(c)
	if done:
		cooldown_left = c.skill_cooldown
		used.emit(c.id, at)
	return done


# Công binh — Dựng tốc: blueprints around build faster for a while.
func _rapid_build(c: PlayerClass) -> bool:
	var network := _warrior.builder.network
	var boosted := false
	if network:
		for structure in network.structures():
			if not structure.built and structure.global_position.distance_to(_warrior.global_position) <= c.skill_radius:
				structure.boost_build(c.skill_power, c.skill_duration)
				boosted = true
	return boosted


# Tiều phu — Bổ mạnh: one strike takes several units from the tree / deposit in front.
func _heavy_chop(c: PlayerClass) -> bool:
	var best: ResourceNode = null
	var best_score := -INF
	for node: ResourceNode in get_tree().get_nodes_in_group(&"resource_nodes"):
		if node.is_queued_for_deletion() or node.amount <= 0 or not _same_world(node):
			continue
		var offset := node.global_position - _warrior.global_position
		offset.y = 0.0
		if offset.length() > c.skill_radius:
			continue
		var score := offset.normalized().dot(_warrior.input.aim_direction) - offset.length() * 0.2
		if score > best_score:
			best = node
			best_score = score
	if best == null:
		return false
	var before := best.amount
	best.gather(_warrior, roundi(c.skill_power))
	return best.amount < before


# Võ tướng — Hét trận: monsters around turn on the warrior, who takes less damage meanwhile.
func _war_cry(c: PlayerClass) -> bool:
	for enemy: Enemy in get_tree().get_nodes_in_group(&"enemies"):
		if _same_world(enemy) and enemy.global_position.distance_to(_warrior.global_position) <= c.skill_radius:
			enemy.taunt(_warrior, c.skill_duration)
	_warrior.health.damage_taken_multiplier = c.skill_power
	_guard_left = c.skill_duration
	return true


# Thầy pháp — Bùa trận: where the area goes (the aim point, within the warrior's build range).
func _charm_point(_c: PlayerClass) -> Vector3:
	var offset := _warrior.input.aim_point - _warrior.global_position
	offset.y = 0.0
	return _warrior.global_position + offset.limit_length(_warrior.builder.build_range)


# Groups span the whole SceneTree; in-process co-op tests run two worlds in one tree.
func _same_world(node: Node3D) -> bool:
	return node.get_world_3d() == _warrior.get_world_3d()


# Thợ máy — Đốt lò: overdrive speed for a while without the extra coal.
func _stoke_boiler(c: PlayerClass) -> bool:
	if fortress == null or fortress.follower.is_stopped:
		return false
	fortress.free_overdrive_left = c.skill_duration
	return true
