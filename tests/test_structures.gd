extends GameTest

const TURRET := preload("res://structures/types/crossbow_turret.tres")
const BARRICADE := preload("res://structures/types/barricade.tres")


## A parked run with the warrior standing off the road near the start (no trees before 30 m).
func _setup() -> Node:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	m.get_node("Warrior").global_position = Vector3(14, 0.1, -10)
	await frames(2)
	return m


func test_run_starts_with_wood_in_storage() -> void:
	var m := await start_match(1, false, true)
	check(m.get_node("Fortress").storage.get_amount(&"wood") == 30, "storage starts with 30 wood")


func test_placing_costs_wood_and_obeys_rules() -> void:
	var m := await _setup()
	var warrior: Warrior = m.get_node("Warrior")
	var storage: Inventory = m.get_node("Fortress").storage
	var network: StructureNetwork = m.get_node("Structures")
	check(not m.request_place(TURRET, Vector3(17, 0, -10), warrior), "cannot build without wood")

	storage.add(&"wood", 20)
	check(m.request_place(TURRET, Vector3(17, 0, -10), warrior), "turret placed off the road")
	check(storage.get_amount(&"wood") == 5, "turret costs 15 wood")
	check(network.structures().size() == 1, "one structure in the network")
	await frames(2)
	check(not m.request_place(BARRICADE, Vector3(17.5, 0, -10), warrior), "cannot overlap another structure")
	check(not m.request_place(BARRICADE, Vector3(2, 0, -10), warrior), "cannot build on the road")
	check(not m.request_place(BARRICADE, Vector3(30, 0, -10), warrior), "cannot build out of reach")
	check(storage.get_amount(&"wood") == 5, "failed placements cost nothing")
	check(m.request_place(BARRICADE, Vector3(14, 0, -15), warrior), "barricade placed")
	check(storage.get_amount(&"wood") == 0, "barricade costs 5 wood")


func test_supply_near_fortress_and_buffer_away_from_it() -> void:
	var m := await _setup()
	var network: StructureNetwork = m.get_node("Structures")
	var near := network.place(TURRET, Vector3(10, 0, -3))
	var far := network.place(TURRET, Vector3(18, 0, -14))
	check(network.check_placement(TURRET, Vector3(10, 0, -3.5)) != StructureNetwork.Placement.UNPOWERED, "near spot is in service")
	check(network.check_placement(TURRET, Vector3(19, 0, -16)) == StructureNetwork.Placement.UNPOWERED, "far spot is unpowered")
	await seconds(2.0)
	check(near.powered and near.buffer == near.buffer_seconds, "near turret stays full")
	check(not far.powered, "far turret is not supplied")
	check_near(far.buffer, far.buffer_seconds - 2.0, 0.1, "far turret drains its buffer")


func test_turret_shoots_then_overloads_and_explodes() -> void:
	var m := await _setup()
	m.get_node("Warrior").global_position = Vector3(-60, 0.1, 30)
	var network: StructureNetwork = m.get_node("Structures")
	var turret: CrossbowTurret = network.place(TURRET, Vector3(20, 0, -20))
	var blast_damage := turret.blast_damage  # the turret frees itself when it explodes
	var overload_time := turret.last_shot_duration
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = Vector3(30, 0, -20)
	await seconds(2.5)
	check(not is_instance_valid(enemy) or enemy.get_node("Health").current < enemy.get_node("Health").max_health, "turret shoots enemies")

	turret.buffer = 0.3
	await seconds(0.5)
	check(turret.is_overloading(), "an empty buffer starts the last shot")
	check(not turret.can_recover(), "an overloading turret cannot be recovered")
	var victim: Enemy = m.get_node("Spawner").spawn_one()
	victim.global_position = turret.global_position + Vector3(3, 0, 0)
	victim.apply_scaling(10.0, 1.0)  # tough enough to survive the shots and feel the blast
	await seconds(overload_time)
	check(not is_instance_valid(turret), "the turret explodes after its last shot")
	check(is_instance_valid(victim) and victim.get_node("Health").current < victim.get_node("Health").max_health - blast_damage + 0.1,
		"the blast hurts enemies nearby")


func test_barricade_lures_enemies_away_from_fortress() -> void:
	var m := await _setup()
	m.get_node("Warrior").global_position = Vector3(-60, 0.1, 30)
	var fortress: Fortress = m.get_node("Fortress")
	var barricade: Structure = m.get_node("Structures").place(BARRICADE, Vector3(14, 0, -22))
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = Vector3(18, 0, -28)
	await seconds(5.0)
	check(barricade.health.current < barricade.health.max_health, "enemy attacks the barricade")
	check(fortress.health.current == fortress.health.max_health, "fortress left alone")


