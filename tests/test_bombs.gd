extends GameTest


func test_fortress_triggers_a_bomb_once() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var content: RouteContent = m.get_node("RouteContent")
	var bomb := content.place_bomb(fortress.follower.distance + 20.0)
	var damage := bomb.damage
	var explosions := []
	bomb.exploded.connect(func(at: Vector3) -> void: explosions.append(at))
	fortress.follower.base_speed = 30.0
	await seconds(2.0)
	check(explosions.size() == 1, "bomb explodes once, got %d" % explosions.size())
	check(fortress.health.current == fortress.health.max_health - damage,
		"fortress takes the bomb damage, hp=%.0f" % fortress.health.current)
	await seconds(0.8)
	check(not is_instance_valid(bomb), "spent bomb is removed")
	check(m.get_node("UI/HUD/%Toast").text.contains(tr("bom")), "HUD warns about the bomb")


func test_player_and_enemies_do_not_trigger_bombs() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var bomb: HiddenBomb = m.get_node("RouteContent").place_bomb(60.0)
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = bomb.global_position + Vector3(0, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = bomb.global_position + Vector3(0.5, 0, 0)
	await seconds(1.0)
	check(is_instance_valid(bomb) and not bomb._spent, "bomb ignores players and enemies")
	check(fortress.health.current == fortress.health.max_health, "fortress untouched")


func test_bomb_is_invisible_until_it_explodes() -> void:
	var m := await start_match()
	var bomb: HiddenBomb = m.get_node("RouteContent").place_bomb(60.0)
	var visible_meshes := bomb.find_children("*", "MeshInstance3D", true, false).filter(
		func(mesh: MeshInstance3D) -> bool: return mesh.visible)
	check(visible_meshes.is_empty(), "nothing of the bomb is drawn before it explodes")
