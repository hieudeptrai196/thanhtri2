extends GameTest


func test_moves_up_the_screen_at_move_speed() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 40)
	await frames(2)
	var start := warrior.global_position
	Input.action_press(&"move_up")
	await seconds(1.0)
	Input.action_release(&"move_up")
	var moved := warrior.global_position - start
	moved.y = 0.0
	check(moved.normalized().dot(Vector3(-1, 0, -1).normalized()) > 0.99,
		"up moves toward the top of the screen, got %s" % moved.normalized())
	check_near(moved.length(), warrior.move_speed, 0.3, "distance in one second")


func test_fortress_blocks_player() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = fortress.global_position + Vector3(0, 0.1, 10)
	Input.action_press(&"move_up")
	Input.action_press(&"move_right")  # up + right = world -Z, straight into the fortress
	await seconds(4.0)
	var offset := warrior.global_position - fortress.global_position
	check(offset.z > 5.2, "player stays outside the fortress, z offset=%.2f" % offset.z)


func test_ready_departs_at_stop() -> void:
	var m := await start_match()
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if follower.is_stopped:
			break
	check(follower.is_stopped, "fortress reaches the stop")
	Input.action_press(&"ready")
	await frames(2)
	Input.action_release(&"ready")
	await frames(2)
	check(not follower.is_stopped, "ready makes the fortress depart")


func test_mouse_aim_points_at_cursor() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	var camera: Camera3D = m.get_node("IsoCamera")
	var target := warrior.global_position + Vector3(-3, 0, -7)
	var aim := warrior.input.aim_from_screen(camera.unproject_position(target))
	var expected := (target - warrior.global_position).normalized()
	check(aim.dot(expected) > 0.999, "aim %s should match %s" % [aim, expected])


func test_attacks_automatically_and_prefers_aim_direction() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(30, 0.1, 30)
	var behind := spawn_dummy(m, Vector3(28.6, 0, 30))   # nearer, opposite the aim
	var ahead := spawn_dummy(m, Vector3(32.0, 0, 30))    # farther, in the aim direction
	aim_at(warrior, Vector3(40, 0, 30))
	await frames(3)
	check(ahead.get_node("Health").current < 50.0, "first swing goes to the dummy in the aim direction")
	check(behind.get_node("Health").current == 50.0, "the nearer dummy behind is not chosen first")
	await seconds(6.0)  # 2 dummies × 5 hits × 0.5 s
	check(not is_instance_valid(ahead) and not is_instance_valid(behind), "keeps attacking on its own until both are gone")


func test_auto_attack_prefers_enemies_over_trees() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(30, 0.1, 30)
	var tree_node := spawn_resource(m, TREE_SCENE, Vector3(31.5, 0, 30))
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = Vector3(28.0, 0, 30)
	await frames(2)
	for action in AIM_ACTIONS:
		Input.action_release(action)
	await seconds(1.6)
	check(warrior.inventory.get_amount(&"wood") == 0, "no chopping while an enemy is in reach")
	await seconds(3.0)
	check(not is_instance_valid(enemy), "the enemy goes down first")
	check(warrior.inventory.get_amount(&"wood") > 0, "then it chops the tree on its own")


func test_dash_moves_fast_has_cooldown_and_dodges() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 40)
	await frames(2)
	var start := warrior.global_position
	Input.action_press(&"move_up")
	Input.action_press(&"dash")
	await frames(2)
	Input.action_release(&"dash")
	check(warrior.is_dashing(), "dash starts")
	check(not warrior.get_node("Hurtbox").monitorable, "cannot be hit while dashing")
	await seconds(warrior.dash_duration + 0.05)
	Input.action_release(&"move_up")
	var moved := warrior.global_position - start
	moved.y = 0.0
	check(moved.length() > warrior.dash_distance, "dash covers its distance quickly (%.1f m)" % moved.length())
	check(warrior.get_node("Hurtbox").monitorable, "can be hit again after the dash")

	var before := warrior.global_position
	Input.action_press(&"dash")
	await frames(2)
	Input.action_release(&"dash")
	check(not warrior.is_dashing(), "no second dash during the cooldown")
	await seconds(warrior.dash_cooldown)
	Input.action_press(&"dash")
	await frames(2)
	Input.action_release(&"dash")
	check(warrior.is_dashing(), "dash is available again after the cooldown")


func test_dies_and_respawns_next_to_fortress() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.health.apply_damage(1000.0)
	check(not warrior.is_alive and not warrior.visible, "a fallen warrior is gone")
	await seconds(m.respawn_delay + 0.2)
	check(warrior.is_alive and warrior.visible, "warrior respawns")
	check(warrior.health.current == warrior.health.max_health, "respawns at full health")
	check_near(warrior.global_position.distance_to(fortress.global_position), 8.0, 0.5, "respawn distance")
