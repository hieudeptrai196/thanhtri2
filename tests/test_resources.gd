extends GameTest


func test_chopping_and_mining_fill_inventory() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	var tree_node := spawn_resource(m, TREE_SCENE, Vector3(-30, 0, 20))
	warrior.global_position = tree_node.global_position + Vector3(1.6, 0.1, 0)
	check(await attack_until_freed(warrior, tree_node), "tree is used up")
	check(warrior.inventory.get_amount(&"wood") == 5, "tree gives 5 wood, got %d" % warrior.inventory.get_amount(&"wood"))

	var rock := spawn_resource(m, ROCK_SCENE, Vector3(-40, 0, 40))
	warrior.global_position = rock.global_position + Vector3(2.0, 0.1, 0)
	check(await attack_until_freed(warrior, rock), "rock is used up")
	check(warrior.inventory.get_amount(&"stone") == 5, "rock gives 5 stone")


func test_full_inventory_takes_nothing_more() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	var rock := spawn_resource(m, ROCK_SCENE, Vector3(-40, 0, 40))
	warrior.global_position = rock.global_position + Vector3(2.0, 0.1, 0)
	await frames(2)  # leave the fortress service zone first, or it deposits what we add
	warrior.inventory.add(&"wood", warrior.inventory.capacity - 1)
	aim_at(warrior, rock.global_position)
	Input.action_press(&"attack")
	await seconds(1.2)
	Input.action_release(&"attack")
	check(warrior.inventory.total() == warrior.inventory.capacity, "fills up to capacity")
	check(rock.amount == 4, "rock only loses what was carried away, left=%d" % rock.amount)


func test_deposit_and_repair_at_fortress() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 0)
	await frames(2)
	warrior.inventory.add(&"wood", 3)
	warrior.inventory.add(&"stone", 2)
	warrior.global_position = fortress.global_position + Vector3(7, 0.1, 0)
	await frames(3)
	check(warrior.inventory.total() == 0, "player drops everything off")
	check(fortress.storage.amounts == {&"wood": 3, &"stone": 2}, "storage gets it, got %s" % fortress.storage.amounts)

	fortress.health.apply_damage(100.0)
	Input.action_press(&"interact")
	await seconds(1.5)
	Input.action_release(&"interact")
	check(fortress.health.current == 430.0, "3 wood repair 30 health, got %.0f" % fortress.health.current)
	check(fortress.storage.get_amount(&"wood") == 0, "repair spends the wood")
	check(fortress.storage.get_amount(&"stone") == 2, "repair leaves other resources")


func test_death_drops_carried_resources_for_recovery() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 0)
	await frames(2)
	var carried := {&"wood": 4, &"stone": 2, &"bronze": 1}
	warrior.inventory.add_all(carried)
	warrior.health.apply_damage(1000.0)
	await frames(2)
	check(warrior.inventory.total() == 0, "a fallen warrior carries nothing")
	var piles := m.get_node("Pickups").get_children()
	check(piles.size() == 1 and piles[0].contents == carried, "one pile with everything carried")
	if piles.is_empty():
		return
	var pile: Pickup = piles[0]

	await seconds(m.respawn_delay + 0.5)
	check(is_instance_valid(pile), "the pile waits where the warrior fell (not grabbed on respawn)")
	warrior.global_position = pile.global_position + Vector3(0, 0.1, 0)
	await frames(5)
	check(not is_instance_valid(pile), "walking over the pile picks it up")
	check(warrior.inventory.amounts == carried, "everything is recovered, got %s" % warrior.inventory.amounts)
