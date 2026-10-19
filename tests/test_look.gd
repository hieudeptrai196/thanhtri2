extends GameTest
## M3 playtest build: models, scenery, fortress look and sounds (gameplay must not depend on them).


func test_warrior_model_follows_class() -> void:
	var m: Match = await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	var model: CharacterModel = warrior.get_node("Model")
	check(model.animation_player != null, "a rigged model with animations")
	check(not warrior.get_node("Body").visible, "placeholder capsule hidden")
	warrior.apply_class(PlayerClasses.find(&"shaman"))
	await frames(1)
	var meshes := model.find_children("*", "MeshInstance3D", true, false).map(func(n: Node) -> String: return String(n.name))
	check(meshes.any(func(n: String) -> bool: return n.begins_with("Mage")), "the Thầy pháp wears the mage model")
	var ring: MeshInstance3D = warrior.get_node("ClassRing")
	check((ring.mesh.material as StandardMaterial3D).albedo_color.is_equal_approx(Color(PlayerClasses.find(&"shaman").color, 0.75)),
		"class colour on the ring")


func test_warrior_runs_and_rests() -> void:
	var m: Match = await start_match()
	var warrior: Warrior = m.get_node("Warrior")
	var model: CharacterModel = warrior.get_node("Model")
	warrior.global_position = m.get_node("Fortress").global_position + Vector3(20, 0.1, 20)
	Input.action_press(&"move_right")
	await seconds(0.5)
	check(model.current in [&"Running_A", &"Running_B"], "running while moving (%s)" % model.current)
	Input.action_release(&"move_right")
	await seconds(0.6)
	check(model.current == &"Idle_A", "idle when still (%s)" % model.current)


func test_enemies_are_skeletons_with_merged_bodies() -> void:
	var m: Match = await start_match()
	var spawner: Spawner = m.get_node("Spawner")
	for i in 4:
		var enemy := spawner.spawn_one()
		var model: CharacterModel = enemy.get_node("Model")
		var names := model.find_children("*", "MeshInstance3D", true, false).map(func(n: Node) -> String: return String(n.name))
		check(names.has("MergedBody"), "body merged into one mesh")
		check(names.size() <= 4, "few meshes per enemy: merged body + held items (%d)" % names.size())
		check(not names.any(func(n: String) -> bool: return n.contains("Hat") or n.contains("Hood")), "no hats or hoods that look like players")


func test_scenery_lines_the_road_and_is_cleaned_up() -> void:
	var m: Match = await start_match()
	var content: RouteContent = m.get_node("RouteContent")
	var scenery := content.get_children().filter(func(n: Node) -> bool: return n.is_in_group(&"scenery"))
	check(scenery.size() > 10, "roadside scenery placed (%d)" % scenery.size())
	for node: Node3D in scenery:
		check(node.get_node_or_null(^"CollisionShape3D") == null, "scenery has no collision")
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	follower.base_speed = 300.0
	await seconds(2.0)
	follower.base_speed = 0.0
	var behind := content._spawned.filter(func(e: Array) -> bool:
		return is_instance_valid(e[0]) and e[0].is_in_group(&"scenery") and e[1] < follower.distance - content.despawn_behind - 1.0)
	check(behind.is_empty(), "scenery far behind is freed")


func test_fortress_wheels_turn_and_tier_changes_walls() -> void:
	var m: Match = await start_match(1, false, true)
	var fortress: Fortress = m.get_node("Fortress")
	clear_random_bombs(m)
	var look: FortressLook = fortress.get_node("Look")
	var wheel: Node3D = look._wheels[0]
	var before := wheel.basis
	await seconds(0.5)
	check(not wheel.basis.is_equal_approx(before), "wheels turn while the fortress moves")
	var walls_before: Node = look._walls
	fortress.storage.add_all({&"wood": 999, &"bronze": 999, &"coal": 999})
	check(fortress.upgrade_tier(), "upgraded")
	await frames(1)
	check(look._walls != walls_before and look._tier == 1, "stone walls replace the palisade")


func test_sounds_are_capped() -> void:
	var m: Match = await start_match()
	var cap: int = Sfx.SOUNDS[&"hit"][2]
	for i in cap + 5:
		Sfx.play(m, &"hit", Vector3.ZERO)
	check(Sfx._voices[&"hit"] == cap, "no more than %d hit sounds at once (%d)" % [cap, Sfx._voices[&"hit"]])


func test_music_follows_the_run() -> void:
	var m: Match = await start_match()
	check(m.music.current == &"battle", "march music while travelling")
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	clear_random_bombs(m)
	follower.base_speed = 300.0
	await wait_until(func() -> bool: return follower.is_stopped, 300)
	follower.base_speed = 0.0
	check(m.music.current == &"stop", "calmer music at a stop")
	follower.depart()
	await frames(2)
	check(m.music.current == &"battle", "back to the march on departure")


func test_fortress_rumbles_with_speed() -> void:
	var m: Match = await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	clear_random_bombs(m)
	await frames(5)
	var rumble: AudioStreamPlayer3D = fortress.get_node("Rumble")
	check(rumble.playing and rumble.volume_db > -30.0, "wheels rumble while moving (%.1f dB)" % rumble.volume_db)
	fortress.follower.base_speed = 0.0
	await frames(5)
	check(rumble.volume_db < -50.0, "quiet when still")
