extends GameTest
## M2.3d: class combos — two classes together do more than each alone.

const ENGINEER := preload("res://classes/types/engineer.tres")
const WOODCUTTER := preload("res://classes/types/woodcutter.tres")
const SHAMAN := preload("res://classes/types/shaman.tres")
const MECHANIC := preload("res://classes/types/mechanic.tres")
const TURRET := preload("res://structures/types/crossbow_turret.tres")
const BARRICADE := preload("res://structures/types/barricade.tres")


func _field(m: Match) -> Fortress:
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	clear_random_bombs(m)
	return fortress


# A second warrior on this machine stands in for a teammate.
func _teammate(m: Match, player_class: PlayerClass, at: Vector3) -> Warrior:
	var mate: Warrior = m.spawn_player(2, player_class)
	mate.input.remote = true
	mate.global_position = at
	return mate


# Hammers `blueprint` every tick as `hammerer` (purse = its bag) until built or `max_frames` pass.
func _hammer_until_built(blueprint: Structure, hammerer: Warrior, max_frames: int = 600) -> void:
	for i in max_frames:
		if blueprint.built:
			return
		blueprint.add_hammer(hammerer.inventory, hammerer.hammer_multiplier, hammerer)
		await frames(1)


func test_war_cry_in_battle_charm_hexes_monsters() -> void:
	var m: Match = await start_match()
	var fortress := _field(m)
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = fortress.global_position + Vector3(0, 0.1, 30)
	var spawner: Spawner = m.get_node("Spawner")
	var taunted: Enemy = spawner.spawn_one()
	var plain: Enemy = spawner.spawn_one()
	for enemy in [taunted, plain]:
		enemy.damage = 0.0
		enemy.get_node("Health").set_max_health(1e6)
	var spot := fortress.global_position + Vector3(25, 0, 25)
	taunted.global_position = spot + Vector3(1, 0, 0)
	plain.global_position = spot + Vector3(-1, 0, 0)
	taunted.taunt(warrior, 5.0)
	m._show_skill(&"shaman", spot, true)
	await frames(3)
	check(taunted._slow == CharmZone.HEX_SLOW_FACTOR and taunted._slow_left > 0.0, "taunted monster in the charm: much slower")
	check(taunted.get_node("Health").damage_taken_multiplier == CharmZone.HEX_DAMAGE_TAKEN, "and takes more damage")
	check(plain._slow == CharmZone.SLOW_FACTOR, "an untaunted one is only slowed as usual")
	check(plain.get_node("Health").damage_taken_multiplier == 1.0, "and takes normal damage")
	taunted.global_position = spot + Vector3(30, 0, 0)  # out of the charm
	await seconds(0.5)
	check(taunted.get_node("Health").damage_taken_multiplier == 1.0, "the hex wears off outside")


func test_engineer_turret_in_shaman_aura_is_engraved() -> void:
	var m: Match = await start_match()
	var fortress := _field(m)
	fortress.storage.add_all({&"wood": 100})
	var engineer: Warrior = m.get_node("Warrior")
	engineer.apply_class(ENGINEER)
	var network: StructureNetwork = m.get_node("Structures")
	var spot := fortress.global_position + Vector3(25, 0, 25)
	var shaman := _teammate(m, SHAMAN, spot + Vector3(2, 0.1, 0))
	engineer.global_position = spot + Vector3(-2, 0.1, 0)
	await frames(2)
	var turret := network.place_blueprint(TURRET, spot)
	await _hammer_until_built(turret, engineer)
	check(turret.built, "built")
	check_near(turret.engrave_bonus, ENGINEER.engrave_fire_rate, 0.001, "khắc phù")
	await frames(2)
	check_near(turret.fire_rate_bonus, SHAMAN.structure_fire_rate * ENGINEER.engrave_fire_rate, 0.001, "on top of the aura")
	shaman.global_position = spot + Vector3(40, 0.1, 0)
	await frames(2)
	check_near(turret.fire_rate_bonus, ENGINEER.engrave_fire_rate, 0.001, "and keeps it when the Thầy pháp walks away")
	check(turret.get_node_or_null("Rune") != null, "shows a rune")
	var barricade := network.place_blueprint(BARRICADE, spot + Vector3(0, 0, 5))
	shaman.global_position = spot + Vector3(2, 0.1, 5)
	await frames(2)
	await _hammer_until_built(barricade, engineer)
	check(barricade.engrave_bonus == 1.0, "only shooting structures get engraved")


func test_no_engraving_without_both_classes() -> void:
	var m: Match = await start_match()
	var fortress := _field(m)
	fortress.storage.add_all({&"wood": 100})
	var builder: Warrior = m.get_node("Warrior")
	var network: StructureNetwork = m.get_node("Structures")
	var spot := fortress.global_position + Vector3(25, 0, 25)
	_teammate(m, SHAMAN, spot + Vector3(2, 0.1, 0))
	builder.global_position = spot + Vector3(-2, 0.1, 0)
	await frames(2)
	var by_plain := network.place_blueprint(TURRET, spot)
	await _hammer_until_built(by_plain, builder)
	check(by_plain.built and by_plain.engrave_bonus == 1.0, "no Công binh: no engraving")
	builder.apply_class(ENGINEER)
	m.player_by_peer(2).global_position = spot + Vector3(40, 0.1, 0)
	var no_aura := network.place_blueprint(TURRET, spot + Vector3(0, 0, -6))
	await frames(2)
	await _hammer_until_built(no_aura, builder)
	check(no_aura.built and no_aura.engrave_bonus == 1.0, "no Thầy pháp near: no engraving")


