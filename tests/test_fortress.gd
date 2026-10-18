extends GameTest


func test_stops_at_each_interval_and_follows_the_road() -> void:
	var m := await start_match()
	var route: EndlessRoute = m.get_node("Route")
	var fortress: Fortress = m.get_node("Fortress")
	var follower := fortress.follower
	follower.base_speed = 120.0
	var stop_distances: Array[float] = []
	var last := fortress.global_position
	var facing_errors := 0
	for i in 1500:
		await frames(1)
		var move := fortress.global_position - last
		if move.length() > 0.01 and (-fortress.global_basis.z).dot(move.normalized()) < 0.9:
			facing_errors += 1
		last = fortress.global_position
		if follower.is_stopped:
			stop_distances.append(follower.distance)
			if stop_distances.size() == 2:
				break
			await frames(20)
			check(follower.is_stopped, "stays stopped until departure")
			follower.depart()

	check(stop_distances.size() == 2, "reaches two stops, got %d" % stop_distances.size())
	if stop_distances.size() == 2:
		check_near(stop_distances[0], route.stop_distance(0), 0.01, "first stop distance")
		check_near(stop_distances[1], route.stop_distance(1), 0.01, "second stop distance")
	check(fortress.global_position.distance_to(route.position_at(follower.distance)) < 0.01,
		"fortress sits on the road")
	check(facing_errors == 0, "faces its travel direction (%d bad frames)" % facing_errors)


func test_speed_scales_with_health() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.health.apply_damage(250.0)
	check_near(fortress.follower.speed_multiplier, 0.7, 0.001, "multiplier at half health")
	var start := fortress.follower.distance
	await seconds(1.0)
	check_near(fortress.follower.distance - start, 2.1, 0.1, "measured speed at half health (m/s)")
	fortress.health.apply_damage(9999.0)
	check_near(fortress.follower.speed_multiplier, 0.4, 0.001, "multiplier at zero health (floor)")


func test_fortress_crossbow_hits_enemies_at_its_walls_only() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.thorns_damage = 0.0
	m.get_node("Warrior").global_position = Vector3(-60, 0.1, 30)
	var spawner: Spawner = m.get_node("Spawner")
	var far: Enemy = spawner.spawn_one()
	far.move_speed = 0.0
	far.global_position = fortress.global_position + Vector3(20, 0, 0)
	var near: Enemy = spawner.spawn_one()
	near.global_position = fortress.global_position + Vector3(8, 0, 0)
	await seconds(3.0)
	check(not is_instance_valid(near) or near.get_node("Health").current < near.get_node("Health").max_health,
		"the crossbow shoots an enemy at the walls")
	check(far.get_node("Health").current == far.get_node("Health").max_health, "it ignores enemies farther out")
	await seconds(6.0)
	check(not is_instance_valid(near), "it can bring down a lone attacker")


func test_thorns_hurt_attackers() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.crossbow.enabled = false
	m.get_node("Warrior").global_position = Vector3(-60, 0.1, 30)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = fortress.global_position + Vector3(7, 0, 0)
	await seconds(4.0)
	var hits := roundi((fortress.health.max_health - fortress.health.current) / enemy.damage)
	check(hits >= 2, "the enemy hit the fortress (%d hits)" % hits)
	check_near(enemy.get_node("Health").max_health - enemy.get_node("Health").current, hits * fortress.thorns_damage, 0.01,
		"each hit costs the attacker the thorns damage")
