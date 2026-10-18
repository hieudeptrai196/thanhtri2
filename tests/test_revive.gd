extends GameTest
## M2.3a: with teammates, a warrior at 0 health lies downed and can be helped up.


func _downed_pair(m: Match) -> Array:
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var first: Warrior = m.get_node("Warrior")
	var second := m.spawn_player(2)  # a second warrior on the same machine stands in for a teammate
	second.input.remote = true
	first.global_position = fortress.global_position + Vector3(0, 0.1, 25)
	second.global_position = first.global_position + Vector3(1.2, 0, 0)
	await frames(2)
	return [first, second]


func test_solo_still_falls_at_once() -> void:
	var m := await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	warrior.inventory.add(&"wood", 3)
	warrior.health.apply_damage(9999.0)
	await frames(2)
	check(not warrior.downed and not warrior.visible, "solo: no downed state")
	check(m._respawns.has(warrior), "respawn scheduled")


func test_teammate_helps_a_downed_warrior_up() -> void:
	var m := await start_match()
	var pair := await _downed_pair(m)
	var down: Warrior = pair[0]
	var helper: Warrior = pair[1]
	down.inventory.add(&"wood", 3)
	down.health.apply_damage(9999.0)
	await frames(1)
	check(down.downed and not down.is_alive and down.visible, "lies downed instead of falling")
	check(not m._respawns.has(down), "no respawn while downed")
	check(down.inventory.get_amount(&"wood") == 3, "keeps what it carries while downed")
	helper.input.apply_remote_state({"interact": true})
	var up := await wait_until(func() -> bool: return down.is_alive, roundi(down.revive_time * 60) + 30)
	check(up, "helped up after holding E")
	check_near(down.health.current, down.health.max_health * down.revive_health_ratio, 0.5, "comes back with part of its health")
	check(down.inventory.get_amount(&"wood") == 3, "still has its wood")


func test_downed_warrior_bleeds_out_alone() -> void:
	var m := await start_match()
	var pair := await _downed_pair(m)
	var down: Warrior = pair[0]
	down.inventory.add(&"wood", 3)
	down.health.apply_damage(9999.0)
	await seconds(down.bleed_out_time + 0.3)
	check(not down.downed and not down.visible, "falls after bleeding out")
	check(m._respawns.has(down) or down.is_alive, "respawn scheduled")
	check(down.inventory.get_amount(&"wood") == 0, "drops what it carried")


func test_enemies_ignore_downed_warriors() -> void:
	var m := await start_match()
	var pair := await _downed_pair(m)
	var down: Warrior = pair[0]
	pair[1].global_position += Vector3(30, 0, 0)
	down.health.apply_damage(9999.0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = down.global_position + Vector3(2, 0, 0)
	await frames(2)
	check(enemy._pick_target() != down, "a downed warrior is not chased")


func test_client_sees_downed_and_revives_over_the_network() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await wait_until(func() -> bool: return client.local_warrior != null)
	var fortress: Fortress = host.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var host_warrior := host.local_warrior
	var client_on_host := host.player_by_peer(client.multiplayer.get_unique_id())
	host_warrior.global_position = fortress.global_position + Vector3(0, 0.1, 25)
	client_on_host.global_position = host_warrior.global_position + Vector3(1.2, 0, 0)
	await seconds(0.3)
	host_warrior.health.apply_damage(9999.0)
	var mirror := client.player_by_peer(1)
	check(await wait_until(func() -> bool: return mirror.downed), "client sees the host downed")
	Input.action_press(&"interact")  # shared Input: the client's warrior holds E (the downed host cannot act)
	var up := await wait_until(func() -> bool: return host_warrior.is_alive, 300)
	Input.action_release(&"interact")
	check(up, "the client's held E revives the host")
	check(await wait_until(func() -> bool: return not mirror.downed and mirror.is_alive), "client sees it back up")
