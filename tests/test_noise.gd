extends GameTest


func test_noise_rises_while_marching_and_faster_in_overdrive() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 50)
	var noise: NoiseMeter = m.noise
	await seconds(10.0)
	check_near(noise.value, 10.0 * noise.passive_per_second, 0.2, "passive noise after 10 s")
	var before := noise.value
	m.request_overdrive()
	await seconds(5.0)
	check_near(noise.value - before, 5.0 * (noise.passive_per_second + noise.overdrive_per_second), 0.3, "overdrive is louder")


func test_noisy_actions_add_noise() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	m.get_node("Fortress").storage.add(&"coal", 50)
	var noise: NoiseMeter = m.noise
	noise.passive_per_second = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	var tree_node := spawn_resource(m, TREE_SCENE, Vector3(-30, 0, 20))
	warrior.global_position = tree_node.global_position + Vector3(1.6, 0.1, 0)
	await attack_until_freed(warrior, tree_node)
	check_near(noise.value, 5 * tree_node.noise_per_hit if is_instance_valid(tree_node) else 1.5, 0.01, "chopping a tree makes noise")


func test_stop_calms_noise_and_levels_follow_value() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 50)
	var noise: NoiseMeter = m.noise
	noise.add(60.0)
	check(noise.level() == NoiseMeter.Level.SWARM, "60 is a swarm")
	fortress.follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if fortress.follower.is_stopped:
			break
	check(noise.value <= noise.stop_calm_to, "reaching a stop calms noise, now %.1f" % noise.value)
	var at_stop := noise.value
	await seconds(3.0)
	noise.add(20.0)
	check(noise.value == at_stop, "no noise builds up while stopped")
	noise.value = 0.0
	for pair in [[0.0, NoiseMeter.Level.QUIET], [30.0, NoiseMeter.Level.PROBING], [80.0, NoiseMeter.Level.HEAVY], [100.0, NoiseMeter.Level.PURSUIT]]:
		noise.value = pair[0]
		check(noise.level() == pair[1], "level at %.0f" % pair[0])


func test_pursuit_spawns_from_behind_and_escalates() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.storage.add(&"coal", 50)
	var noise: NoiseMeter = m.noise
	var spawner: Spawner = m.get_node("Spawner")
	var quiet_rate := noise.spawn_rate_multiplier()
	noise.add(100.0)
	check(noise.level() == NoiseMeter.Level.PURSUIT, "full noise means pursuit")
	check(noise.spawn_rate_multiplier() > quiet_rate * 1.9, "waves come about twice as often")
	spawner.spawn_wave(6)
	var behind := fortress.global_basis.z
	behind.y = 0.0
	var from_behind := 0
	for enemy: Node3D in spawner.get_children():
		var offset := enemy.global_position - fortress.global_position
		offset.y = 0.0
		if offset.normalized().dot(behind.normalized()) > cos(deg_to_rad(spawner.pursuit_rear_degrees + spawner.pack_spread_degrees + 1.0)):
			from_behind += 1
	check(from_behind == spawner.get_child_count(), "pursuit waves come from behind (%d of %d)" % [from_behind, spawner.get_child_count()])
	await seconds(10.0)
	check(noise.pursuit_time > 9.0 and noise.enemy_speed_multiplier() > 1.05, "enemies speed up as pursuit drags on")


func test_divine_crossbow_charges_and_fires() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.storage.add(&"coal", 50)
	var divine := fortress.divine_crossbow
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = warrior.global_position + Vector3(2, 0, 3)
	await attack_until_freed(warrior, enemy)
	await frames(2)
	check(divine.charge == divine.charge_per_kill, "a kill charges it")
	warrior.inventory.add(&"wood", 4)
	warrior.global_position = fortress.global_position + Vector3(7, 0.1, 0)
	await frames(3)
	check(divine.charge == divine.charge_per_kill + 4 * divine.charge_per_deposited_unit, "deposits charge it")
	check(not m.request_divine_crossbow(), "cannot fire before it is full")

	divine.add_charge(divine.max_charge)
	var spawner: Spawner = m.get_node("Spawner")
	var near: Enemy = spawner.spawn_one()
	near.move_speed = 0.0
	near.global_position = fortress.global_position + Vector3(15, 0, 0)
	near.apply_scaling(5.0, 1.0)
	var far: Enemy = spawner.spawn_one()
	far.move_speed = 0.0
	far.global_position = fortress.global_position + Vector3(40, 0, 0)
	await frames(3)
	var noise_before: float = m.noise.value
	var key := InputEventKey.new()
	key.physical_keycode = KEY_G
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	check(divine.charge == 0.0, "G fires it and empties the charge")
	check_near(near.get_node("Health").max_health - near.get_node("Health").current, divine.damage, 0.01, "hits enemies around the fortress")
	check(far.get_node("Health").current == far.get_node("Health").max_health, "but not beyond its reach")
	check(m.noise.value >= noise_before + divine.noise - 0.01, "and it is loud")
