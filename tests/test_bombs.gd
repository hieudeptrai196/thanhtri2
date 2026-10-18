extends GameTest


func test_fortress_triggers_each_bomb_once_along_route() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var follower := fortress.follower
	var bomb1: HiddenBomb = m.get_node("Bombs/Bomb1")
	var bomb2: HiddenBomb = m.get_node("Bombs/Bomb2")
	var bomb_damage := bomb1.damage + bomb2.damage  # bombs free themselves after exploding
	var explosions := []
	bomb1.exploded.connect(func(at: Vector3) -> void: explosions.append(at))
	bomb2.exploded.connect(func(at: Vector3) -> void: explosions.append(at))
	follower.base_speed = 60.0

	for i in 600:
		await frames(1)
		if fortress.global_position.z < -50.0:
			break
	check(explosions.size() == 1, "first bomb explodes once, got %d" % explosions.size())
	check(fortress.health.current == fortress.health.max_health - bomb1.damage,
		"fortress takes the bomb damage, hp=%.0f" % fortress.health.current)
	check(is_instance_valid(bomb2), "second bomb is still waiting")

	var ended := [false]
	follower.reached_end.connect(func() -> void: ended[0] = true)
	for i in 1200:
		await frames(1)
		if follower.is_stopped:
			follower.depart()
		if ended[0]:
			break
	check(ended[0], "fortress reaches the end")
	check(explosions.size() == 2, "both bombs exploded once each, got %d" % explosions.size())
	check(fortress.health.current == fortress.health.max_health - bomb_damage,
		"two bomb hits in total, hp=%.0f" % fortress.health.current)
	await seconds(0.6)
	check(not is_instance_valid(bomb1) and not is_instance_valid(bomb2), "spent bombs are removed")


func test_player_and_enemies_do_not_trigger_bombs() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var bomb: HiddenBomb = m.get_node("Bombs/Bomb1")
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = bomb.global_position + Vector3(0, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = bomb.global_position + Vector3(0.5, 0, 0)
	await seconds(1.0)
	check(is_instance_valid(bomb) and not bomb._spent, "bomb ignores players and enemies")
	check(fortress.health.current == fortress.health.max_health, "fortress untouched")


func test_bomb_is_invisible_until_it_explodes() -> void:
	var m := await start_match()
	var bomb: HiddenBomb = m.get_node("Bombs/Bomb1")
	var visible_meshes := bomb.find_children("*", "MeshInstance3D", true, false).filter(
		func(mesh: MeshInstance3D) -> bool: return mesh.visible)
	check(visible_meshes.is_empty(), "nothing of the bomb is drawn before it explodes")