func test_hammering_next_to_a_woodcutter_uses_their_bag() -> void:
	var m: Match = await start_match()
	var fortress := _field(m)
	var warrior: Warrior = m.get_node("Warrior")
	var spot := fortress.global_position + Vector3(25, 0, 25)
	warrior.global_position = spot + Vector3(-1.5, 0.1, 0)
	var woodcutter := _teammate(m, WOODCUTTER, spot + Vector3(-1.5, 0.1, 2.5))
	await frames(2)
	woodcutter.inventory.add(&"wood", 30)
	var network: StructureNetwork = m.get_node("Structures")
	var barricade := network.place_blueprint(BARRICADE, spot)
	Input.action_press(&"interact")
	await wait_until(func() -> bool: return barricade.built, 600)
	Input.action_release(&"interact")
	check(barricade.built, "built with an empty storage, from the Tiều phu's bag")
	check(woodcutter.inventory.get_amount(&"wood") == 30 - BARRICADE.cost[&"wood"], "paid exactly from the bag")
	check(fortress.storage.get_amount(&"wood") == 0, "storage untouched")

	woodcutter.global_position = spot + Vector3(-1.5, 0.1, 12)  # too far to share
	await frames(2)
	var far := network.place_blueprint(BARRICADE, spot + Vector3(0, 0, -4))
	warrior.global_position = far.global_position + Vector3(-1.5, 0.1, 0)
	await frames(2)
	Input.action_press(&"interact")
	await seconds(1.0)
	Input.action_release(&"interact")
	check(not far.built and far.starved, "a Tiều phu too far away does not pay")


func test_engineer_gets_more_from_a_woodcutters_bag() -> void:
	var m: Match = await start_match()
	var fortress := _field(m)
	var warrior: Warrior = m.get_node("Warrior")
	warrior.apply_class(ENGINEER)
	var spot := fortress.global_position + Vector3(25, 0, 25)
	warrior.global_position = spot + Vector3(-1.5, 0.1, 0)
	var woodcutter := _teammate(m, WOODCUTTER, spot + Vector3(-1.5, 0.1, 2.5))
	await frames(2)
	woodcutter.inventory.add(&"wood", 30)
	var turret := (m.get_node("Structures") as StructureNetwork).place_blueprint(TURRET, spot)
	Input.action_press(&"interact")
	await wait_until(func() -> bool: return turret.built, 900)
	Input.action_release(&"interact")
	var cost: int = TURRET.cost[&"wood"]
	var spent := 30 - woodcutter.inventory.get_amount(&"wood")
	check(turret.built, "built")
	check(spent == ceili(cost / ENGINEER.shared_bag_value), "each shared unit counts 1.5 (%d spent for %d)" % [spent, cost])
	check(turret.paid[&"wood"] == spent, "only what was spent is refundable")


func test_stoked_boiler_speeds_up_a_manned_crossbow() -> void:
	var m: Match = await start_match()
	var fortress := _field(m)
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = fortress.ladder_point()
	await frames(2)
	check(fortress.try_man_crossbow(warrior), "manned")
	var interval := fortress.crossbow.interval
	var reach := fortress.crossbow.range_radius
	fortress.free_overdrive_left = 3.0
	await frames(2)
	check_near(fortress.crossbow.interval, interval / fortress.stoked_gunner_rate, 0.001, "fires faster during Đốt lò")
	check_near(fortress.crossbow.range_radius, reach, 0.001, "same range for a non-Thợ máy gunner")
	fortress.release_gunner()
	warrior.apply_class(MECHANIC)
	await frames(2)
	check(fortress.try_man_crossbow(warrior), "manned by the Thợ máy")
	check_near(fortress.crossbow.range_radius, reach * MECHANIC.stoked_gunner_range, 0.001, "a Thợ máy gunner also shoots farther")
	fortress.free_overdrive_left = 0.0
	await frames(2)
	check_near(fortress.crossbow.interval, interval, 0.001, "back to normal when Đốt lò ends")
	check_near(fortress.crossbow.range_radius, reach, 0.001, "range too")


func test_client_sees_the_rune() -> void:
	var matches := await start_net_match(1, 1, 24850)
	var host: Match = matches[0]
	var client: Match = matches[1]
	var fortress: Fortress = host.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var turret := (host.get_node("Structures") as StructureNetwork).place(TURRET, fortress.global_position + Vector3(25, 0, 25))
	turret.engrave(1.25)
	var client_network: StructureNetwork = client.get_node("Structures")
	var seen := await wait_until(func() -> bool:
		return client_network.structures().any(func(s: Structure) -> bool: return s.engrave_bonus == 1.25), 120)
	check(seen, "the client's copy is engraved too")
