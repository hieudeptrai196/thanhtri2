extends GameTest
## Each class attacks its own way: wide slash, ground smash, thrown axe, magic orb, crossbow bolt.


func _setup(m: Match, class_id: StringName) -> Warrior:
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	clear_random_bombs(m)
	var warrior: Warrior = m.get_node("Warrior")
	warrior.apply_class(PlayerClasses.find(class_id))
	warrior.global_position = fortress.global_position + Vector3(25, 0.1, 25)
	await frames(2)
	return warrior


func _still_enemy(m: Match, at: Vector3) -> Enemy:
	var enemy: Enemy = (m.get_node("Spawner") as Spawner).spawn_one()
	enemy.move_speed = 0.0
	enemy.damage = 0.0
	enemy.get_node("Health").set_max_health(1e6)
	enemy.global_position = at
	return enemy


func _hurt(enemy: Enemy) -> bool:
	var health: HealthComponent = enemy.get_node("Health")
	return health.current < health.max_health


func test_general_slashes_up_close() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m, &"general")
	check(warrior.weapon.style == MeleeWeapon.Style.ARC, "Võ tướng slashes")
	var near := _still_enemy(m, warrior.global_position + Vector3(2.0, 0, 0))
	var far := _still_enemy(m, warrior.global_position + Vector3(6.0, 0, 0))
	await seconds(1.0)
	check(_hurt(near), "hits the enemy beside him")
	check(not _hurt(far), "cannot reach one 6 m away")


func test_engineer_smash_hits_a_group() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m, &"engineer")
	check(warrior.weapon.style == MeleeWeapon.Style.SMASH, "Công binh smashes")
	var a := _still_enemy(m, warrior.global_position + Vector3(1.6, 0, 0))
	var b := _still_enemy(m, warrior.global_position + Vector3(1.6, 0, 1.2))
	var c := _still_enemy(m, warrior.global_position + Vector3(1.6, 0, -1.2))
	await seconds(1.2)
	check(_hurt(a) and _hurt(b) and _hurt(c), "one smash hurts the whole group")


func test_mechanic_shoots_from_afar() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m, &"mechanic")
	check(warrior.weapon.style == MeleeWeapon.Style.PROJECTILE, "Thợ máy shoots")
	var enemy := _still_enemy(m, warrior.global_position + Vector3(10.0, 0, 0))
	await seconds(1.2)
	check(_hurt(enemy), "a bolt hits an enemy 10 m away")
	check(warrior.global_position.distance_to(enemy.global_position) > 9.0, "without walking up to it")


func test_shaman_orb_splashes() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m, &"shaman")
	var target := _still_enemy(m, warrior.global_position + Vector3(8.0, 0, 0))
	var neighbour := _still_enemy(m, warrior.global_position + Vector3(8.0, 0, 1.2))
	await seconds(2.0)
	check(_hurt(target) and _hurt(neighbour), "the orb also hurts the enemy next to its target")


func test_woodcutter_axe_still_gathers_wood() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m, &"woodcutter")
	spawn_resource(m, TREE_SCENE, warrior.global_position + Vector3(6.0, 0, 0))
	await seconds(2.0)
	check(warrior.inventory.get_amount(&"wood") > 0, "a thrown axe chops wood from 6 m")


func test_client_sees_the_shots() -> void:
	var matches := await start_net_match(1, 1, 24880)
	var host: Match = matches[0]
	var client: Match = matches[1]
	host.get_node("Fortress").follower.base_speed = 0.0
	var shooter := host.player_by_peer(client.multiplayer.get_unique_id())
	shooter.apply_class(PlayerClasses.find(&"mechanic"))
	shooter.global_position = host.get_node("Fortress").global_position + Vector3(25, 0.1, 25)
	var enemy := _still_enemy(host, shooter.global_position + Vector3(9.0, 0, 0))
	var seen := await wait_until(func() -> bool:
		return client.get_children().any(func(n: Node) -> bool: return n is Projectile), 180)
	check(seen, "the client shows the bolts the host fires")
	check(client.get_children().filter(func(n: Node) -> bool: return n is Projectile).all(
		func(p: Projectile) -> bool: return p.damage == 0.0), "client bolts are pictures only")
	check(await wait_until(func() -> bool: return _hurt(enemy), 120), "the host's bolts do the damage")
