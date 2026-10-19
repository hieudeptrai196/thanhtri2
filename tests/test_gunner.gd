extends GameTest
## M2.3b: a player can climb the ladder and man the fortress crossbow.


func _press_interact() -> void:
	Input.action_press(&"interact")
	await frames(2)
	Input.action_release(&"interact")
	await frames(1)


func _at_ladder(m: Match) -> Warrior:
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = fortress.ladder_point()
	await frames(2)
	return warrior


func test_climbs_on_and_off_with_interact() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var warrior := await _at_ladder(m)
	var base_damage := fortress.crossbow.damage
	var base_interval := fortress.crossbow.interval
	var base_range := fortress.crossbow.range_radius
	await _press_interact()
	check(warrior.manning and fortress.gunner == warrior, "E at the ladder mans the crossbow")
	check(fortress.gunner_peer == 1, "the gunner's peer is known")
	check_near(fortress.crossbow.damage, base_damage * fortress.manned_damage_multiplier, 0.01, "manned: harder")
	check_near(fortress.crossbow.interval, base_interval / fortress.manned_rate_multiplier, 0.01, "manned: faster")
	check_near(fortress.crossbow.range_radius, base_range * fortress.manned_range_multiplier, 0.01, "manned: farther")
	check(warrior.global_position.y > 4.0, "stands on top of the fortress")
	fortress.follower.base_speed = 300.0
	await frames(5)
	fortress.follower.base_speed = 0.0
	await frames(2)  # the seat moves after the warrior within a tick
	var seat: Vector3 = fortress.get_node("GunnerSeat").global_position
	check(warrior.global_position.distance_to(seat) < 0.5, "rides along as the fortress moves")
	await _press_interact()
	check(not warrior.manning and fortress.gunner == null and fortress.gunner_peer == 0, "E again climbs down")
	check(warrior.global_position.distance_to(fortress.ladder_point()) < 1.0, "back at the foot of the ladder")
	check_near(fortress.crossbow.damage, base_damage, 0.01, "unmanned crossbow back to its own damage")
	check_near(fortress.crossbow.range_radius, base_range, 0.01, "and its own range")


func test_dash_climbs_down() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var warrior := await _at_ladder(m)
	await _press_interact()
	check(warrior.manning, "manning")
	Input.action_press(&"dash")
	await frames(2)
	Input.action_release(&"dash")
	check(not warrior.manning and fortress.gunner == null, "dash climbs down")


func test_only_from_the_ladder_with_free_hands() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var warrior := await _at_ladder(m)
	warrior.global_position = fortress.ladder_point() + Vector3(6, 0, 0)
	await frames(2)
	await _press_interact()
	check(not warrior.manning, "too far from the ladder")
	warrior.global_position = fortress.ladder_point()
	warrior.carry(StructureTypes.ALL[0], 50.0)
	await frames(2)
	check(not fortress.can_man_crossbow(warrior), "not while carrying a structure")


func test_one_gunner_at_a_time() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var first := await _at_ladder(m)
	var second: Warrior = m.spawn_player(2)
	second.input.remote = true
	second.global_position = fortress.ladder_point() + Vector3(0.8, 0, 0)
	await frames(2)
	await _press_interact()
	check(first.manning, "first one up")
	check(not fortress.try_man_crossbow(second), "the second cannot climb up while it is taken")
	check(not second.manning and fortress.gunner == first, "first one keeps it")


func test_manned_crossbow_shoots_where_aimed() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.thorns_damage = 0.0
	var warrior := await _at_ladder(m)
	var spawner: Spawner = m.get_node("Spawner")
	var near: Enemy = spawner.spawn_one()
	near.move_speed = 0.0
	near.global_position = fortress.global_position + Vector3(8, 0, 0)
	# Beyond the unmanned range (10.5), inside the manned one (15.75).
	var far: Enemy = spawner.spawn_one()
	far.move_speed = 0.0
	far.global_position = fortress.global_position + Vector3(-14, 0, 0)
	await _press_interact()
	check(warrior.manning, "manning")
	aim_at(warrior, far.global_position)
	await seconds(1.5)
	check(not is_instance_valid(far) or far.get_node("Health").current < far.get_node("Health").max_health,
		"hits the aimed enemy, out of the unmanned range")
	check(near.get_node("Health").current == near.get_node("Health").max_health, "ignores the nearer one off the aim")
	check(fortress.crossbow.aim_direction.x < -0.9, "the crossbow follows the aim")


func test_falling_on_the_crossbow_frees_it() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var warrior := await _at_ladder(m)
	await _press_interact()
	warrior.health.apply_damage(9999.0)
	await frames(2)
	check(not warrior.manning and fortress.gunner == null, "the crossbow is free again")
	check(warrior.global_position.distance_to(fortress.ladder_point()) < 1.0, "fell at the foot of the ladder, not on the roof")


func test_enemies_do_not_chase_the_gunner() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var warrior := await _at_ladder(m)
	await _press_interact()
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.move_speed = 0.0
	enemy.global_position = fortress.ladder_point() + Vector3(0, 0, 3)
	await frames(1)
	check(enemy._pick_target() == fortress, "goes for the walls, not the player up on the crossbow")
	await _press_interact()
	await frames(1)
	check(enemy._pick_target() == warrior, "chases the player again once down")


func test_client_mans_the_crossbow() -> void:
	var matches := await start_net_match(1, 1, 24830)
	var host: Match = matches[0]
	var client: Match = matches[1]
	var fortress: Fortress = host.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	# Input is shared by both machines: keep the host's warrior away from the ladder.
	host.local_warrior.global_position = fortress.ladder_point() + Vector3(20, 0, 0)
	var remote := host.player_by_peer(client.multiplayer.get_unique_id())
	remote.global_position = fortress.ladder_point()
	await wait_until(func() -> bool: return client.get_node("Fortress").can_man_crossbow(client.local_warrior), 60)
	await _press_interact()
	await wait_until(func() -> bool: return client.local_warrior.manning, 60)
	check(remote.manning and fortress.gunner == remote, "the host puts the client's warrior on the crossbow")
	check(not host.local_warrior.manning, "the host's own warrior stays down")
	check(client.local_warrior.manning, "the client knows it is manning")
	check(client.get_node("Fortress").gunner_peer == remote.peer_id, "the client knows who mans it")
