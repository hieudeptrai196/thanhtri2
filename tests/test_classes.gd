extends GameTest
## M2.2a: classes as roles — passive strengths, picking, and co-op sync.

const ENGINEER := preload("res://classes/types/engineer.tres")
const WOODCUTTER := preload("res://classes/types/woodcutter.tres")
const GENERAL := preload("res://classes/types/general.tres")
const SHAMAN := preload("res://classes/types/shaman.tres")
const MECHANIC := preload("res://classes/types/mechanic.tres")


func test_no_class_keeps_plain_stats() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	check(warrior.player_class == null, "tests start without a class")
	check(warrior.carry_capacity == 1 and warrior.hammer_multiplier == 1.0, "plain stats")


func test_general_is_tougher_and_hits_harder() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	var health := warrior.health.max_health
	var damage := warrior.weapon.damage
	warrior.apply_class(GENERAL)
	check_near(warrior.health.max_health, health * GENERAL.max_health_multiplier, 0.01, "more health")
	check(warrior.health.current == warrior.health.max_health, "starts full")
	check_near(warrior.weapon.damage, damage * GENERAL.damage_multiplier, 0.01, "more damage")
	warrior.apply_class(null)
	check_near(warrior.weapon.damage, damage, 0.01, "dropping the class restores the stats (no compounding)")


func test_woodcutter_carries_more_and_runs_faster_empty() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	var capacity := warrior.inventory.capacity
	warrior.apply_class(WOODCUTTER)
	check(warrior.inventory.capacity == roundi(capacity * 2.0), "double pack")
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	warrior.global_position = fortress.global_position + Vector3(20, 0.1, 20)
	await frames(2)
	var start := warrior.global_position
	Input.action_press(&"move_right")
	await seconds(1.0)
	Input.action_release(&"move_right")
	var empty_speed := warrior.global_position.distance_to(start)
	check(empty_speed > warrior.move_speed * 1.1, "faster than a plain warrior with an empty pack (%.2f m/s)" % empty_speed)


func test_engineer_builds_faster_and_carries_two() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	warrior.apply_class(ENGINEER)
	check(warrior.carry_capacity == 2, "carries two structures")
	var type := StructureTypes.ALL[0]
	warrior.carry(type, 50.0)
	check(warrior.can_carry_more(), "room for a second one")
	warrior.carry(type, 40.0)
	check(not warrior.can_carry_more() and warrior.carried_count() == 2, "full with two")
	warrior.clear_carried()
	check(warrior.carried_type == type and warrior.carried_health == 50.0, "the first one comes up after placing the second")
	warrior.clear_carried()
	check(warrior.carried_type == null, "hands free")

	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"wood": 100})
	var structures: StructureNetwork = m.get_node("Structures")
	var plain := structures.place_blueprint(type, fortress.global_transform * Vector3(14, 0, 0))
	var fast := structures.place_blueprint(type, fortress.global_transform * Vector3(-14, 0, 0))
	var purse := Inventory.new()
	for i in 30:
		plain.add_hammer(purse, 1.0)
		fast.add_hammer(purse, warrior.hammer_multiplier)
		await frames(1)
	check(fast.build_progress > plain.build_progress * 1.3, "a Công binh's hammer counts for more (%.2f vs %.2f)" % [fast.build_progress, plain.build_progress])
	purse.free()


func test_mechanic_makes_team_upgrades_cheaper() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var upgrade: FortressUpgrade = FortressUpgrades.ALL[0]
	var full := fortress.next_upgrade_cost(upgrade)
	m.get_node("Warrior").apply_class(MECHANIC)
	m._update_team_bonuses()
	var cheaper := fortress.next_upgrade_cost(upgrade)
	for id in full:
		check(cheaper[id] <= full[id], "%s not dearer" % id)
	check(cheaper != full, "at least one price drops")
	check(fortress.overdrive_fuel_multiplier < 1.0, "overdrive burns less coal")


func test_shaman_speeds_up_nearby_structures() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var structures: StructureNetwork = m.get_node("Structures")
	var near := structures.place(StructureTypes.ALL[0], fortress.global_transform * Vector3(14, 0, 0))
	var far := structures.place(StructureTypes.ALL[0], fortress.global_transform * Vector3(-14, 0, 0))
	warrior.apply_class(SHAMAN)
	warrior.global_position = near.global_position + Vector3(2, 0.1, 0)
	await frames(3)
	check(near.fire_rate_bonus == SHAMAN.structure_fire_rate, "structure near the Thầy pháp fires faster")
	check(far.fire_rate_bonus == 1.0, "far one does not")


func test_picked_class_is_remembered_and_used() -> void:
	PlayerClasses.choose(WOODCUTTER)
	var m := await start_match()
	check(m.get_node("Warrior").player_class == WOODCUTTER, "the run uses the picked class")
	var menu: StartMenu = m.get_node("UI/StartMenu")
	menu.open()
	menu._class_cards[GENERAL].pressed.emit()
	check(PlayerClasses.chosen() == GENERAL, "picking on the menu saves it")


func test_clients_class_reaches_everyone() -> void:
	PlayerClasses.choose(SHAMAN)  # both machines share the save in tests: host and client are Thầy pháp
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var client_id := client.multiplayer.get_unique_id()
	check(host.player_by_peer(client_id).player_class == SHAMAN, "host knows the client's class")
	check(await wait_until(func() -> bool: return client.player_by_peer(1) != null and client.player_by_peer(1).player_class == SHAMAN),
		"client sees the host's class")
