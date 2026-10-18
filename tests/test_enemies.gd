extends GameTest


func test_spawner_spawns_on_ring_around_fortress() -> void:
	var m := await start_match(42, true)
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var spawner: Spawner = m.get_node("Spawner")
	m.get_node("Warrior").global_position = Vector3(150, 0.1, 60)
	await seconds(spawner.interval + 0.2)
	check(spawner.alive_count() == 1, "one enemy after one interval, got %d" % spawner.alive_count())
	if spawner.alive_count() > 0:
		var enemy: Node3D = spawner.get_child(0)
		var flat := Vector3(enemy.global_position.x, 0, enemy.global_position.z)
		check_near(flat.distance_to(fortress.global_position), spawner.ring_radius, 1.5, "spawn distance")


func test_enemy_walks_to_and_damages_fortress() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	m.get_node("Warrior").global_position = Vector3(150, 0.1, 60)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = fortress.global_position + Vector3(0, 0, 25)
	await frames(2)
	var start := enemy.global_position.distance_to(fortress.global_position)
	await seconds(2.0)
	check_near(start - enemy.global_position.distance_to(fortress.global_position), 7.0, 0.5,
		"walks toward the fortress at move speed (m in 2 s)")
	await seconds(6.0)
	check(fortress.health.current < fortress.health.max_health, "damages the fortress")


func test_enemy_switches_to_nearby_player() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = fortress.global_position + Vector3(0, 0, 30)
	warrior.global_position = enemy.global_position + Vector3(0, 0.1, 5)
	await seconds(4.0)
	check(warrior.health.current < warrior.health.max_health, "attacks the nearby player")
	check(fortress.health.current == fortress.health.max_health, "leaves the fortress alone meanwhile")


func test_killed_enemy_drops_bronze() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = warrior.global_position + Vector3(2, 0, 3)
	check(await attack_until_freed(warrior, enemy), "player kills the enemy")
	await frames(2)
	var piles := m.get_node("Pickups").get_children()
	check(piles.size() == 1 and piles[0].contents == {&"bronze": 1}, "drops one bronze, got %s" % [
		piles.map(func(p: Pickup) -> Dictionary: return p.contents)])


func test_stop_is_safe_zone() -> void:
	var m := await start_match(1, true)
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	var spawner: Spawner = m.get_node("Spawner")
	for i in 3:
		spawner.spawn_one()
	follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if follower.is_stopped:
			break
	await frames(5)
	check(spawner.alive_count() == 0, "enemies are cleared at a stop")
	check(not spawner.active, "spawning pauses at a stop")
	await seconds(spawner.interval * 2.0)
	check(spawner.alive_count() == 0, "nothing spawns while stopped")
	follower.depart()
	check(spawner.active, "spawning resumes on departure")
