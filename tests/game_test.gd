class_name GameTest
extends RefCounted
## Base for headless gameplay tests. The runner calls every `test_*` method on a fresh instance;
## a test typically calls `start_match()` and drives the game through physics frames and input.
## Run with: tests/run.sh [filter]

const MAIN_SCENE := preload("res://scenes/main.tscn")
const DUMMY_SCENE := preload("res://combat/training_dummy.tscn")
const TREE_SCENE := preload("res://resources/tree.tscn")
const COAL_SCENE := preload("res://resources/coal_deposit.tscn")
const AIM_ACTIONS: Array[StringName] = [&"aim_left", &"aim_right", &"aim_up", &"aim_down"]

var tree: SceneTree
var failures: PackedStringArray = []
## Set when the test method returns (the runner uses it to detect hangs).
var finished: bool = false

var _scene: Node


## Instantiates the main scene and returns its Match node. Enemy spawning is off unless asked;
## the fortress storage starts empty unless `keep_starting_resources`.
func start_match(rng_seed: int = 1, spawn_enemies: bool = false, keep_starting_resources: bool = false) -> Node:
	if is_instance_valid(_scene):
		_scene.free()
	_scene = MAIN_SCENE.instantiate()
	var match_node := _scene.get_node("Match")
	match_node.rng_seed = rng_seed
	tree.root.add_child(_scene)
	await frames(1)
	match_node.get_node("Spawner").active = spawn_enemies
	if not keep_starting_resources:
		match_node.get_node("Fortress").storage.take_all()
	return match_node


## Runs one test method and flags completion; the runner watches `finished` with a timeout.
func run(test_name: String) -> void:
	await call(test_name)
	finished = true


func cleanup() -> void:
	tree.paused = false
	for action in InputMap.get_actions():
		if not String(action).begins_with("ui_"):
			Input.action_release(action)
	if is_instance_valid(_scene):
		_scene.free()


func frames(count: int) -> void:
	for i in count:
		await tree.physics_frame


func seconds(duration: float) -> void:
	await frames(roundi(duration * Engine.physics_ticks_per_second))


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func check_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	check(absf(actual - expected) <= tolerance,
		"%s (got %.3f, expected %.3f ± %.3f)" % [message, actual, expected, tolerance])


## Tilts the right stick so the player's PlayerInput aims from `who` toward `target`.
func aim_at(who: Node3D, target: Vector3) -> void:
	var camera := tree.root.get_viewport().get_camera_3d()
	var direction := target - who.global_position
	direction.y = 0.0
	direction = direction.normalized()
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	var forward := Vector3(-camera.global_basis.z.x, 0.0, -camera.global_basis.z.z).normalized()
	var stick := Vector2(direction.dot(right), -direction.dot(forward))
	for action in AIM_ACTIONS:
		Input.action_release(action)
	Input.action_press(&"aim_right" if stick.x > 0.0 else &"aim_left", absf(stick.x))
	Input.action_press(&"aim_down" if stick.y > 0.0 else &"aim_up", absf(stick.y))


## Holds attack toward `target` until it is freed or `max_frames` pass. Returns true if freed.
func attack_until_freed(who: Node3D, target: Node3D, max_frames: int = 300) -> bool:
	Input.action_press(&"attack")
	for i in max_frames:
		if not is_instance_valid(target):
			break
		aim_at(who, target.global_position)
		await frames(1)
	Input.action_release(&"attack")
	return not is_instance_valid(target)


## A tree or coal deposit placed by the test, so it does not depend on the random road layout.
func spawn_resource(match_node: Node, scene: PackedScene, at: Vector3) -> ResourceNode:
	var node: ResourceNode = scene.instantiate()
	match_node.add_child(node)
	node.global_position = at
	return node


## Removes the randomly placed bombs so a test is not affected by the road layout.
func clear_random_bombs(match_node: Node) -> void:
	for bomb in match_node.get_node("RouteContent").bombs():
		bomb.free()


func spawn_dummy(match_node: Node, at: Vector3) -> Node3D:
	var dummy: Node3D = DUMMY_SCENE.instantiate()
	match_node.add_child(dummy)
	dummy.global_position = at
	return dummy