func test_recover_carry_and_place_again_for_free() -> void:
	var m := await _setup()
	var warrior: Warrior = m.get_node("Warrior")
	var storage: Inventory = m.get_node("Fortress").storage
	var network: StructureNetwork = m.get_node("Structures")
	var turret := network.place(TURRET, Vector3(16, 0, -10))
	turret.health.apply_damage(40.0)
	var barricade := network.place(BARRICADE, Vector3(14, 0, -6))
	check(not barricade.can_recover(), "barricades cannot be recovered")

	Input.action_press(&"recover")
	await seconds(0.5)
	check(is_instance_valid(turret), "recovering needs a held button")
	await seconds(0.7)
	Input.action_release(&"recover")
	check(not is_instance_valid(turret), "turret folded away")
	check(warrior.carried_type == TURRET, "warrior carries the turret")

	var dummy := spawn_dummy(m, warrior.global_position + Vector3(-1.5, 0, 0))
	var start := warrior.global_position
	Input.action_press(&"move_up")
	await seconds(1.0)
	Input.action_release(&"move_up")
	var moved := warrior.global_position - start
	moved.y = 0.0
	check_near(moved.length(), warrior.carry_speed, 0.4, "carrying slows the warrior (m in 1 s)")
	check(dummy.get_node("Health").current == 50.0, "no attacks while carrying")

	check(storage.total() == 0, "storage is empty")
	var spot := warrior.global_position + Vector3(3, 0, 0)
	check(m.request_place(TURRET, spot, warrior), "carried turret placed again")
	check(warrior.carried_type == null, "hands free after placing")
	var placed: Structure = network.structures().filter(func(s: Structure) -> bool: return s.type == TURRET)[0]
	check(placed.health.current == 80.0, "it keeps its damage, got %.0f" % placed.health.current)


func test_fallen_warrior_drops_carried_turret() -> void:
	var m := await _setup()
	var warrior: Warrior = m.get_node("Warrior")
	var network: StructureNetwork = m.get_node("Structures")
	warrior.carry(TURRET, 100.0)
	var at := warrior.global_position
	warrior.health.apply_damage(1000.0)
	await frames(2)
	check(warrior.carried_type == null, "nothing carried after falling")
	check(network.structures().size() == 1, "the turret is left on the ground")
	if network.structures().size() == 1:
		var dropped := network.structures()[0]
		check(Vector2(dropped.global_position.x - at.x, dropped.global_position.z - at.z).length() < 0.5, "where the warrior fell")
		check(dropped.health.current == 100.0, "with the carried health")


func test_build_mode_with_number_key_and_click() -> void:
	var m := await _setup()
	var warrior: Warrior = m.get_node("Warrior")
	var storage: Inventory = m.get_node("Fortress").storage
	storage.add(&"wood", 15)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	check(warrior.builder.selected == TURRET, "key 1 picks the turret")
	aim_at(warrior, warrior.global_position + Vector3(4, 0, 0))
	await frames(2)
	check(warrior.builder.get_node("Ghost").visible, "a ghost shows where it will go")
	Input.action_press(&"attack")
	await frames(2)
	Input.action_release(&"attack")
	check(m.get_node("Structures").structures().size() == 1, "clicking places it")
	check(storage.get_amount(&"wood") == 0, "and pays for it")

	Input.action_press(&"cancel")
	await frames(2)
	Input.action_release(&"cancel")
	check(warrior.builder.selected == null, "cancel leaves build mode")
	check(not warrior.builder.get_node("Ghost").visible, "ghost hidden")


func test_radial_menu_picks_with_stick() -> void:
	var m := await _setup()
	var warrior: Warrior = m.get_node("Warrior")
	Input.action_press(&"build")
	await frames(2)
	check(warrior.builder.radial_open, "holding build opens the radial menu")
	Input.action_press(&"aim_down", 1.0)  # second entry sits at the bottom with two entries
	await frames(2)
	check(warrior.builder.radial_highlight == 1, "stick highlights an entry, got %d" % warrior.builder.radial_highlight)
	Input.action_release(&"build")
	Input.action_release(&"aim_down")
	await frames(2)
	check(not warrior.builder.radial_open, "releasing closes the menu")
	check(warrior.builder.selected == BARRICADE, "and picks the highlighted entry")
